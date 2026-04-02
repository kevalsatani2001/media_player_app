package com.kkmedia.media_player

import android.app.PictureInPictureParams
import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.PresetReverb
import android.media.audiofx.Virtualizer
import android.provider.MediaStore   // àª† àª²àª¾àªˆàª¨ àª‰àª®à«‡àª°à«‹
import android.media.RingtoneManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.IntentSender
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File                   // àª† àª²àª¾àªˆàª¨ àª‰àª®à«‡àª°à«‹

class MainActivity : AudioServiceActivity() {
    private val pipChannel = "media_player/pip"
    private val eqChannel = "media_player/equalizer"
    private val ringtoneChannel = "media_player/ringtone"
    private val editChannel = "media_player/editor" // àª¨àªµà«‹ àªšà«‡àª¨àª²
    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var reverb: PresetReverb? = null
    // àª† àªµà«‡àª°àª¿àªàª¬àª²à«àª¸ àª…àª¹à«€àª‚ (Class level) àª¹à«‹àªµàª¾ àªœà«‹àªˆàª
    private var pendingResult: Result? = null
    private var pendingNewName: String? = null
    private var pendingFavouriteResult: Boolean? = null
    private var pendingFilePath: String? = null
    private val EDIT_REQUEST_CODE = 1001


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // --- RENAME CHANNEL ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, editChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "renameVideo") {
                    val filePath = call.argument<String>("path")
                    val newName = call.argument<String>("newName")
                    val isFavourite = call.argument<Boolean>("isFavourite")

                    if (filePath != null && newName != null&&isFavourite != null) {
                        pendingResult = result
                        pendingFilePath = filePath
                        pendingNewName = newName
                        pendingFavouriteResult = isFavourite
                        renameAndroidMedia(filePath, newName,isFavourite)
                    } else {
                        result.error("INVALID_ARGS", "Path or Name is null", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
        // --- RENAME CHANNEL END ---

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, pipChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enterPip" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val success = enterPictureInPictureMode(PictureInPictureParams.Builder().build())
                            result.success(success)
                        } else {
                            result.success(false)
                        }
                    }
                    "isPipSupported" -> {
                        result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    }
                    else -> result.notImplemented()
                }
            }

        // --- Ringtone channel ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ringtoneChannel)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "setRingtone" -> {
                            val id = call.argument<Int>("id") ?: -1
                            if (id < 0) {
                                result.error("INVALID_ARGS", "id is invalid", null)
                                return@setMethodCallHandler
                            }

                            val uri = Uri.withAppendedPath(
                                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                                id.toString()
                            )

                            RingtoneManager.setActualDefaultRingtoneUri(
                                applicationContext,
                                RingtoneManager.TYPE_RINGTONE,
                                uri
                            )
                            result.success(true)
                        }

                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("RINGTONE_FAILED", e.message, null)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, eqChannel)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "setEnabled" -> {
                            val enabled = call.argument<Boolean>("enabled") ?: false
                            ensureAudioEffects()
                            equalizer?.enabled = enabled
                            bassBoost?.enabled = enabled
                            virtualizer?.enabled = enabled
                            reverb?.enabled = enabled
                            result.success(true)
                        }
                        "setBassBoost" -> {
                            val percent = (call.argument<Double>("value") ?: 0.0).coerceIn(0.0, 100.0)
                            ensureAudioEffects()
                            val strength = (percent * 10).toInt().coerceIn(0, 1000).toShort()
                            bassBoost?.setStrength(strength)
                            result.success(true)
                        }
                        "setVirtualizer" -> {
                            val percent = (call.argument<Double>("value") ?: 0.0).coerceIn(0.0, 100.0)
                            ensureAudioEffects()
                            val strength = (percent * 10).toInt().coerceIn(0, 1000).toShort()
                            virtualizer?.setStrength(strength)
                            result.success(true)
                        }
                        "setReverb" -> {
                            val reverbName = call.argument<String>("value") ?: "None"
                            ensureAudioEffects()
                            val preset = when (reverbName) {
                                "Small Room" -> PresetReverb.PRESET_SMALLROOM
                                "Medium Room" -> PresetReverb.PRESET_MEDIUMROOM
                                "Large Room" -> PresetReverb.PRESET_LARGEROOM
                                "Medium Hall" -> PresetReverb.PRESET_MEDIUMHALL
                                "Large Hall" -> PresetReverb.PRESET_LARGEHALL
                                "Plate" -> PresetReverb.PRESET_PLATE
                                else -> PresetReverb.PRESET_NONE
                            }
                            reverb?.preset = preset
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("EQ_ERROR", e.message, null)
                }
            }
    }


    // Rename Logic Function
// ... àª¬àª¾àª•à«€àª¨à«‹ àª‰àªªàª°àª¨à«‹ àª•à«‹àª¡ àª àªœ àª°àª¹à«‡àª¶à«‡ ...

    // 1. àª«àª‚àª•à«àª¶àª¨àª¨à«€ àª¡à«‡àª«àª¿àª¨à«‡àª¶àª¨àª®àª¾àª‚ isFav àª‰àª®à«‡àª°à«àª¯à«àª‚
    private fun renameAndroidMedia(filePath: String, newName: String, isFav: Boolean) {
        val file = File(filePath)
        val extension = file.extension
        val fullNewName = if (newName.contains(".")) newName else "$newName.$extension"

        try {
            val cursor = contentResolver.query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.Video.Media._ID),
                MediaStore.Video.Media.DATA + "=?",
                arrayOf(file.absolutePath),
                null
            )

            if (cursor != null && cursor.moveToFirst()) {
                val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Video.Media._ID))
                cursor.close()

                val contentUri = Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id.toString())

                val contentValues = ContentValues().apply {
                    // àª¨àª¾àª® àª¬àª¦àª²àªµàª¾ àª®àª¾àªŸà«‡
                    put(MediaStore.Video.Media.DISPLAY_NAME, fullNewName)

                    // 2. àª«à«‡àªµàª°àª¿àªŸ àª¸à«àªŸà«‡àªŸàª¸ àª¸à«‡àªŸ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡ (Android 11 àª…àª¨à«‡ àª¤à«‡àª¨àª¾àª¥à«€ àª‰àªªàª° àª®àª¾àªŸà«‡)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        put(MediaStore.Video.Media.IS_FAVORITE, if (isFav) 1 else 0)
                    }
                }

                val updatedRows = contentResolver.update(contentUri, contentValues, null, null)

                if (updatedRows > 0) {
                    pendingResult?.success(true)
                    pendingFilePath = null
                    pendingNewName = null
                    pendingFavouriteResult = null
                } else {
                    pendingResult?.success(false)
                }
            } else {
                cursor?.close()
                pendingResult?.success(false)
            }
        } catch (e: Exception) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && e is RecoverableSecurityException) {
                val intentSender = e.userAction.actionIntent.intentSender
                startIntentSenderForResult(intentSender, EDIT_REQUEST_CODE, null, 0, 0, 0)
            } else {
                e.printStackTrace()
                pendingResult?.error("RENAME_FAILED", e.message, null)
            }
        }
    }

    // 3. onActivityResult àª®àª¾àª‚ àªªàª£ 3 àª†àª°à«àª—à«àª¯à«àª®à«‡àª¨à«àªŸà«àª¸ àª¸àª¾àª¥à«‡ àª•à«‹àª² àª•àª°à«‹
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == EDIT_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                if (pendingFilePath != null && pendingNewName != null && pendingFavouriteResult != null) {
                    // àª…àª¹à«€àª‚ 3 àª†àª°à«àª—à«àª¯à«àª®à«‡àª¨à«àªŸ àªªàª¾àª¸ àª•àª°à«€
                    renameAndroidMedia(pendingFilePath!!, pendingNewName!!, pendingFavouriteResult!!)
                }
            } else {
                pendingResult?.success(false)
                pendingFilePath = null
                pendingNewName = null
                pendingFavouriteResult = null
            }
        }
    }

    private fun ensureAudioEffects() {
        if (equalizer == null) {
            // Use output mix session for broad compatibility with video playback.
            equalizer = Equalizer(0, 0)
            equalizer?.enabled = false
        }
        if (bassBoost == null) {
            bassBoost = BassBoost(0, 0)
            bassBoost?.enabled = false
        }
        if (virtualizer == null) {
            virtualizer = Virtualizer(0, 0)
            virtualizer?.enabled = false
        }
        if (reverb == null) {
            reverb = PresetReverb(0, 0)
            reverb?.enabled = false
        }
    }

    override fun onDestroy() {
        equalizer?.release()
        bassBoost?.release()
        virtualizer?.release()
        reverb?.release()
        super.onDestroy()
    }
}
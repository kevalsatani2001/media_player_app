package com.nova.media.vision

import android.app.Activity
import android.app.PictureInPictureParams
import android.app.RecoverableSecurityException
import android.content.ContentValues
import android.content.Intent            // <--- Add this line
import android.content.IntentSender
import android.media.RingtoneManager
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.PresetReverb
import android.media.audiofx.Virtualizer
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings          // <--- Ensure this is here
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.videoplayer.VideoPlayerPlugin
import java.io.File

class MainActivity : AudioServiceActivity() {
    private val pipChannel = "media_player/pip"
    private val eqChannel = "media_player/equalizer"
    private val ringtoneChannel = "media_player/ringtone"
    private val editChannel = "media_player/editor"
    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var reverb: PresetReverb? = null

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

                    if (filePath != null && newName != null && isFavourite != null) {
                        pendingResult = result
                        pendingFilePath = filePath
                        pendingNewName = newName
                        pendingFavouriteResult = isFavourite
                        renameAndroidMedia(filePath, newName, isFavourite)
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
                            val success =
                                enterPictureInPictureMode(PictureInPictureParams.Builder().build())
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
                        "checkPermission" -> {
                            // Returns true if we already have permission
                            val canWrite = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                android.provider.Settings.System.canWrite(applicationContext)
                            } else {
                                true
                            }
                            result.success(canWrite)
                        }

                        "openPermissionSettings" -> {
                            // Opens the system settings screen for your app
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                val intent = Intent(android.provider.Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                                    data = Uri.parse("package:$packageName")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.success(true)
                            }
                        }

                        "setRingtone" -> {
                            val idArg = call.argument<Number>("id")
                            if (idArg == null) {
                                result.error("INVALID_ARGS", "id is null", null)
                                return@setMethodCallHandler
                            }

                            // Check permission one last time before setting
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !android.provider.Settings.System.canWrite(applicationContext)) {
                                result.error("PERMISSION_DENIED", "WRITE_SETTINGS not granted", null)
                                return@setMethodCallHandler
                            }

                            val uri = Uri.withAppendedPath(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, idArg.toLong().toString())

                            // 1. Get original song metadata from MediaStore
                            var title = "Custom Ringtone"
                            var mimeType = "audio/mp3"
                            var displayName = "ringtone_${idArg}.mp3"

                            val projection = arrayOf(
                                MediaStore.Audio.Media.TITLE,
                                MediaStore.Audio.Media.DISPLAY_NAME,
                                MediaStore.Audio.Media.MIME_TYPE
                            )
                            contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                                if (cursor.moveToFirst()) {
                                    title = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)) ?: "Custom Ringtone"
                                    displayName = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)) ?: "ringtone_${idArg}.mp3"
                                    mimeType = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)) ?: "audio/mp3"
                                }
                            }

                            // Ensure displayName is valid and has proper suffix
                            if (!displayName.contains(".") && mimeType.contains("/")) {
                                val ext = mimeType.substringAfter("/")
                                if (ext.isNotEmpty()) {
                                    displayName = "$displayName.$ext"
                                }
                            }

                            // 2. Check if a ringtone with the same display name and IS_RINGTONE = 1 already exists in MediaStore
                            var existingUri: Uri? = null
                            val ringtoneSelection = "${MediaStore.Audio.Media.IS_RINGTONE} = 1 AND ${MediaStore.Audio.Media.DISPLAY_NAME} = ?"
                            val selectionArgs = arrayOf(displayName)
                            contentResolver.query(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, arrayOf(MediaStore.Audio.Media._ID), ringtoneSelection, selectionArgs, null)?.use { cursor ->
                                if (cursor.moveToFirst()) {
                                    val existingId = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID))
                                    existingUri = Uri.withAppendedPath(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, existingId.toString())
                                }
                            }

                            if (existingUri != null) {
                                RingtoneManager.setActualDefaultRingtoneUri(applicationContext, RingtoneManager.TYPE_RINGTONE, existingUri)
                                result.success(true)
                                return@setMethodCallHandler
                            }

                            // 3. If it doesn't exist, copy the file to the Ringtones folder via MediaStore
                            val values = ContentValues().apply {
                                put(MediaStore.Audio.Media.TITLE, title)
                                put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
                                put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
                                put(MediaStore.Audio.Media.IS_RINGTONE, true)
                                put(MediaStore.Audio.Media.IS_NOTIFICATION, false)
                                put(MediaStore.Audio.Media.IS_ALARM, false)
                                put(MediaStore.Audio.Media.IS_MUSIC, false)
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    put(MediaStore.Audio.Media.RELATIVE_PATH, android.os.Environment.DIRECTORY_RINGTONES)
                                } else {
                                    val ringtonesDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_RINGTONES)
                                    if (!ringtonesDir.exists()) {
                                        ringtonesDir.mkdirs()
                                    }
                                    val ringtoneFile = File(ringtonesDir, displayName)
                                    put(MediaStore.MediaColumns.DATA, ringtoneFile.absolutePath)
                                }
                            }

                            val ringtonesUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                            val newRingtoneUri = contentResolver.insert(ringtonesUri, values)

                            if (newRingtoneUri != null) {
                                try {
                                    contentResolver.openInputStream(uri)?.use { inputStream ->
                                        contentResolver.openOutputStream(newRingtoneUri)?.use { outputStream ->
                                            inputStream.copyTo(outputStream)
                                        }
                                    }
                                    RingtoneManager.setActualDefaultRingtoneUri(applicationContext, RingtoneManager.TYPE_RINGTONE, newRingtoneUri)
                                    result.success(true)
                                } catch (e: Exception) {
                                    // Clean up on failure
                                    contentResolver.delete(newRingtoneUri, null, null)
                                    result.error("COPY_FAILED", e.message, null)
                                }
                            } else {
                                result.error("INSERT_FAILED", "Failed to insert ringtone into MediaStore", null)
                            }
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
                            val percent =
                                (call.argument<Double>("value") ?: 0.0).coerceIn(0.0, 100.0)
                            ensureAudioEffects()
                            val strength = (percent * 10).toInt().coerceIn(0, 1000).toShort()
                            bassBoost?.setStrength(strength)
                            result.success(true)
                        }

                        "setVirtualizer" -> {
                            val percent =
                                (call.argument<Double>("value") ?: 0.0).coerceIn(0.0, 100.0)
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

                val contentUri =
                    Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id.toString())

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
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: android.content.Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == EDIT_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                if (pendingFilePath != null && pendingNewName != null && pendingFavouriteResult != null) {
                    // àª…àª¹à«€àª‚ 3 àª†àª°à«àª—à«àª¯à«àª®à«‡àª¨à«àªŸ àªªàª¾àª¸ àª•àª°à«€
                    renameAndroidMedia(
                        pendingFilePath!!,
                        pendingNewName!!,
                        pendingFavouriteResult!!
                    )
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

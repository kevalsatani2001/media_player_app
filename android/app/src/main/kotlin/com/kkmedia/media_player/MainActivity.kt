package com.kkmedia.media_player

import android.app.PictureInPictureParams
import android.os.Build
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.PresetReverb
import android.media.audiofx.Virtualizer
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val pipChannel = "media_player/pip"
    private val eqChannel = "media_player/equalizer"
    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var virtualizer: Virtualizer? = null
    private var reverb: PresetReverb? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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

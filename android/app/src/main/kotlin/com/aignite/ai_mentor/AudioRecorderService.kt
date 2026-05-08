package com.aignite.ai_mentor

import android.Manifest
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.os.Build
import android.os.Environment
import android.os.IBinder
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*

/**
 * AudioRecorderService — запись аудио с микрофона для совещаний
 * и голосовых команд. Доступен для Android 10+ (API 29+).
 */
class AudioRecorderService : Service() {

    companion object {
        private const val TAG = "AiMentorAudio"
        private var methodChannel: MethodChannel? = null
        private var mediaRecorder: MediaRecorder? = null
        private var outputFilePath: String? = null
        private var isRecording = false

        fun setMethodChannel(channel: MethodChannel?) {
            methodChannel = channel
        }

        fun isRecording(): Boolean = isRecording

        fun getOutputFilePath(): String? = outputFilePath

        fun startRecording(context: android.content.Context): Boolean {
            if (isRecording) {
                Log.w(TAG, "Already recording")
                return false
            }

            // Проверяем разрешение на запись аудио
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (ActivityCompat.checkSelfPermission(
                        context,
                        Manifest.permission.RECORD_AUDIO
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    Log.e(TAG, "RECORD_AUDIO permission not granted")
                    methodChannel?.invokeMethod("onRecordingError", "Permission not granted")
                    return false
                }
            }

            try {
                val dir = File(
                    Environment.getExternalStoragePublicDirectory(
                        Environment.DIRECTORY_MUSIC
                    ),
                    "AiMentorRecordings"
                )
                if (!dir.exists()) {
                    dir.mkdirs()
                }

                val timestamp = SimpleDateFormat(
                    "yyyyMMdd_HHmmss",
                    Locale.getDefault()
                ).format(Date())
                val fileName = "meeting_$timestamp.mp4"
                outputFilePath = File(dir, fileName).absolutePath

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    mediaRecorder = MediaRecorder(android.content.Context.AUDIO_SERVICE)
                } else {
                    @Suppress("DEPRECATION")
                    mediaRecorder = MediaRecorder()
                }

                mediaRecorder?.apply {
                    setAudioSource(MediaRecorder.AudioSource.MIC)
                    setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                    setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                    setAudioSamplingRate(44100)
                    setAudioBitRate(128000)
                    setOutputFile(outputFilePath)
                    prepare()
                    start()
                }

                isRecording = true
                Log.d(TAG, "Recording started: $outputFilePath")
                methodChannel?.invokeMethod("onRecordingStarted", outputFilePath)
                return true

            } catch (e: IOException) {
                Log.e(TAG, "Failed to start recording: ${e.message}")
                methodChannel?.invokeMethod("onRecordingError", e.message)
                return false
            }
        }

        fun stopRecording(): String? {
            if (!isRecording) {
                Log.w(TAG, "Not recording")
                return null
            }

            try {
                mediaRecorder?.apply {
                    stop()
                    release()
                }
                mediaRecorder = null
                isRecording = false

                val filePath = outputFilePath
                Log.d(TAG, "Recording stopped: $filePath")
                methodChannel?.invokeMethod("onRecordingStopped", filePath)
                return filePath

            } catch (e: Exception) {
                Log.e(TAG, "Failed to stop recording: ${e.message}")
                methodChannel?.invokeMethod("onRecordingError", e.message)
                return null
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        if (isRecording) {
            stopRecording()
        }
        super.onDestroy()
    }
}

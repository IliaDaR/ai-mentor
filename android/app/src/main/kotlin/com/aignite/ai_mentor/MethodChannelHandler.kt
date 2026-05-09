package com.aignite.ai_mentor

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannelHandler — мост между Flutter (Dart) и Kotlin (Android).
 * Обрабатывает вызовы из Flutter для нативных функций:
 * - Запись аудио
 * - Перехват уведомлений
 * - Системные разрешения
 */
class MethodChannelHandler(private val activity: Activity) {

    companion object {
        private const val TAG = "AiMentorChannel"
        private const val CHANNEL = "com.aignite.ai_mentor/native"
        private const val CHANNEL_NOTIFICATIONS = "com.aignite.ai_mentor/notifications"
        private const val CHANNEL_AUDIO = "com.aignite.ai_mentor/audio"

        fun setup(flutterEngine: FlutterEngine, activity: Activity) {
            val handler = MethodChannelHandler(activity)

            // Main channel
            MethodChannel(flutterEngine.dartExecutor, CHANNEL).setMethodCallHandler { call, result ->
                handler.handleMainCall(call, result)
            }

            // Notification channel
            MethodChannel(flutterEngine.dartExecutor, CHANNEL_NOTIFICATIONS).setMethodCallHandler { call, result ->
                handler.handleNotificationCall(call, result)
            }

            // Audio channel
            MethodChannel(flutterEngine.dartExecutor, CHANNEL_AUDIO).setMethodCallHandler { call, result ->
                handler.handleAudioCall(call, result)
            }
        }
    }

    private fun handleMainCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestNotificationAccess" -> {
                requestNotificationAccess(result)
            }
            "isNotificationAccessGranted" -> {
                result.success(isNotificationAccessGranted())
            }
            "requestAudioPermission" -> {
                requestAudioPermission(result)
            }
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleNotificationCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestNotificationAccess" -> {
                requestNotificationAccess(result)
            }
            "isNotificationAccessGranted" -> {
                result.success(isNotificationAccessGranted())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleAudioCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startRecording" -> {
                val success = AudioRecorderService.startRecording(activity)
                result.success(success)
            }
            "stopRecording" -> {
                val filePath = AudioRecorderService.stopRecording()
                result.success(filePath)
            }
            "isRecording" -> {
                result.success(AudioRecorderService.isRecording())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun requestNotificationAccess(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
            activity.startActivity(intent)
            result.success(true)
        } else {
            result.success(false)
        }
    }

    private fun isNotificationAccessGranted(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            activity.contentResolver,
            "enabled_notification_listeners"
        )
        return enabledListeners?.contains(activity.packageName) == true
    }

    private fun requestAudioPermission(result: MethodChannel.Result) {
        // В реальном приложении используйте ActivityCompat.requestPermissions
        result.success(true)
    }
}

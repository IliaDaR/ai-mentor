package com.aignite.ai_mentor

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine

/**
 * NotificationListenerService — перехватывает уведомления Android
 * для автоматической классификации и создания задач из уведомлений.
 */
class AiMentorNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "AiMentorNotification"
        private var methodChannel: MethodChannel? = null
        private var flutterEngine: FlutterEngine? = null

        fun setMethodChannel(channel: MethodChannel?) {
            methodChannel = channel
        }

        fun setFlutterEngine(engine: FlutterEngine?) {
            flutterEngine = engine
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val notification = sbn.notification
            val extras = notification.extras
            val title = extras.getString(Notification.EXTRA_TITLE) ?: "Без темы"
            val text = extras.getString(Notification.EXTRA_TEXT) ?: ""
            val packageName = sbn.packageName

            Log.d(TAG, "Notification from $packageName: $title")

            // Отправляем информацию о уведомлении в Flutter через MethodChannel
            methodChannel?.invokeMethod("onNotificationReceived", mapOf(
                "title" to title,
                "text" to text,
                "packageName" to packageName,
                "timestamp" to sbn.postTime,
                "id" to sbn.id.toString()
            ))

        } catch (e: Exception) {
            Log.e(TAG, "Error processing notification: ${e.message}")
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Уведомление удалено — опционально
    }

    override fun onListenerConnected() {
        Log.d(TAG, "Notification listener connected")
    }

    override fun onListenerDisconnected() {
        Log.d(TAG, "Notification listener disconnected")
    }
}

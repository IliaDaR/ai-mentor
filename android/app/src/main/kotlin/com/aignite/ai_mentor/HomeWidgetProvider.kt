package com.aignite.ai_mentor

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * HomeWidgetProvider — виджет на главный экран Android.
 * Отображает:
 * - Следующую задачу из квадранта "Срочно-Важно"
 * - Статус фокуса (время/пауза)
 * - Кнопку быстрого запуска фокуса
 */
class AiMentorHomeWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "AiMentorWidget"
        const val WIDGET_UPDATE_ACTION = "com.aignite.ai_mentor.WIDGET_UPDATE"

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(
                context.packageName,
                R.layout.home_widget_layout
            )

            // Устанавливаем обработчики кликов
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            val openAppPendingIntent = PendingIntent.getActivity(
                context, 0, openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)

            // Кнопка "Начать фокус"
            val startFocusIntent = Intent(context, MainActivity::class.java).apply {
                action = "com.aignite.ai_mentor.START_FOCUS"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val startFocusPendingIntent = PendingIntent.getActivity(
                context, 1, startFocusIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_focus_button, startFocusPendingIntent)

            // Здесь можно установить данные из SharedPreferences/БД
            // Например, следующую задачу

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        updateWidget(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (WIDGET_UPDATE_ACTION == intent.action) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, AiMentorHomeWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            updateWidget(context, appWidgetManager, appWidgetIds)
        }
    }
}

package com.ivra.refill

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class DailyRefillWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val hotelName = widgetData.getString("active_hotel_name", "")
        val isLoggedIn = widgetData.getBoolean("widget_logged_in", false)
        val refilledRooms = widgetData.getInt("refilled_rooms_count", 0)
        val totalRooms = widgetData.getInt("total_rooms_count", 0)
        val nextPriorityRoom = widgetData.getString("next_priority_room", "")

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.daily_refill_widget)
            
            // Set hotel name
            views.setTextViewText(
                R.id.widget_hotel_name, 
                when {
                    !isLoggedIn -> "Sign in to Ivra"
                    hotelName.isNullOrEmpty() -> "Select a hotel"
                    else -> hotelName
                }
            )

            // Set progress text
            views.setTextViewText(
                R.id.widget_progress_text,
                if (!isLoggedIn) "Open the app to connect your account" else "Rooms Refilled: $refilledRooms/$totalRooms"
            )

            // Set next room text
            views.setTextViewText(
                R.id.widget_next_room_text,
                when {
                    !isLoggedIn -> "Login required"
                    nextPriorityRoom.isNullOrEmpty() -> "Next: No priority room"
                    else -> "Next: $nextPriorityRoom"
                }
            )

            // Set progress bar
            views.setProgressBar(
                R.id.widget_progress_bar,
                if (totalRooms > 0) totalRooms else 100,
                refilledRooms,
                false
            )

            // Deep link click pending intent for the widget body to launch app dashboard
            val mainIntent = Intent(Intent.ACTION_VIEW, Uri.parse("ivra://app/dashboard")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val mainPendingIntent = PendingIntent.getActivity(
                context,
                1,
                mainIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_body, mainPendingIntent)

            // Deep link click pending intent for the refresh button: ivra://app/dashboard?sync=true
            val refreshIntent = Intent(Intent.ACTION_VIEW, Uri.parse("ivra://app/dashboard?sync=true")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val refreshPendingIntent = PendingIntent.getActivity(
                context,
                2,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_button_refresh, refreshPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

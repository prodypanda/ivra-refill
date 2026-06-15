package com.ivra.refill

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class QuickScanWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val hotelName = widgetData.getString("active_hotel_name", "No Hotel Selected")

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_scan_widget)
            
            // Set hotel name
            views.setTextViewText(
                R.id.widget_hotel_name, 
                if (hotelName.isNullOrEmpty()) "No Hotel Selected" else hotelName
            )

            // Setup deep link click pending intent: ivra://app/rooms?scan=true
            val deepLinkUri = Uri.parse("ivra://app/rooms?scan=true")
            val intent = Intent(Intent.ACTION_VIEW, deepLinkUri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_button_scan, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

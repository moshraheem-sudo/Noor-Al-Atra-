package com.example.flutter_noor_alatra

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PrayerBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences("noor_alatra_prayer_times", Context.MODE_PRIVATE)
        val isActive = prefs.getBoolean("is_active", true)
        if (isActive) {
            val fajr = prefs.getString("fajr", "05:07 ص") ?: "05:07 ص"
            val sunrise = prefs.getString("sunrise", "06:33 ص") ?: "06:33 ص"
            val dhuhr = prefs.getString("dhuhr", "11:44 ص") ?: "11:44 ص"
            val maghrib = prefs.getString("maghrib", "05:09 م") ?: "05:09 م"
            MainActivity.showStaticPrayerNotification(context, fajr, sunrise, dhuhr, maghrib)
        }
    }
}

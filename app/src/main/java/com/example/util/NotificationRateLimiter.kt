package com.example.util

import android.content.Context

/**
 * Central rate limiter for all notifications across the application.
 * Ensures that AT MOST ONE notification is presented within any 60-minute (1 hour) window,
 * completely preventing batch dumps, notification spamming, or simultaneous alerts.
 */
object NotificationRateLimiter {
    private const val PREFS_NAME = "app_notification_rate_limiter_prefs"
    private const val KEY_LAST_NOTIFIED_TIME = "last_notification_timestamp_ms"
    
    // Strictly 1 notification per 1 hour (60 minutes in milliseconds)
    const val COOLDOWN_INTERVAL_MS = 60 * 60 * 1000L

    /**
     * Checks whether a notification can be posted right now.
     * If allowed, atomically records the current timestamp so subsequent concurrent workers
     * or requests are blocked for the next hour.
     */
    @Synchronized
    fun canPostNotification(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val lastTime = prefs.getLong(KEY_LAST_NOTIFIED_TIME, 0L)
        val now = System.currentTimeMillis()

        // If less than 1 hour has elapsed since the last notification, disallow
        if (now - lastTime < COOLDOWN_INTERVAL_MS) {
            return false
        }

        // Allowed: record current timestamp
        prefs.edit().putLong(KEY_LAST_NOTIFIED_TIME, now).apply()
        return true
    }

    /**
     * Returns the timestamp of the last posted notification.
     */
    fun getLastNotifiedTime(context: Context): Long {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getLong(KEY_LAST_NOTIFIED_TIME, 0L)
    }

    /**
     * Manually record that a notification was just displayed (if triggered externally).
     */
    fun recordNotificationPosted(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putLong(KEY_LAST_NOTIFIED_TIME, System.currentTimeMillis()).apply()
    }
}

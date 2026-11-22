package com.example.flutter_noor_alatra

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra("prayer_name") ?: "الصلاة"
        val muezzinPath = intent.getStringExtra("muezzin_path")
        val muezzinName = intent.getStringExtra("muezzin_name")

        AdhanAudioService.startAdhan(context, prayerName, muezzinPath, muezzinName)
    }
}

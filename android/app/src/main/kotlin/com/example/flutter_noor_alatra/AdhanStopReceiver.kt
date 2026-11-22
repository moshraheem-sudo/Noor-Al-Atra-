package com.example.flutter_noor_alatra

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AdhanStopReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AdhanAudioService.stopAdhan(context)
    }
}

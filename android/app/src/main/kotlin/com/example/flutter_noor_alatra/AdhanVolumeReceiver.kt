package com.example.flutter_noor_alatra

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AdhanVolumeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AdhanAudioService.toggleVolume(context)
    }
}

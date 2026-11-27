package com.example.flutter_noor_alatra

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import androidx.core.app.NotificationCompat
import java.io.File

class AdhanAudioService : Service() {

    companion object {
        const val ACTION_PLAY = "com.example.flutter_noor_alatra.ACTION_PLAY_ADHAN"
        const val ACTION_STOP = "com.example.flutter_noor_alatra.ACTION_STOP_ADHAN"
        const val ACTION_TOGGLE_VOLUME = "com.example.flutter_noor_alatra.ACTION_TOGGLE_VOLUME"
        const val ACTION_SET_VOLUME = "com.example.flutter_noor_alatra.ACTION_SET_VOLUME"
        const val EXTRA_IS_LOW = "extra_is_low"
        const val EXTRA_PRAYER_NAME = "extra_prayer_name"
        const val EXTRA_MUEZZIN_PATH = "extra_muezzin_path"
        const val EXTRA_MUEZZIN_NAME = "extra_muezzin_name"

        const val CHANNEL_ID = "adhan_live_audio_channel_v6"
        const val NOTIFICATION_ID = 4099

        @Volatile
        var isPlaying: Boolean = false

        @Volatile
        var isVolumeLowered: Boolean = false

        @Volatile
        var currentPrayerName: String = "الصلاة"

        private var activeService: AdhanAudioService? = null

        fun isPrayerAllowed(context: Context, prayerName: String): Boolean {
            if (prayerName.contains("تجربة")) return true
            val key = when {
                prayerName.contains("فجر") -> "fajr"
                prayerName.contains("ظهر") -> "dhuhr"
                prayerName.contains("عصر") -> "asr"
                prayerName.contains("مغرب") -> "maghrib"
                prayerName.contains("عشاء") -> "isha"
                else -> return false
            }
            val settings = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val enabled = settings.getBoolean("flutter.settings_notify_$key", true)
            val stoppedUntil = context.getSharedPreferences("adhan_playback", Context.MODE_PRIVATE)
                .getLong("stopped_until_$key", 0L)
            return enabled && System.currentTimeMillis() >= stoppedUntil
        }

        fun startAdhan(context: Context, prayerName: String, muezzinPath: String? = null, muezzinName: String? = null) {
            if (!isPrayerAllowed(context, prayerName)) return
            currentPrayerName = prayerName
            val intent = Intent(context, AdhanAudioService::class.java).apply {
                action = ACTION_PLAY
                putExtra(EXTRA_PRAYER_NAME, prayerName)
                putExtra(EXTRA_MUEZZIN_PATH, muezzinPath)
                putExtra(EXTRA_MUEZZIN_NAME, muezzinName)
            }
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        fun stopAdhan(context: Context) {
            // Stop in this process immediately: no activity launch or service-start
            // restriction should delay a notification tap.
            val keys = listOf("fajr", "dhuhr", "asr", "maghrib", "isha")
            val editor = context.getSharedPreferences("adhan_playback", Context.MODE_PRIVATE).edit()
            for (key in keys) editor.putLong("stopped_until_$key", System.currentTimeMillis() + 90000L)
            editor.apply()
            activeService?.stopAdhanAudio()
            context.stopService(Intent(context, AdhanAudioService::class.java))
        }

        fun toggleVolume(context: Context) {
            val intent = Intent(context, AdhanAudioService::class.java).apply {
                action = ACTION_TOGGLE_VOLUME
            }
            try {
                context.startService(intent)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        fun setVolume(context: Context, isLow: Boolean) {
            val intent = Intent(context, AdhanAudioService::class.java).apply {
                action = ACTION_SET_VOLUME
                putExtra(EXTRA_IS_LOW, isLow)
            }
            try {
                context.startService(intent)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    override fun onCreate() {
        super.onCreate()
        activeService = this
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        when (intent.action) {
            ACTION_PLAY -> {
                val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: "الصلاة"
                val muezzinPath = intent.getStringExtra(EXTRA_MUEZZIN_PATH)
                val muezzinName = intent.getStringExtra(EXTRA_MUEZZIN_NAME) ?: "الحاج عامر الكاظمي"
                playAdhanAudio(prayerName, muezzinPath, muezzinName)
            }
            ACTION_STOP -> {
                stopAdhanAudio()
                stopSelf()
            }
            ACTION_TOGGLE_VOLUME -> {
                setAdhanVolumeInternal(!isVolumeLowered)
            }
            ACTION_SET_VOLUME -> {
                val isLow = intent.getBooleanExtra(EXTRA_IS_LOW, false)
                setAdhanVolumeInternal(isLow)
            }
        }
        return START_NOT_STICKY
    }

    private fun setAdhanVolumeInternal(isLow: Boolean) {
        isVolumeLowered = isLow
        val vol = if (isLow) 0.2f else 1.0f
        try {
            mediaPlayer?.setVolume(vol, vol)
            Log.d("AdhanAudioService", "Adhan volume set to: $vol (isLow=$isLow)")
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, buildAdhanNotification(currentPrayerName))
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun buildAdhanNotification(prayerName: String): Notification {
        val stopIntent = Intent(this, AdhanStopReceiver::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val volumeIntent = Intent(this, AdhanVolumeReceiver::class.java).apply {
            action = ACTION_TOGGLE_VOLUME
        }
        val volumePendingIntent = PendingIntent.getBroadcast(
            this,
            1,
            volumeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val largeIconBitmap: Bitmap? = try {
            BitmapFactory.decodeResource(resources, R.drawable.app_icon)
                ?: run {
                    val drawable = packageManager.getApplicationIcon(packageName)
                    val bmp = Bitmap.createBitmap(
                        drawable.intrinsicWidth.coerceAtLeast(1),
                        drawable.intrinsicHeight.coerceAtLeast(1),
                        Bitmap.Config.ARGB_8888
                    )
                    val canvas = Canvas(bmp)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bmp
                }
        } catch (e: Exception) {
            null
        }

        val volumeActionTitle = if (isVolumeLowered) "رفع الصوت 🔊" else "خفض الصوت 🔉"
        val volumeActionIcon = if (isVolumeLowered) android.R.drawable.ic_lock_silent_mode_off else android.R.drawable.ic_lock_silent_mode

        val contentStatusText = if (isVolumeLowered) {
            "حان الآن موعد صلاة $prayerName (الصوت مخفّض 🔉 • مستمر)"
        } else {
            "حان الآن موعد صلاة $prayerName • المس لإيقاف الأذان"
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setLargeIcon(largeIconBitmap)
            .setContentTitle("أذان $prayerName المبارك 🕌")
            .setContentText(contentStatusText)
            .setContentIntent(stopPendingIntent)
            .setOngoing(false)
            .setAutoCancel(true)
            .setDeleteIntent(stopPendingIntent)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setColor(0xFF059669.toInt())
            .addAction(
                volumeActionIcon,
                volumeActionTitle,
                volumePendingIntent
            )
            .addAction(
                android.R.drawable.ic_media_pause,
                "إيقاف الأذان ⏹",
                stopPendingIntent
            )
            .build()
    }

    private fun playAdhanAudio(prayerName: String, muezzinPath: String?, muezzinName: String) {
        // If already playing this Adhan, do NOT cut off and do NOT restart!
        if (isPlaying) {
            Log.d("AdhanAudioService", "Adhan is already playing continuously, ignoring duplicate trigger.")
            return
        }

        if (!isPrayerAllowed(this, prayerName)) {
            stopSelf()
            return
        }
        stopAdhanAudio()
        isPlaying = true // Includes preparation, so the in-app stop card stays available.
        isVolumeLowered = false
        currentPrayerName = prayerName

        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "NoorAlatra:AdhanWakeLock").apply {
                setReferenceCounted(false)
                acquire(12 * 60 * 1000L) // 12 minutes max timeout for full Adhan
            }

            createNotificationChannel()

            val notification = buildAdhanNotification(prayerName)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }

            // Request Audio Focus so playback is never interrupted or ducked by other apps
            audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val focusReq = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .build()
                    )
                    .setOnAudioFocusChangeListener { /* Keep playing Adhan uninterrupted */ }
                    .build()
                audioFocusRequest = focusReq
                audioManager?.requestAudioFocus(focusReq)
            } else {
                @Suppress("DEPRECATION")
                audioManager?.requestAudioFocus(
                    null,
                    AudioManager.STREAM_ALARM,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE
                )
            }

            mediaPlayer = MediaPlayer().apply {
                // Ensure CPU stays awake for MediaPlayer until finished
                setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)

                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setLegacyStreamType(AudioManager.STREAM_ALARM)
                        .build()
                )

                // Try local custom file path first
                var sourceSet = false
                if (!muezzinPath.isNullOrEmpty()) {
                    val file = File(muezzinPath)
                    if (file.exists() && file.length() > 1024) {
                        setDataSource(file.absolutePath)
                        sourceSet = true
                    }
                }

                // If not set, use raw/adhan (Amer Al-Kazemi)
                if (!sourceSet) {
                    val afd = resources.openRawResourceFd(R.raw.adhan)
                    if (afd != null) {
                        setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                        afd.close()
                    }
                }

                setOnPreparedListener { mp ->
                    if (mediaPlayer !== mp || !isPrayerAllowed(this@AdhanAudioService, prayerName)) {
                        stopAdhanAudio()
                        stopSelf()
                        return@setOnPreparedListener
                    }
                    val vol = if (isVolumeLowered) 0.2f else 1.0f
                    mp.setVolume(vol, vol)
                    mp.start()
                    AdhanAudioService.isPlaying = true
                    Log.d("AdhanAudioService", "Adhan playback started successfully and continuously.")
                }

                setOnCompletionListener {
                    Log.d("AdhanAudioService", "Adhan completed naturally.")
                    stopAdhanAudio()
                    stopSelf()
                }

                setOnErrorListener { _, what, extra ->
                    Log.e("AdhanAudioService", "MediaPlayer error: what=$what, extra=$extra")
                    stopAdhanAudio()
                    stopSelf()
                    true
                }

                prepareAsync()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            stopAdhanAudio()
            stopSelf()
        }
    }

    private fun stopAdhanAudio() {
        val player = mediaPlayer
        mediaPlayer = null
        AdhanAudioService.isPlaying = false
        AdhanAudioService.isVolumeLowered = false
        try {
            // release() also works while preparing. Querying isPlaying/stop in
            // that state can throw and leave a pending player alive.
            player?.setOnPreparedListener(null)
            player?.setOnCompletionListener(null)
            player?.setOnErrorListener(null)
            player?.release()
        } catch (e: Exception) {
            Log.e("AdhanAudioService", "Failed to release Adhan player", e)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
            } else {
                @Suppress("DEPRECATION")
                audioManager?.abandonAudioFocus(null)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            audioFocusRequest = null
        }

        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            wakeLock = null
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(NOTIFICATION_ID)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                CHANNEL_ID,
                "أذان الصلاة المباشر",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "تشغيل الأذان المبارك عند دخول وقت الفريضة الشرعي مع زر إيقاف فوري"
                setSound(null, null) // Sound is played directly by MediaPlayer at ALARM volume
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        if (activeService === this) activeService = null
        stopAdhanAudio()
        super.onDestroy()
    }
}

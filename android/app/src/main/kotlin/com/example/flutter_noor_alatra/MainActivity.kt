package com.example.flutter_noor_alatra

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.view.WindowManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.AlarmManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.widget.RemoteViews
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.app.Activity
import android.app.WallpaperManager
import android.speech.RecognizerIntent
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SENSOR_CHANNEL = "com.example.flutter_noor_alatra/proximity"
    private val WAKELOCK_CHANNEL = "com.example.flutter_noor_alatra/wakelock"

    private var sensorManager: SensorManager? = null
    private var proximitySensor: Sensor? = null
    private var sensorEventListener: SensorEventListener? = null

    private val SPEECH_REQUEST_CODE = 7788
    private var pendingSpeechResult: MethodChannel.Result? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == SPEECH_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val matches = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                val text = matches?.firstOrNull() ?: ""
                pendingSpeechResult?.success(text)
            } else {
                pendingSpeechResult?.success("")
            }
            pendingSpeechResult = null
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        proximitySensor = sensorManager?.getDefaultSensor(Sensor.TYPE_PROXIMITY)

        // WakeLock & Battery Optimization Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WAKELOCK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableKeepScreenOn" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    result.success(true)
                }
                "disableKeepScreenOn" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    result.success(true)
                }
                "updateCustomPrayerNotification" -> {
                    val fajr = call.argument<String>("fajr") ?: "04:28"
                    val sunrise = call.argument<String>("sunrise") ?: "05:50"
                    val dhuhr = call.argument<String>("dhuhr") ?: "11:48"
                    val maghrib = call.argument<String>("maghrib") ?: "05:59"
                    showStaticPrayerNotification(this, fajr, sunrise, dhuhr, maghrib)
                    result.success(true)
                }
                "cancelCustomPrayerNotification" -> {
                    cancelCustomPrayerNotification()
                    result.success(true)
                }
                "startVoiceRecognition" -> {
                    try {
                        val prompt = call.argument<String>("prompt") ?: "تحدث الآن للبحث..."
                        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ar")
                            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "ar")
                            putExtra(RecognizerIntent.EXTRA_PROMPT, prompt)
                        }
                        pendingSpeechResult = result
                        startActivityForResult(intent, SPEECH_REQUEST_CODE)
                    } catch (e: Exception) {
                        result.error("SPEECH_NOT_AVAILABLE", e.localizedMessage, null)
                    }
                }
                "setDeviceWallpaper" -> {
                    val filePath = call.argument<String>("filePath")
                    val target = call.argument<String>("target") ?: "both" // "home", "lock", "both"
                    if (filePath != null) {
                        val file = java.io.File(filePath)
                        if (file.exists()) {
                            try {
                                val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                                if (bitmap != null) {
                                    val wm = WallpaperManager.getInstance(applicationContext)
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                        when (target) {
                                            "home" -> wm.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                                            "lock" -> wm.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                                            else -> wm.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK)
                                        }
                                    } else {
                                        wm.setBitmap(bitmap)
                                    }
                                    result.success(true)
                                } else {
                                    result.error("DECODE_ERROR", "Failed to decode image bitmap", null)
                                }
                            } catch (e: Exception) {
                                result.error("WALLPAPER_ERROR", e.localizedMessage, null)
                            }
                        } else {
                            result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
                        }
                    } else {
                        result.error("INVALID_PATH", "filePath is null", null)
                    }
                }
                "showCustomQuranNotification" -> {
                    val surahName = call.argument<String>("surahName") ?: "القرآن الكريم"
                    val ayahNum = call.argument<Int>("ayahNum") ?: 1
                    val text = call.argument<String>("text") ?: ""
                    val surahId = call.argument<Int>("surahId") ?: 1

                    showStaticQuranNotification(applicationContext, surahName, ayahNum, text, surahId)
                    result.success(true)
                }
                "installApk" -> {
                    val apkFilePath = call.argument<String>("filePath")
                    if (apkFilePath != null) {
                        val file = java.io.File(apkFilePath)
                        if (file.exists()) {
                            try {
                                val apkUri = androidx.core.content.FileProvider.getUriForFile(
                                    applicationContext,
                                    "$packageName.fileprovider",
                                    file
                                )
                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(apkUri, "application/vnd.android.package-archive")
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("INSTALL_ERROR", e.message, null)
                            }
                        } else {
                            result.error("FILE_NOT_FOUND", "File not found: $apkFilePath", null)
                        }
                    } else {
                        result.error("INVALID_PATH", "filePath is null", null)
                    }
                }
                "isBatteryOptimizationIgnored" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    } else {
                        result.success(true)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                            try {
                                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                    data = Uri.parse("package:$packageName")
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                try {
                                    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                    startActivity(intent)
                                    result.success(true)
                                } catch (e2: Exception) {
                                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                        data = Uri.parse("package:$packageName")
                                    }
                                    startActivity(intent)
                                    result.success(true)
                                }
                            }
                        } else {
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "openBatterySettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR", e2.message, null)
                        }
                    }
                }
                "canScheduleExactAlarms" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        result.success(alarmManager.canScheduleExactAlarms())
                    } else {
                        result.success(true)
                    }
                }
                "openExactAlarmSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "playNativeAdhan" -> {
                    val prayerName = call.argument<String>("prayerName") ?: "الصلاة"
                    val muezzinPath = call.argument<String>("muezzinPath")
                    val muezzinName = call.argument<String>("muezzinName") ?: "الحاج عامر الكاظمي"
                    AdhanAudioService.startAdhan(this, prayerName, muezzinPath, muezzinName)
                    result.success(true)
                }
                "stopNativeAdhan" -> {
                    AdhanAudioService.stopAdhan(this)
                    result.success(true)
                }
                "lowerAdhanVolume" -> {
                    val isLow = call.argument<Boolean>("isLow") ?: true
                    AdhanAudioService.setVolume(this, isLow)
                    result.success(true)
                }
                "toggleAdhanVolume" -> {
                    AdhanAudioService.toggleVolume(this)
                    result.success(true)
                }
                "isAdhanVolumeLowered" -> {
                    result.success(AdhanAudioService.isVolumeLowered)
                }
                "isAdhanPlaying" -> {
                    result.success(AdhanAudioService.isPlaying)
                }
                "getAdhanStatus" -> {
                    val status = mapOf(
                        "isPlaying" to AdhanAudioService.isPlaying,
                        "prayerName" to AdhanAudioService.currentPrayerName,
                        "isVolumeLowered" to AdhanAudioService.isVolumeLowered
                    )
                    result.success(status)
                }
                "scheduleNativePrayerAlarm" -> {
                    val prayerName = call.argument<String>("prayerName") ?: "الصلاة"
                    val triggerTimeMs = (call.argument<Number>("triggerTimeMs"))?.toLong() ?: 0L
                    val muezzinPath = call.argument<String>("muezzinPath")
                    val muezzinName = call.argument<String>("muezzinName") ?: "الحاج عامر الكاظمي"
                    val alarmId = call.argument<Int>("alarmId") ?: 100

                    if (triggerTimeMs > System.currentTimeMillis()) {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val intent = Intent(this, AdhanAlarmReceiver::class.java).apply {
                            putExtra("prayer_name", prayerName)
                            putExtra("muezzin_path", muezzinPath)
                            putExtra("muezzin_name", muezzinName)
                        }
                        val pendingIntent = PendingIntent.getBroadcast(
                            this,
                            alarmId,
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        val showIntent = Intent(this, MainActivity::class.java)
                        val showPendingIntent = PendingIntent.getActivity(
                            this,
                            0,
                            showIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerTimeMs, showPendingIntent)
                        alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                    }
                    result.success(true)
                }
                "cancelNativePrayerAlarm" -> {
                    val alarmId = call.argument<Int>("alarmId") ?: 100
                    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    val intent = Intent(this, AdhanAlarmReceiver::class.java)
                    val pendingIntent = PendingIntent.getBroadcast(
                        this,
                        alarmId,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    alarmManager.cancel(pendingIntent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Proximity Sensor EventChannel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SENSOR_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (proximitySensor == null) {
                        events?.error("SENSOR_NOT_AVAILABLE", "Proximity sensor not available on this device", null)
                        return
                    }

                    sensorEventListener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent?) {
                            if (event != null && event.values.isNotEmpty()) {
                                val distance = event.values[0]
                                val maxRange = proximitySensor?.maximumRange ?: 5.0f
                                // distance < maxRange or distance == 0 means near
                                val isNear = distance < maxRange || distance == 0.0f
                                events?.success(if (isNear) 1 else 0)
                            }
                        }

                        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                    }

                    sensorManager?.registerListener(
                        sensorEventListener,
                        proximitySensor,
                        SensorManager.SENSOR_DELAY_UI
                    )
                }

                override fun onCancel(arguments: Any?) {
                    sensorEventListener?.let {
                        sensorManager?.unregisterListener(it)
                    }
                    sensorEventListener = null
                }
            }
        )
    }

    private fun cancelCustomPrayerNotification() {
        try {
            val prefs = getSharedPreferences("noor_alatra_prayer_times", Context.MODE_PRIVATE)
            prefs.edit().putBoolean("is_active", false).apply()
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(PRAYER_NOTIF_ID)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    companion object {
        const val PRAYER_NOTIF_ID = 10001
        const val PRAYER_CHANNEL_ID = "prayer_ongoing_times_bar_v1"
        const val PRAYER_CHANNEL_NAME = "شريط مواقيت الصلاة الدائم"
        const val PRAYER_CHANNEL_DESC = "بطاقة دائمة في لوحة الإشعارات تعرض مواقيت الصلاة لليوم بدقة"

        fun showStaticPrayerNotification(context: Context, fajr: String, sunrise: String, dhuhr: String, maghrib: String) {
            try {
                val prefs = context.getSharedPreferences("noor_alatra_prayer_times", Context.MODE_PRIVATE)
                prefs.edit()
                    .putBoolean("is_active", true)
                    .putString("fajr", fajr)
                    .putString("sunrise", sunrise)
                    .putString("dhuhr", dhuhr)
                    .putString("maghrib", maghrib)
                    .apply()

                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val channel = NotificationChannel(
                        PRAYER_CHANNEL_ID,
                        PRAYER_CHANNEL_NAME,
                        NotificationManager.IMPORTANCE_LOW
                    ).apply {
                        description = PRAYER_CHANNEL_DESC
                        setShowBadge(false)
                        enableLights(false)
                        enableVibration(false)
                        setSound(null, null)
                        lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                    }
                    notificationManager.createNotificationChannel(channel)
                }

                val remoteViews = RemoteViews(context.packageName, R.layout.notification_prayer_card).apply {
                    setTextViewText(R.id.tv_fajr_title, "الفجر")
                    setTextViewText(R.id.tv_fajr_time, fajr)

                    setTextViewText(R.id.tv_sunrise_title, "الشروق")
                    setTextViewText(R.id.tv_sunrise_time, sunrise)

                    setTextViewText(R.id.tv_dhuhr_title, "الظهر")
                    setTextViewText(R.id.tv_dhuhr_time, dhuhr)

                    setTextViewText(R.id.tv_maghrib_title, "المغرب")
                    setTextViewText(R.id.tv_maghrib_time, maghrib)
                }

                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    9999,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val summaryText = "الفجر: $fajr | الشروق: $sunrise | الظهر: $dhuhr | المغرب: $maghrib"

                val notification = NotificationCompat.Builder(context, PRAYER_CHANNEL_ID)
                    .setSmallIcon(R.drawable.ic_notification)
                    .setContentTitle("مواقيت الصلاة")
                    .setContentText(summaryText)
                    .setCustomContentView(remoteViews)
                    .setCustomBigContentView(remoteViews)
                    .setStyle(NotificationCompat.DecoratedCustomViewStyle())
                    .setContentIntent(pendingIntent)
                    .setOngoing(true)
                    .setAutoCancel(false)
                    .setCategory(NotificationCompat.CATEGORY_STATUS)
                    .setOnlyAlertOnce(true)
                    .setShowWhen(false)
                    .setPriority(NotificationCompat.PRIORITY_LOW)
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                    .setColor(0xFF14B8A6.toInt())
                    .build().apply {
                        flags = flags or android.app.Notification.FLAG_NO_CLEAR or android.app.Notification.FLAG_ONGOING_EVENT
                    }

                notificationManager.notify(PRAYER_NOTIF_ID, notification)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        const val QURAN_NOTIF_ID = 1001
        const val QURAN_CHANNEL_ID = "quran_verses_channel_v3"

        fun showStaticQuranNotification(
            context: Context,
            surahName: String,
            ayahNum: Int,
            verseText: String,
            surahId: Int
        ) {
            try {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val channel = NotificationChannel(
                        QURAN_CHANNEL_ID,
                        "آيات قرآنية كريمة بالرسم العثماني",
                        NotificationManager.IMPORTANCE_HIGH
                    ).apply {
                        description = "عرض آيات قرآنية مزخرفة بالرسم العثماني مع علامة نهاية الآية الأصلية"
                        enableLights(true)
                        enableVibration(true)
                    }
                    notificationManager.createNotificationChannel(channel)
                }

                val arabicAyah = QuranNotificationRenderer.toArabicDigits(ayahNum)
                val bitmap = QuranNotificationRenderer.renderAyahBitmap(context, verseText, ayahNum, 680)

                val remoteViews = RemoteViews(context.packageName, R.layout.notification_quran_verse)
                remoteViews.setTextViewText(R.id.tv_quran_notif_title, "سورة $surahName • آية $arabicAyah")
                remoteViews.setTextViewText(R.id.tv_quran_notif_subtitle, "نور العترة • تذكير قرآني")
                remoteViews.setImageViewBitmap(R.id.iv_quran_ayah_bitmap, bitmap)

                // PendingIntent for main notification tap
                val mainIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("route", "quran")
                    putExtra("surahId", surahId)
                    putExtra("ayahNum", ayahNum)
                }
                val mainPi = PendingIntent.getActivity(
                    context,
                    2001,
                    mainIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // PendingIntent for Read Ayah button
                val readIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("route", "quran_reader")
                    putExtra("surahId", surahId)
                    putExtra("ayahNum", ayahNum)
                }
                val readPi = PendingIntent.getActivity(
                    context,
                    2002,
                    readIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // PendingIntent for Listen Ayah button
                val listenIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("route", "quran_audio")
                    putExtra("surahId", surahId)
                    putExtra("ayahNum", ayahNum)
                }
                val listenPi = PendingIntent.getActivity(
                    context,
                    2003,
                    listenIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                remoteViews.setOnClickPendingIntent(R.id.btn_read_ayah, readPi)
                remoteViews.setOnClickPendingIntent(R.id.btn_listen_ayah, listenPi)

                val largeIconBitmap: Bitmap? = try {
                    BitmapFactory.decodeResource(context.resources, R.drawable.app_icon)
                } catch (_: Exception) {
                    null
                }

                val notification = NotificationCompat.Builder(context, QURAN_CHANNEL_ID)
                    .setSmallIcon(R.drawable.ic_notification)
                    .setLargeIcon(largeIconBitmap)
                    .setContentTitle("نفحات من القرآن الكريم 📖")
                    .setContentText("﴿ $verseText ﴾ ۝$arabicAyah - سورة $surahName، الآية $arabicAyah")
                    .setStyle(
                        NotificationCompat.BigTextStyle()
                            .bigText("﴿ $verseText ﴾ ۝$arabicAyah\n\n- سورة $surahName، الآية $arabicAyah")
                    )
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setContentIntent(mainPi)
                    .addAction(R.drawable.ic_notification, "▶ استمع الآن", listenPi)
                    .addAction(R.drawable.ic_notification, "📖 اقرأ الآية", readPi)
                    .setAutoCancel(true)
                    .build()

                notificationManager.notify(QURAN_NOTIF_ID, notification)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onDestroy() {
        sensorEventListener?.let {
            sensorManager?.unregisterListener(it)
        }
        sensorEventListener = null
        super.onDestroy()
    }
}

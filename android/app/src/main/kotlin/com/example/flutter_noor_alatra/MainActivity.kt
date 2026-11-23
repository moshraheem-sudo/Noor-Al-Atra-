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
        const val PRAYER_NOTIF_ID = 1003
        const val PRAYER_CHANNEL_ID = "sticky_prayer_cards_v8"

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
                        "مواقيت الصلاة الدائمة",
                        NotificationManager.IMPORTANCE_LOW
                    ).apply {
                        description = "عرض أوقات الصلاة في بطاقات أنيقة مثبتة في مركز الإشعارات"
                        setShowBadge(false)
                        enableLights(false)
                        enableVibration(false)
                        setSound(null, null)
                    }
                    notificationManager.createNotificationChannel(channel)
                }

                val remoteViews = RemoteViews(context.packageName, R.layout.notification_prayer_cards)
                remoteViews.setTextViewText(R.id.tv_time_fajr, fajr)
                remoteViews.setTextViewText(R.id.tv_time_sunrise, sunrise)
                remoteViews.setTextViewText(R.id.tv_time_dhuhr, dhuhr)
                remoteViews.setTextViewText(R.id.tv_time_maghrib, maghrib)

                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val summaryText = "الفجر: $fajr | الشروق: $sunrise | الظهر: $dhuhr | المغرب: $maghrib"

                val largeIconBitmap: Bitmap? = try {
                    BitmapFactory.decodeResource(context.resources, R.drawable.app_icon)
                        ?: run {
                            val drawable = context.packageManager.getApplicationIcon(context.packageName)
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

                val notification = NotificationCompat.Builder(context, PRAYER_CHANNEL_ID)
                    .setSmallIcon(R.drawable.ic_notification)
                    .setLargeIcon(largeIconBitmap)
                    .setContentTitle("مواقيت الصلاة")
                    .setContentText(summaryText)
                    .setCustomContentView(remoteViews)
                    .setCustomBigContentView(remoteViews)
                    .setContentIntent(pendingIntent)
                    .setOngoing(true)
                    .setAutoCancel(false)
                    .setOnlyAlertOnce(true)
                    .setShowWhen(false)
                    .setCategory(NotificationCompat.CATEGORY_STATUS)
                    .setPriority(NotificationCompat.PRIORITY_LOW)
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                    .build().apply {
                        flags = flags or android.app.Notification.FLAG_NO_CLEAR or android.app.Notification.FLAG_ONGOING_EVENT
                    }

                notificationManager.notify(PRAYER_NOTIF_ID, notification)
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

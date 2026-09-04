package com.example.worker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.ExistingWorkPolicy
import java.util.concurrent.TimeUnit
import com.example.R

class ReminderWorker(appContext: Context, workerParams: WorkerParameters) : Worker(appContext, workerParams) {
    override fun doWork(): Result {
        val sharedPref = applicationContext.getSharedPreferences("AhlAlBaytPrefs", Context.MODE_PRIVATE)
        val notificationsEnabled = sharedPref.getBoolean("notifications_enabled", true)
        
        if (!notificationsEnabled) {
            return Result.success()
        }

        val notificationsPerHour = sharedPref.getInt("notifications_per_hour", 3).coerceIn(3, 10)

        // General reminders
        val generalReminders = mutableListOf(
            "هل قرأت زيارة عاشوراء اليوم؟",
            "عطّر فمك بالصلاة: اللهم صل على محمد وآل محمد وعجل فرجهم",
            "جدد وضوءك لتكن على طهارة",
            "لا تنسَ قراءة سورة القدر",
            "هل سبحت تسبيحة الزهراء (عليها السلام)؟",
            "قراءة آية الكرسي تحفظك",
            "لا تنسَ قراءة دعاء الفرج (اللهم كن لوليك الحجة بن الحسن...)",
            "أستغفر الله ربي وأتوب إليه",
            "لا حول ولا قوة إلا بالله العلي العظيم",
            "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
            "جدد بيعتك لصاحب الزمان (عج) بقراءة دعاء العهد",
            "هل وجهت سلاماً لأبي عبد الله الحسين (عليه السلام) اليوم؟",
            "يا كاشف الكرب عن وجه أخيه الحسين اكشف كربي بحق أخيك الحسين (ع)",
            "لا تنسَ زيارة أمين الله لأمير المؤمنين (عليه السلام)",
            "هل قرأت زيارة آل ياسين اليوم؟",
            "زيارة وارث تقربك إلى الحسين (عليه السلام)",
            "اسجد سجدة الشكر وقل: شكراً لله، شكراً لله، شكراً لله",
            "تجديد التوبة: أستغفر الله الذي لا إله إلا هو الحي القيوم وأتوب إليه",
            "اذكر الإمام الرضا (عليه السلام) بزيارته من البعد السلام عليك يا غريب طوس",
            "بادر إلى التوبة الآن فالله غفار الذنوب",
            "لا تكن من الغافلين، اذكر الله",
            "سبحان الله وبحمده سبحان الله العظيم",
            "يا رب السموات والأرض اكفني ما أهمني",
            "لا إله إلا أنت سبحانك إني كنت من الظالمين"
        )
        
        val dayOfWeek = java.time.LocalDate.now().dayOfWeek
        val currentHour = java.time.LocalTime.now().hour
        
        if (dayOfWeek == java.time.DayOfWeek.THURSDAY && currentHour in 15..20) {
            generalReminders.add("عصر الخميس: لا تنسَ قراءة دعاء كميل")
            generalReminders.add("عصر الخميس: لا تنسَ قراءة دعاء كميل") // Add multiple times to increase probability
        } else if (dayOfWeek == java.time.DayOfWeek.TUESDAY && currentHour in 15..20) {
            generalReminders.add("عصر الثلاثاء: لا تنسَ قراءة دعاء التوسل")
            generalReminders.add("عصر الثلاثاء: لا تنسَ قراءة دعاء التوسل")
        } else if (dayOfWeek == java.time.DayOfWeek.FRIDAY && currentHour in 6..11) {
            generalReminders.add("صبيحة الجمعة: لا تنسَ قراءة دعاء الندبة")
            generalReminders.add("صبيحة الجمعة: لا تنسَ قراءة دعاء الندبة")
        }

        val lastMessage = sharedPref.getString("last_reminder_msg", "")
        
        // Pick a diverse message
        var reminderMessage = generalReminders.random()
        while (reminderMessage == lastMessage) {
            reminderMessage = generalReminders.random()
        }

        // Enforce max 1 notification per hour
        if (com.example.util.NotificationRateLimiter.canPostNotification(applicationContext)) {
            showNotification(applicationContext, 3000 + (System.currentTimeMillis() % 1000).toInt(), "فَذَكِّرْ إِن نَّفَعَتِ الذِّكْرَىٰ", reminderMessage)
            sharedPref.edit().putString("last_reminder_msg", reminderMessage).apply()
        }

        // Schedule next reminder (at least 60 minutes to respect 1 notification per hour limit)
        val delayMinutes = 60L
        val nextWorkRequest = OneTimeWorkRequestBuilder<ReminderWorker>()
            .setInitialDelay(delayMinutes, TimeUnit.MINUTES)
            .build()
            
        WorkManager.getInstance(applicationContext).enqueueUniqueWork(
            "ReminderWorkerChain",
            ExistingWorkPolicy.REPLACE,
            nextWorkRequest
        )

        return Result.success()
    }

    private fun showNotification(context: Context, id: Int, title: String, message: String) {
        val channelId = "ahlalbayt_reminders"
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Reminders",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(channel)
        }
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_notification) // Use app icon
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()
        notificationManager.notify(id, notification)
    }
}

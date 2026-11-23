package com.example.flutter_noor_alatra

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.text.Layout
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.StaticLayout
import android.text.TextDirectionHeuristics
import android.text.TextPaint

object QuranNotificationRenderer {

    fun toArabicDigits(num: Any): String {
        val s = num.toString()
        val sb = StringBuilder()
        for (ch in s) {
            when (ch) {
                '0' -> sb.append('٠')
                '1' -> sb.append('١')
                '2' -> sb.append('٢')
                '3' -> sb.append('٣')
                '4' -> sb.append('٤')
                '5' -> sb.append('٥')
                '6' -> sb.append('٦')
                '7' -> sb.append('٧')
                '8' -> sb.append('٨')
                '9' -> sb.append('٩')
                else -> sb.append(ch)
            }
        }
        return sb.toString()
    }

    /**
     * Renders Quranic verse with sacred quotation brackets and the AyahMedallionSpan into a high-res Bitmap
     */
    fun renderAyahBitmap(
        context: Context,
        verseText: String,
        ayahNum: Int,
        widthPx: Int = 960
    ): Bitmap {
        val arabicNum = toArabicDigits(ayahNum)
        val fullText = "﴿ $verseText ﴾ \uFFFC"
        val spannable = SpannableStringBuilder(fullText)

        val span = AyahMedallionSpan(arabicNum)
        val markerIndex = fullText.indexOf('\uFFFC')
        if (markerIndex != -1) {
            spannable.setSpan(span, markerIndex, markerIndex + 1, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }

        val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#1E293B")
            textSize = 38f
            // Attempt to load the Quranic fonts shipped in flutter assets
            try {
                typeface = Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/AmiriQuran-Regular.ttf")
            } catch (_: Exception) {
                try {
                    typeface = Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/UthmanicHafs_v09.otf")
                } catch (_: Exception) {
                    try {
                        typeface = Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/Amiri-Regular.ttf")
                    } catch (_: Exception) {
                        typeface = Typeface.DEFAULT_BOLD
                    }
                }
            }
        }

        val staticLayout = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            StaticLayout.Builder.obtain(spannable, 0, spannable.length, textPaint, widthPx)
                .setAlignment(Layout.Alignment.ALIGN_NORMAL)
                .setTextDirection(TextDirectionHeuristics.RTL)
                .setLineSpacing(14f, 1.25f)
                .setIncludePad(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            StaticLayout(
                spannable,
                textPaint,
                widthPx,
                Layout.Alignment.ALIGN_NORMAL,
                1.25f,
                14f,
                true
            )
        }

        val paddingTop = 14
        val paddingBottom = 16
        val height = staticLayout.height + paddingTop + paddingBottom
        val bitmap = Bitmap.createBitmap(widthPx, height.coerceAtLeast(1), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        canvas.save()
        canvas.translate(0f, paddingTop.toFloat())
        staticLayout.draw(canvas)
        canvas.restore()

        return bitmap
    }
}

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
     * Renders Quranic verse with sacred quotation brackets and AyahMedallionSpans.
     * Supports multiple verses separated by '•', rendering consecutive rosettes for each ayah (e.g. Surah Al-Kawthar)!
     * Also applies Kashida justification (JUSTIFICATION_MODE_INTER_WORD) and enlarged bold text.
     */
    fun renderAyahBitmap(
        context: Context,
        verseText: String,
        startAyahNum: Int,
        widthPx: Int = 1000
    ): Bitmap {
        val parts = verseText.split("•").map { it.trim() }.filter { it.isNotEmpty() }
        val sb = StringBuilder()
        sb.append("﴿ ")

        val markers = mutableListOf<Pair<Int, String>>()
        var currentNum = startAyahNum

        for (i in parts.indices) {
            sb.append(parts[i])
            sb.append(" ")
            val markerPos = sb.length
            sb.append("\uFFFC")
            markers.add(Pair(markerPos, toArabicDigits(currentNum)))
            currentNum++
            if (i < parts.size - 1) {
                sb.append(" ")
            }
        }
        sb.append(" ﴾")

        val fullText = sb.toString()
        val spannable = SpannableStringBuilder(fullText)

        for (marker in markers) {
            val idx = marker.first
            val numStr = marker.second
            val span = AyahMedallionSpan(numStr)
            spannable.setSpan(span, idx, idx + 1, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }

        val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#0F172A")
            textSize = 50f // Enlarged font size for maximum clarity and prominence
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
            val builder = StaticLayout.Builder.obtain(spannable, 0, spannable.length, textPaint, widthPx)
                .setAlignment(Layout.Alignment.ALIGN_NORMAL)
                .setTextDirection(TextDirectionHeuristics.RTL)
                .setLineSpacing(18f, 1.25f)
                .setIncludePad(true)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                builder.setJustificationMode(Layout.JUSTIFICATION_MODE_INTER_WORD) // Kashida / Inter-word justification
            }
            builder.build()
        } else {
            @Suppress("DEPRECATION")
            StaticLayout(
                spannable,
                textPaint,
                widthPx,
                Layout.Alignment.ALIGN_NORMAL,
                1.25f,
                18f,
                true
            )
        }

        val paddingTop = 18
        val paddingBottom = 22
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

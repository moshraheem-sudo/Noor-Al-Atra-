package com.example.flutter_noor_alatra

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.text.style.ReplacementSpan
import kotlin.math.cos
import kotlin.math.sin

/**
 * Custom ReplacementSpan that draws an ornamental Quranic rosette medallion
 * with the Arabic Ayah number centered precisely inside it.
 */
class AyahMedallionSpan(
    private val ayahNumber: String,
    private val medallionColor: Int = Color.parseColor("#C28E00"),
    private val numberColor: Int = Color.parseColor("#78350F")
) : ReplacementSpan() {

    override fun getSize(paint: Paint, text: CharSequence?, start: Int, end: Int, fm: Paint.FontMetricsInt?): Int {
        val size = computeDiameter(paint)
        if (fm != null) {
            val paintFm = paint.fontMetricsInt
            fm.ascent = paintFm.ascent
            fm.descent = paintFm.descent
            fm.top = paintFm.top
            fm.bottom = paintFm.bottom
        }
        return (size + paint.textSize * 0.42f).toInt()
    }

    private fun computeDiameter(paint: Paint): Float {
        val baseSize = paint.textSize * 1.15f
        return when {
            ayahNumber.length >= 3 -> baseSize * 1.35f
            ayahNumber.length == 2 -> baseSize * 1.20f
            else -> baseSize
        }
    }

    override fun draw(
        canvas: Canvas,
        text: CharSequence?,
        start: Int,
        end: Int,
        x: Float,
        top: Int,
        y: Int,
        bottom: Int,
        paint: Paint
    ) {
        val diameter = computeDiameter(paint)
        val radius = diameter / 2f
        val margin = paint.textSize * 0.20f
        val cx = x + margin + radius
        val cy = (top + bottom) / 2f

        val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            color = medallionColor
        }

        // Outer circle
        strokePaint.strokeWidth = paint.textSize * 0.075f
        canvas.drawCircle(cx, cy, radius, strokePaint)

        // Inner circle
        val innerRadius = radius * 0.82f
        strokePaint.strokeWidth = paint.textSize * 0.05f
        canvas.drawCircle(cx, cy, innerRadius, strokePaint)

        // 8 Decorative dots around the medallion (Octagonal Islamic pattern)
        val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            color = medallionColor
        }
        val dotDistance = (radius + innerRadius) / 2f
        val dotRadius = paint.textSize * 0.045f
        for (i in 0 until 8) {
            val angle = Math.toRadians((i * 45.0))
            val dotX = cx + (dotDistance * cos(angle)).toFloat()
            val dotY = cy + (dotDistance * sin(angle)).toFloat()
            canvas.drawCircle(dotX, dotY, dotRadius, dotPaint)
        }

        // Draw Ayah Number in Eastern Arabic digits centered strictly inside the rosette
        val numPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = numberColor
            textAlign = Paint.Align.CENTER
            typeface = Typeface.DEFAULT_BOLD
            textSize = when {
                ayahNumber.length >= 3 -> paint.textSize * 0.44f
                ayahNumber.length == 2 -> paint.textSize * 0.52f
                else -> paint.textSize * 0.60f
            }
        }

        val numFm = numPaint.fontMetrics
        // Precise vertical baseline centering equation: baselineY = cy - (ascent + descent) / 2
        val baselineY = cy - (numFm.ascent + numFm.descent) / 2f
        canvas.drawText(ayahNumber, cx, baselineY, numPaint)
    }
}

package kr.sjh.runlini.wear

import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.unit.dp

internal enum class WearRunButtonIcon { Pause, Play, Stop }

@Composable
internal fun WearRunIconGlyph(
    icon: WearRunButtonIcon,
    color: Color,
    modifier: Modifier = Modifier,
) {
    Canvas(modifier = modifier) {
        when (icon) {
            WearRunButtonIcon.Pause -> {
                val barWidth = size.width * 0.24f
                val gap = size.width * 0.18f
                val barHeight = size.height * 0.72f
                val top = (size.height - barHeight) / 2f
                val left = (size.width - (barWidth * 2f + gap)) / 2f
                val radius = CornerRadius(2.dp.toPx(), 2.dp.toPx())
                drawRoundRect(
                    color = color,
                    topLeft = Offset(left, top),
                    size = Size(barWidth, barHeight),
                    cornerRadius = radius,
                )
                drawRoundRect(
                    color = color,
                    topLeft = Offset(left + barWidth + gap, top),
                    size = Size(barWidth, barHeight),
                    cornerRadius = radius,
                )
            }
            WearRunButtonIcon.Play -> {
                val path = Path().apply {
                    moveTo(size.width * 0.32f, size.height * 0.2f)
                    lineTo(size.width * 0.32f, size.height * 0.8f)
                    lineTo(size.width * 0.78f, size.height * 0.5f)
                    close()
                }
                drawPath(path = path, color = color)
            }
            WearRunButtonIcon.Stop -> {
                val side = size.minDimension * 0.62f
                drawRoundRect(
                    color = color,
                    topLeft = Offset(
                        x = (size.width - side) / 2f,
                        y = (size.height - side) / 2f,
                    ),
                    size = Size(side, side),
                    cornerRadius = CornerRadius(1.5.dp.toPx(), 1.5.dp.toPx()),
                )
            }
        }
    }
}

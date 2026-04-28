package kr.sjh.runlini.wear

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

internal enum class WearLayoutProfile { Compact, Regular }

internal object WearRunLayoutModel {
    const val regularBreakpointDp = 225

    fun profileFor(widthDp: Int, heightDp: Int): WearLayoutProfile {
        return if (minOf(widthDp, heightDp) >= regularBreakpointDp) {
            WearLayoutProfile.Regular
        } else {
            WearLayoutProfile.Compact
        }
    }
}

internal data class WearRunLayoutSpec(
    val profile: WearLayoutProfile,
    val horizontalPadding: Dp,
    val verticalPadding: Dp,
    val pageIndicatorInset: Dp,
)

@Composable
internal fun WearRunPageFrame(
    modifier: Modifier = Modifier,
    reservePageIndicator: Boolean = false,
    horizontalAlignment: Alignment.Horizontal = Alignment.CenterHorizontally,
    verticalArrangement: Arrangement.Vertical = Arrangement.Center,
    content: @Composable ColumnScope.(WearRunLayoutSpec) -> Unit,
) {
    BoxWithConstraints(
        modifier = modifier
            .fillMaxSize()
            .background(RunliniWearColors.Black),
    ) {
        val profile = WearRunLayoutModel.profileFor(
            widthDp = maxWidth.value.toInt(),
            heightDp = maxHeight.value.toInt(),
        )
        val compact = profile == WearLayoutProfile.Compact
        val spec = WearRunLayoutSpec(
            profile = profile,
            horizontalPadding = if (compact) maxWidth * 0.12f else maxWidth * 0.10f,
            verticalPadding = if (compact) maxHeight * 0.06f else maxHeight * 0.07f,
            pageIndicatorInset = if (reservePageIndicator) 14.dp else 0.dp,
        )
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(
                    start = spec.horizontalPadding,
                    end = spec.horizontalPadding,
                    top = spec.verticalPadding,
                    bottom = spec.verticalPadding + spec.pageIndicatorInset,
                ),
            horizontalAlignment = horizontalAlignment,
            verticalArrangement = verticalArrangement,
        ) {
            content(spec)
        }
    }
}

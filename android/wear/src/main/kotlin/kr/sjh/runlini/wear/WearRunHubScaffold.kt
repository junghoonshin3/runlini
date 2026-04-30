package kr.sjh.runlini.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

@Composable
internal fun WearRunHubScaffold(
    primaryLabel: String,
    primaryColor: Color,
    primaryTextColor: Color,
    onPrimary: () -> Unit,
    modifier: Modifier = Modifier,
    primaryIcon: WearRunButtonIcon? = null,
    secondaryLabel: String? = null,
    secondaryColor: Color = RunliniWearColors.Chalk,
    secondaryTextColor: Color = RunliniWearColors.Black,
    secondaryIcon: WearRunButtonIcon? = null,
    onSecondary: (() -> Unit)? = null,
    statusLabel: String? = null,
    isErrorStatus: Boolean = false,
    reservePageIndicator: Boolean = false,
) {
    WearRunPageFrame(
        modifier = modifier,
        verticalArrangement = Arrangement.SpaceBetween,
        reservePageIndicator = reservePageIndicator,
    ) { spec ->
        val compact = spec.profile == WearLayoutProfile.Compact
        val primarySize = if (compact) 76.dp else 94.dp
        val actionHeight = if (compact) 30.dp else 34.dp
        val hasSecondaryAction = secondaryLabel != null && onSecondary != null

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = "RUNLINI",
                color = RunliniWearColors.Chalk,
                fontSize = if (compact) 19.sp else 23.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
            )
        }

        WearCircleButton(
            label = primaryLabel,
            color = primaryColor,
            textColor = primaryTextColor,
            size = primarySize,
            icon = primaryIcon,
            onClick = onPrimary,
        )

        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            statusLabel?.let { label ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    WearStatusPill(
                        label = label,
                        color = if (isErrorStatus) {
                            RunliniWearColors.ElectricRed
                        } else {
                            RunliniWearColors.Muted
                        },
                    )
                }
            }

            if (hasSecondaryAction && statusLabel != null) {
                Spacer(modifier = Modifier.height(if (compact) 5.dp else 7.dp))
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
            ) {
                if (secondaryLabel != null && onSecondary != null) {
                    WearActionButton(
                        label = secondaryLabel,
                        color = secondaryColor,
                        textColor = secondaryTextColor,
                        modifier = Modifier.fillMaxWidth(),
                        height = actionHeight,
                        icon = secondaryIcon,
                        onClick = onSecondary,
                    )
                }
            }
        }
    }
}

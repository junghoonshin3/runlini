package kr.sjh.runlini.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

@Composable
internal fun WearReadyScreen(
    state: WearRunState,
    onStart: () -> Unit,
    onRecordRaceStart: () -> Unit,
    reservePageIndicator: Boolean = false,
) {
    val model = WearReadyScreenModelBuilder.from(state)
    if (model.usesRecordRacePrimary) {
        WearRecordRaceReadyScreen(
            model = model,
            onStart = onStart,
            onRecordRaceStart = onRecordRaceStart,
            reservePageIndicator = reservePageIndicator,
        )
        return
    }

    WearRunHubScaffold(
        primaryLabel = model.primaryLabel.replace('\n', ' '),
        primaryColor = RunliniWearColors.VoltGreen,
        primaryTextColor = RunliniWearColors.Black,
        onPrimary = if (model.usesRecordRacePrimary) onRecordRaceStart else onStart,
        secondaryLabel = model.secondaryLabel,
        secondaryColor = RunliniWearColors.Chalk,
        secondaryTextColor = RunliniWearColors.Black,
        onSecondary = model.secondaryLabel?.let { onStart },
        statusLabel = readyStatusLabel(model),
        isErrorStatus = model.isError,
        reservePageIndicator = reservePageIndicator,
    )
}

@Composable
private fun WearRecordRaceReadyScreen(
    model: WearReadyScreenModel,
    onStart: () -> Unit,
    onRecordRaceStart: () -> Unit,
    reservePageIndicator: Boolean,
) {
    val actions = WearRecordRaceReadyModelBuilder.actionsFrom(model)
    WearRunPageFrame(
        verticalArrangement = Arrangement.SpaceBetween,
        reservePageIndicator = reservePageIndicator,
    ) { spec ->
        val layout = WearRecordRaceReadyModelBuilder.layoutFor(spec.profile)

        Text(
            text = "RUNLINI",
            color = RunliniWearColors.Chalk,
            fontSize = layout.titleSizeSp.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
        )

        Row(
            horizontalArrangement = Arrangement.spacedBy(
                space = layout.gapDp.dp,
                alignment = Alignment.CenterHorizontally,
            ),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            WearCircleButton(
                label = actions.recordRaceStartLabel,
                color = RunliniWearColors.VoltGreen,
                textColor = RunliniWearColors.Black,
                size = layout.circleSizeDp.dp,
                labelFontSize = layout.labelSizeSp.sp,
                onClick = onRecordRaceStart,
            )
            WearCircleButton(
                label = actions.normalStartLabel,
                color = RunliniWearColors.Chalk,
                textColor = RunliniWearColors.Black,
                size = layout.circleSizeDp.dp,
                labelFontSize = layout.labelSizeSp.sp,
                onClick = onStart,
            )
        }

        WearStatusPill(
            label = actions.statusLabel,
            color = if (actions.isError) {
                RunliniWearColors.ElectricRed
            } else {
                RunliniWearColors.Muted
            },
        )
    }
}

private fun readyStatusLabel(model: WearReadyScreenModel): String? {
    return when {
        model.isError -> "오류"
        model.statusLabel == "준비 완료" -> null
        else -> model.statusLabel
    }
}

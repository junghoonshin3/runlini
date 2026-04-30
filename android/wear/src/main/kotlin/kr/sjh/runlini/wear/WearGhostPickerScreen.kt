package kr.sjh.runlini.wear

import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

@Composable
internal fun WearGhostPickerScreen(
    state: WearRunState,
    onSelect: (String) -> Unit,
) {
    val model = WearGhostPickerModelBuilder.from(state)
    WearRunPageFrame(
        reservePageIndicator = true,
        verticalArrangement = Arrangement.Center,
    ) { spec ->
        val compact = spec.profile == WearLayoutProfile.Compact
        Text(
            text = "고스트 선택",
            color = RunliniWearColors.Chalk,
            fontSize = if (compact) 18.sp else 21.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = if (compact) 8.dp else 10.dp),
            verticalArrangement = Arrangement.spacedBy(if (compact) 5.dp else 7.dp),
        ) {
            if (model.items.isEmpty()) {
                Text(
                    text = model.emptyLabel ?: "없음",
                    color = RunliniWearColors.Muted,
                    fontSize = if (compact) 16.sp else 18.sp,
                    fontWeight = FontWeight.Black,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth(),
                    maxLines = 1,
                )
            } else {
                model.items.forEach { item ->
                    WearGhostPickerRow(
                        item = item,
                        compact = compact,
                        onSelect = { onSelect(item.id) },
                    )
                }
            }
        }
    }
}

@Composable
private fun WearGhostPickerRow(
    item: WearGhostPickerItemModel,
    compact: Boolean,
    onSelect: () -> Unit,
) {
    val borderColor = if (item.isSelected) {
        RunliniWearColors.VoltGreen
    } else {
        RunliniWearColors.Border
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(if (compact) 38.dp else 44.dp)
            .border(2.dp, borderColor, RoundedCornerShape(2.dp))
            .clickable(onClick = onSelect)
            .padding(horizontal = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = item.label,
            color = RunliniWearColors.Chalk,
            fontSize = if (compact) 11.sp else 12.sp,
            fontWeight = FontWeight.Black,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )
        Text(
            text = "${item.distance} · ${item.elapsed}",
            color = if (item.isSelected) RunliniWearColors.VoltGreen else RunliniWearColors.Muted,
            fontSize = if (compact) 9.sp else 10.sp,
            fontWeight = FontWeight.Black,
            maxLines = 1,
            textAlign = TextAlign.End,
        )
    }
}

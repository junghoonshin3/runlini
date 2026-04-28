package kr.sjh.runlini.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

@Composable
internal fun WearPermissionScreen(onRequest: () -> Unit) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 18.dp, vertical = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        item {
            Text(
                text = "Runlini",
                color = RunliniWearColors.Chalk,
                fontSize = 24.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
            )
        }
        item { Spacer(modifier = Modifier.height(10.dp)) }
        item {
            Text(
                text = "러닝 기록 권한이 필요해요",
                color = RunliniWearColors.Muted,
                fontSize = 13.sp,
                textAlign = TextAlign.Center,
            )
        }
        item { Spacer(modifier = Modifier.height(16.dp)) }
        item {
            WearActionButton(
                label = "권한 허용",
                color = RunliniWearColors.VoltGreen,
                textColor = RunliniWearColors.Black,
                onClick = onRequest,
            )
        }
    }
}

package org.company.app.feature.hello.presentation

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import multiplatform_app.sharedui.generated.resources.IndieFlower_Regular
import multiplatform_app.sharedui.generated.resources.Res
import org.jetbrains.compose.resources.Font
import org.koin.compose.viewmodel.koinViewModel

/**
 * Stateless screen. The state is owned by [HelloViewModel] (hoisted) and events flow back
 * through `viewModel.handleEvent(...)`. Identical wiring works on every platform.
 */
@Composable
fun HelloScreen(
    onNavigateToDetail: (id: String) -> Unit = {},
    viewModel: HelloViewModel = koinViewModel(),
) {
    val state by viewModel.uiState.collectAsState()
    HelloContent(
        state = state,
        onEvent = viewModel::handleEvent,
        onNavigateToDetail = onNavigateToDetail,
    )
}

@Composable
private fun HelloContent(
    state: HelloUiState,
    onEvent: (HelloUiEvent) -> Unit,
    onNavigateToDetail: (id: String) -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .windowInsetsPadding(WindowInsets.safeDrawing)
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
    ) {
        Text(
            text = state.message,
            fontFamily = FontFamily(Font(Res.font.IndieFlower_Regular)),
            style = MaterialTheme.typography.displayLarge,
        )

        if (state.isLoading) {
            CircularProgressIndicator()
        }

        state.error?.let { message ->
            Text(text = message, color = MaterialTheme.colorScheme.error)
            Button(onClick = { onEvent(HelloUiEvent.DismissError) }) {
                Text("Dismiss")
            }
        }

        Button(onClick = { onEvent(HelloUiEvent.Refresh) }) {
            Text("Refresh")
        }

        Button(onClick = { onNavigateToDetail("42") }) {
            Text("Open detail #42")
        }
    }
}

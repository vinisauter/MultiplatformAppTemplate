package org.company.app.feature.detail.presentation

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
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import org.koin.compose.viewmodel.koinViewModel
import org.koin.core.parameter.parametersOf

@Composable
fun DetailScreen(
    id: String,
    onBack: () -> Unit,
    viewModel: DetailViewModel = koinViewModel { parametersOf(id) },
) {
    val state by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .windowInsetsPadding(WindowInsets.safeDrawing)
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
    ) {
        when {
            state.isLoading -> CircularProgressIndicator()
            state.error != null -> {
                Text(text = state.error.orEmpty(), color = MaterialTheme.colorScheme.error)
                Button(onClick = { viewModel.handleEvent(DetailUiEvent.Reload) }) {
                    Text("Retry")
                }
            }
            state.item != null -> {
                Text(state.item!!.title, style = MaterialTheme.typography.headlineMedium)
                Text(state.item!!.body, style = MaterialTheme.typography.bodyLarge)
            }
        }

        OutlinedButton(onClick = onBack) {
            Text("Back")
        }
    }
}


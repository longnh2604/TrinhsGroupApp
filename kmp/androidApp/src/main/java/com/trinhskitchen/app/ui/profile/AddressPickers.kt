package com.trinhskitchen.app.ui.profile

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.model.AuAddress
import com.trinhsgroup.shared.model.AuLocalities
import com.trinhsgroup.shared.model.Locality
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** The bundled suburb list, read off the main thread. Null until it has loaded. */
@Composable
internal fun rememberAuLocalities(): AuLocalities? {
    val context = LocalContext.current
    val localities by produceState<AuLocalities?>(null) {
        value = withContext(Dispatchers.IO) {
            AuLocalities.parse(context.assets.open("au_localities.json").bufferedReader().use { it.readText() })
        }
    }
    return localities
}

/** A read-only field that opens a picker. A read-only text field would take the tap itself. */
@Composable
internal fun PickerField(
    value: String,
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier.fillMaxWidth(),
    enabled: Boolean = true
) {
    Box(modifier = modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = {},
            label = { Text(label) },
            readOnly = true,
            enabled = enabled,
            singleLine = true,
            trailingIcon = { Icon(Icons.Default.ArrowDropDown, contentDescription = null) },
            modifier = Modifier.fillMaxWidth()
        )
        Box(
            modifier = Modifier
                .matchParentSize()
                .clickable(enabled = enabled, onClick = onClick)
        )
    }
}

@Composable
internal fun SuburbPickerDialog(
    localities: AuLocalities,
    state: String,
    onSelect: (Locality) -> Unit,
    onDismiss: () -> Unit
) {
    var query by remember { mutableStateOf("") }
    val results = remember(query) { localities.search(state, query) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Suburb in ${AuAddress.stateName(state)}") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    placeholder = { Text("Search suburb or postcode") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                LazyColumn(modifier = Modifier.heightIn(max = 360.dp)) {
                    items(results, key = { "${it.name}|${it.postcode}" }) { locality ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { onSelect(locality) }
                                .padding(vertical = 12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(locality.name)
                            Text(locality.postcode, color = AppColors.TextSecondary)
                        }
                    }
                }
                if (results.isEmpty()) {
                    Text("No suburb matches \"$query\".", color = AppColors.TextSecondary)
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}

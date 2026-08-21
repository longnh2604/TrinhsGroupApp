package com.trinhskitchen.app.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.model.Billing
import com.trinhsgroup.shared.viewmodel.AuthViewModel

/**
 * Edit billing address.
 * Mirrors iOS EditAddressView — the same nine billing fields, saved with PUT /me.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditAddressScreen(
    authViewModel: AuthViewModel,
    onNavigateBack: () -> Unit
) {
    val user by authViewModel.user.collectAsState()
    val isLoading by authViewModel.showLoading.collectAsState()
    val isUpdated by authViewModel.isUpdatedUser.collectAsState()
    val message by authViewModel.message.collectAsState()

    var firstName by remember(user.id) { mutableStateOf(user.billing.firstName) }
    var lastName by remember(user.id) { mutableStateOf(user.billing.lastName) }
    var country by remember(user.id) { mutableStateOf(user.billing.country) }
    var address1 by remember(user.id) { mutableStateOf(user.billing.address1) }
    var state by remember(user.id) { mutableStateOf(user.billing.state) }
    var city by remember(user.id) { mutableStateOf(user.billing.city) }
    var postcode by remember(user.id) { mutableStateOf(user.billing.postcode) }
    var phone by remember(user.id) { mutableStateOf(user.billing.phone) }
    var email by remember(user.id) { mutableStateOf(user.billing.email.ifEmpty { user.email }) }

    LaunchedEffect(Unit) { authViewModel.clearUpdatedUser() }

    LaunchedEffect(isUpdated) {
        if (isUpdated) onNavigateBack()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background)
    ) {
        TopAppBar(
            title = { Text(text = "Edit Billing Address", fontWeight = FontWeight.Bold) },
            navigationIcon = {
                IconButton(onClick = onNavigateBack) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Back"
                    )
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = AppColors.Background,
                titleContentColor = AppColors.TextPrimary,
                navigationIconContentColor = AppColors.BarIcon,
                actionIconContentColor = AppColors.BarIcon
            )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = firstName,
                    onValueChange = { firstName = it },
                    label = { Text("First name") },
                    singleLine = true,
                    modifier = Modifier.weight(1f)
                )
                OutlinedTextField(
                    value = lastName,
                    onValueChange = { lastName = it },
                    label = { Text("Last name") },
                    singleLine = true,
                    modifier = Modifier.weight(1f)
                )
            }
            OutlinedTextField(
                value = country,
                onValueChange = { country = it },
                label = { Text("Country") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = address1,
                onValueChange = { address1 = it },
                label = { Text("Street address") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = state,
                onValueChange = { state = it },
                label = { Text("State") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = city,
                    onValueChange = { city = it },
                    label = { Text("City / Town") },
                    singleLine = true,
                    modifier = Modifier.weight(1f)
                )
                OutlinedTextField(
                    value = postcode,
                    onValueChange = { postcode = it },
                    label = { Text("Postcode") },
                    singleLine = true,
                    modifier = Modifier.weight(1f)
                )
            }
            OutlinedTextField(
                value = phone,
                onValueChange = { phone = it },
                label = { Text("Phone") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                label = { Text("Email") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                modifier = Modifier.fillMaxWidth()
            )

            if (message.isNotEmpty()) {
                Text(text = message, color = AppColors.Error)
            }

            Button(
                onClick = {
                    // Nothing here changes the password; make sure none is sent.
                    authViewModel.setPassword("")
                    authViewModel.onUpdateUser(
                        user.copy(
                            billing = Billing(
                                firstName = firstName,
                                lastName = lastName,
                                country = country,
                                address1 = address1,
                                city = city,
                                postcode = postcode,
                                state = state,
                                email = email,
                                phone = phone,
                                company = user.billing.company
                            )
                        )
                    )
                },
                enabled = !isLoading,
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(if (isLoading) "Saving…" else "Save")
            }
        }
    }
}

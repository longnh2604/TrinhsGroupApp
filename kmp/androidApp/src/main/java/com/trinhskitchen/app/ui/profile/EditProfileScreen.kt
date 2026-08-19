package com.trinhskitchen.app.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
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
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.text.KeyboardOptions
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.model.Billing
import com.trinhsgroup.shared.viewmodel.AuthViewModel

/**
 * Edit Profile.
 * Mirrors iOS EditProfileView: name, phone and an optional new password, saved with PUT /me.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditProfileScreen(
    authViewModel: AuthViewModel,
    onNavigateBack: () -> Unit
) {
    val user by authViewModel.user.collectAsState()
    val isLoading by authViewModel.showLoading.collectAsState()
    val isUpdated by authViewModel.isUpdatedUser.collectAsState()
    val message by authViewModel.message.collectAsState()

    var firstName by remember(user.id) { mutableStateOf(user.firstName) }
    var lastName by remember(user.id) { mutableStateOf(user.lastName) }
    var phone by remember(user.id) { mutableStateOf(user.billing.phone) }
    var newPassword by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }

    // A previous save would otherwise still read as "just saved".
    LaunchedEffect(Unit) { authViewModel.clearUpdatedUser() }

    LaunchedEffect(isUpdated) {
        if (isUpdated) onNavigateBack()
    }

    val passwordError = when {
        newPassword.isEmpty() -> null
        newPassword.length < 6 -> "Password must be at least 6 characters"
        newPassword != confirmPassword -> "Passwords do not match"
        else -> null
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background)
    ) {
        TopAppBar(
            title = { Text(text = "Edit Profile", fontWeight = FontWeight.Bold) },
            navigationIcon = {
                IconButton(onClick = onNavigateBack) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Back"
                    )
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = AppColors.Primary,
                titleContentColor = Color.White,
                navigationIconContentColor = Color.White
            )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            OutlinedTextField(
                value = user.email,
                onValueChange = {},
                label = { Text("Email") },
                enabled = false,
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = firstName,
                onValueChange = { firstName = it },
                label = { Text("First name") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = lastName,
                onValueChange = { lastName = it },
                label = { Text("Last name") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = phone,
                onValueChange = { phone = it },
                label = { Text("Phone") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = newPassword,
                onValueChange = { newPassword = it },
                label = { Text("New password (optional)") },
                singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = confirmPassword,
                onValueChange = { confirmPassword = it },
                label = { Text("Confirm new password") },
                singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                isError = passwordError != null,
                supportingText = passwordError?.let { { Text(it, color = AppColors.Error) } },
                modifier = Modifier.fillMaxWidth()
            )

            if (message.isNotEmpty()) {
                Text(text = message, color = AppColors.Error)
            }

            Button(
                onClick = {
                    // Blank clears whatever password the sign-in form left behind.
                    authViewModel.setPassword(newPassword)
                    authViewModel.onUpdateUser(
                        user.copy(
                            firstName = firstName,
                            lastName = lastName,
                            billing = user.billing.withPhone(phone)
                        )
                    )
                },
                enabled = !isLoading && passwordError == null,
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(if (isLoading) "Saving…" else "Save")
            }
        }
    }
}

/** Billing is not a data class, so a one-field change is spelled out. */
private fun Billing.withPhone(phone: String) = Billing(
    firstName = firstName,
    lastName = lastName,
    country = country,
    address1 = address1,
    city = city,
    postcode = postcode,
    state = state,
    email = email,
    phone = phone,
    company = company
)

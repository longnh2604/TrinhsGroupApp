package com.trinhskitchen.app.ui.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
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
import com.trinhsgroup.shared.viewmodel.AuthViewModel

/**
 * Forgot password.
 * Mirrors iOS ForgetPasswordView: one email field, one reset request.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ForgotPasswordScreen(
    authViewModel: AuthViewModel,
    onNavigateBack: () -> Unit
) {
    val isLoading by authViewModel.showLoading.collectAsState()
    val message by authViewModel.message.collectAsState()
    val isSent by authViewModel.isPasswordReset.collectAsState()

    var email by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        authViewModel.clearPasswordReset()
        authViewModel.clearMessage()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background)
    ) {
        TopAppBar(
            title = { Text(text = "Forgot Password", fontWeight = FontWeight.Bold) },
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
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "Enter the email address on your account and we will send you a link to reset your password.",
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextSecondary
            )

            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                label = { Text("Email") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                modifier = Modifier.fillMaxWidth()
            )

            if (isSent) {
                Text(
                    text = "Reset link sent. Check your inbox.",
                    color = AppColors.Primary
                )
            } else if (message.isNotEmpty()) {
                Text(text = message, color = AppColors.Error)
            }

            Button(
                onClick = { authViewModel.onForgotPassword(email.trim()) },
                enabled = !isLoading && email.isNotBlank(),
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(if (isLoading) "Sending…" else "Send reset link")
            }
        }
    }
}

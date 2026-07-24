//
//  EditProfileView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isPasswordRevealed = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false

    private var hasChanges: Bool {
        firstName != authViewModel.user.first_name
            || lastName != authViewModel.user.last_name
            || phone != authViewModel.user.billing.phone
            || !newPassword.isEmpty
    }

    private var passwordError: String? {
        guard !newPassword.isEmpty else { return nil }
        if newPassword.count < 6 {
            return L10n.Profile.passwordTooShort.localized
        }
        if newPassword != confirmPassword {
            return L10n.Profile.passwordMismatch.localized
        }
        return nil
    }

    private var canSave: Bool {
        hasChanges && passwordError == nil && !authViewModel.showLoading
    }

    var body: some View {
        ZStack {
            ProfileDesign.Colors.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                CustomNavigationBarView(title: L10n.Profile.editProfileTitle.localized)
                    .environmentObject(authViewModel)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: ProfileDesign.Spacing.md) {
                        AccountCard()
                        PersonalInfoCard()
                        PasswordCard()
                        SaveButton()
                    }
                    .padding(.horizontal, ProfileDesign.Spacing.md)
                    .padding(.top, ProfileDesign.Spacing.md)
                    .padding(.bottom, ProfileDesign.Spacing.xxl)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onTapGesture {
            hideKeyboard()
        }
        .onDisappear {
            hideKeyboard()
        }
        .onAppear {
            firstName = authViewModel.user.first_name
            lastName = authViewModel.user.last_name
            phone = authViewModel.user.billing.phone
        }
        .onChange(of: authViewModel.isUpdatedUser) { isUpdated in
            if isUpdated {
                hideKeyboard()
                newPassword = ""
                confirmPassword = ""
                showSuccessAlert = true
            }
        }
        .onChange(of: authViewModel.message) { message in
            if !message.isEmpty {
                showErrorAlert = true
            }
        }
        .alert(L10n.Common.success.localizedKey, isPresented: $showSuccessAlert) {
            Button(L10n.Common.ok.localized, role: .cancel) {
                hideKeyboard()
                authViewModel.showEditProfile = false
            }
        } message: {
            Text(L10n.Profile.updatedUserSuccessful.localizedKey)
        }
        .alert(L10n.Common.error.localizedKey, isPresented: $showErrorAlert) {
            Button(L10n.Common.ok.localized, role: .cancel) {
                authViewModel.message = ""
            }
        } message: {
            Text(authViewModel.message)
        }
    }

    // MARK: - Account Card (read-only)
    @ViewBuilder
    private func AccountCard() -> some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.sm) {
            Text(L10n.Profile.accountNav.localizedKey)
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
                .padding(.bottom, 4)

            LockedFieldRow(
                icon: "person.fill",
                label: L10n.Auth.username.localized,
                value: authViewModel.user.username,
                note: L10n.Profile.usernameLockedNote.localized
            )

            Divider().padding(.leading, 48)

            LockedFieldRow(
                icon: "envelope.fill",
                label: L10n.Common.email.localized,
                value: authViewModel.user.email,
                note: L10n.Profile.emailLockedNote.localized
            )
        }
        .profileCard()
    }

    // MARK: - Personal Info Card
    @ViewBuilder
    private func PersonalInfoCard() -> some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.sm) {
            Text(L10n.Profile.personalInformation.localizedKey)
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
                .padding(.bottom, 4)

            EditableFieldRow(
                label: L10n.Profile.firstName.localized,
                placeholder: L10n.Profile.firstName_placeholder.localized,
                text: $firstName
            )

            Divider()

            EditableFieldRow(
                label: L10n.Profile.lastName.localized,
                placeholder: L10n.Profile.lastName_placeholder.localized,
                text: $lastName
            )

            Divider()

            EditableFieldRow(
                label: L10n.Profile.phone.localized,
                placeholder: L10n.Profile.phone.localized,
                text: $phone,
                keyboard: .phonePad
            )
        }
        .profileCard()
    }

    // MARK: - Password Card
    @ViewBuilder
    private func PasswordCard() -> some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.sm) {
            Text(L10n.Profile.changePassword.localizedKey)
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)

            Text(L10n.Profile.passwordKeepNote.localizedKey)
                .font(ProfileDesign.Typography.caption)
                .foregroundColor(ProfileDesign.Colors.textSecondary)
                .padding(.bottom, 4)

            PasswordFieldRow(
                label: L10n.Profile.newPassword.localized,
                text: $newPassword,
                isRevealed: $isPasswordRevealed
            )

            Divider()

            PasswordFieldRow(
                label: L10n.Profile.confirmPassword.localized,
                text: $confirmPassword,
                isRevealed: $isPasswordRevealed
            )

            if let error = passwordError {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(ProfileDesign.Typography.caption)
                    .foregroundColor(ProfileDesign.Colors.error)
            }
        }
        .profileCard()
    }

    // MARK: - Save Button
    @ViewBuilder
    private func SaveButton() -> some View {
        Button(action: save) {
            ZStack {
                RoundedRectangle(cornerRadius: ProfileDesign.Radius.md, style: .continuous)
                    .fill(Constants.AppColor.primaryRed)
                    .opacity(canSave ? 1 : 0.4)

                if authViewModel.showLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(L10n.Profile.saveChanges.localizedKey)
                        .font(ProfileDesign.Typography.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 52)
        }
        .disabled(!canSave)
        .padding(.top, ProfileDesign.Spacing.xs)
    }

    private func save() {
        hideKeyboard()
        var updated = authViewModel.user
        updated.first_name = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.last_name = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.billing.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        authViewModel.onUpdateUser(user: updated, password: newPassword)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Locked Field Row
private struct LockedFieldRow: View {
    let icon: String
    let label: String
    let value: String
    let note: String

    var body: some View {
        HStack(spacing: ProfileDesign.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: ProfileDesign.Radius.xs, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ProfileDesign.Colors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(ProfileDesign.Typography.caption)
                    .foregroundColor(ProfileDesign.Colors.textSecondary)
                Text(value.isEmpty ? "-" : value)
                    .font(ProfileDesign.Typography.body)
                    .foregroundColor(ProfileDesign.Colors.textPrimary)
                Text(note)
                    .font(ProfileDesign.Typography.caption2)
                    .foregroundColor(ProfileDesign.Colors.textTertiary)
            }

            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(ProfileDesign.Colors.textTertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Editable Field Row
private struct EditableFieldRow: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(ProfileDesign.Typography.caption)
                .foregroundColor(ProfileDesign.Colors.textSecondary)

            TextField(placeholder, text: $text)
                .font(ProfileDesign.Typography.body)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
                .keyboardType(keyboard)
                .disableAutocorrection(true)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Password Field Row
private struct PasswordFieldRow: View {
    let label: String
    @Binding var text: String
    @Binding var isRevealed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(ProfileDesign.Typography.caption)
                .foregroundColor(ProfileDesign.Colors.textSecondary)

            HStack {
                Group {
                    if isRevealed {
                        TextField(label, text: $text)
                    } else {
                        SecureField(label, text: $text)
                    }
                }
                .font(ProfileDesign.Typography.body)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
                .autocapitalization(.none)
                .disableAutocorrection(true)

                Button(action: { isRevealed.toggle() }) {
                    Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ProfileDesign.Colors.textTertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
            .environmentObject(AuthViewModel())
            .environmentObject(MainViewModel())
    }
}

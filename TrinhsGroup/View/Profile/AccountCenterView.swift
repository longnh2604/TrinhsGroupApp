//
//  AccountCenterView.swift
//  TrinhsGroup
//
//  Account Center Screen - Change Avatar, Password, Manage Address
//

import SwiftUI

struct AccountCenterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showChangeAvatar = false
    @State private var showChangePassword = false
    @State private var showManageAddress = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ProfileDesign.Colors.screenBackground
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: ProfileDesign.Spacing.md) {
                        // Profile Header
                        ProfileHeaderCard()
                        
                        // Account Settings
                        AccountSettingsCard(
                            onAvatarTap: { showChangeAvatar = true },
                            onPasswordTap: { showChangePassword = true },
                            onAddressTap: { showManageAddress = true }
                        )
                        
                        // Personal Information
                        PersonalInfoCard()
                    }
                    .padding(.horizontal, ProfileDesign.Spacing.md)
                    .padding(.top, ProfileDesign.Spacing.sm)
                    .padding(.bottom, ProfileDesign.Spacing.xxl)
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showManageAddress) {
                EditAddressView()
                    .environmentObject(authViewModel)
            }
        }
    }
    
    // MARK: - Profile Header Card
    @ViewBuilder
    private func ProfileHeaderCard() -> some View {
        VStack(spacing: ProfileDesign.Spacing.md) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                AvatarView(url: authViewModel.user.avatar_url, size: 100)
                
                // Edit button
                Button(action: { showChangeAvatar = true }) {
                    ZStack {
                        Circle()
                            .fill(ProfileDesign.Colors.primary)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: ProfileDesign.Icons.camera)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 4, y: 4)
            }
            
            // User info
            VStack(spacing: 4) {
                Text(authViewModel.user.username.isEmpty ? "Guest User" : authViewModel.user.username)
                    .font(ProfileDesign.Typography.title)
                    .foregroundColor(ProfileDesign.Colors.textPrimary)
                
                Text(authViewModel.user.email.isEmpty ? "Not logged in" : authViewModel.user.email)
                    .font(ProfileDesign.Typography.subheadline)
                    .foregroundColor(ProfileDesign.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ProfileDesign.Spacing.lg)
        .profileCard()
    }
    
    // MARK: - Account Settings Card
    @ViewBuilder
    private func AccountSettingsCard(
        onAvatarTap: @escaping () -> Void,
        onPasswordTap: @escaping () -> Void,
        onAddressTap: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.sm) {
            Text("Account Settings")
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
                .padding(.bottom, 4)
            
            ProfileRowItem(
                icon: ProfileDesign.Icons.camera,
                iconColor: .pink,
                title: "Change Avatar",
                subtitle: "Update your profile picture",
                action: onAvatarTap
            )
            
            Divider().padding(.leading, 48)
            
            ProfileRowItem(
                icon: ProfileDesign.Icons.password,
                iconColor: .orange,
                title: "Change Password",
                subtitle: "Update your password",
                action: onPasswordTap
            )
            
            Divider().padding(.leading, 48)
            
            ProfileRowItem(
                icon: ProfileDesign.Icons.address,
                iconColor: .green,
                title: "Manage Address",
                subtitle: "Billing and shipping addresses",
                action: onAddressTap
            )
        }
        .profileCard()
    }
    
    // MARK: - Personal Info Card
    @ViewBuilder
    private func PersonalInfoCard() -> some View {
        VStack(alignment: .leading, spacing: ProfileDesign.Spacing.sm) {
            Text("Personal Information")
                .font(ProfileDesign.Typography.headline)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
                .padding(.bottom, 4)
            
            InfoRow(label: "First Name", value: authViewModel.user.first_name)
            Divider().padding(.leading, 0)
            InfoRow(label: "Last Name", value: authViewModel.user.last_name)
            Divider().padding(.leading, 0)
            InfoRow(label: "Email", value: authViewModel.user.email)
            Divider().padding(.leading, 0)
            InfoRow(label: "Phone", value: authViewModel.user.billing.phone)
        }
        .profileCard()
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(ProfileDesign.Typography.subheadline)
                .foregroundColor(ProfileDesign.Colors.textSecondary)
            
            Spacer()
            
            Text(value.isEmpty ? "-" : value)
                .font(ProfileDesign.Typography.body)
                .foregroundColor(ProfileDesign.Colors.textPrimary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct AccountCenterView_Previews: PreviewProvider {
    static var previews: some View {
        AccountCenterView()
            .environmentObject(AuthViewModel())
    }
}

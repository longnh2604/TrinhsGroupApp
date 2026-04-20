//
//  EditProfileView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    fileprivate func NameTextFields() -> some View {
        return HStack {
            Image(systemName: "person.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding(.leading, 20)
                .foregroundColor(Constants.AppColor.primaryRed)
            TextField(L10n.Profile.name.localizedKey, text: $authViewModel.user.username)
                .padding(.leading, 12)
                .font(.system(size: 20))
                .frame(height: 55)
                .disabled(true)
        }
        .background(Color.white)
        .cornerRadius(25)
        .overlay(RoundedRectangle(cornerRadius: 25.0).foregroundColor(Color.gray.opacity(0.15)))
        .padding([.leading, .trailing], 20)
        .padding(.top, 5)
        .shadow(color: .gray, radius: 0.5)
    }
    
    fileprivate func EmailTextFields() -> some View {
        return HStack {
            Image(systemName: "envelope.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding(.leading, 20)
                .foregroundColor(Constants.AppColor.primaryRed)
            TextField(L10n.Auth.email.localizedKey, text: $authViewModel.user.email)
                .padding(.leading, 12)
                .font(.system(size: 20))
                .frame(height: 55)
        }
        .background(Color.white)
        .cornerRadius(25)
        .overlay(RoundedRectangle(cornerRadius: 25.0).foregroundColor(Color.gray.opacity(0.15)))
        .padding([.leading, .trailing], 20)
        .padding(.top, 5)
        .shadow(color: .gray, radius: 0.5)
    }
    
    fileprivate func PasswordTextField() -> some View {
        return HStack {
            Image(systemName: "lock.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding(.leading, 20)
                .foregroundColor(Constants.AppColor.primaryRed)
            SecureField(L10n.Auth.password.localizedKey, text: $authViewModel.password)
                .padding(.leading, 12)
                .font(.system(size: 20))
                .frame(height: 55)
        }
        .background(Color.white)
        .cornerRadius(25)
        .overlay(RoundedRectangle(cornerRadius: 25.0).foregroundColor(Color.gray.opacity(0.15)))
        .padding([.leading, .trailing], 20)
        .padding(.top, 5)
        .shadow(color: .gray, radius: 0.5)
    }
    
    fileprivate func UpdateButton() -> some View {
        return Button(action: {
            authViewModel.onUpdateUser(user: authViewModel.user)
        }) {
            Text(L10n.Common.update.localizedKey)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(Constants.AppColor.primaryRed)
                .cornerRadius(25)
        }
        .padding([.leading, .trailing], 20)
        .padding(.top, 40)
    }
    
    
    var body: some View {
        ZStack {
            Color.init(hex: "f9f9f9")
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                CustomNavigationBarView(title: "Profile")
                    .environmentObject(authViewModel)
                
                NameTextFields()
                    .padding(.top)
                EmailTextFields()
                PasswordTextField()
//                UpdateButton()
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

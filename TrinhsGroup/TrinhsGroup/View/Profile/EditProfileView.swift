//
//  EditProfileView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct EditProfileView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                withAnimation(.spring()){
                    authViewModel.showEditProfile.toggle()
                }
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(Constants.AppColor.secondaryBlack)
            }
            .padding(.leading, 10)
            .frame(width: 40, height: 40)
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width, height: 35)
        .overlay(
            Text("Edit Profile")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.horizontal, 10)
                .background(Color.clear)
            , alignment: .center)
    }
    
    fileprivate func NameTextFiels() -> some View {
        return HStack {
            Image(systemName: "person.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding(.leading, 20)
                .foregroundColor(Color("ColorPrimary"))
            TextField("Name", text: $authViewModel.user.username)
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
    
    fileprivate func EmailTextFiels() -> some View {
        return HStack {
            Image(systemName: "envelope.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding(.leading, 20)
                .foregroundColor(Color("ColorPrimary"))
            TextField("Email", text: $authViewModel.user.email)
                .padding(.leading, 12)
                .font(.system(size: 20))
                .frame(height: 55)
        }
        .background(Color.white)
        .cornerRadius(25)
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
                .foregroundColor(Color("ColorPrimary"))
            SecureField("Password", text: $authViewModel.password)
                .padding(.leading, 12)
                .font(.system(size: 20))
                .frame(height: 55)
        }
        .background(Color.white)
        .cornerRadius(25)
        .padding([.leading, .trailing], 20)
        .padding(.top, 5)
        .shadow(color: .gray, radius: 0.5)
    }
    
    fileprivate func UpdateButton() -> some View {
        return Button(action: {
            authViewModel.updateUser()
        }) {
            Text("Update")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(Color("ColorPrimary"))
                .cornerRadius(25)
        }
        .padding([.leading, .trailing], 20)
        .padding(.top, 40)
    }
    
    
    var body: some View {
        
        NavigationView {
            ZStack {
                Color.init(hex: "f9f9f9")
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    NavigationBarView()
                    NameTextFiels()
                        .padding(.top)
                    EmailTextFiels()
                    PasswordTextField()
                    UpdateButton()
                    
                    Spacer()
                }
            }
            .navigationBarTitle(Text(""), displayMode: .inline)
            .navigationBarHidden(true)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
            .environmentObject(AuthViewModel())
    }
}

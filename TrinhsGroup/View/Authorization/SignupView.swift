//
//  SignupView.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import SwiftUI

struct SignupView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var selection: Int? = nil
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    fileprivate func NavigationBarView() -> some View {
        return HStack(alignment: .center) {
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.black)
            }
            .padding(.leading, 10)
            .frame(width: 40, height: 40)
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width, height: 45)
        .overlay(
            Text("Signup")
                .font(.headline)
                .padding(.horizontal, 10)
                .background(Color.init(hex: "f9f9f9"))
            , alignment: .center)
    }
    
    fileprivate func AppIcon() -> some View {
        return HStack {
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100, alignment: .center)
                .padding(.top, 10)
        }
    }
    
    fileprivate func NameTextField() -> some View {
        return HStack {
            Image(systemName: "person.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding(.leading, 20)
                .foregroundColor(Color("ColorPrimary"))
            TextField("Username", text: $authViewModel.username)
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
    
    fileprivate func EmailTextField() -> some View {
        return HStack {
            Image(systemName: "envelope.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding(.leading, 20)
                .foregroundColor(Color("ColorPrimary"))
            TextField("Email", text: $authViewModel.email)
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
    
    fileprivate func SignUpButton() -> some View {
        return Button(action: {
            authViewModel.createUser()
        }) {
            Text("Sign Up")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color.init(hex: "cb2d3e"), Color.init(hex: "ef473a")]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(25)
        }
        .padding([.leading, .trailing], 20)
        .padding(.top, 40)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.init(hex: "F9F9F9")
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    NavigationBarView()
                    AppIcon()
                    NameTextField()
                        .padding(.top, 30)
                    EmailTextField()
                    PasswordTextField()
                    SignUpButton()
                    Spacer()
                }
                if authViewModel.showLoading {
                    LoadingView().ignoresSafeArea()
                }
                if !authViewModel.message.isEmpty {
                    CustomAlertView(message: authViewModel.message)
                }
                if authViewModel.isCreatedUser {
                    CustomAlertView(message: "Your account was created successfully. Please switch to login")
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}

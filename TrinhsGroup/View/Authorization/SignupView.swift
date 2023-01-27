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
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Text("")
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

    // Push view
    fileprivate func GoToLoginButton() -> some View {
        return NavigationLink(destination: LogInView()
                                .environmentObject(authViewModel), tag: 2, selection: $selection) {
            Button(action: {
                self.selection = 2
            }) {
                Text("Already have an account?")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
    
    fileprivate func GoogleLogInButton() -> some View {
        return Button(action: {
            
        }) {
            Image("google")
                .renderingMode(.original)
        }
    }
    
    fileprivate func FacebookLogInButton() -> some View {
        return Button(action: {
            
        }) {
            Image("facebook")
                .renderingMode(.original)
        }
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
                    GoToLoginButton()
                    Spacer()
                    Text("Signup with social account")
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                    HStack {
                        GoogleLogInButton()
                        FacebookLogInButton()
                    }
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
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}

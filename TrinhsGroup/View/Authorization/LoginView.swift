//
//  LoginView.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import SwiftUI

struct LogInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var isShowForgetPasswordView : Bool = false
    @State var isShowSignUp : Bool = false
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    fileprivate func AppIcon() -> some View {
        return HStack {
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100, alignment: .center)
                .padding(.top, 10)
        }
    }
    
    fileprivate func EmailTextFiels() -> some View {
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
    
    fileprivate func LoginButton() -> some View {
        return Button(action: {
            authViewModel.onAuthUser()
        }) {
            Text("Login")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color.init(hex: "cb2d3e"), Color.init(hex: "ef473a")]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(25)
        }
        .padding([.leading, .trailing], 20)
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
    
    fileprivate func ForgetPasswordButton() -> some View {
        return Button(action: {
            self.isShowForgetPasswordView.toggle()
        }) {
            Text("Forget your password?")
                .foregroundColor(.gray)
                .padding()
        }.sheet(isPresented: $isShowForgetPasswordView) {
            ForgetPasswordView()
                .environmentObject(authViewModel)
        }
    }
    
    fileprivate func GoToSignUp() -> some View {
        return Button(action: {
            self.isShowSignUp.toggle()
        }) {
            Text("Don't have an account yet? Sign Up")
                .foregroundColor(.gray)
                .padding()
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.init(hex: "F9F9F9")
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    AppIcon()
                    EmailTextFiels()
                        .padding(.top, 30)
                    PasswordTextField()
                    LoginButton()
                    ForgetPasswordButton()
                    GoToSignUp()
                }
                if authViewModel.showLoading {
                    LoadingView().ignoresSafeArea()
                }
                if !authViewModel.message.isEmpty {
                    CustomAlertView(message: authViewModel.message)
                }
                
                NavigationLink(destination: SignupView().environmentObject(authViewModel), isActive: $isShowSignUp) {
                    EmptyView()
                }
            }
            .navigationBarTitle(Text(""), displayMode: .inline)
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView()
    }
}

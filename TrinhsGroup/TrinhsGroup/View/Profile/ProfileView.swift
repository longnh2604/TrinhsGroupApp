//
//  ProfileView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
//    @EnvironmentObject var historyViewModel: HistoryViewModel
    @State var selection: Int? = nil
    @State private var showDialog : Bool = false
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Text("")
        }
        .frame(width: UIScreen.main.bounds.width, height: 45)
        .overlay(
            Text("Profile")
                .font(.custom(Constants.AppFont.semiBoldFont, size: 15))
                .padding(.horizontal, 10)
                .background(Color.init(hex: "f9f9f9"))
            , alignment: .center)
    }
    
    fileprivate func LogoutButton() -> some View {
        return Button(action: {
            showDialog.toggle()
        }) {
            Text("Logout")
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
                VStack(alignment: .leading) {
                    
                    NavigationBarView()
                    
                    HStack {
                        VStack(alignment: .leading) {
//                            Text(authViewModel.displayName)
//                                .font(.headline)
//                                .bold()
//                            Text(authViewModel.userEmail)
//                                .font(.caption)
//                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()){
//                                authViewModel.showEditProfile.toggle()
                            }
                        }) {
                            Text("Edit")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color("ColorPrimary"))
                                .cornerRadius(20)
                        }
                    }
                    .padding()
                    .padding(.horizontal, 10)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    VStack{
                        
                        Button(action: {
                            withAnimation(.spring()){
//                                historyViewModel.showHistory.toggle()
                            }
                        }, label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("My Orders")
                                        .foregroundColor(.primary)
                                        .font(.subheadline)
                                        .bold()
//                                    Text("Already have \(historyViewModel.orders.count) orders")
//                                        .font(.caption)
//                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.primary)
                            }.padding([.horizontal, .vertical], 10)
                        })
                        
                        
                        Button(action: {
                            withAnimation(.spring()){
//                                authViewModel.showEditAddress.toggle()
                            }
                        }, label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Manage Address")
                                        .foregroundColor(.primary)
                                        .font(.subheadline)
                                        .bold()
                                    Text("2 address")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.primary)
                            }
                        })
                        .padding([.horizontal, .vertical], 10)
                        
                    }
                    .colorMultiply(Color.init(hex: "f9f9f9"))
                    .padding()
                    
                    Spacer()
                    LogoutButton()
                        .padding(.bottom, 8)
                }
                .navigationBarTitle(Text(""), displayMode: .inline)
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
                
//                if authViewModel.showEditProfile {
//                    EditProfileView()
//                        .environmentObject(authViewModel)
//                }
//                
//                if authViewModel.showEditAddress {
//                    EditAddressView()
//                        .environmentObject(authViewModel)
//                }
                
//                if historyViewModel.showHistory {
//                    MyOrdersView()
//                        .environmentObject(mainViewModel)
//                        .environmentObject(historyViewModel)
//                        .environmentObject(authViewModel)
//                }
            }
        }.alert(isPresented: $showDialog, content: {
            Alert(title: Text("Logout"),
                  message: Text("Are you sure want to logout"),
                  primaryButton: .default(Text("Yes")) {
                    authViewModel.username = ""
                    authViewModel.email = ""
                    authViewModel.password = ""
                    authViewModel.isLogin = false
                  },
                  secondaryButton: .cancel()
            )
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}

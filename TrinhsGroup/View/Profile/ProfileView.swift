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
    @EnvironmentObject var historyViewModel: HistoryViewModel
    @State var selection: Int? = nil
    @State private var showDialog : Bool = false
    
    fileprivate func LogoutButton() -> some View {
        return Button(action: {
            showDialog.toggle()
        }) {
            Text("Logout")
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
        NavigationView {
            ZStack {
                Color.init(hex: "f9f9f9")
                    .edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading) {
                    HomeNavigationBarView(title: "Profile", showNotificationIcon: false)
                        .environmentObject(mainViewModel)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(authViewModel.user.username)
                                .font(.headline)
                                .bold()
                            Text(authViewModel.user.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()){
                                authViewModel.showEditProfile.toggle()
                            }
                        }) {
                            Text("View")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Constants.AppColor.primaryRed)
                                .cornerRadius(20)
                        }
                    }
                    .padding()
                    .padding(.horizontal, 10)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    VStack {
                        Button(action: {
                            withAnimation(.spring()){
                                mainViewModel.showOrderReceived.toggle()
                            }
                        }, label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("My Orders")
                                        .foregroundColor(.primary)
                                        .font(.subheadline)
                                        .bold()
                                    Text("Already have \(historyViewModel.orders.count) orders")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.primary)
                            }.padding([.horizontal, .vertical], 10)
                        })
                        
                        
                        Button(action: {
                            withAnimation(.spring()){
                                authViewModel.showEditAddress.toggle()
                            }
                        }, label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Manage Address")
                                        .foregroundColor(.primary)
                                        .font(.subheadline)
                                        .bold()
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
                
                NavigationLink(
                    destination: EditProfileView()
                        .environmentObject(authViewModel),
                    isActive: $authViewModel.showEditProfile,
                    label: {
                        EmptyView()
                    }
                )
                .hidden()
                
                NavigationLink(
                    destination: EditAddressView()
                        .environmentObject(authViewModel)
                        .environmentObject(mainViewModel),
                    isActive: $authViewModel.showEditAddress,
                    label: {
                        EmptyView()
                    }
                )
                .hidden()
                
                NavigationLink(
                    destination: MyOrdersView()
                        .environmentObject(mainViewModel)
                        .environmentObject(historyViewModel)
                        .environmentObject(authViewModel),
                    isActive: $mainViewModel.showOrderReceived,
                    label: {
                        EmptyView()
                    }
                )
                .hidden()
            }
        }
        .alert(isPresented: $showDialog, content: {
            Alert(title: Text("Logout"),
                  message: Text("Are you sure want to logout"),
                  primaryButton: .default(Text("Yes")) {
                    authViewModel.user = .empty
                    authViewModel.isLogin = false
                  },
                  secondaryButton: .cancel()
            )
        })
        .onAppear {
            historyViewModel.fetchOrders(customerId: authViewModel.user.id)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}

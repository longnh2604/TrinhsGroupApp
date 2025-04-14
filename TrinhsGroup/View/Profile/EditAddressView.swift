//
//  EditAddressView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct EditAddressView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    
    fileprivate func BillingFirstNameTextField() -> some View {
        return HStack {
            TextField("First name", text: $authViewModel.user.billing.first_name)
                .padding(.leading, 20)
                .font(.system(size: 20))
                .frame(height: 55)
        }
        .background(Color.white)
        .cornerRadius(25)
        .padding([.leading], 20)
        .padding(.top, 5)
        .shadow(color: .gray, radius: 0.5)
    }
    
    fileprivate func BillingLastNameTextField() -> some View {
        return HStack {
            TextField("Last name", text: $authViewModel.user.billing.last_name)
                .padding(.leading, 20)
                .font(.system(size: 20))
                .frame(height: 55)
        }
        .background(Color.white)
        .cornerRadius(25)
        .padding([.trailing], 20)
        .padding(.top, 5)
        .shadow(color: .gray, radius: 0.5)
    }
    
    fileprivate func BillingCountryTextField() -> some View {
        return HStack {
            TextField("Country", text: $authViewModel.user.billing.country)
                .padding(.leading, 20)
                .font(.system(size: 20))
                .frame(height: 55)
        }
        .background(Color.white)
        .cornerRadius(25)
        .padding([.leading, .trailing], 20)
        .padding(.top, 5)
        .shadow(color: .gray, radius: 0.5)
    }
    
    fileprivate func BillingStreetAddressTextField() -> some View {
        return HStack {
            TextField("Street address", text: $authViewModel.user.billing.address_1)
                .padding(.leading, 20)
                .font(.system(size: 20))
                .frame(height: 55)
        }
        .background(Color.white)
        .cornerRadius(25)
        .padding([.leading, .trailing], 20)
        .padding(.top, 5)
        .shadow(color: .gray, radius: 0.5)
    }
    
    fileprivate func BillingStateTextField() -> some View {
        return HStack {
            TextField("State", text: $authViewModel.user.billing.state)
                .padding(.leading, 20)
                .font(.system(size: 20))
                .frame(height: 55)
        }
        .background(Color.white)
        .cornerRadius(25)
        .padding([.leading, .trailing], 20)
        .padding(.top, 5)
        .shadow(color: .gray, radius: 0.5)
    }
    
    fileprivate func BillingCityTextField() -> some View {
        return HStack {
            TextField("City / Town", text: $authViewModel.user.billing.city)
                .padding(.leading, 20)
                .font(.system(size: 20))
                .frame(height: 55)
        }
        .background(Color.white)
        .cornerRadius(25)
        .padding([.leading], 20)
        .padding(.top, 5)
        .shadow(color: .gray, radius: 0.5)
    }
    
    fileprivate func BillingPostcodeNameTextField() -> some View {
        return HStack {
            TextField("Postcode", text: $authViewModel.user.billing.postcode)
                .padding(.leading, 20)
                .font(.system(size: 20))
                .frame(height: 55)
        }
        .background(Color.white)
        .cornerRadius(25)
        .padding([.trailing], 20)
        .padding(.top, 5)
        .shadow(color: .gray, radius: 0.5)
    }
    
    
    fileprivate func BillingPhoneTextField() -> some View {
        return HStack {
            TextField("Phone", text: $authViewModel.user.billing.phone)
                .padding(.leading, 20)
                .font(.system(size: 20))
                .frame(height: 55)
        }
        .background(Color.white)
        .cornerRadius(25)
        .padding([.leading, .trailing], 20)
        .padding(.top, 5)
        .shadow(color: .gray, radius: 0.5)
    }
    
    
    fileprivate func BillingEmailTextField() -> some View {
        return HStack {
            TextField("Email", text: $authViewModel.user.billing.email)
                .padding(.leading, 20)
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
            authViewModel.onUpdateUser(user: authViewModel.user)
        }) {
            Text("Update")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(Constants.AppColor.primaryRed)
                .cornerRadius(25)
        }
        .padding([.leading, .trailing], 20)
    }
    
    var body: some View {
        ZStack {
            Color.init(hex: "f9f9f9")
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                CustomNavigationBarView(title: "Edit Billing Address")
                    .environmentObject(authViewModel)
                
                ScrollView(.vertical, showsIndicators: false, content: {
                    VStack(alignment: .leading) {
                        Text("Billing Address")
                            .font(.custom(Constants.AppFont.boldFont, size: 22))
                            .foregroundColor(Constants.AppColor.secondaryBlack)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 10) {
                            BillingFirstNameTextField().frame(minWidth: 0,
                                                  maxWidth: .infinity)
                            BillingLastNameTextField().frame(minWidth: 0,
                                                  maxWidth: .infinity)
                        }
                        BillingCountryTextField()
                        BillingStreetAddressTextField()
                        BillingStateTextField()
                        HStack(spacing: 10) {
                            BillingCityTextField().frame(minWidth: 0,
                                                  maxWidth: .infinity)
                            BillingPostcodeNameTextField().frame(minWidth: 0,
                                                  maxWidth: .infinity)
                        }
                        BillingPhoneTextField()
                        BillingEmailTextField()
      
                    }
                })
                .padding(.top)
                
                UpdateButton()
                
                Spacer()
            }
            if authViewModel.showLoading {
                LoadingView().ignoresSafeArea()
            }
            if authViewModel.isUpdatedUser {
                CustomAlertView(message: "Updated User Info Successful")
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

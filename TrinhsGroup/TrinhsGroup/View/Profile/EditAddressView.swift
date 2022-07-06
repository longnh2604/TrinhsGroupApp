//
//  EditAddressView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct EditAddressView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    fileprivate func NavigationBarView() -> some View {
        return HStack {
            Button(action: {
                withAnimation(.spring()){
                    authViewModel.showEditAddress.toggle()
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
    
    fileprivate func BillingNameTextFiels() -> some View {
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
    
    fileprivate func BillingLastNameTextFiels() -> some View {
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
    
    fileprivate func BillingCompanyTextFiels() -> some View {
        return HStack {
            TextField("Company (optional)", text: $authViewModel.user.billing.company)
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
    
    fileprivate func BillingCountryTextFiels() -> some View {
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
    
    fileprivate func BillingStreetAddressTextFiels() -> some View {
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
    
    fileprivate func BillingApartmentTextFiels() -> some View {
        return HStack {
            TextField("Apartment, unit, etc. (optional)", text: $authViewModel.user.billing.address_2)
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
    
    fileprivate func BillingStateTextFiels() -> some View {
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
    
    fileprivate func BillingCityTextFiels() -> some View {
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
    
    fileprivate func BillingPostcodeNameTextFiels() -> some View {
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
    
    
    fileprivate func BillingPhoneTextFiels() -> some View {
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
    
    
    fileprivate func BillingEmailTextFiels() -> some View {
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
    
    fileprivate func ShippingNameTextFiels() -> some View {
        return HStack {
            TextField("First name", text: $authViewModel.user.shipping.first_name)
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
    
    fileprivate func ShippingLastNameTextFiels() -> some View {
        return HStack {
            TextField("Last name", text:  $authViewModel.user.shipping.last_name)
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
    
    fileprivate func ShippingCompanyTextFiels() -> some View {
        return HStack {
            TextField("Company (optional)", text:  $authViewModel.user.shipping.company)
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
    
    fileprivate func ShippingCountryTextFiels() -> some View {
        return HStack {
            TextField("Country", text:  $authViewModel.user.shipping.country)
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
    
    fileprivate func ShippingStreetAddressTextFiels() -> some View {
        return HStack {
            TextField("Street address", text:  $authViewModel.user.shipping.address_1)
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
    
    fileprivate func ShippingApartmentTextFiels() -> some View {
        return HStack {
            TextField("Apartment, unit, etc. (optional)", text:  $authViewModel.user.shipping.address_2)
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
    
    fileprivate func ShippingStateTextFiels() -> some View {
        return HStack {
            TextField("State", text:  $authViewModel.user.shipping.state)
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
    
    fileprivate func ShippingCityTextFiels() -> some View {
        return HStack {
            TextField("City / Town", text:  $authViewModel.user.shipping.city)
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
    
    fileprivate func ShippingPostcodeNameTextFiels() -> some View {
        return HStack {
            TextField("Postcode", text:  $authViewModel.user.shipping.postcode)
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
    }
    
    var body: some View {
        
        NavigationView {
            ZStack {
                Color.init(hex: "f9f9f9")
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    NavigationBarView()
                    ScrollView(.vertical, showsIndicators: false, content: {
                        VStack(alignment: .leading) {
                            Text("Billing Address")
                                .font(.custom(Constants.AppFont.boldFont, size: 22))
                                .foregroundColor(Constants.AppColor.secondaryBlack)
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 10) {
                                BillingNameTextFiels().frame(minWidth: 0,
                                                      maxWidth: .infinity)
                                BillingLastNameTextFiels().frame(minWidth: 0,
                                                      maxWidth: .infinity)
                            }
                            BillingCompanyTextFiels()
                            BillingCountryTextFiels()
                            BillingStreetAddressTextFiels()
                            BillingApartmentTextFiels()
                            BillingStateTextFiels()
                            HStack(spacing: 10) {
                                BillingCityTextFiels().frame(minWidth: 0,
                                                      maxWidth: .infinity)
                                BillingPostcodeNameTextFiels().frame(minWidth: 0,
                                                      maxWidth: .infinity)
                            }
                            BillingPhoneTextFiels()
                            BillingEmailTextFiels()
          
                        }
                        
//                        VStack(alignment: .leading) {
//
//                            Text("Shipping Address")
//                                .font(.custom(Constants.AppFont.boldFont, size: 22))
//                                .foregroundColor(Constants.AppColor.secondaryBlack)
//                                .padding(.horizontal, 20)
//
//                            HStack(spacing: 10) {
//                                ShippingNameTextFiels().frame(minWidth: 0,
//                                                      maxWidth: .infinity)
//                                ShippingLastNameTextFiels().frame(minWidth: 0,
//                                                      maxWidth: .infinity)
//                            }
//                            ShippingCompanyTextFiels()
//                            ShippingCountryTextFiels()
//                            ShippingStreetAddressTextFiels()
//                            ShippingApartmentTextFiels()
//                            ShippingStateTextFiels()
//                            HStack(spacing: 10) {
//                                ShippingCityTextFiels().frame(minWidth: 0,
//                                                      maxWidth: .infinity)
//                                ShippingPostcodeNameTextFiels().frame(minWidth: 0,
//                                                      maxWidth: .infinity)
//                            }
//                        }
//                        .padding(.vertical, 20)
                    })
                    .padding(.top)
                    
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

struct EditAddressView_Previews: PreviewProvider {
    static var previews: some View {
        EditAddressView()
            .environmentObject(AuthViewModel())
    }
}

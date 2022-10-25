//
//  SettingView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("isOnboarding") var isOnboarding: Bool = false

    fileprivate func NavigationBarView() -> some View {
        return HStack {
            
        }
        .padding(.horizontal, 15)
        .frame(width: UIScreen.main.bounds.width, height: 35)
        .overlay(
            Text("Setting")
                .font(.custom(Constants.AppFont.boldFont, size: 20))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.horizontal, 10)
            , alignment: .center)
    }
    
    var body: some View {
        VStack {
            NavigationBarView()
            ZStack {
                Constants.AppColor.lightGrayColor
                    .edgesIgnoringSafeArea(.all)
                ScrollView(.vertical, showsIndicators: false){
                    VStack(spacing: 20){
                        
                        GroupBox(label:SettingsLabelView(labelText: APP_NAME, labelImage: "info.circle")){
                            
                            Divider().padding(.vertical, 4)
                            
                            HStack(alignment:.top, spacing: 10) {
                                Image("logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(9)
                                Text(APP_DESCRIPTION)
                                    .font(.footnote)
                                Spacer()
                            }
                        }
                        
                        GroupBox(label : SettingsLabelView(labelText: "Customization", labelImage: "paintbrush")){
                            
                            Divider().padding(.vertical, 4)
                            Text("If you wish, you can restart the application by toggle the switch in this box. That way it starts the onboarding process and you will see the welcome screen again.")
                                .padding(.vertical, 8)
                                .frame(minHeight: 60)
                                .layoutPriority(1)
                                .font(.footnote)
                                .multilineTextAlignment(.leading)
                            
                            Toggle(isOn: $isOnboarding){
                                if isOnboarding {
                                    Text("Restart".uppercased())
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                } else {
                                    Text("Restart".uppercased())
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.tertiarySystemBackground).clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)))
                        }
                        
                        GroupBox(label: SettingsLabelView(labelText: "Application", labelImage: "apps.iphone")){
                            SettingsRowView(name: "Developer",content: DEVELOPER)
                            SettingsRowView(name: "Compability",content: COMPABILITY)
                            SettingsRowView(name: "Website", linkLabel: WEBSITE_LABEL, linkDestination: WEBSITE_LINK)
                            SettingsRowView(name: "Version",content: VERSION)
                        }
                    }
                    .navigationBarTitle("Setting", displayMode: .inline)
                    .padding()
                }//: ScrollView
            }
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}

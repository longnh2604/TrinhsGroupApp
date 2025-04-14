//
//  CustomNavigationBarView.swift
//  TrinhsGroup
//
//  Created by longnh on 2023/03/27.
//

import SwiftUI

struct CustomNavigationBarView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    var title: String
    
    var body: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .padding(.leading, 15)
            }
            
            Spacer()
        }
        .frame(width: getRect().width, height: 35)
        .background(Constants.AppColor.lightGrayColor)
        .overlay(
            Text(title)
                .font(.custom(Constants.AppFont.semiBoldFont, size: 20))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .padding(.horizontal, 10),
            alignment: .center
        )
    }
}


//
//  CustomAlertView.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import SwiftUI

struct CustomAlertView: View {
    
    var message: String
    
    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: .bottom) {
                Color.clear.ignoresSafeArea()
                
                VStack {
                    Text(message)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(width: reader.size.width - 44.0)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.8))
                .cornerRadius(10)
                .padding(.bottom, 34)
                
            }
        }
    }
}

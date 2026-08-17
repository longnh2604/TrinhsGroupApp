//
//  SplashView.swift
//  TrinhsGroup
//
//  Created by longnh on 2025/04/11.
//

import SwiftUI

struct SplashView: View {
    // Customise your SplashScreen here
    var body: some View {
        Image(AppAssets.splash)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}



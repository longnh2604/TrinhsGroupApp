//
//  OnboardCardView.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import SwiftUI

struct OnboardCardView: View {
    var onboard: Onboard
    @State private var isAnimating: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing:20) {
                Image(onboard.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100, alignment: .center)
                    .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.15), radius: 8, x: 6, y: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.6)
                
                Text(onboard.title)
                    .foregroundColor(Color.white)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .shadow(color: Color( red: 0, green: 0, blue: 0, opacity: 0.15), radius: 2, x: 2, y: 2)
                
                Text(onboard.headline).foregroundColor(Color.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal,16)
                    .frame(maxWidth:480)
                
                StartButtonView()
                
            } //: VStack
        } //: ZStack
        .onAppear{
            withAnimation(.easeOut(duration:0.5)){
                isAnimating = true
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
        .background(LinearGradient(gradient: Gradient(colors: onboard.gradientColors), startPoint: .top, endPoint: .bottom))
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
}

struct OnboardCardView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardCardView(onboard: ONBOARD_DATA[0]).previewLayout(.fixed(width: 320, height: 640))
    }
}

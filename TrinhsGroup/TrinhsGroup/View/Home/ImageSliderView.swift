//
//  ImageSliderView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI
import Kingfisher

struct ImageSliderView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    @State var index = 0
    
    var body: some View {
        PagingView(index: $index.animation(), maxIndex: mainViewModel.sliders.count - 1) {
            ForEach(mainViewModel.sliders) { slider in
                KFImage(URL(string:slider.image))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: getRect().width, height: getRect().width / 2)
            }
        }
        .aspectRatio(contentMode: .fill)
        .frame(width: getRect().width, height: getRect().width / 2)
    }
}

struct ImageSliderView_Previews: PreviewProvider {
    static var previews: some View {
        ImageSliderView()
    }
}

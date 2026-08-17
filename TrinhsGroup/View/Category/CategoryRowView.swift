//
//  CategoryRowView.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import SwiftUI
import Kingfisher

struct CategoryRowView: View {
    
    var category: Category
    
    var body: some View {
        HStack {
            Text(self.category.name)
                .font(.custom(Constants.AppFont.boldFont, size: 18))
                .foregroundColor(Constants.AppColor.secondaryBlack)
                .padding(.leading, 20)
            Spacer()
            OptimizedKFImage(
                url: category.image.flatMap { image in URL(string: image.src) },
                width: getRect().width / 2 - 15,
                height: getRect().width / 2 - 30,
                contentMode: .fill,
                cornerRadius: 10
            )
        }
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct CategoryRowView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryRowView(category: Category.default)
            .previewLayout(.sizeThatFits)
    }
}

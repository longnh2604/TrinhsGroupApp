//
//  NotificationItemView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI

struct NotificationItemView: View {
    
    var notification: AppNotification
    
    var body: some View {
        
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(notification.title)
                    Spacer()
                }
                Text(notification.content)
            }
            .padding()
            .background(Color.white.cornerRadius(15))
    }
}

struct NotificationItemView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationItemView(notification: AppNotification(title: "Title", content: "Content"))
            .previewLayout(.sizeThatFits)
    }
}

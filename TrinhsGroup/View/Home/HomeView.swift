//
//  HomeView.swift
//  TrinhsGroup
//
//  Created by long on 05/07/2022.
//

import SwiftUI
import Kingfisher

struct HomeView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State var showNotifications = false
    @State private var selectedEvent: EventBanner?

    var body: some View {
        NavigationView {
            ZStack {
                Constants.AppColor.lightGrayColor
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    HomeNavigationBarView(title: "Home", showNotificationIcon: true, showNotifications: $showNotifications)
                        .environmentObject(mainViewModel)
                    
                    ScrollView {
                        VStack {
                            // Events
                            VStack(alignment: .leading) {
                                Text("Events")
                                    .font(.custom(Constants.AppFont.boldFont, size: 17))
                                    .foregroundColor(Constants.AppColor.primaryBlack)
                                    .padding(.horizontal)

                                TabView {
                                    ForEach(EventBanner.all) { event in
                                        EventBannerCard(event: event)
                                            .padding(.horizontal)
                                            .padding(.bottom, 24)
                                            .onTapGesture {
                                                selectedEvent = event
                                            }
                                    }
                                }
                                .frame(height: 220)
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                            }
                            
                            // Categories
                            VStack(alignment: .leading) {
                                Text("Categories")
                                    .font(.custom(Constants.AppFont.boldFont, size: 17))
                                    .foregroundColor(Constants.AppColor.primaryBlack)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 20) {
                                        ForEach(mainViewModel.categories, id: \.id) { category in
                                            VStack {
                                                OptimizedKFImage(
                                                    url: category.image.flatMap { image in URL(string: image.src) },
                                                    width: 60,
                                                    height: 60,
                                                    contentMode: .fill,
                                                    cornerRadius: 30,
                                                    placeholder: Image(AppAssets.noimage)
                                                )
                                                
                                                Text(category.name)
                                                    .font(.caption)
                                            }
                                            .onTapGesture {
                                                // Set category to navigate and trigger tab switch
                                                mainViewModel.categoryToNavigate = category
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Popular
                            if !mainViewModel.popularProducts.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Popular")
                                        .font(.custom(Constants.AppFont.boldFont, size: 17))
                                        .foregroundColor(Constants.AppColor.primaryBlack)
                                        .padding(.horizontal)
                                    
                                    LazyVStack(spacing: 16) {
                                        ForEach(mainViewModel.popularProducts, id: \.id) { product in
                                            ProductCard(product: product) { selectedProduct in
                                                mainViewModel.add(item: selectedProduct)
                                            }
                                            .onTapGesture {
                                                mainViewModel.selectedProduct = product
                                                mainViewModel.presentedType = .productDetail
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            Spacer()
                        }
                    }.edgesIgnoringSafeArea(.top)
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .onAppear(perform: {
                NotificationStore.shared.syncDeliveredNotifications()
            })
        }
        .fullScreenCover(isPresented: $showNotifications, content: {
            NewNotificationsView()
        })
        .sheet(item: $selectedEvent, content: { event in
            EventPosterView(event: event)
        })
    }
}

// MARK: - Event Banner

struct EventBanner: Identifiable {
    let id: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let detail: String
    let imageAsset: String
    let posterAsset: String

    static let all: [EventBanner] = [
        EventBanner(id: "family_combo",
                    eyebrow: "FAMILY SHARING",
                    title: "Family Combo",
                    subtitle: "Trio $49.90 · Share Box $69.90",
                    detail: "Free kids colouring activity",
                    imageAsset: "event_family_combo",
                    posterAsset: "poster_family_combo"),
        EventBanner(id: "kids_menu",
                    eyebrow: "FOR KIDS UNDER 12",
                    title: "Kids Menu",
                    subtitle: "8 kids meals from $5.00",
                    detail: "Free colouring with every meal",
                    imageAsset: "event_kids_menu",
                    posterAsset: "poster_kids_menu"),
        EventBanner(id: "lunch_special",
                    eyebrow: "11AM – 3:30PM · TAKEAWAY",
                    title: "Lunch Special",
                    subtitle: "Bánh mì + prawn dumplings $15",
                    detail: "Soft drink $2 · Viet coffee $4.50",
                    imageAsset: "event_lunch_special",
                    posterAsset: "poster_lunch_special")
    ]
}

struct EventBannerCard: View {
    let event: EventBanner

    private let posterRed = Color.init(hex: "B3231B")
    private let posterCream = Color.init(hex: "F8EFE1")
    private let posterInk = Color.init(hex: "3B2A1F")

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(event.eyebrow)
                    .font(.custom(Constants.AppFont.boldFont, size: 9))
                    .kerning(1.1)
                    .foregroundColor(posterRed)

                Text(event.title)
                    .font(.custom(Constants.AppFont.extraBoldFont, size: 21))
                    .foregroundColor(posterRed)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(event.subtitle)
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
                    .foregroundColor(posterInk)
                    .lineLimit(2)

                Text(event.detail)
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 10))
                    .foregroundColor(posterInk)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.init(hex: "F5C95C").opacity(0.45))
                    .cornerRadius(6)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)

                HStack(spacing: 3) {
                    Text("View poster")
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 11))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(posterRed)
            }
            .padding(.init(top: 14, leading: 16, bottom: 14, trailing: 10))
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(event.imageAsset)
                .resizable()
                .scaledToFill()
                .frame(width: 140)
                .clipped()
        }
        .frame(height: 196)
        .background(posterCream)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(posterRed.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Constants.AppColor.shadowColor.opacity(0.5), radius: 8, x: 0, y: 2)
    }
}

struct EventPosterView: View {
    let event: EventBanner
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                Image(event.posterAsset)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 24)
            }

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .padding(16)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

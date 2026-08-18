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
    @State private var selectedEvent: AppEvent?

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
                            if !firestoreManager.events.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Events")
                                        .font(.custom(Constants.AppFont.boldFont, size: 17))
                                        .foregroundColor(Constants.AppColor.primaryBlack)
                                        .padding(.horizontal)

                                    TabView {
                                        ForEach(firestoreManager.events) { event in
                                            EventBannerCard(event: event)
                                                .padding(.horizontal)
                                                .padding(.bottom, 24)
                                                .onTapGesture {
                                                    // Nothing to open until a poster is uploaded.
                                                    if !event.posterURL.isEmpty {
                                                        selectedEvent = event
                                                    }
                                                }
                                        }
                                    }
                                    .frame(height: 220)
                                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                                    // Plain dots disappear against pale artwork, and nothing
                                    // else tells you there are three of these.
                                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                                }
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

struct EventBannerCard: View {
    let event: AppEvent

    private let posterRed = Color.init(hex: "B3231B")
    private let posterCream = Color.init(hex: "F8EFE1")
    private let posterInk = Color.init(hex: "3B2A1F")

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                // Each line is skipped when its field is blank, so a half-filled document
                // reads as a smaller card rather than one with holes in it.
                if !event.eyebrow.isEmpty {
                    Text(event.eyebrow)
                        .font(.custom(Constants.AppFont.boldFont, size: 9))
                        .kerning(1.1)
                        .foregroundColor(posterRed)
                }

                Text(event.title)
                    .font(.custom(Constants.AppFont.extraBoldFont, size: 21))
                    .foregroundColor(posterRed)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if !event.subtitle.isEmpty {
                    Text(event.subtitle)
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 13))
                        .foregroundColor(posterInk)
                        .lineLimit(2)
                }

                if !event.detail.isEmpty {
                    Text(event.detail)
                        .font(.custom(Constants.AppFont.semiBoldFont, size: 10))
                        .foregroundColor(posterInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.init(hex: "F5C95C").opacity(0.45))
                        .cornerRadius(6)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 0)

                // Only promise a poster when one has been uploaded.
                if !event.posterURL.isEmpty {
                    HStack(spacing: 3) {
                        Text("View poster")
                            .font(.custom(Constants.AppFont.semiBoldFont, size: 11))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(posterRed)
                }
            }
            .padding(.init(top: 14, leading: 16, bottom: 14, trailing: 10))
            .frame(maxWidth: .infinity, alignment: .leading)

            OptimizedKFImage(
                url: URL(string: event.imgURL),
                width: 140,
                height: 196,
                contentMode: .fill
            )
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
    let event: AppEvent
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                KFImage(URL(string: event.posterURL))
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

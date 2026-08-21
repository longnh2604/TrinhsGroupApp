package com.trinhskitchen.app.di

import android.content.Context
import com.trinhskitchen.app.firebase.EventsRepository
import com.trinhskitchen.app.firebase.PushTokens
import com.trinhskitchen.app.payments.StripePresenter
import com.trinhskitchen.app.BuildConfig
import com.trinhsgroup.shared.auth.AuthTokenStore
import com.trinhsgroup.shared.network.WooCommerceApi
import com.trinhsgroup.shared.payments.StripeRepository
import com.trinhsgroup.shared.service.AuthService
import com.trinhsgroup.shared.service.HistoryService
import com.trinhsgroup.shared.service.MainService
import com.trinhsgroup.shared.service.PointsService
import com.trinhsgroup.shared.storage.FavoritesRepository
import com.trinhsgroup.shared.storage.KeyValueStore
import com.trinhsgroup.shared.storage.NotificationStore
import com.trinhsgroup.shared.viewmodel.AuthViewModel
import com.trinhsgroup.shared.viewmodel.HistoryViewModel
import com.trinhsgroup.shared.viewmodel.MainViewModel
import com.trinhsgroup.shared.viewmodel.PointsViewModel
import org.koin.android.ext.koin.androidContext
import org.koin.core.module.dsl.singleOf
import org.koin.dsl.module

/**
 * Koin dependency injection module for the Android app.
 * Provides shared KMP components to the UI layer.
 */
val appModule = module {
    // Storage
    single { KeyValueStore(androidContext()) }
    single { FavoritesRepository(get()) }
    single { AuthTokenStore(get()) }
    single { NotificationStore(get()) }
    
    // Network
    // The consumer key is read-only and only ever reaches the public catalog; everything
    // customer-scoped is authorised by the signed-in user's JWT.
    single {
        WooCommerceApi(
            consumerKey = BuildConfig.WOO_CONSUMER_KEY,
            consumerSecret = BuildConfig.WOO_CONSUMER_SECRET,
            tokenStore = get()
        )
    }
    
    // Services
    single { AuthService(get(), get()) }
    single { MainService(get()) }
    single { HistoryService(get()) }
    single { PointsService(get()) }
    
    // Payment (Android-specific)
    single { StripeRepository(get()) }
    single { StripePresenter() }
    single { EventsRepository() }
    single { PushTokens(get(), get()) }
    
    // ViewModels (shared KMP ViewModels)
    factory { AuthViewModel(get(), get(), get()) }
    factory { MainViewModel(get(), get()) }
    factory { HistoryViewModel(get()) }
    factory { PointsViewModel(get()) }
}

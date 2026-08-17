package com.trinhskitchen.app

import android.app.Application
import coil3.ImageLoader
import coil3.PlatformContext
import coil3.SingletonImageLoader
import coil3.disk.DiskCache
import coil3.disk.directory
import coil3.memory.MemoryCache
import coil3.request.CachePolicy
import coil3.request.crossfade
import com.trinhskitchen.app.di.appModule
import org.koin.android.ext.koin.androidContext
import org.koin.android.ext.koin.androidLogger
import org.koin.core.context.startKoin
import org.koin.core.logger.Level

class TrinhsApp : Application(), SingletonImageLoader.Factory {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize Koin for dependency injection
        startKoin {
            androidLogger(Level.ERROR)
            androidContext(this@TrinhsApp)
            modules(appModule)
        }
    }
    
    /**
     * Configures Coil image loader to mirror Kingfisher's caching behavior:
     * - 7-day disk cache
     * - 5-minute memory cache (approximated with size limits)
     */
    override fun newImageLoader(context: PlatformContext): ImageLoader {
        return ImageLoader.Builder(context)
            .crossfade(true)
            .memoryCachePolicy(CachePolicy.ENABLED)
            .memoryCache {
                MemoryCache.Builder()
                    .maxSizePercent(context, 0.25) // 25% of available memory
                    .build()
            }
            .diskCachePolicy(CachePolicy.ENABLED)
            .diskCache {
                DiskCache.Builder()
                    .directory(cacheDir.resolve("image_cache"))
                    .maxSizeBytes(100 * 1024 * 1024) // 100MB disk cache
                    .build()
            }
            .build()
    }
}

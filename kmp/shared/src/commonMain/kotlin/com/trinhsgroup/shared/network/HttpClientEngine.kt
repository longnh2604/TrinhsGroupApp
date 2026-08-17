package com.trinhsgroup.shared.network

import io.ktor.client.engine.HttpClientEngine

/**
 * Platform-specific HTTP client engine factory.
 * - Android: OkHttp
 * - iOS: Darwin (URLSession)
 */
expect fun createHttpClientEngine(): HttpClientEngine

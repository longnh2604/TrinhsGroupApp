package com.trinhsgroup.shared.storage

import com.trinhsgroup.shared.model.Product
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Repository for managing favorite products.
 * Mirrors Swift's UserDefaultsManager favorites functionality.
 *
 * Note: Swift stores favorites as [Data] (array of JSON-encoded products).
 * We store as a single JSON string for simplicity.
 */
class FavoritesRepository(private val keyValueStore: KeyValueStore) {

    companion object {
        private const val FAVORITES_KEY = "favorites"
    }

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    /**
     * Loads all favorite products.
     * Mirrors Swift's loadFavorites().
     */
    fun loadFavorites(): List<Product> {
        val jsonString = keyValueStore.getString(FAVORITES_KEY)
        if (jsonString.isEmpty()) return emptyList()
        
        return try {
            json.decodeFromString<List<Product>>(jsonString)
        } catch (e: Exception) {
            emptyList()
        }
    }

    /**
     * Saves all favorite products.
     * Mirrors Swift's saveFavorites(_:).
     */
    fun saveFavorites(products: List<Product>) {
        val jsonString = json.encodeToString(products)
        keyValueStore.putString(FAVORITES_KEY, jsonString)
    }

    /**
     * Adds a product to favorites.
     * Mirrors Swift's saveFavorite(_:).
     */
    fun saveFavorite(product: Product) {
        val favorites = loadFavorites().toMutableList()
        favorites.add(product)
        saveFavorites(favorites)
    }

    /**
     * Removes a product from favorites by matching product ID.
     * Mirrors Swift's removeFavorite(_:).
     */
    fun removeFavorite(product: Product) {
        val favorites = loadFavorites().toMutableList()
        favorites.removeAll { it.id == product.id }
        saveFavorites(favorites)
    }

    /**
     * Toggles a product's favorite status.
     * Mirrors Swift's toggleFavorite(_:).
     */
    fun toggleFavorite(product: Product) {
        if (isFavorite(product.id)) {
            removeFavorite(product)
        } else {
            saveFavorite(product)
        }
    }

    /**
     * Checks if a product is in favorites.
     * Mirrors Swift's isFavorite(_:).
     */
    fun isFavorite(productId: Int): Boolean {
        return loadFavorites().any { it.id == productId }
    }

    /**
     * Clears all favorites.
     */
    fun clearFavorites() {
        saveFavorites(emptyList())
    }
}

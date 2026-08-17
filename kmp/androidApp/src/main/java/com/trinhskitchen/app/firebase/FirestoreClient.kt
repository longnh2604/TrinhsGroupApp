package com.trinhskitchen.app.firebase

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.messaging.FirebaseMessaging
import com.trinhsgroup.shared.model.AppEvent
import com.trinhsgroup.shared.model.ProductAddOns
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.tasks.await

/**
 * Firebase Firestore client for Android.
 * Mirrors iOS FirestoreManager behavior.
 *
 * Handles:
 * - Fetching events for home screen banners/sliders
 * - Fetching product add-ons for item detail screen
 * - FCM token management
 */
class FirestoreClient {
    
    private val db = FirebaseFirestore.getInstance()
    
    private val _events = MutableStateFlow<List<AppEvent>>(emptyList())
    val events: StateFlow<List<AppEvent>> = _events.asStateFlow()
    
    private val _productAddOns = MutableStateFlow<List<ProductAddOns>>(emptyList())
    val productAddOns: StateFlow<List<ProductAddOns>> = _productAddOns.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()
    
    /**
     * Fetches events from Firestore "events" collection.
     * Mirrors iOS FirestoreManager.fetchEvents().
     */
    suspend fun fetchEvents() {
        _isLoading.value = true
        _error.value = null
        
        try {
            val snapshot = db.collection("events").get().await()
            
            val eventList = snapshot.documents.mapNotNull { doc ->
                val data = doc.data ?: return@mapNotNull null
                AppEvent(
                    id = (data["id"] as? Number)?.toInt() ?: 0,
                    content = data["content"] as? String ?: "",
                    type = data["type"] as? String ?: "",
                    title = data["title"] as? String ?: "",
                    link = data["link"] as? String ?: "",
                    imgURL = data["imgURL"] as? String ?: ""
                )
            }
            
            _events.value = eventList
        } catch (e: Exception) {
            _error.value = e.message
        } finally {
            _isLoading.value = false
        }
    }
    
    /**
     * Fetches product add-ons from Firestore "productAddons" collection.
     * Filters by categoryId array containing the given ID.
     * Mirrors iOS FirestoreManager.fetchProductAddOns().
     *
     * @param categoryId The category ID to filter by
     */
    suspend fun fetchProductAddOns(categoryId: Int) {
        _isLoading.value = true
        _error.value = null
        
        try {
            val snapshot = db.collection("productAddons")
                .whereArrayContains("categoryId", categoryId)
                .get()
                .await()
            
            val addonsList = snapshot.documents.mapNotNull { doc ->
                val data = doc.data ?: return@mapNotNull null
                ProductAddOns.fromMap(data)
            }.sortedBy { it.content }
            
            _productAddOns.value = addonsList
        } catch (e: Exception) {
            _error.value = e.message
        } finally {
            _isLoading.value = false
        }
    }
    
    /**
     * Gets the FCM registration token.
     * Used for push notification registration.
     */
    suspend fun getFcmToken(): String? {
        return try {
            FirebaseMessaging.getInstance().token.await()
        } catch (e: Exception) {
            _error.value = e.message
            null
        }
    }
    
    /**
     * Clears error state.
     */
    fun clearError() {
        _error.value = null
    }
}

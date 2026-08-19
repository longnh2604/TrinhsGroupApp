package com.trinhskitchen.app.firebase

import com.google.firebase.firestore.FirebaseFirestore
import com.trinhsgroup.shared.model.AppEvent
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * The Home events carousel, read from Firestore.
 * Mirrors iOS FirestoreManager.fetchEvents(): a snapshot listener, so an edit in the
 * console shows up without a relaunch.
 */
class EventsRepository {

    private val _events = MutableStateFlow<List<AppEvent>>(emptyList())
    val events: StateFlow<List<AppEvent>> = _events.asStateFlow()

    private var listening = false

    fun start() {
        if (listening) return
        listening = true

        FirebaseFirestore.getInstance().collection("events")
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    println("📅 EventsRepository: ${error.message}")
                    return@addSnapshotListener
                }
                _events.value = (snapshot?.documents ?: emptyList())
                    .map { AppEvent.fromMap(it.data.orEmpty()) }
                    .filter { it.active }
                    .sortedBy { it.id }
            }
    }
}

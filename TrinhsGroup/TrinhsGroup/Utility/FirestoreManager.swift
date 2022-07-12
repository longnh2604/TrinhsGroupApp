//
//  FirestoreManager.swift
//  TrinhsGroup
//
//  Created by long on 08/07/2022.
//

import Firebase
import FirebaseFirestore

class FirestoreManager: ObservableObject {
    
    @Published var events = [AppEvent]()
    
    init() {
        fetchEvents()
    }
    
    func fetchEvents() {
        let db = Firestore.firestore()

        let docRef = db.collection("events")
        docRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.events.removeAll()
                for document in querySnapshot!.documents {
                    self.events.append(AppEvent.init(document.data()))
                }
            }
        }
    }
}

//
//  FirestoreManager.swift
//  TrinhsGroup
//
//  Created by long on 08/07/2022.
//

import Firebase
import FirebaseFirestore

class FirestoreManager: ObservableObject {
    
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
                for document in querySnapshot!.documents {
                    print("\(document.documentID): \(document.data())")
                }
            }
        }
    }
}

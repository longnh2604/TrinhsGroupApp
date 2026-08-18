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
    @Published var productAddOns = [ProductAddOns]()
    
    init() {
        fetchEvents()
    }
    
    /// Live, not a one-shot read: editing a banner in the Firestore console is meant to be
    /// the whole job, and `getDocuments` would have held the old copy until the next launch.
    func fetchEvents() {
        Firestore.firestore().collection("events")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error getting documents: \(error)")
                    return
                }
                let documents = querySnapshot?.documents ?? []
                self.events = documents
                    .map { AppEvent($0.data()) }
                    .filter { $0.active }
                    .sorted { $0.id < $1.id }
            }
    }
    
    func fetchProductAddOns(categoryId: Int) {
        let db = Firestore.firestore()

        let docRef = db.collection("productAddons").whereField("categoryId", arrayContains: categoryId)
        docRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.productAddOns.removeAll()
                for document in querySnapshot!.documents {
                    self.productAddOns.append(ProductAddOns.init(document.data()))
                }
                self.productAddOns = self.productAddOns.sorted(by: { $0.content < $1.content })
            }
        }
    }
}

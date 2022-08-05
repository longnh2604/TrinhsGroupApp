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
    
    func fetchProductAddOns(categoryId: Int) {
        let db = Firestore.firestore()

        let docRef = db.collection("productAddons").whereField("categoryId", isEqualTo: categoryId)
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

//
//  UserTableViewCell.swift
//  group-project
//
//  Created by fizza imran on 2024-10-29.
//

import SwiftUI
import UIKit
import FirebaseStorage
import FirebaseFirestore

class UserTableViewCell: UITableViewCell {
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!

    // Configure cell with user data
    func configure(with user: [String: Any]) {
        nameLabel.text = user["username"] as? String ?? "Unknown"
        profileImageView.image = nil // Reset the image to avoid showing an old one
        
        // Fetch user ID
        guard let userId = user["userID"] as? String else { return }
        
        // Reference to Firestore document
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        userRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                print("User document does not exist")
                return
            }
            
            // Fetch the image URL from the document
            if let imageUrlString = data["imgUrl"] as? String, let imageUrl = URL(string: imageUrlString) {
                self.loadImage(from: imageUrl)
            }
        }
    }

    
    // Load image from URL
    private func loadImage(from url: URL) {
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: url)
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.profileImageView.image = image
                    }
                }
            } catch {
                print("Error loading image from URL: \(error)")
            }
        }
    }

}

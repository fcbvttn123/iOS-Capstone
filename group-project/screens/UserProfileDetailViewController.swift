//
//  UserProfileDetailViewController.swift
//  group-project
//
//  Created by fizza imran on 2024-10-27.
//

import UIKit
import FirebaseFirestore

class UserProfileDetailViewController: UIViewController {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!

    var userID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let userID = userID {
            fetchUserDetails(for: userID)
        }
    }

    // Fetch user details from Firestore
    func fetchUserDetails(for userID: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user details: \(error)")
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data() else {
                print("User document does not exist.")
                return
            }
            
            // Extract user details
            if let username = data["username"] as? String {
                self.nameLabel.text = username
            }
            if let email = data["email"] as? String {
                self.emailLabel.text = email
            }
            if let imgUrlString = data["imgUrl"] as? String,
               let imgUrl = URL(string: imgUrlString) {
                // Fetch and display user image
                URLSession.shared.dataTask(with: imgUrl) { data, _, error in
                    guard let data = data, error == nil else {
                        print("Error fetching user image: \(error?.localizedDescription ?? "No error info")")
                        return
                    }
                    DispatchQueue.main.async {
                        self.profileImageView.image = UIImage(data: data) ?? UIImage(systemName: "person.crop.circle")
                    }
                }.resume()
            }
        }
    }
}

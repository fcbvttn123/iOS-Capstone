//
//  UITableViewCell.swift
//  group-project
//
//  Created by fizza imran on 2024-10-29.
//

import SwiftUI
import UIKit

class UserTableViewCell: UITableViewCell {
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!

    // Configure cell with user data
    func configure(with user: [String: Any]) {
        nameLabel.text = user["name"] as? String ?? "Unknown"
        
        // Load the profile image if available, otherwise set a placeholder
        if let imageUrlString = user["profileImageURL"] as? String, let imageUrl = URL(string: imageUrlString) {
            // Load image asynchronously
            URLSession.shared.dataTask(with: imageUrl) { data, _, error in
                guard let data = data, error == nil else {
                    print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                DispatchQueue.main.async {
                    self.profileImageView.image = UIImage(data: data)
                }
            }.resume()
        } else {
            profileImageView.image = UIImage(named: "placeholder") // Placeholder image
        }
    }
}

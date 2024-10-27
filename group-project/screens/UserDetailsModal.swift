//
//  UserDetailsModal.swift
//  group-project
//
//  Created by fizza imran on 2024-10-27.
//
import UIKit
import FirebaseFirestore

class UserDetailsModal: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!

        var userID: String? // Add this line to define userID
        var attendingUsers: [String] = []  // List of user IDs attending the event
        var userProfiles: [(name: String, image: UIImage?)] = []  // User profile details

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        fetchUserProfiles()
    }

    // Fetch profiles of attending users from Firestore
    func fetchUserProfiles() {
        let db = Firestore.firestore()
        let usersRef = db.collection("users")

        for userID in attendingUsers {
            usersRef.document(userID).getDocument { document, error in
                if let document = document, document.exists,
                   let data = document.data(),
                   let userName = data["username"] as? String,
                   let imgUrlString = data["imgUrl"] as? String,
                   let imgUrl = URL(string: imgUrlString) {

                    // Fetch user image
                    URLSession.shared.dataTask(with: imgUrl) { data, _, _ in
                        let image = data.flatMap { UIImage(data: $0) }
                        self.userProfiles.append((name: userName, image: image))
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }.resume()
                }
            }
        }
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userProfiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserProfileCell", for: indexPath)
        let profile = userProfiles[indexPath.row]
        cell.textLabel?.text = profile.name
        cell.imageView?.image = profile.image ?? UIImage(systemName: "person.crop.circle") // Placeholder image
        return cell
    }

    // Handle user selection to show more details
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUserID = attendingUsers[indexPath.row]
        performSegue(withIdentifier: "toUserProfileDetail", sender: selectedUserID)
    }
    
    // Prepare for segue to user profile detail screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toUserProfileDetail",
           let destinationVC = segue.destination as? UserProfileDetailViewController,
           let userID = sender as? String {
            destinationVC.userID = userID  // Pass the selected user ID to the detail view
        }
    }
}

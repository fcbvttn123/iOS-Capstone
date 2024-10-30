import StreamChat
import StreamChatUI
import FirebaseCore
import GoogleSignIn
import FirebaseAuth
import FirebaseFirestore
import UIKit

class DemoChannelList: ChatChannelListVC, UISearchBarDelegate {
    
    let searchBar = UISearchBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        setupBackButton()
    }
    
    // Search Bar
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search for a username"
        navigationItem.titleView = searchBar
        searchBar.sizeToFit()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Remove non-lowercase letters and spaces from the search text
        let filteredText = searchText.lowercased().replacingOccurrences(of: " ", with: "")
        if filteredText != searchText {
            searchBar.text = filteredText
        }
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let usernameToSearch = searchBar.text, !usernameToSearch.isEmpty else { return }
        Task {
            do {
                let usernames = try await fetchUsernames()
                // Check if the username exists
                if usernames.contains(usernameToSearch) {
                    // Create a direct message channel
                    createDirectMessageChannel(with: usernameToSearch)
                } else {
                    print("Username '\(usernameToSearch)' does not exist.")
                }
            } catch {
                print("Error fetching usernames: \(error.localizedDescription)")
            }
        }
        searchBar.resignFirstResponder()
    }
    private func createDirectMessageChannel(with username: String) {
        // Safely unwrap the current user ID
        guard let currentUserId = AppDelegate.shared.email?.components(separatedBy: "@").first else {
            print("Error: Current user ID is nil.")
            return
        }
        
        // Create a set of user IDs, ensuring username is not nil or empty
        let userIds: Set<UserId> = [currentUserId, username]

        do {
            let channelController = try ChatManager.shared.chatClient.channelController(
                createDirectMessageChannelWith: userIds,
                extraData: [:]
            )
            
            channelController.synchronize { error in
                if let error = error {
                    print("Error synchronizing channel: \(error.localizedDescription)")
                } else {
                    print("Channel synchronized successfully!")
                }
            }
        } catch {
            print("Error creating channel: \(error.localizedDescription)")
        }
    }
    func fetchUsernames() async throws -> [String] {
        let collection = Firestore.firestore().collection("chat-test")
        let querySnapshot = try await collection.getDocuments()
        var usernames = [String]()

        for document in querySnapshot.documents {
            if let username = document.data()["username"] as? String { // Accessing the username field
                usernames.append(username)
            }
        }
        return usernames
    }
    
    // Back Button
    private func setupBackButton() {
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem = backButton
    }
    @objc private func backButtonPressed() {
        navigationController?.popViewController(animated: true)
    }
    
}

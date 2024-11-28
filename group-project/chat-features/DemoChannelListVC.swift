import UIKit
import StreamChat
import StreamChatUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// A custom channel list screen for managing chat channels.
class DemoChannelList: ChatChannelListVC {
    
    /// Instance of `SearchBarManager` to handle search bar functionality.
    let searchBarManager = SearchBarManager()
    
    /// Called after the controller’s view is loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()   // Initialize and set up the search bar.
        setupBackButton()  // Initialize and set up the back button.
    }
    
    // MARK: - Search Bar Setup
    
    /// Configures the search bar for the channel list screen.
    private func setupSearchBar() {
        // Set the search bar as the title view in the navigation bar.
        navigationItem.titleView = searchBarManager.searchBar
        
        // Handle the search action through a callback.
        searchBarManager.onSearch = { [weak self] username in
            self?.performUserSearch(username)
        }
    }
    
    // MARK: - Back Button Setup
    
    /// Configures the back button for the channel list screen.
    private func setupBackButton() {
        navigationItem.leftBarButtonItem = BackButtonManager.createBackButton(
            target: self,
            action: #selector(backButtonPressed)
        )
    }
    
    /// Handles the back button action by popping the current view controller.
    @objc private func backButtonPressed() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Channel Creation

    /// Performs a search for the given username and attempts to create a direct message channel if the username exists.
    private func performUserSearch(_ username: String) {
        Task {
            do {
                // Fetch all usernames from Firestore.
                let usernames = try await fetchUsernames()
                
                // Check if the searched username exists.
                if usernames.contains(username) {
                    createDirectMessageChannel(with: username) // Create a new channel for the user.
                } else {
                    print("Username '\(username)' does not exist.") // Log an error if the username is not found.
                }
            } catch {
                print("Error fetching usernames: \(error.localizedDescription)") // Log any errors during fetching.
            }
        }
    }
    
    /// Creates a direct message channel with the given username.
    private func createDirectMessageChannel(with username: String) {
        // Safely extract the current user's ID from their email.
        guard let currentUserId = AppDelegate.shared.email?.components(separatedBy: "@").first else {
            print("Error: Current user ID is nil.")
            return
        }
        
        let userIds: Set<UserId> = [currentUserId, username]
        
        do {
            // Initialize the channel controller with the user IDs.
            let channelController = try ChatManager.shared.chatClient.channelController(
                createDirectMessageChannelWith: userIds,
                extraData: [:]
            )
            
            // Synchronize the channel controller to finalize the creation.
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
    
    // MARK: - Firestore Integration
    
    /// Fetches a list of all usernames from the Firestore database.
    func fetchUsernames() async throws -> [String] {
        let collection = Firestore.firestore().collection("chat-test")
        let querySnapshot = try await collection.getDocuments()
        
        // Extract usernames from Firestore documents.
        return querySnapshot.documents.compactMap { $0.data()["username"] as? String }
    }
}

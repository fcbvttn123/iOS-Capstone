//
//  HomeScreen.swift
//  group-project
//
//  Created by fizza imran on 2024-10-25.
//

import Foundation
import FirebaseFirestore
import StreamChat

class HomeScreen: BaseViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func connectUserToStream() {
        // Get the part before @ symbol of user email as an unique username
        if let username = AppDelegate.shared.email?.components(separatedBy: "@").first {
            // Start connecting user to Stream
            ChatService.shared.connectUserToStream(username: username)
        } else {
            print("Error: Email is nil or empty.")
        }
    }

    // Connect user to Stream (a third-party library) before loading the screen
    // Each will be called in different contexts based on how the view controller is created
    // init() is used for programmatically created instances
    // init?(coder:) is used for storyboard/nib-loaded instances
    init() {
        super.init(nibName: nil, bundle: nil)
        connectUserToStream()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        connectUserToStream()
    }
    
    // This function is used to make the keyboard disappear when we tap the "return" key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // This function is used to navigate back to this view controller
    @IBAction func toHomeScreen(sender: UIStoryboardSegue) {
        // No action needed
    }
    
    // MARK: - Other Button Actions

    @IBAction func pickPlayButtonTapped(_ sender: UIButton) {
        // For now we dont need anything since we are handling the conditional segue
    }
    
    @IBAction func viewBookingsButtonTapped(_ sender: UIButton) {
        guard let currentUserUID = AppDelegate.shared.currentUserUID else {
            return
        }
        // Perform segue to ViewBookingsScreen with identifier toBookings
        performSegue(withIdentifier: "toBookings", sender: self)
    }
    
    // A click event on a button to direct user to Channel List Screen
    @IBAction func chatButtonTapped(_ sender: Any) {
        // Instantiate a Screen for Channel List
        let chatVC = DemoChannelList()
        // Get the part before @ symbol of user email as an unique username
        if let userId = AppDelegate.shared.email?.components(separatedBy: "@").first, !userId.isEmpty {
            // Create the query to fetch channels of this unique username
            let query = ChannelListQuery(filter: .containMembers(userIds: [userId]))
            // Set the controller
            chatVC.controller = ChatManager.shared.chatClient.channelListController(query: query)
            // Push the DemoChannelList onto the navigation stack. Show the ViewController (chatVC) on screen.
            self.navigationController?.pushViewController(chatVC, animated: true)
        } else {
            // Handle the case where userId is nil or empty
            print("User ID is nil or empty.")
        }
    }
    
    @IBAction func addPlayButtonTapped(_ sender: UIButton) {
        // For now we dont need anything since we are handling the conditional segue
    }
}


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
    
    // Connect user to StreamChat before loading the screen
    init() {
        super.init(nibName: nil, bundle: nil)
        
        // Safely unwrap the username
        if let username = AppDelegate.shared.email?.components(separatedBy: "@").first {
            ChatService.shared.connectUserToStream(username: username)
        } else {
            print("Error: Email is nil or empty.")
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if let username = AppDelegate.shared.email?.components(separatedBy: "@").first {
            ChatService.shared.connectUserToStream(username: username)
        } else {
            print("Error: Email is nil or empty.")
        }
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
    
    @IBAction func chatButtonTapped(_ sender: Any) {
        // When the button is clicked, push the chat screen
        let chatVC = DemoChannelList()

        // Create the query for the channel list
        if let userId = AppDelegate.shared.email?.components(separatedBy: "@").first, !userId.isEmpty {
            let query = ChannelListQuery(filter: .containMembers(userIds: [userId]))

            // Set the controller
            chatVC.controller = ChatManager.shared.chatClient.channelListController(query: query)

            // Push the DemoChannelList onto the navigation stack
            self.navigationController?.pushViewController(chatVC, animated: true)
        } else {
            // Handle the case where userId is nil or empty
            print("User ID is nil or empty.")
            // Optionally, you can show an alert or message to the user
        }
    }
    
    @IBAction func addPlayButtonTapped(_ sender: UIButton) {
        // For now we dont need anything since we are handling the conditional segue
    }
}


//
//  HomeScreen.swift
//  group-project
//
//  Created by fizza imran on 2024-10-25.
//

import Foundation
import FirebaseFirestore

class HomeScreen: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // This function is used to make the keyboard disappear when we tap the "return" key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // This function is used to navigate back to this view controller
    @IBAction func toHomeScreen(sender: UIStoryboardSegue) {
        // No action needed
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toBookings" {
            if let destinationVC = segue.destination as? ViewBookingsScreen,
               let bookingId = sender as? String {
                destinationVC.bookingId = bookingId
            }
        }
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
        performSegue(withIdentifier: "toBookings", sender: currentUserUID)
    }
    
    @IBAction func addPlayButtonTapped(_ sender: UIButton) {
        // For now we dont need anything since we are handling the conditional segue
    }
}


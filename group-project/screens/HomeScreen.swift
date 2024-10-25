//
//  HomeScreen.swift
//  group-project
//
//  Created by fizza imran on 2024-10-25.
//

import Foundation
import FirebaseFirestore

class HomeScreen: UIViewController {
    
    // Firestore reference
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createUserDocumentIfNeeded()
    }
    
    // This function is used to make the keyboard disappear when we tap the "return" key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // This function is used to navigate back to this view controller
    @IBAction func toHomeScreen(sender: UIStoryboardSegue) {
        // No action needed
    }
    
    // MARK: - Home Campus Management
    
    // Function to create a user document if it does not already exist
    private func createUserDocumentIfNeeded() {
        guard let email = AppDelegate.shared.email else { return }
        
        // Reference to the Users collection
        let usersRef = db.collection("users")
        
        // Check if the user document exists
        usersRef.whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error checking for user document: \(error)")
                return
            }
            
            // If no documents found, create a new user document
            if querySnapshot?.isEmpty == true {
                // Prepare user data
                let userData: [String: Any] = [
                    "username": AppDelegate.shared.username ?? "",
                    "email": email,
                    "country": AppDelegate.shared.country ?? "",
                    "college": AppDelegate.shared.college ?? ""
                ]
                
                // Add new document with a unique ID
                usersRef.addDocument(data: userData) { error in
                    if let error = error {
                        print("Error creating user document: \(error)")
                    } else {
                        print("User document created successfully.")
                    }
                }
            } else {
                print("User document already exists.")
            }
        }
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


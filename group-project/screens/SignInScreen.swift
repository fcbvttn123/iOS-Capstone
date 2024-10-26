//
//  SignInScreen.swift
//  group-project
//
//  Created by fizza imran on 2024-10-25.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import CryptoKit
import StreamChat
import StreamChatUI


class SignInScreen: UIViewController, UITextFieldDelegate {
    
    // Reference to Firestore
      private var db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        username.text = AppDelegate.shared.email
        // Set password field to secure text entry
        password.isSecureTextEntry = true
    }
    
    // MARK: - Outlets
    
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var btn: UIButton!
    @IBOutlet var signUpButton: UIButton!

    
    // MARK: - Actions

    
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        guard let email = username.text, !email.isEmpty,
              let password = password.text, !password.isEmpty else {
            showAlert(message: "Please enter both email and password.")
            return
        }
        
        // Sign in with Firebase
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                self.showAlert(message: error.localizedDescription)
                return
            }
            
            // User is signed in
            AppDelegate.shared.email = self.username.text
            AppDelegate.shared.currentUserUID = self.username.text
            // Navigate to the next screen
            
            // Check for empty properties and update if necessary
            self.checkAndUpdateUserInfo()
            
            self.performSegue(withIdentifier: "toHome", sender: self)
        }
    }
    
    // Function to check and update user info from Firestore
        private func checkAndUpdateUserInfo() {
            // Check if properties are empty
            if AppDelegate.shared.college?.isEmpty ?? true ||
               AppDelegate.shared.country?.isEmpty ?? true ||
               AppDelegate.shared.username?.isEmpty ?? true {
                
                guard let email = AppDelegate.shared.email else { return }
                
                // Reference to the Users collection
                let usersRef = db.collection("users")
                
                // Retrieve user data from Firestore
                usersRef.whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Error fetching user document: \(error)")
                        return
                    }
                    
                    // Check if the user document exists and update properties
                    if let document = querySnapshot?.documents.first {
                        AppDelegate.shared.username = document.get("username") as? String ?? ""
                        AppDelegate.shared.country = document.get("country") as? String ?? ""
                        AppDelegate.shared.college = document.get("college") as? String ?? ""
                        
                        print("User info updated from Firestore.")
                    } else {
                        print("User document not found.")
                    }
                }
            }
        }
    
    // Action that shows user "what is Institutional Email"
    @IBAction func InstituteEmailPopup(_ sender: UIButton){
        let alert = UIAlertController(title: "Institutional Email",
                                      message: "As a student or faculty member, you're provided an official email by your institution. For example, your email might be formatted like yourname@Universitydomain.com. Please use this email to continue and create a new password.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // Action for Sign-Up button
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
           // Perform segue to the email verification screen
           self.performSegue(withIdentifier: "toEmailVerification", sender: self)
       }
    
    // This function is used to navigate back to this view controller
    @IBAction func toLoginScreen(sender: UIStoryboardSegue) {
        // No action needed
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // MARK: - Helper Methods
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func unwindToLoginScreen(_ segue: UIStoryboardSegue) {

    }
    
}


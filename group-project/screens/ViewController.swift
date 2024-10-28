import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import CryptoKit
import StreamChat
import StreamChatUI

class ViewController: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            // Navigate to the next screen
            self.performSegue(withIdentifier: "goToNextScreen", sender: self)
        }
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
}



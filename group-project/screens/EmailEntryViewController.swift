//
//  EmailEntryViewController.swift
//  group-project
//
//  Created by fizza imran on 2024-10-24.
//

import Foundation
import UIKit
import Combine

class EmailEntryViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var sendCodeButton: UIButton!
    
    private let emailService = EmailService()
    private var cancelables = Set<AnyCancellable>()
    
    var verificationCode: String = "test"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func sendCodeButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert("Please enter a valid email.")
            return
        }
        
        AppDelegate.shared.email = emailTextField.text ?? ""
        sendEmail(email: email)
    }
    
    func sendEmail(email : String){
        // Generate a 6-digit random code
        verificationCode = String(format: "%06d", Int.random(in: 0...999999))
        
        // Email content with instructions
        let emailContent = """
           Hello,
           
           Thank you for signing up! Use the following verification code:
           
           Code: \(verificationCode)
           ------------------------
           
            Thank you,
            The Team - PlayPal
           """
        
        emailService.send(message: email, verificationCode: verificationCode, emailContent: emailContent)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert("Failed to send email: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] isSuccessful in
                guard isSuccessful else { return }
                
                // Perform segue to the verification code screen
                self?.performSegue(withIdentifier: "toCodeVerificationScreen", sender: self)
            }
            .store(in: &cancelables)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCodeVerificationScreen",
           let destinationVC = segue.destination as? CodeVerificationViewController {
            destinationVC.verificationCode = self.verificationCode
        }
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


//
//  CodeVerificationViewController.swift
//  group-project
//
//  Created by fizza imran on 2024-10-24.
//

import Foundation
import UIKit
import Combine

class CodeVerificationViewController: UIViewController {
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!
    
    var verificationCode: String = "" // Set this from the previous screen
    var timer: Timer?
    var countdown: Int = 60 {
        didSet {
            // Enable or disable the resend button based on countdown
            resendButton.isEnabled = countdown == 0
            resendButton.setTitle(countdown == 0 ? "Resend Code" : "Resend in \(countdown)s", for: .normal)
        }
    }
    
    private let emailService = EmailService() // Create an instance of EmailService
    private var cancelables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.isEnabled = false
        startTimer()
        
        // Add observer to monitor changes in the codeTextField
        codeTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        // Enable the submit button if the codeTextField is not empty
        submitButton.isEnabled = !(textField.text?.isEmpty ?? true)
    }
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        guard let enteredCode = codeTextField.text, enteredCode == verificationCode else {
            showAlert("Incorrect code. Please try again.")
            return
        }
        
        // Mark email as verified
        AppDelegate.shared.isEmailVerified = true
        // Proceed with next steps (e.g., segue to sign-up screen)
        performSegue(withIdentifier: "toSignUp", sender: self)
    }
    
    @IBAction func resendButtonTapped(_ sender: UIButton) {
        // Reset the countdown and start the timer again
        resetTimer()
        // Resend the verification code
        resendVerificationCode()
    }
    
    private func resetTimer() {
        countdown = 60
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate() // Stop the previous timer if it's running
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            if self.countdown > 0 {
                self.countdown -= 1
            } else {
                timer.invalidate() // Stop the timer when countdown reaches 0
            }
        }
    }
    
    private func resendVerificationCode() {
        // Generate a new verification code
        let newVerificationCode = generateNewVerificationCode()
        verificationCode = newVerificationCode // Update the verification code
        
        // Get the email address from the app delegate
        guard let email = AppDelegate.shared.email else {
            showAlert("No email address available. Please enter your email.")
            return
        }
        
        // Prepare email content
        let emailContent = """
           Hello,
           
           Your previous verification code has expired. Use the following new verification code:
           
           Code: \(newVerificationCode)
           ------------------------
           
           Thank you,
           The Team - PlayPal
           """
        
        // Send the new verification code via email
        emailService.send(message: email, verificationCode: newVerificationCode, emailContent: emailContent)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert("Failed to resend email: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] isSuccessful in
                guard isSuccessful else { return }
            }
            .store(in: &cancelables)
    }
    
    private func generateNewVerificationCode() -> String {
        // Generate a new verification code
        return String(format: "%06d", Int.random(in: 0...999999))
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

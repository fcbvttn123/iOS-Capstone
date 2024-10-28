//
//  EmailVerificationScreen.swift
//  group-project
//
//  Created by fizza imran on 2024-10-02.
//

import UIKit
import Combine

class EmailVerificationScreen: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var sendCodeButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var timerLabel: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var EmailMsg: UILabel!
    private let emailService = EmailService()
    private var cancelables = Set<AnyCancellable>()
    
    var verificationCode: String = "test"
    var timer: Timer?
    var countdown: Int = 60 {
        didSet {
            timerLabel.text = "\(countdown)s"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.isEnabled = false
    }
    
    @IBAction func sendCodeButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert("Please enter a valid email.")
            return
        }
        
        AppDelegate.shared.email = emailTextField.text ?? ""
        
        // Generate a 6-digit random code
        verificationCode = String(format: "%06d", Int.random(in: 0...999999))
        
        // Enhanced email content with instructions
        let emailContent = """
           Hello,
           
           Thank you for signing up! Please use the following verification code to confirm your email address:
           --------------------------------------------------------------------------------------------------
           Verification Code: \(verificationCode)
           --------------------------------------------------------------------------------------------------
           Instructions:
           1. Enter the code in the provided field in the app.
           2. Make sure to do this within the next 60 seconds, as the code will expire.
           3. If you did not receive the code, please check your spam folder or click "Re-send Code" to receive a new one.
           
           If you did not request this verification, please ignore this email.
           
           Thank you,
           The Team
           """
        
        emailService.send(message: email, verificationCode: verificationCode, emailContent: emailContent)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert("Failed to send verification email. \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] isSuccessful in
                guard isSuccessful else { return }
                self?.sendCodeButton.setTitle("Re-send Code", for: .normal)
                self?.sendCodeButton.isEnabled = false
                
                self?.EmailMsg.text = "Email Sent to \(self?.emailTextField.text ?? "")"
                
                // Update UI for entering code
                self?.titleLabel.text = "Plaese Enter 6-digit code here"
                self?.emailTextField.placeholder = "000-000"
                
                // Clear the email text field
                self?.emailTextField.text = ""
                
                
                // Enable the submit button
                self?.submitButton.isEnabled = true
                
                self?.countdown = 60
                self?.startTimer()
            }
            .store(in: &cancelables)
    }
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        guard let enteredCode = emailTextField.text, enteredCode == verificationCode else {
            showAlert("Incorrect code. Please try again.")
            return
        }
        // Update the AppDelegate with the verified email and set isEmailVerified to true
        AppDelegate.shared.isEmailVerified = true
        
        // Perform segue to proceed after email verification
        performSegue(withIdentifier: "toSignUp", sender: self)
    }

    
    @IBAction func resendCodeButtonTapped(_ sender: UIButton) {
        sendCodeButton.isEnabled = false
        sendCodeButton.setTitle("Sending...", for: .normal)
        
        // Call sendCodeButtonTapped method to resend the code
        sendCodeButtonTapped(sender)
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.countdown > 0 {
                self.countdown -= 1
            } else {
                self.timer?.invalidate()
                self.sendCodeButton.isEnabled = true
                self.sendCodeButton.setTitle("Re-send Code", for: .normal)
                self.titleLabel.text = "Verification Code Expired"
                self.emailTextField.text = ""
                self.emailTextField.placeholder = ""
            }
        }
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

class EmailService {
    func send(message: String, verificationCode: String, emailContent: String) -> AnyPublisher<Bool, Error> {
        let data: Data = {
            let senderEmail = "imranfi@sheridancollege.ca"
            let reciverEmail = message // use the provided email
            let json: [String: Any] = [
                "personalizations": [["to": [["email": reciverEmail]]]],
                "from": ["email": senderEmail],
                "subject": "Verification Code",
                "content": [["type": "text/plain", "value": emailContent]]
            ]
            return try! JSONSerialization.data(withJSONObject: json, options: [])
        }()
        
        let request: URLRequest = {
            let apiKey = ProcessInfo.processInfo.environment["SENDGRID_API_KEY"] ?? ""
            let url = URL(string: "https://api.sendgrid.com/v3/mail/send")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
            return request
        }()
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .catch { error in
                return Fail(error: error).eraseToAnyPublisher()
            }.tryMap { output in
                let statusCode = (output.response as? HTTPURLResponse)?.statusCode ?? 0
                return (200...299).contains(statusCode)
            }.eraseToAnyPublisher()
    }
    
}



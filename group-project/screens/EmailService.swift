//
//  EmailService.swift
//  group-project
//
//  Created by fizza imran on 2024-10-24.
//

import Foundation
import Combine

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
            let apiKey = ProcessInfo.processInfo.environment["SENDGRID_API_KEY"] ?? "SG.59Buz7OsQa-o4RRkNhCrbA.ovcj9lM_KSTSJgCM1-U-ypfq-fPZwyUQRhesTK_b5fISG.59Buz7OsQa-o4RRkNhCrbA.ovcj9lM_KSTSJgCM1-U-ypfq-fPZwyUQRhesTK_b5fI"
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

//
//  AttendingUsersViewController.swift
//  group-project
//
//  Created by fizza imran on 2024-10-29.
//

import SwiftUI
import UIKit
import FirebaseFirestore

class AttendingUsersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView!
    
    var attendingUsers: [[String: Any]] = [] // Array to hold user data
    var eventID: String? // Declare the eventID property

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        fetchAttendingUsers()
    }

    func fetchAttendingUsers() {
        let db = Firestore.firestore()
        
        // Check if eventID is available
        guard let eventID = eventID else { return }
        let collegeID = AppDelegate.shared.college?.replacingOccurrences(of: " ", with: "_") ?? ""
        
        db.collection("events").document(collegeID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching event data: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists,
                  let eventsArray = document.get("events") as? [[String: Any]] else {
                print("No events found for college ID: \(collegeID)")
                return
            }
            print("Fetched events array: \(eventsArray)") // Debug print
            
            // Locate the specific event and retrieve attending users
            if let event = eventsArray.first(where: { $0["eventID"] as? String == eventID }),
               let userIDs = event["attendingUsers"] as? [String] {
                self.fetchUserDetails(for: userIDs)
            }
        }
    }

    func fetchUserDetails(for userIDs: [String]) {
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup() // Create a dispatch group
        
        for userID in userIDs {
            dispatchGroup.enter() // Enter the dispatch group
            db.collection("users").document(userID).getDocument { [weak self] document, error in
                defer { dispatchGroup.leave() } // Leave the dispatch group when done
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching user data: \(error.localizedDescription)")
                    return
                }
                
                if let userData = document?.data() {
                    self.attendingUsers.append(userData)
                    print("Fetched user data for ID \(userID): \(userData)") // Debug print
                } else {
                    print("No user data found for ID: \(userID)") // Debug print
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { // Notify when all requests are done
            self.tableView.reloadData()
        }
    }


    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attendingUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as? UserTableViewCell else {
            fatalError("Failed to dequeue UserTableViewCell.")
        }
        
        let user = attendingUsers[indexPath.row]
        cell.configure(with: user)
        
        return cell
    }

    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

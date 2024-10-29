/*
 Group Name: Byte_Buddies
 Group Members:
 - Tran Thanh Ngan Vu 991663076
 - Chahat Jain 991668960
 - Fizza Imran 991670304
 - Chakshita Gupta 991653663
 Description: Class for displaying event details and handling event registration.
 */

import UIKit
import FirebaseFirestore

class EventDisplayScreen: BaseViewController {
    
    // MARK: - Outlets
    @IBOutlet var eventNameLabel: UILabel!
    @IBOutlet var eventDateLabel: UILabel!
    @IBOutlet var contactNumberLabel: UILabel!
    @IBOutlet var eventAddressLabel: UILabel!
    @IBOutlet var sportTypeLabel: UILabel!
    @IBOutlet var numberOfPlayersLabel: UILabel!
    @IBOutlet var notesTextView: UITextView!
    
    
    // fuctionlaity to display attending users
    @IBOutlet weak var attendingUsersCollectionView: UICollectionView!

    var attendingUsers: [String] = [] // Array of user IDs attending this event
    var userImages: [String: UIImage] = [:] // Dictionary to cache user profile images
    
    // MARK: - Properties
    var eventID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let eventID = eventID {
            fetchEventDetails(eventID: eventID)
        }
    }
    
    func fetchEventDetails(eventID: String) {
        let db = Firestore.firestore()
        let collegeID = AppDelegate.shared.college?.replacingOccurrences(of: " ", with: "_") ?? ""
        let eventsRef = db.collection("events").document(collegeID)
        
        eventsRef.getDocument { document, error in
            if let error = error {
                print("Error fetching events: \(error)")
                return
            }
            
            guard let document = document, document.exists,
                  let eventsArray = document.get("events") as? [[String: Any]] else {
                print("No events found for college ID: \(collegeID)")
                return
            }
            
            // Iterate through events to find the correct one
            for eventData in eventsArray {
                if let fetchedEventID = eventData["eventID"] as? String, fetchedEventID == eventID {
                    // Populate UI with event data
                    self.eventNameLabel.text = eventData["eventName"] as? String
                    self.eventDateLabel.text = eventData["date"] as? String
                    self.contactNumberLabel.text = eventData["contactNumber"] as? String
                    self.eventAddressLabel.text = eventData["eventAddress"] as? String
                    self.sportTypeLabel.text = eventData["sportType"] as? String
                    self.numberOfPlayersLabel.text = "\(eventData["numberOfPlayers"] as? Int ?? 0)"
                    self.notesTextView.text = eventData["notes"] as? String
                    break // Exit loop once the event is found
                }
            }
        }
    }
    // MARK: - Register Event Action
    @IBAction func registerEvent(sender: UIButton) {
        guard let eventID = eventID else {
            showAlert(withTitle: "Error", message: "Event ID is not available.")
            return
        }
        
        let db = Firestore.firestore()
        let userID = AppDelegate.shared.currentUserUID ?? ""
        let collegeID = AppDelegate.shared.college?.replacingOccurrences(of: " ", with: "_") ?? ""
        let eventRef = db.collection("events").document(collegeID)
        
        // Update user's registered events
        let userRef = db.collection("users").document(userID)
        
        userRef.updateData([
            "registeredEvents": FieldValue.arrayUnion([eventID])
        ]) { error in
            if let error = error {
                print("Error updating user document: \(error)")
                self.showAlert(withTitle: "Error", message: "Failed to register for the event.")
                return
            }
            
            print("User's registered events updated successfully.")
        }
        
        // Update event's attending users
        eventRef.getDocument { document, error in
            if let error = error {
                print("Error fetching event document: \(error)")
                self.showAlert(withTitle: "Error", message: "Failed to fetch event details.")
                return
            }
            
            guard let document = document, document.exists,
                  let eventsArray = document.get("events") as? [[String: Any]] else {
                print("No events found for college ID: \(collegeID)")
                return
            }
            
            // Find the specific event to update
            for (index, eventData) in eventsArray.enumerated() {
                if let fetchedEventID = eventData["eventID"] as? String, fetchedEventID == eventID {
                    // Check if the user is already registered for this event
                    var attendingUsers = eventData["attendingUsers"] as? [String] ?? []
                    
                    print("Attending users:", attendingUsers)

                    if attendingUsers.contains(userID) {
                        // User is already registered for this event
                        self.showAlert(withTitle: "Info", message: "You are already registered for this event.")
                        return
                    }
                    
                    // Update the attending users for the found event
                    attendingUsers.append(userID) // Add the user's ID to the array
                    
                    // Update the events array with the modified event data
                    var updatedEventData = eventData
                    updatedEventData["attendingUsers"] = attendingUsers
                    
                    var updatedEventsArray = eventsArray
                    updatedEventsArray[index] = updatedEventData
                    
                    // Update the event document
                    eventRef.updateData([
                        "events": updatedEventsArray
                    ]) { error in
                        if let error = error {
                            print("Error updating event attendees: \(error)")
                            self.showAlert(withTitle: "Error", message: "Failed to add user to event attendees.")
                        } else {
                            print("User added to event attendees successfully.")
                            
                            // Show alert for successful registration
                            self.showAlert(withTitle: "Success", message: "You have successfully registered for the event!")
                            
                            // Perform segue to user bookings
                            self.performSegue(withIdentifier: "toUserBookings", sender: nil)
                        }
                    }
                    break // Exit loop once the event is found and updated
                }
            }
        }
    }
    @IBAction func viewAttendingUsersTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "toAttendingUsers", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAttendingUsers" {
            if let attendingUsersVC = segue.destination as? AttendingUsersViewController {
                attendingUsersVC.eventID = self.eventID // Pass the eventID
                print("Passing eventID: \(self.eventID ?? "nil")")
            }
        }
    }

    func showAlert(withTitle title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

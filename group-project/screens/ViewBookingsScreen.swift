/*
Group Name: Byte_Buddies
Group Members:
- Tran Thanh Ngan Vu 991663076
- Chahat Jain 991668960
- Fizza Imran 991670304
- Chakshita Gupta 991653663
Description: A screen for displaying the list of bookings made by the user.
*/
import UIKit
import FirebaseFirestore

// Protocol to handle delete action
protocol DeleteBookingDelegate: AnyObject {
    func deleteBooking(at index: Int)
}

// Custom UITableViewCell for booking display
class BookingTableViewCell: UITableViewCell {
    @IBOutlet var eventNameLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    weak var delegate: DeleteBookingDelegate?

    // Configure cell with booking details
    func configure(with bookingDetails: [String: Any]) {
        eventNameLabel.text = bookingDetails["eventName"] as? String ?? ""
        dateLabel.text = "Date: \(bookingDetails["date"] as? String ?? "")"
        addressLabel.text = "Address: \(bookingDetails["eventAddress"] as? String ?? "")"
    }

    // Handle delete button tap
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        delegate?.deleteBooking(at: tag)
    }
}

/*
 This view controller presents a list of bookings retrieved from Firestore.
 It conforms to UITableViewDataSource and UITableViewDelegate protocols to manage the table view displaying the bookings.
 */
class ViewBookingsScreen: BaseViewController, UITableViewDataSource, UITableViewDelegate, DeleteBookingDelegate {

    @IBOutlet var tableView: UITableView!

    var bookingData: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        fetchRegisteredEvents()
    }

    func fetchRegisteredEvents() {
        guard let userId = AppDelegate.shared.currentUserUID else {
            print("Error: User ID not available.")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists,
                  let registeredEvents = document.data()?["registeredEvents"] as? [String], !registeredEvents.isEmpty else {
                print("No registered events found or document does not exist.")
                return
            }
            
            print("Registered events for user \(userId): \(registeredEvents)")
            self.fetchEventDetails(for: registeredEvents)
        }
    }

    func fetchEventDetails(for eventIDs: [String]) {
        let db = Firestore.firestore()
        
        guard !eventIDs.isEmpty else {
            print("No event IDs provided.")
            return
        }
        
        // Firestore's `in` query limit is 10 items; if more, split into batches
        let eventIDBatches = stride(from: 0, to: eventIDs.count, by: 10).map {
            Array(eventIDs[$0..<min($0 + 10, eventIDs.count)])
        }
        
        var batchCounter = 1
        for batch in eventIDBatches {
            print("Fetching batch \(batchCounter) with event IDs: \(batch)")
            
            // Fetch each document corresponding to collegeID
            let collegeID = AppDelegate.shared.college?.replacingOccurrences(of: " ", with: "_") ?? ""
            let eventsRef = db.collection("events").document(collegeID)
            
            eventsRef.getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching events document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists,
                      let eventsArray = document.get("events") as? [[String: Any]] else {
                    print("No events found for college ID: \(collegeID)")
                    return
                }

                for eventData in eventsArray {
                    if let fetchedEventID = eventData["eventID"] as? String, batch.contains(fetchedEventID) {
                        self.bookingData.append(eventData)
                        print("Event data: \(eventData)")
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            batchCounter += 1
        }
    }



    func deleteBooking(at index: Int) {
        // Ensure the index is valid
        guard index >= 0 && index < bookingData.count else {
            print("Invalid index for deletion.")
            return
        }
        
        let bookingToDelete = bookingData[index]
        
        // Retrieve eventID from booking details
        guard let eventID = bookingToDelete["eventID"] as? String else {
            print("Error: Event ID not found for booking.")
            return
        }
        
        // Get user ID
        guard let userId = AppDelegate.shared.currentUserUID else {
            print("Error: User ID not available.")
            return
        }
        
        let db = Firestore.firestore()
        let collegeID = AppDelegate.shared.college?.replacingOccurrences(of: " ", with: "_") ?? ""
        let eventRef = db.collection("events").document(collegeID)
        
        // Remove the event from user's `registeredEvents`
        db.collection("users").document(userId).updateData([
            "registeredEvents": FieldValue.arrayRemove([eventID])
        ]) { error in
            if let error = error {
                print("Error deleting booking from Firestore: \(error.localizedDescription)")
            } else {
                // Remove the user from `attendingUsers` in the events collection
                eventRef.getDocument { document, error in
                    if let error = error {
                        print("Error fetching event document: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let document = document, document.exists,
                          var eventsArray = document.get("events") as? [[String: Any]] else {
                        print("No events found for college ID: \(collegeID)")
                        return
                    }
                    
                    // Find the specific event to update
                    for (eventIndex, eventData) in eventsArray.enumerated() {
                        if let fetchedEventID = eventData["eventID"] as? String, fetchedEventID == eventID {
                            var attendingUsers = eventData["attendingUsers"] as? [String] ?? []
                            
                            // Remove the user from attending users if they are present
                            if let userIndex = attendingUsers.firstIndex(of: userId) {
                                attendingUsers.remove(at: userIndex)
                                
                                // Update the event data with modified attending users
                                var updatedEventData = eventData
                                updatedEventData["attendingUsers"] = attendingUsers
                                eventsArray[eventIndex] = updatedEventData
                                
                                // Save the updated events array back to Firestore
                                eventRef.updateData([
                                    "events": eventsArray
                                ]) { error in
                                    if let error = error {
                                        print("Error updating event attendees: \(error)")
                                    } else {
                                        print("User removed from event attendees successfully.")
                                        
                                        // Update the data source and the table view
                                        self.bookingData.remove(at: index)
                                        DispatchQueue.main.async {
                                            self.tableView.performBatchUpdates({
                                                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                                            }, completion: nil)
                                        }
                                    }
                                }
                                break
                            }
                        }
                    }
                }
            }
        }
    }



    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookingData.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "bookingCell", for: indexPath) as? BookingTableViewCell else {
            fatalError("Failed to dequeue BookingTableViewCell.")
        }

        cell.tag = indexPath.row
        cell.delegate = self
        cell.configure(with: bookingData[indexPath.row])

        return cell
    }
}

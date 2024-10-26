//
//  ViewAllEvents.swift
//  group-project
//
//  Created by fizza imran on 2024-10-25.
//
import UIKit
import FirebaseFirestore

class ViewAllEvents: UIViewController, UIPickerViewDelegate, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Variables
    var events: [Event] = []

    struct Event {
        let eventName: String
        let eventDate: Date
        let eventLocation: String
        // Add other properties as needed
    }

    @IBOutlet var urlButton: UIButton!
    @IBOutlet var tableView: UITableView!

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up table view
        tableView.delegate = self
        tableView.dataSource = self
        
        // Add action to the URL button
        urlButton.addTarget(self, action: #selector(urlButtonTapped), for: .touchUpInside)

        // Load events for the user's college
        fetchUserData()
    }

    // MARK: - TableView Delegate and DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath)
        let event = events[indexPath.row]

        // Configure the cell
        let eventNameAttributedString = attributedEventName(event.eventName)
        let eventDateTimeAttributedString = attributedDateTime(for: event.eventDate)
        let eventAddressAttributedString = attributedAddress(for: event.eventLocation)

        let combinedAttributedString = NSMutableAttributedString()
        combinedAttributedString.append(eventNameAttributedString)
        combinedAttributedString.append(NSAttributedString(string: "\n"))
        combinedAttributedString.append(eventDateTimeAttributedString)
        combinedAttributedString.append(NSAttributedString(string: "\n"))
        combinedAttributedString.append(eventAddressAttributedString)

        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.attributedText = combinedAttributedString
        
        return cell
    }

    // MARK: - Fetch User Data
    func fetchUserData() {
        guard let userEmail = AppDelegate.shared.email else {
            print("No user email found in AppDelegate.")
            return
        }
        let college = AppDelegate.shared.college
        let collegeWebsite = AppDelegate.shared.collegeWebsite
        
        print("College: \(college ?? "N/A"), College Website: \(collegeWebsite ?? "N/A")")
                
        // Set the button URL
        self.urlButton.setTitle(collegeWebsite, for: .normal)

        // Normalize the college ID
        if let college = college {
            let collegeID = college.replacingOccurrences(of: " ", with: "_")
            print("Normalized college ID: \(collegeID)")
                
            // Fetch events for the user's college
            self.fetchEvents(for: collegeID)
        } else {
            print("College or collegeWebsite not found in user data.")
            self.showNoEventsAlert()
        }
    }

    func fetchEvents(for collegeID: String) {
        let db = Firestore.firestore()
        let eventsRef = db.collection("events").document(collegeID)
        
        print("Fetching events for college ID: \(collegeID)")

        eventsRef.getDocument { document, error in
            guard let document = document, document.exists else {
                print("No events document found for college ID: \(collegeID)")
                self.showNoEventsAlert()
                return
            }
            
            if let eventsData = document.get("events") as? [[String: Any]] {
                print("Events data found: \(eventsData.count) events")
                
                self.events = eventsData.compactMap { data in
                    guard let eventName = data["eventName"] as? String,
                          let dateString = data["date"] as? String,
                          let eventLocation = data["eventAddress"] as? String,
                          let date = self.date(from: dateString) else {
                        print("Error parsing event data: \(data)")
                        return nil
                    }
                    
                    print("Event added - Name: \(eventName), Date: \(date), Location: \(eventLocation)")
                    return Event(eventName: eventName, eventDate: date, eventLocation: eventLocation)
                }

                if self.events.isEmpty {
                    print("No events parsed from data.")
                    self.showNoEventsAlert()
                }

                // Refresh the table view
                self.tableView.reloadData()
            } else {
                print("No 'events' field found or is empty in document for college ID: \(collegeID)")
                self.showNoEventsAlert()
            }
        }
    }

    // MARK: - Helper Functions
    func showNoEventsAlert() {
        let alertController = UIAlertController(title: "No Events", message: "There are no events registered for your college.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    // Converts string to date
    func date(from dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: dateString)
    }

    // MARK: - Button Action
    @objc func urlButtonTapped() {
        // Remove any extra whitespace around the URL
        guard let urlString = urlButton.title(for: .normal)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: urlString),
              UIApplication.shared.canOpenURL(url) else {
            print("Invalid or unopenable URL: \(urlButton.title(for: .normal) ?? "No URL")")
            showInvalidUrlAlert()
            return
        }
        
        performSegue(withIdentifier: "toWebView", sender: url.absoluteString)
    }

    // Show an alert if URL is invalid
    func showInvalidUrlAlert() {
        let alert = UIAlertController(title: "Invalid URL", message: "The URL provided is not valid or cannot be opened.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }


    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toWebView", let urlString = sender as? String, let destinationVC = segue.destination as? WebScreen {
            destinationVC.urlString = urlString
        }
    }
    
    // MARK: - Other Methods
    // Creates attributed string for event name
    func attributedEventName(_ eventName: String) -> NSAttributedString {
        let attributedString = NSAttributedString(string: eventName, attributes: [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.blue])
        return attributedString
    }

    // Creates attributed string for Date and Time
    func attributedDateTime(for date: Date) -> NSAttributedString {
        // Create a formatter for date and time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy 'at' HH:mm"
        
        // Create attributed string for date and time
        let dateString = dateFormatter.string(from: date)
        let attributedString = NSAttributedString(string: "Date & Time: \(dateString)", attributes: [.font: UIFont.italicSystemFont(ofSize: 14)])
        
        return attributedString
    }

    // Creates attributed string for address
    func attributedAddress(for address: String) -> NSAttributedString {
        let attributedString = NSAttributedString(string: "Address: \(address)", attributes: [.font: UIFont.italicSystemFont(ofSize: 14)])
        
        return attributedString
    }
}


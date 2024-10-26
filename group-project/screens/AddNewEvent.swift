//
//  AddNewEvent.swift
//  group-project
//
//  Created by Fizza Imran on 2024-10-25.
//

import UIKit
import FirebaseFirestore

class AddNewEvent: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    // MARK: - Outlets
    @IBOutlet var eventNameTextField: UITextField!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var contactNumberTextField: UITextField!
    @IBOutlet var eventAddressTextField: UITextField!
    @IBOutlet var sportTypePickerView: UIPickerView!
    @IBOutlet var numberOfPlayersStepper: UIStepper!
    @IBOutlet var numberOfPlayersLabel: UILabel!
    @IBOutlet var notesTextView: UITextView!

    // MARK: - Properties
    var sportTypes: [String] = []
    
    override func viewDidLoad() {
           super.viewDidLoad()
           
           sportTypePickerView.delegate = self
           sportTypePickerView.dataSource = self
           
           numberOfPlayersStepper.value = 1
           numberOfPlayersStepper.minimumValue = 1
           numberOfPlayersStepper.addTarget(self, action: #selector(stepperValueChanged(_:)), for: .valueChanged)

           fetchSportTypes() // Fetch available sport types from Firestore
       }

       func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
           if row == sportTypes.count { // Last item, "Add New Sport"
               presentAddNewSportAlert()
           }
       }
    
    // MARK: - UIPickerView Data Source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sportTypes.count + 1 // Plus one for the "Add New Sport" option
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row < sportTypes.count {
            return sportTypes[row]
        } else {
            return "Add New Sport"
        }
    }
    
    // Show alert to add a new sport
        func presentAddNewSportAlert() {
            let alert = UIAlertController(title: "Add New Sport", message: "Enter the name of the new sport.", preferredStyle: .alert)
            
            alert.addTextField { textField in
                textField.placeholder = "Sport name"
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
                if let sportName = alert.textFields?.first?.text, !sportName.isEmpty {
                    self?.addNewSport(sportName)
                }
            }))
            
            present(alert, animated: true, completion: nil)
        }
        
        // Add the new sport to Firestore and update local data
        func addNewSport(_ sportName: String) {
            let db = Firestore.firestore()
            let sportTypesRef = db.collection("sports").document("type")
            
            // Add the new sport type to Firestore
            sportTypesRef.updateData(["types": FieldValue.arrayUnion([sportName])]) { error in
                if let error = error {
                    self.displayAlert(message: "Error adding new sport: \(error.localizedDescription)")
                } else {
                    // Update local data and reload the picker view
                    self.sportTypes.append(sportName)
                    self.sportTypePickerView.reloadAllComponents()
                    print("New sport added successfully.")
                }
            }
        }
    
    // MARK: - Stepper Value Changed
    @objc func stepperValueChanged(_ sender: UIStepper) {
        numberOfPlayersLabel.text = "\(Int(sender.value))"
    }
    
    // MARK: - Firestore Integration
    func fetchSportTypes() {
        let db = Firestore.firestore()
        let sportTypesRef = db.collection("sports").document("type")
        
        sportTypesRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let data = document.data(), let types = data["types"] as? [String] {
                    self.sportTypes = types
                }
            } else {
                print("Sport types document does not exist. Creating default.")
                self.createDefaultSportTypes()
            }
            self.sportTypePickerView.reloadAllComponents()
        }
    }

    func createDefaultSportTypes() {
        let db = Firestore.firestore()
        let sportTypesRef = db.collection("sports").document("type")
        
        // Example default sport types, you can customize as needed
        let defaultTypes: [String] = [
            "Soccer", "Basketball", "Baseball", "American Football", "Tennis",
            "Golf", "Cricket", "Rugby", "Ice Hockey", "Field Hockey", "Table Tennis",
            "Badminton", "Volleyball", "Swimming", "Athletics", "Boxing",
            "Wrestling", "Martial Arts", "Cycling", "Equestrian", "Sailing",
            "Gymnastics", "Skiing", "Snowboarding", "Surfing", "Skateboarding",
            "Rock Climbing", "Rowing", "Kayaking", "Canoeing", "Lacrosse",
            "Fencing", "Handball", "Squash", "Dodgeball", "Bowling", "Darts",
            "Snooker", "Billiards", "Polo", "Horse Racing", "Motor Racing",
            "Archery", "Weightlifting", "Powerlifting", "Triathlon", "Pentathlon",
            "Softball", "Kickboxing", "CrossFit", "Dance", "Cheerleading",
            "Figure Skating", "Ice Dancing", "Curling", "Biathlon", "Water Polo",
            "Speed Skating", "Skeleton", "Luge", "Bobsleigh", "Freestyle Skiing",
            "Modern Pentathlon", "Rhythmic Gymnastics", "Trampoline",
            "Judo", "Karate", "Taekwondo", "Sumo Wrestling", "Kendo", "Capoeira",
            "Muay Thai", "Kickball", "Australian Football", "Gaelic Football",
            "Hurling", "Kabaddi", "Sepak Takraw"
        ]
        sportTypesRef.setData(["types": defaultTypes]) { error in
            if let error = error {
                print("Error creating sport types: \(error)")
            } else {
                self.sportTypes = defaultTypes
                self.sportTypePickerView.reloadAllComponents()
            }
        }
    }
    
    // MARK: - Action Methods
    @IBAction func addPlayButtonTapped(_ sender: UIButton) {
        guard let eventName = eventNameTextField.text, !eventName.isEmpty,
              let eventAddress = eventAddressTextField.text, !eventAddress.isEmpty,
              let sportTypeIndex = sportTypePickerView.selectedRow(inComponent: 0) >= 0 ? sportTypePickerView.selectedRow(inComponent: 0) : nil,
              sportTypeIndex < sportTypes.count || sportTypeIndex == sportTypes.count // Check if user selected "Add New Sport"
        else {
            // At least one mandatory field is missing, show alert
            displayAlertForMissingFields()
            return
        }
        
        let sportType = sportTypes[sportTypeIndex]
        
        // Check if contactNumber is numeric
        guard let contactNumber = contactNumberTextField.text, !contactNumber.isEmpty, let _ = Double(contactNumber) else {
            displayAlert(message: "Contact number must be numeric.")
            return
        }
        
        let numberOfPlayers = Int(numberOfPlayersStepper.value)

        // Normalize college name to be used as document ID
        guard let collegeID = AppDelegate.shared.college?.replacingOccurrences(of: " ", with: "_"), !collegeID.isEmpty else {
            displayAlert(message: "College ID is empty. Please provide a valid college name.")
            return
        }

        // All mandatory fields are filled out and numeric, proceed to add the event to Firestore
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: datePicker.date)

        // Prepare data for Firestore
        let eventData: [String: Any] = [
            "eventName": eventName,
            "date": dateString,
            "contactNumber": contactNumber,
            "eventAddress": eventAddress,
            "sportType": sportType,
            "numberOfPlayers": numberOfPlayers,
            "notes": notesTextView.text ?? "",
            "createdBy": AppDelegate.shared.email ?? ""
        ]

        let db = Firestore.firestore()
        let eventsRef = db.collection("events").document(collegeID)
        
        eventsRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // Document exists, just add the event to the array
                eventsRef.updateData(["events": FieldValue.arrayUnion([eventData])]) { error in
                    if let error = error {
                        self.displayAlert(message: "Error adding event: \(error.localizedDescription)")
                    } else {
                        print("Event added successfully.")
                    }
                }
            } else {
                // Document does not exist, create it with the event data
                eventsRef.setData(["events": [eventData]]) { error in
                    if let error = error {
                        self.displayAlert(message: "Error creating events document: \(error.localizedDescription)")
                    } else {
                        print("Events document created successfully.")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    func displayAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func displayAlertForMissingFields() {
        let alert = UIAlertController(title: "Missing Fields", message: "Please fill out all mandatory fields.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}


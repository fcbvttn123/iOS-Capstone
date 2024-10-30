//
//  AccountManagement.swift
//  group-project
//
//  Created by Fizza Imran on 2024-10-25.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseStorage

class AccountManagement: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    let db = Firestore.firestore()
    let storage = Storage.storage()
    var sportTypes: [String] = []
    var selectedSport: String?
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var dateOfBirthPicker: UIDatePicker!
    @IBOutlet weak var sportTypePickerView: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProfileImageView()
        sportTypePickerView.delegate = self
        sportTypePickerView.dataSource = self
        fetchSportTypes() // Fetch available sport types from Firestore
    }
    
    // This function is used to make the keyboard disappear when we tap the "return" key
    private func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // Function to setup profile image view
    private func setupProfileImageView() {
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.layer.borderColor = UIColor.blue.cgColor
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.masksToBounds = true
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

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            if row == sportTypes.count { // Last item, "Add New Sport"
                presentAddNewSportAlert()
            } else {
                selectedSport = sportTypes[row]
            }
        }

        // MARK: - Fetch Sports from Firestore
        func fetchSportTypes() {
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

        // MARK: - Create Default Sports Types
        func createDefaultSportTypes() {
            let sportTypesRef = db.collection("sports").document("type")
            
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

        // MARK: - Add New Sport
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

        func addNewSport(_ sportName: String) {
            let sportTypesRef = db.collection("sports").document("type")
            sportTypesRef.updateData(["types": FieldValue.arrayUnion([sportName])]) { error in
                if let error = error {
                    self.displayAlert(message: "Error adding new sport: \(error.localizedDescription)")
                } else {
                    self.sportTypes.append(sportName)
                    self.sportTypePickerView.reloadAllComponents()
                    print("New sport added successfully.")
                }
            }
        }

    // MARK: - Upload User Info
        @IBAction func submitButtonTapped(_ sender: UIButton) {
            // Make username optional
            let username = usernameTextField.text?.isEmpty == true ? nil : usernameTextField.text

            let dateOfBirth = dateOfBirthPicker.date
            let formattedDate = DateFormatter.localizedString(from: dateOfBirth, dateStyle: .short, timeStyle: .none)

            // Use user ID instead of email
            guard let userID = AppDelegate.shared.currentUserUID else {
                print("No user ID in app delegate")
                displayAlert(message: "User not logged in.")
                return
            }

            let userDocumentRef = db.collection("users").document(userID)

            // Prepare user data to update
            var userData: [String: Any] = [
                "dateOfBirth": formattedDate,
                "preferredSport": selectedSport ?? ""
            ]
            
            // Include username only if it is not nil
            if let username = username {
                userData["username"] = username
            }

            // Update user info in Firestore
            userDocumentRef.setData(userData, merge: true) { error in
                if let error = error {
                    self.displayAlert(message: "Error updating user info: \(error.localizedDescription)")
                } else {
                    print("User info updated successfully.")
                    // Show success message and navigate back
                    let successAlert = UIAlertController(title: "Success", message: "\(username ?? "User")'s information updated.", preferredStyle: .alert)
                    successAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        // Perform segue back to home screen
                        self.performSegue(withIdentifier: "backToHome", sender: self)
                    }))
                    self.present(successAlert, animated: true, completion: nil)
                }
            }
        }

       // MARK: - Helper Methods
    func displayAlert(message: String) {
           let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
           present(alert, animated: true, completion: nil)
       }
    
    @IBAction func uploadButtonTapped(_ sender: UIButton) {
        print("Upload button tapped") // Debugging line
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        // Ensure presenting on the main thread
        DispatchQueue.main.async {
            self.present(imagePicker, animated: true, completion: nil)
        }
    }

    // Image picker delegate method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        
        // Display selected image in the profileImageView
        profileImageView.image = selectedImage
        
        // Upload image
        uploadProfileImage(selectedImage) { result in
            switch result {
            case .success:
                print("Profile image uploaded and URL saved to Firestore.")
            case .failure(let error):
                print("Error uploading profile image: \(error)")
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // Function to upload profile image
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let email = AppDelegate.shared.email else {
            print("User email not found.")
            return
        }
        
        // Convert image to data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error converting image to data.")
            return
        }
        
        // Create a reference to the Storage path for the profile image
        let imageRef = storage.reference().child("profileImages/\(email).jpg")
        
        // Upload the image data
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error)")
                completion(.failure(error))
                return
            }
            
            // Get the download URL for the uploaded image
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error)")
                    completion(.failure(error))
                    return
                }
                
                guard let url = url else {
                    print("Download URL is nil.")
                    return
                }
                
                // Update the user document with the image URL
                self.updateUserImageUrl(imageUrl: url.absoluteString) { result in
                    completion(result)
                }
            }
        }
    }
    
    // Function to update Firestore document with image URL
    private func updateUserImageUrl(imageUrl: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Use user ID instead of email
        guard let userID = AppDelegate.shared.currentUserUID else {
            print("No user ID in app delegate")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])))
            return
        }

        // Reference to the user's Firestore document
        let userRef = db.collection("users").document(userID)
        
        // Check if user document exists
        userRef.getDocument { (document, error) in
            if let error = error {
                print("Error checking for user document: \(error)")
                completion(.failure(error))
                return
            }
            
            // If the document does not exist, create a new one with user data
            if document == nil || !document!.exists {
                let userData: [String: Any] = [
                    "username": AppDelegate.shared.username ?? "",
                    "email": AppDelegate.shared.email ?? "",
                    "country": AppDelegate.shared.country ?? "",
                    "college": AppDelegate.shared.college ?? "",
                    "imgUrl": imageUrl
                ]
                
                userRef.setData(userData) { error in
                    if let error = error {
                        print("Error creating user document: \(error)")
                        completion(.failure(error))
                    } else {
                        print("User document created successfully with profile image URL.")
                        completion(.success(()))
                    }
                }
            } else {
                // Update only the `imgUrl` field if document already exists
                userRef.updateData(["imgUrl": imageUrl]) { error in
                    if let error = error {
                        print("Error updating user document with image URL: \(error)")
                        completion(.failure(error))
                    } else {
                        print("User document updated successfully with profile image URL.")
                        completion(.success(()))
                    }
                }
            }
        }
    }

}


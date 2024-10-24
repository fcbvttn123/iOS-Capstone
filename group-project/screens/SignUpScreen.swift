import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpScreen: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var universityLabel: UILabel!
    @IBOutlet weak var addUniversityButton: UIButton!
    @IBOutlet weak var signIn: UIButton!

    var countries: [[String: String]] = []
    var universities: [[String: Any]] = []
    var filteredUniversities: [[String: Any]] = []

    var selectedCountry: String?
    var selectedUniversity: String?
    var institute: String?
    
    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add tap gesture recognizers
        let countryTapGesture = UITapGestureRecognizer(target: self, action: #selector(showCountryDropdown))
        countryLabel.isUserInteractionEnabled = true
        countryLabel.addGestureRecognizer(countryTapGesture)

        let universityTapGesture = UITapGestureRecognizer(target: self, action: #selector(showUniversityDropdown))
        universityLabel.isUserInteractionEnabled = true
        universityLabel.addGestureRecognizer(universityTapGesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("Email set in AppDelegate: \(AppDelegate.shared.email ?? "No email set")")
        
    }
    
    @IBAction func signIn(_ sender: UIButton) {
        self.performSegue(withIdentifier: "toSignIn", sender: self)
    }
    
    @IBAction func addUniversityTapped(_ sender: UIButton) {
        promptToAddUniversity()
    }
    
    @IBOutlet var email: UITextField!
    @IBOutlet var password: UITextField!
    
    @IBAction func signUp(sender: Any) {
        let emailText = AppDelegate.shared.email
        guard let emailText = emailText, !emailText.isEmpty,
              let passwordText = password.text, !passwordText.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Please enter both email and password", preferredStyle: .alert)
            let closeAlertAction = UIAlertAction(title: "Close", style: .cancel)
            alert.addAction(closeAlertAction)
            self.present(alert, animated: true)
            return
        }
        
        // Extract domain from email
        let emailComponents = emailText.split(separator: "@")
        guard emailComponents.count == 2, let domain = emailComponents.last else {
            showAlert(withTitle: "Error", message: "Invalid email format.")
            return
        }
        
        // Check Firestore for matching university domain
        checkUniversityDomainInFirestore(domain: String(domain)) { university, country in
            if let university = university, let country = country {
                // Update UI with found university and country
                self.universityLabel.text = university
                self.countryLabel.text = country
                self.institute = university
            } else {
                // Fallback: Allow user to select manually
                self.promptToAddUniversity()
            }
        }
    }
    
    // Check Firestore for matching university domain
    func checkUniversityDomainInFirestore(domain: String, completion: @escaping (String?, String?) -> Void) {
        let universitiesRef = db.collection("universities")
        
        // Iterate through all documents to find matching domain
        universitiesRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching universities: \(error)")
                completion(nil, nil)
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(nil, nil)
                return
            }
            
            for document in documents {
                let data = document.data()
                if let universities = data["universities"] as? [[String: Any]] {
                    for university in universities {
                        if let universityDomains = university["domains"] as? [String], universityDomains.contains(domain) {
                            let universityName = university["name"] as? String
                            let countryName = university["country"] as? String
                            completion(universityName, countryName)
                            return
                        }
                    }
                }
            }
            completion(nil, nil)  // No match found
        }
    }
    
    // Manual prompt to add university if no match is found
    func promptToAddUniversity() {
        let alert = UIAlertController(title: "Add University", message: "Enter the name of the university", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "University Name"
        }
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            if let newUniversity = alert.textFields?.first?.text, !newUniversity.isEmpty {
                self.selectedUniversity = newUniversity
                self.universityLabel.text = self.selectedUniversity
                self.institute = newUniversity  // Store new university in 'institute'
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    // Function to update universities based on selected country
    func updateUniversities(for country: String) {
        filteredUniversities = universities.filter { university in
            guard let universityCountry = university["country"] as? String else { return false }
            return universityCountry == country
        }
    }
    
    // Dropdown for selecting country
       @objc func showCountryDropdown() {
           let alert = UIAlertController(title: "Select a Country", message: nil, preferredStyle: .actionSheet)
           
           for country in countries {
               let action = UIAlertAction(title: country["name"], style: .default) { _ in
                   self.selectedCountry = country["name"]
                   self.countryLabel.text = self.selectedCountry
                   self.updateUniversities(for: self.selectedCountry!)
               }
               alert.addAction(action)
           }
           
           let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
           alert.addAction(cancelAction)
           
           present(alert, animated: true, completion: nil)
       }

    // Dropdown for selecting university
    @objc func showUniversityDropdown() {
        guard let selectedCountry = selectedCountry else {
            let alert = UIAlertController(title: "Error", message: "Please select a country first", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alert.addAction(okAction)
            present(alert, animated: true)
            return
        }
        
        let alert = UIAlertController(title: "Select a University", message: nil, preferredStyle: .actionSheet)
        
        for university in filteredUniversities {
            if let universityName = university["name"] as? String {
                let action = UIAlertAction(title: universityName, style: .default) { _ in
                    self.selectedUniversity = universityName
                    self.universityLabel.text = self.selectedUniversity
                    self.institute = universityName
                }
                alert.addAction(action)
            }
        }
        
        let addUniversityAction = UIAlertAction(title: "Add University", style: .default) { _ in
            self.promptToAddUniversity()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        alert.addAction(addUniversityAction)
        
        present(alert, animated: true, completion: nil)
    }

    
    func validatePassword(_ password: String) -> (isValid: Bool, message: String) {
        if password.count < 6 {
            return (false, "Password must be at least 6 characters.")
        }
        return (true, "")
    }

    func showAlert(withTitle title: String, message: String) {
        if title == "Success" {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let closeAction = UIAlertAction(title: "Continue", style: .default) { _ in
                self.goToSignIn()
            }
            alert.addAction(closeAction)
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let closeAction = UIAlertAction(title: "Close", style: .cancel)
            alert.addAction(closeAction)
            present(alert, animated: true)
        }
    }

    
    func goToSignIn(){
        self.performSegue(withIdentifier: "toSignIn", sender: self)
    }
        
    
    func styleLabels() {
        // Add styling code for labels if needed
    }
}



import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpScreen: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var countryButton: UIButton!
    @IBOutlet weak var universityButton: UIButton!
    @IBOutlet weak var addUniversityButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet var emailfield: UITextField!
    @IBOutlet var password: UITextField!


    var countries: [[String: String]] = []
    var universities: [[String: Any]] = []
    var filteredUniversities: [[String: Any]] = []

    var selectedCountry: String?
    var selectedUniversity: String?
    var institute: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the email from AppDelegate
        let email = AppDelegate.shared.email
        let emailComponents = email?.split(separator: "@")
        emailfield.text = email
        if emailComponents?.count == 2, let domain = emailComponents?.last {
            fetchUniversities(for: String(domain))
            loadCountries()
        }
        styleButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showEmailVerificationAlert()
    }

    func showEmailVerificationAlert() {
        let alert = UIAlertController(title: "Email Verified", message: "Your email has been successfully verified. Please continue to make an account.", preferredStyle: .alert)
        let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
        alert.addAction(continueAction)
        present(alert, animated: true, completion: nil)
    }

    func fetchUniversities(for domain: String) {
        let db = Firestore.firestore()
        db.collection("universities").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching universities: \(error)")
                return
            }
            
            print("Fetched Universities Snapshot: \(String(describing: snapshot))") // Print the snapshot
            
            for document in snapshot!.documents {
                print("Document ID: \(document.documentID), Data: \(document.data())") // Print each document's data
                
                if let universitiesArray = document.data()["universities"] as? [[String: Any]] {
                    for university in universitiesArray {
                        if let domains = university["domains"] as? [String],
                           domains.contains(domain) {
                            let universityName = university["name"] as? String
                            let countryName = university["country"] as? String
                            
                            // Update the button titles and institute
                            self.universityButton.setTitle(universityName, for: .normal)
                            self.countryButton.setTitle(countryName, for: .normal)
                            self.institute = universityName // Set institute here
                            self.selectedCountry = countryName
                            self.selectedUniversity = universityName
                            print("University found: \(universityName ?? "") in country: \(countryName ?? "")") // Print found university
                            return
                        }
                    }
                } else {
                    print("No universities found in document: \(document.documentID)") // Print if no universities found
                }
            }
            print("No matching universities found for domain: \(domain)") // Print if no matching university found
        }
    }

    func loadCountries() {
        let db = Firestore.firestore()
        db.collection("countries").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching countries: \(error)")
                return
            }
            
            for document in snapshot!.documents {
                if let name = document.data()["name"] as? String,
                   let code = document.data()["code"] as? String {
                    self.countries.append(["name": name, "code": code])
                }
            }
        }
    }

    @IBAction func signInButtonTapped(_ sender: UIButton) {
        self.performSegue(withIdentifier: "toSignIn", sender: self)
    }
    
    @IBAction func addUniversityButtonTapped(_ sender: UIButton) {
        promptToAddUniversity()
    }
    
    @IBAction func showCountryDropdown(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Select Country", message: nil, preferredStyle: .actionSheet)

        for country in countries {
            if let name = country["name"] {
                let action = UIAlertAction(title: name, style: .default) { [weak self] _ in
                    self?.selectedCountry = name
                    self?.countryButton.setTitle(name, for: .normal)  // Updated to set button title
                    self?.updateUniversities(for: name)
                }
                alertController.addAction(action)
            }
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func showUniversityDropdown(_ sender: UIButton) {
        guard let selectedCountry = selectedCountry else {
            let alert = UIAlertController(title: "Error", message: "Please select a country first", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alert.addAction(okAction)
            present(alert, animated: true)
            return
        }
        
        updateUniversities(for: selectedCountry)

        let alert = UIAlertController(title: "Select a University", message: nil, preferredStyle: .actionSheet)

        for university in filteredUniversities {
            if let universityName = university["name"] as? String {
                let action = UIAlertAction(title: universityName, style: .default) { _ in
                    self.selectedUniversity = universityName
                    self.universityButton.setTitle(universityName, for: .normal)  // Updated to set button title
                    self.institute = universityName
                }
                alert.addAction(action)
            }
        }
        
        let addUniversityAction = UIAlertAction(title: "Add University", style: .default) { _ in
            self.promptToAddUniversity()
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(addUniversityAction)

        present(alert, animated: true, completion: nil)
    }

    func promptToAddUniversity() {
        let alert = UIAlertController(title: "Add University", message: "Enter the name of the university", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "University Name"
        }
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            if let newUniversity = alert.textFields?.first?.text, !newUniversity.isEmpty {
                self.selectedUniversity = newUniversity
                self.universityButton.setTitle(newUniversity, for: .normal)
                self.institute = newUniversity
                self.addUniversityToFirestore(universityName: newUniversity)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(addAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    func addUniversityToFirestore(universityName: String) {
        let db = Firestore.firestore()
        
        // Extract domain from the selected university
        guard let selectedCountry = selectedCountry else { return }
        let sanitizedCountryName = selectedCountry.replacingOccurrences(of: " ", with: "_").lowercased()
        
        // Check the university document for the selected country
        let universityRef = db.collection("universities").document(sanitizedCountryName)
        
        universityRef.updateData([
            "universities": FieldValue.arrayUnion([[
                "name": universityName,
                "domains": [String(describing: AppDelegate.shared.email?.split(separator: "@").last)],
                "country": selectedCountry,
                "state-province": NSNull(),
                "web_pages": [NSNull()]
            ]])
        ]) { error in
            if let error = error {
                print("Error adding university: \(error)")
            } else {
                print("University added successfully!")
            }
        }
    }

    func updateUniversities(for country: String) {
        let sanitizedCountryName = country.replacingOccurrences(of: " ", with: "_").lowercased()
        let db = Firestore.firestore()
        
        db.collection("universities").document(sanitizedCountryName).getDocument { (document, error) in
            if let error = error {
                print("Error fetching universities: \(error)")
                return
            }
            guard let data = document?.data(), let universitiesArray = data["universities"] as? [[String: Any]] else {
                print("No universities found for country: \(country)")
                return
            }
            self.filteredUniversities = universitiesArray
            print("Filtered Universities: \(self.filteredUniversities)")
        }
    }

    @IBAction func signUp(sender: Any) {
        guard let emailText = emailfield.text, !emailText.isEmpty,
              let passwordText = password.text, !passwordText.isEmpty else {
            showAlert(withTitle: "Error", message: "Please enter both email and password.")
            return
        }
        
        // Check email domain
        let emailComponents = emailText.split(separator: "@")
        guard emailComponents.count == 2, let domain = emailComponents.last else {
            showAlert(withTitle: "Error", message: "Invalid email format.")
            return
        }
        
        // Fetch universities by domain first
        fetchUniversities(for: String(domain)) { [weak self] universities in
            guard let self = self else { return }
            
            // Ensure that a university is selected
            guard let selectedUniversity = self.selectedUniversity else {
                self.showAlert(withTitle: "Error", message: "Please select a university.")
                return
            }
            
            // Check if the selected university's domain matches the email domain
            let matchingUniversity = universities.first { university in
                if let universityName = university["name"] as? String,
                   let domains = university["domains"] as? [String] {
                    return universityName == selectedUniversity && domains.contains(String(domain))
                }
                return false
            }
            
            if matchingUniversity != nil {
                // Proceed with account creation if the email domain is valid
                Auth.auth().createUser(withEmail: emailText, password: passwordText) { authResult, error in
                    if let error = error {
                        self.showAlert(withTitle: "Error", message: error.localizedDescription)
                    } else {
                        if AppDelegate.shared.isEmailVerified {
                            self.showAlert(withTitle: "Success", message: "Account created successfully.")
                        }
                    }
                }
            } else {
                self.showAlert(withTitle: "Error", message: "Please use your University Email for \(selectedUniversity).")
            }
        }
    }


    func fetchUniversities(for domain: String, completion: @escaping ([[String: Any]]) -> Void) {
        let db = Firestore.firestore()
        db.collection("universities").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching universities: \(error)")
                completion([])
                return
            }
            
            var universitiesArray: [[String: Any]] = []
            for document in snapshot!.documents {
                if let universitiesData = document.data()["universities"] as? [[String: Any]] {
                    universitiesArray.append(contentsOf: universitiesData)
                }
            }
            completion(universitiesArray)
        }
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
        
    
    func styleButtons() {
            // Style your buttons here if needed
            // For example, setting title color, background color, etc.
            countryButton.setTitleColor(.systemBlue, for: .normal)
            universityButton.setTitleColor(.systemBlue, for: .normal)
            addUniversityButton.setTitleColor(.systemBlue, for: .normal)
            signInButton.setTitleColor(.systemBlue, for: .normal)
        }
}



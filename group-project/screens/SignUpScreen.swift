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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load JSON data
        loadCountries()
        loadUniversities()
        styleLabels()

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
        
        // Show the verification alert when the view appears
        showEmailVerificationAlert()
    }

    // Function to show email verification alert
    func showEmailVerificationAlert() {
        let alert = UIAlertController(title: "Email Verified", message: "Your email has been successfully verified. Please continue to make an account.", preferredStyle: .alert)
        let continueAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
        alert.addAction(continueAction)
        present(alert, animated: true, completion: nil)
    }

    // Load Countries and Universities JSON files
    func loadCountries() {
        if let path = Bundle.main.path(forResource: "countries", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let array = json as? [[String: String]] {
                    self.countries = array
                }
            } catch {
                print("Error loading countries: \(error)")
            }
        }
    }

    func loadUniversities() {
        if let path = Bundle.main.path(forResource: "world_universities_and_domains", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let array = json as? [[String: Any]] {
                    self.universities = array
                }
            } catch {
                print("Error loading universities: \(error)")
            }
        }
    }

    @IBAction func signIn(_ sender: UIButton) {
        self.performSegue(withIdentifier: "toSignIn", sender: self)
    }
    @IBAction func addUniversityTapped(_ sender: UIButton) {
        promptToAddUniversity()
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
                if let selectedUniversity = self.selectedUniversity, !selectedUniversity.isEmpty {
                    AppDelegate.shared.homeCampus = selectedUniversity
                } else if let institute = self.institute {
                    AppDelegate.shared.homeCampus = institute
                }
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(addAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    func updateUniversities(for country: String) {
        filteredUniversities = universities.filter { university in
            guard let universityCountry = university["country"] as? String else { return false }
            return universityCountry == country
        }
    }

    @IBOutlet var email: UITextField!
    @IBOutlet var password: UITextField!

    @IBAction func signUp(sender: Any) {
        guard let emailText = email.text, !emailText.isEmpty,
              let passwordText = password.text, !passwordText.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Please enter both email and password", preferredStyle: .alert)
            let closeAlertAction = UIAlertAction(title: "Close", style: .cancel)
            alert.addAction(closeAlertAction)
            self.present(alert, animated: true)
            return
        }
        
        // Check email domain
        let emailComponents = emailText.split(separator: "@")
        guard emailComponents.count == 2, let domain = emailComponents.last else {
            showAlert(withTitle: "Error", message: "Invalid email format.")
            return
        }
        
        // Check if the domain matches any university domain
        var isValidDomain = false
        for university in universities {
            if let universityDomains = university["domains"] as? [String],
               universityDomains.contains(String(domain)) {
                isValidDomain = true
                break
            }
        }
        
        if !isValidDomain {
            let alert = UIAlertController(title: "Error", message: "Please use your University Email (\(self.institute ?? "unknown university"))", preferredStyle: .alert)
            let closeAction = UIAlertAction(title: "Close", style: .cancel)
            alert.addAction(closeAction)
            present(alert, animated: true)
            return
        }
        
        // Password validation
        let passwordValidationResult = validatePassword(passwordText)
        if !passwordValidationResult.isValid {
            let alert = UIAlertController(title: "Error", message: passwordValidationResult.message, preferredStyle: .alert)
            let closeAction = UIAlertAction(title: "Close", style: .cancel)
            alert.addAction(closeAction)
            present(alert, animated: true)
            return
        }

        // Check if the email already exists
        Auth.auth().fetchSignInMethods(forEmail: emailText) { signInMethods, error in
            if let error = error {
                self.showAlert(withTitle: "Error", message: error.localizedDescription)
                return
            }
            
            if let signInMethods = signInMethods, !signInMethods.isEmpty {
                // Account already exists
                let alert = UIAlertController(title: "Account Exists", message: "Account with \(emailText) already exists.", preferredStyle: .alert)
                let signInAction = UIAlertAction(title: "Sign In", style: .default) { _ in
                    self.goToSignIn()
                }
                alert.addAction(signInAction)
                let closeAlertAction = UIAlertAction(title: "Close", style: .cancel)
                alert.addAction(closeAlertAction)
                self.present(alert, animated: true)
            } else {
                // Create a new account
                Auth.auth().createUser(withEmail: emailText, password: passwordText) { authResult, error in
                    if let error = error {
                        self.showAlert(withTitle: "Error", message: error.localizedDescription)
                    } else {
                        if(AppDelegate.shared.isEmailVerified == true){
                            self.showAlert(withTitle: "Success", message: "Account created successfully.")
                        }
                    }
                }
            }
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
        
    
    func styleLabels() {
        // Add styling code for labels if needed
    }
}



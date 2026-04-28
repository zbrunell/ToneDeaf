// Project: ToneDeaf
// EID: ztb456
// Course: CS329E

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: BaseViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!

    var db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()

        passwordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTheme),
            name: Notification.Name("darkModeChanged"),
            object: nil
        )

        updateTheme()
    }
    
    @objc func updateTheme() {
        // Applies dark mode settings to styling in labels and texts
        let isDark = darkMode.isDarkMode

        view.backgroundColor = isDark ? .black : .white
        titleLabel.textColor = isDark ? .white : .black

        emailTextField.textColor = isDark ? .white : .black
        passwordTextField.textColor = isDark ? .white : .black
        confirmPasswordTextField.textColor = isDark ? .white : .black

        emailTextField.attributedPlaceholder = NSAttributedString(
            string: emailTextField.placeholder ?? "",
            attributes: [.foregroundColor: isDark ? UIColor.white : UIColor.black]
        )

        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: passwordTextField.placeholder ?? "",
            attributes: [.foregroundColor: isDark ? UIColor.white : UIColor.black]
        )

        confirmPasswordTextField.attributedPlaceholder = NSAttributedString(
            string: confirmPasswordTextField.placeholder ?? "",
            attributes: [.foregroundColor: isDark ? UIColor.white : UIColor.black]
        )
    }

    @IBAction func signUpPressed(_ sender: Any) {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty,
              let password = passwordTextField.text,
              !password.isEmpty,
              let confirm = confirmPasswordTextField.text,
              !confirm.isEmpty else {
            showAlert(message: "Please fill in all fields.")
            return
        }

        guard password == confirm else {
            showAlert(message: "Passwords do not match.")
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.showAlert(message: error.localizedDescription)
                return
            }

            guard let uid = result?.user.uid else {
                self.showAlert(message: "Could not create user.")
                return
            }

            let baseUsername = email.components(separatedBy: "@")[0]
            self.createUniqueUsername(baseUsername: baseUsername, uid: uid, email: email)
        }
    }
        
    func createUniqueUsername(baseUsername: String, uid: String, email: String) {
        // Attempts to create a unique username by appending a number if needed.
        // Recursively checks Firestore until an unused username is found.
        var username = baseUsername
        var counter = 1

        func tryUsername() {
            db.collection("usernames").document(username).getDocument { snapshot, error in
                if let error = error {
                    self.showAlert(message: error.localizedDescription)
                    return
                }

                if snapshot?.exists == true {
                    username = "\(baseUsername)\(counter)"
                    counter += 1
                    tryUsername()
                } else {
                    self.saveUser(uid: uid, email: email, username: username)
                }
            }
        }

        tryUsername()
    }

    func saveUser(uid: String, email: String, username: String) {
            // Uses a Firestore batch write to:
            // 1. Create the user document with default app settings
            // 2. Reserve the username in a separate collection for uniqueness
        let batch = db.batch()

        let userRef = db.collection("users").document(uid)
        let usernameRef = db.collection("usernames").document(username)

        batch.setData([
            "email": email,
            "username": username,
            "instrument": "Electric Guitar",
            "tuning": "Standard",
            "referencePitch": 440
        ], forDocument: userRef)

        batch.setData([
            "uid": uid,
            "email": email
        ], forDocument: usernameRef)

        batch.commit { error in
            if let error = error {
                self.showAlert(message: error.localizedDescription)
                return
            }

            self.performSegue(withIdentifier: "signUpToMain", sender: nil)
        }
    }

    func showAlert(message: String) {
        // Displays a simple error alert to the user during sign-up
        let alert = UIAlertController(title: "Sign Up Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

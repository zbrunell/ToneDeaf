// Project: ToneDeaf
// EID: ztb456
// Course: CS329E

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: BaseViewController, UITextFieldDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        guard let loginText = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !loginText.isEmpty,
              let password = passwordTextField.text,
              !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email/username and password.")
            return
        }
        
        if loginText.contains("@") {
            signInWithEmail(email: loginText, password: password)
        } else {
            signInWithUsername(username: loginText.lowercased(), password: password)
        }
    }
    
    func signInWithEmail(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if error != nil {
                self.showAlert(
                    title: "Login Failed",
                    message: "The username/email or password you entered is incorrect."
                )
                return
            }
            
            self.syncEmailIfNeeded {
                self.performSegue(withIdentifier: "loginToMain", sender: nil)
            }
        }
    }
    
    func signInWithUsername(username: String, password: String) {
        // Looks up the username in Firestore, retrieves the linked email, then signs in normally.
        let db = Firestore.firestore()
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        db.collection("usernames").document(cleanUsername).getDocument { snapshot, error in
            
            if error != nil {
                self.showAlert(title: "Login Failed",
                               message: "Could not check that username. Please try again.")
                return
            }
            
            guard let data = snapshot?.data(),
                  let email = data["email"] as? String else {
                self.showAlert(title: "Login Failed",
                               message: "No account was found with that username.")
                return
            }
            
            self.signInWithEmail(email: email, password: password)
        }
    }
    
    @IBAction func createAccountPressed(_ sender: Any) {
        performSegue(withIdentifier: "toCreateAccount", sender: nil)
    }
    
    @IBAction func forgotPasswordPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Reset Password",
                                      message: "Enter your email or username.",
                                      preferredStyle: .alert)
        
        alert.addTextField { field in
            field.placeholder = "Email or Username"
            field.keyboardType = .emailAddress
            field.textColor = .black
        }
        
        alert.addAction(UIAlertAction(title: "Send", style: .default) { _ in
            guard let loginText = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !loginText.isEmpty else {
                return
            }
            
            if loginText.contains("@") {
                self.sendResetEmail(email: loginText)
            } else {
                self.findEmailForUsername(username: loginText) { email in
                    if let email = email {
                        self.sendResetEmail(email: email)
                    } else {
                        self.showAlert(title: "Error", message: "No account found with that username.")
                    }
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func sendResetEmail(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
            } else {
                self.showAlert(title: "Sent", message: "Password reset email sent.")
            }
        }
    }
    
    func findEmailForUsername(username: String, completion: @escaping (String?) -> Void) {
        // Converts a username into its linked email
        let db = Firestore.firestore()
        let cleanUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        db.collection("usernames").document(cleanUsername).getDocument { snapshot, error in
            if error != nil {
                completion(nil)
                return
            }
            
            let email = snapshot?.data()?["email"] as? String
            completion(email)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            passwordTextField.resignFirstResponder()
            loginButtonPressed(textField)
        }
        
        return true
    }    // Called when the user clicks on the view outside of the UITextField
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        emailTextField.returnKeyType = .next
        passwordTextField.returnKeyType = .go
        passwordTextField.isSecureTextEntry = true
        
        emailTextField.textColor = .white
        passwordTextField.textColor = .white
        titleLabel.textColor = .white
        
        styleTextField(emailTextField)
        styleTextField(passwordTextField)
        
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: emailTextField.placeholder ?? "",
            attributes: [.foregroundColor: UIColor.white]
        )
        
        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: passwordTextField.placeholder ?? "",
            attributes: [.foregroundColor: UIColor.white]
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTheme),
            name: Notification.Name("darkModeChanged"),
            object: nil
        )
        
        updateTheme()
    }
    
    @objc func updateTheme() {
        // Applies dark/light mode styling to labels, fields, and buttons
        let isDark = darkMode.isDarkMode
        
        view.backgroundColor = isDark ? .black : .white
        titleLabel.textColor = isDark ? .white : .black
        
        emailTextField.textColor = isDark ? .white : .black
        passwordTextField.textColor = isDark ? .white : .black
        
        var config = UIButton.Configuration.plain()
        config.title = "Create Account"
        config.baseForegroundColor = .black
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 10,
            leading: 20,
            bottom: 10,
            trailing: 20
        )
        
        createAccountButton.configuration = config
        createAccountButton.backgroundColor = .white
        createAccountButton.layer.cornerRadius = createAccountButton.frame.height / 2
        createAccountButton.layer.borderWidth = 0
        createAccountButton.clipsToBounds = true
        createAccountButton.layer.cornerRadius = 10
    }
    
    func styleTextField(_ textField: UITextField) {
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.clipsToBounds = true
        
        textField.backgroundColor = .clear
        textField.setLeftPaddingPoints(10)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if Auth.auth().currentUser != nil {
            syncEmailIfNeeded {
                self.performSegue(withIdentifier: "loginToMain", sender: nil)
            }
        }
    }
    
    func syncEmailIfNeeded(completion: @escaping () -> Void) {
        guard let user = Auth.auth().currentUser,
              let authEmail = user.email else {
            completion()
            return
        }
        
        let uid = user.uid
        let db = Firestore.firestore()
        
        db.collection("users").document(uid).getDocument { snapshot, _ in
            let data = snapshot?.data()
            let firestoreEmail = data?["email"] as? String
            let username = data?["username"] as? String
            
            if firestoreEmail != authEmail {
                db.collection("users").document(uid).updateData([
                    "email": authEmail
                ])
            }
            
            if let username = username {
                db.collection("usernames").document(username).updateData([
                    "email": authEmail
                ]) { _ in
                    completion()
                }
            } else {
                completion()
            }
        }
    }
}
extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        // Adds spacing inside the left side of a text field.
        let paddingView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: amount,
                height: self.frame.size.height
                )
            )

            self.leftView = paddingView
            self.leftViewMode = .always
        }
    }



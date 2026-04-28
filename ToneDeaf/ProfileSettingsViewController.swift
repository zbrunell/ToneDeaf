// Project: ToneDeaf
// EID: ztb456
// Course: CS329E

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileSettingsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    var currentUsername = ""
    let settingsItems = [
        "Edit Profile Picture",
        "Username",
        "Update Email",
        "Dark Mode",
        "Tuning Settings",
        "Microphone Permissions"
    ]
    
    var db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.rowHeight = 58
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        tableView.isScrollEnabled = false
        
        setupProfileImage()
        applyDarkModeSetting()
        
        setupDefaultUsername()
        loadCurrentUsername()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
        
        profileImageView.layer.borderWidth = 2
    }
    
    // MARK: - Table Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsItems.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        let item = settingsItems[indexPath.row]
        let isDark = darkMode.isDarkMode
        
        var config: UIListContentConfiguration
        
        if item == "Username" {
            config = UIListContentConfiguration.valueCell()
            config.text = "Username"
            config.secondaryText = currentUsername
            config.image = UIImage(systemName: "person")
            config.secondaryTextProperties.color = isDark ? .white : .black
        } else {
            config = cell.defaultContentConfiguration()
            config.text = item
            
            if item == "Edit Profile Picture" {
                config.image = UIImage(systemName: "person.crop.circle")
            } else if item == "Update Email" {
                config.image = UIImage(systemName: "envelope")
            } else if item == "Dark Mode" {
                config.image = UIImage(systemName: "moon")
            } else if item == "Tuning Settings" {
                config.image = UIImage(systemName: "slider.horizontal.3")
            } else if item == "Microphone Permissions" {
                config.image = UIImage(systemName: "mic")
            }
        }
        
        config.textProperties.color = isDark ? .white : .black
        config.textProperties.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        config.imageProperties.tintColor = .systemIndigo
        
        cell.backgroundColor = isDark ? .black : .white
        config.textProperties.color = isDark ? .white : .black
        config.imageProperties.tintColor = isDark ? .white : .black
        
        let selectedView = UIView()
        selectedView.backgroundColor = isDark
            ? UIColor(white: 0.15, alpha: 1)
            : UIColor(white: 0.90, alpha: 1)

        cell.selectedBackgroundView = selectedView
        
        if item == "Dark Mode" {
            let darkSwitch = UISwitch()
            darkSwitch.isOn = isDark

            // ON color
            darkSwitch.onTintColor = .systemIndigo

            // OFF color (make body visible)
            darkSwitch.backgroundColor = isDark ? .white : .black
            darkSwitch.layer.cornerRadius = 16
            darkSwitch.clipsToBounds = true

            // Thumb
            darkSwitch.thumbTintColor = isDark ? .black : .white

            darkSwitch.addTarget(self, action: #selector(darkModeSwitchToggled(_:)), for: .valueChanged)

            cell.accessoryView = darkSwitch
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }  else {
            let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            chevron.tintColor = isDark ? .lightGray : .darkGray
            chevron.contentMode = .scaleAspectFit

            cell.accessoryView = chevron
            cell.accessoryType = .none
            cell.selectionStyle = .default
        }
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = settingsItems[indexPath.row]
        
        if item == "Edit Profile Picture" {
            uploadPhotoPressed()
        } else if item == "Username" {
            updateUsernamePressed()
        } else if item == "Update Email"{
            updateEmailPressed()
        } else if item == "Tuning Settings" {
            tuningSettingsPressed(self)
        } else if item == "Microphone Permissions" {
            microphonePermissionsPressed(self)
        }
    }
    
    // MARK: - Profile Image
    
    func setupProfileImage() {
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        
        if let data = UserDefaults.standard.data(forKey: "profileImage"),
           let savedImage = UIImage(data: data) {
            profileImageView.image = savedImage
        } else {
            profileImageView.image = UIImage(named: "defaultProfile")
        }
    }
    
    func saveProfileImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: "profileImage")
        }
    }
    
    func uploadPhotoPressed() {
        let alert = UIAlertController(title: "Profile Photo", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
                self.presentImagePicker(source: .camera)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { _ in
            self.presentImagePicker(source: .photoLibrary)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func presentImagePicker(source: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = source
        present(picker, animated: true)
    }
    
    // MARK: - Dark Mode
    
    @objc func darkModeSwitchToggled(_ sender: UISwitch) {
        darkMode.isDarkMode = sender.isOn
        applyDarkModeSetting()
        NotificationCenter.default.post(name: Notification.Name("darkModeChanged"), object: nil)
    }

    func applyDarkModeSetting() {
        if UserDefaults.standard.object(forKey: "darkMode") == nil {
            UserDefaults.standard.set(true, forKey: "darkMode")
        }

        let isDark = darkMode.isDarkMode

        view.backgroundColor = isDark ? .black : .white
        tableView.backgroundColor = isDark ? .black : .white

        profileImageView.layer.borderColor = isDark
            ? UIColor.white.cgColor
            : UIColor.black.cgColor

        tableView.reloadData()
    }
    
    // MARK: - Username
    
    // Ensures the current user has a default username.
    // If none exists in Firestore, derives one from email and finds an available variant.
    func setupDefaultUsername() {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            return
        }
        
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let existingUsername = data["username"] as? String,
               !existingUsername.isEmpty {
                return
            }
            
            let defaultUsername = email.components(separatedBy: "@")[0].lowercased()
            self.findAvailableUsername(base: defaultUsername, attempt: 0, user: user, email: email)
        }
    }
    
    // Recursively searches for an available username by appending a number if needed.
    // Once found, stores it in both `usernames` (for uniqueness) and `users` collections.
    //
    // - Parameters:
    //   - base: Base username derived from email
    //  - attempt: Current numeric suffix attempt
    //  - user: Firebase authenticated user
    //   - email: User's email for record storage
    func findAvailableUsername(base: String, attempt: Int, user: User, email: String) {
        let username = attempt == 0 ? base : "\(base)\(attempt)"
        
        db.collection("usernames").document(username).getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                self.findAvailableUsername(base: base, attempt: attempt + 1, user: user, email: email)
            } else {
                self.db.collection("usernames").document(username).setData([
                    "uid": user.uid,
                    "email": email
                ])
                
                self.db.collection("users").document(user.uid).setData([
                    "username": username,
                    "email": email
                ], merge: true)
                
                self.currentUsername = username
                self.tableView.reloadData()
            }
        }
    }
    
    // Fetches the current username from Firestore and updates the UI
    func loadCurrentUsername() {
        guard let user = Auth.auth().currentUser else { return }
        
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let username = data["username"] as? String {
                self.currentUsername = username
                self.tableView.reloadData()
            }
        }
    }
    
    func updateUsernamePressed() {
        let alert = UIAlertController(title: "Update Username",
                                      message: "Enter your new username.",
                                      preferredStyle: .alert)

        alert.addTextField { field in
            field.placeholder = "Username"
            field.autocapitalizationType = .none
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            guard let newUsername = alert.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
                  !newUsername.isEmpty,
                  let user = Auth.auth().currentUser,
                  let email = user.email else {
                return
            }

            self.db.collection("users").document(user.uid).getDocument { userSnapshot, error in
                let oldUsername = userSnapshot?.data()?["username"] as? String

                if oldUsername == newUsername {
                    self.showAlert(title: "No Change", message: "That is already your username.")
                    return
                }

                self.db.collection("usernames").document(newUsername).getDocument { usernameSnapshot, error in
                    if let usernameSnapshot = usernameSnapshot,
                       usernameSnapshot.exists {
                        let ownerUid = usernameSnapshot.data()?["uid"] as? String

                        if ownerUid != user.uid {
                            self.showAlert(title: "Username Taken", message: "Please choose another username.")
                            return
                        }
                    }

                    self.db.collection("usernames").document(newUsername).setData([
                        "uid": user.uid,
                        "email": email
                    ]) { error in
                        if let error = error {
                            self.showAlert(title: "Error", message: error.localizedDescription)
                            return
                        }

                        self.db.collection("users").document(user.uid).setData([
                            "username": newUsername,
                            "email": email
                        ], merge: true) { error in
                            if let error = error {
                                self.showAlert(title: "Error", message: error.localizedDescription)
                                return
                            }

                            if let oldUsername = oldUsername,
                               !oldUsername.isEmpty,
                               oldUsername != newUsername {
                                self.db.collection("usernames").document(oldUsername).delete()
                            }

                            self.currentUsername = newUsername
                            self.tableView.reloadData()
                            self.showAlert(title: "Saved", message: "Username updated.")
                        }
                    }
                }
            }
        })

        present(alert, animated: true)
    }
    
    // MARK: - Update Email
    
    func updateEmail(newEmail: String) {
        guard let user = Auth.auth().currentUser else { return }

        user.sendEmailVerification(beforeUpdatingEmail: newEmail) { error in
            if error != nil {
                self.showAlert(
                    title: "Error",
                    message: "Could not send verification email. Try again."
                )
                return
            }

            self.showAlert(
                title: "Verify Your Email",
                message: "We sent a verification link to \(newEmail). Your email will only change after you confirm it."
            )
        }
    }
    
    func updateEmailPressed() {
        let alert = UIAlertController(
            title: "Update Email",
            message: "Enter your new email address.",
            preferredStyle: .alert
        )

        alert.addTextField { field in
            field.placeholder = "New Email"
            field.keyboardType = .emailAddress
            field.autocapitalizationType = .none
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Send Verification", style: .default) { _ in
            guard let newEmail = alert.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
                  !newEmail.isEmpty else {
                return
            }

            self.updateEmail(newEmail: newEmail)
        })

        present(alert, animated: true)
    }
    
    // MARK: - Navigation Rows
    
    func tuningSettingsPressed(_ sender: Any) {
        performSegue(withIdentifier: "profileToTuning", sender: nil)
    }
    
    func microphonePermissionsPressed(_ sender: Any) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Logout / Delete
    
    @IBAction func logoutPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Log Out",
                                      message: "Are you sure you want to log out?",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            try? Auth.auth().signOut()
            self.performSegue(withIdentifier: "profileToLogin", sender: nil)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @IBAction func deleteAccountPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Delete Account",
                                      message: "This permanently deletes your account and all data.",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            guard let user = Auth.auth().currentUser else { return }
            
            self.db.collection("users").document(user.uid).getDocument { snapshot, error in
                let username = snapshot?.data()?["username"] as? String
                
                if let username = username, !username.isEmpty {
                    self.db.collection("usernames").document(username).delete()
                }
                
                self.db.collection("users").document(user.uid).delete()
                
                user.delete { error in
                    if let error = error {
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    } else {
                        self.performSegue(withIdentifier: "profileToLogin", sender: nil)
                    }
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Image Picker

extension ProfileSettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        if let image = info[.originalImage] as? UIImage {
            profileImageView.image = image
            saveProfileImage(image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

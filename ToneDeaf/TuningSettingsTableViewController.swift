// Project: ToneDeaf
// EID: ztb456
// Course: CS329E

import UIKit
import FirebaseAuth
import FirebaseFirestore

class TuningSettingsTableViewController: UITableViewController {

    @IBOutlet weak var tuningCell: UITableViewCell!
    @IBOutlet weak var referencePitchLabel: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var guitarTypeCell: UITableViewCell!
    @IBOutlet weak var referencePitchStepper: UIStepper!

    var db = Firestore.firestore()
    var referencePitch: Int = 440

    let tuningOptions = ["Standard", "Eb Standard", "D Standard", "C# Standard", "Drop D"]
    let guitarTypes   = ["Electric Guitar", "Acoustic Guitar"]

    var selectedTuning: String = "Standard"
    var selectedGuitarType: String = "Electric Guitar"

    override func viewDidLoad() {
        super.viewDidLoad()
        referencePitchStepper.tintColor = .systemIndigo
        referencePitchStepper.layer.cornerRadius = 8
        referencePitchStepper.clipsToBounds = true
        referencePitchLabel.textColor = .lightGray
        label.font = UIFont(name: "Poppins-Bold", size: 14)
        label.textAlignment = .center
        referencePitchLabel.font = UIFont(name: "Poppins-Bold", size: 13)
        tableView.rowHeight = 58
        tableView.isScrollEnabled = false
        tableView.isOpaque = false
        

        title = "Tuning Settings"
        loadSettings()
        NotificationCenter.default.addObserver(self,
                                                   selector: #selector(updateTheme),
                                                   name: Notification.Name("darkModeChanged"),
                                                   object: nil)
            updateTheme()
    }
    
    @objc func updateTheme() {
        // Applies dark/light styling to the table and labels
        let isDark = darkMode.isDarkMode
        
        view.backgroundColor = isDark ? .black : .white
        tableView.backgroundColor = isDark ? .black : .white
        tableView.separatorColor = isDark ? UIColor(white: 0.18, alpha: 1) : UIColor(white: 0.85, alpha: 1)
        
        label.textColor = isDark ? .white : .black
        referencePitchLabel.textColor = isDark ? .lightGray : .darkGray
        
        tableView.reloadData()
    }
    

    // MARK: - Firebase

    func loadSettings() {
        // Loads the user's saved tuning, guitar type, and reference pitch
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data() else { return }
            self.selectedTuning    = data["tuning"]          as? String ?? "Standard"
            self.selectedGuitarType = data["instrument"]     as? String ?? "Electric Guitar"
            self.referencePitch    = data["referencePitch"]  as? Int    ?? 440
            self.updateLabels()
        }
    }

    func saveSettings() {
        // Saves the user's current tuning preferences to Firestore
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData([
            "tuning":         selectedTuning,
            "instrument":     selectedGuitarType,
            "referencePitch": referencePitch
        ])
    }

    func updateLabels() {
        // Updates visible cell labels to match the current settings.
        tuningCell.detailTextLabel?.text = selectedTuning
        referencePitchLabel.text = "\(referencePitch) Hz"
        referencePitchStepper.value = Double(referencePitch)
        guitarTypeCell.detailTextLabel?.text = selectedGuitarType
    }

    // MARK: - Reference Pitch Stepper

    @IBAction func stepperChanged(_ sender: UIStepper) {
        referencePitch = Int(sender.value)
        referencePitchLabel.text = "\(referencePitch) Hz"
        saveSettings()
    }

    // MARK: - Table View Cell Tap
    
    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        // Styles each table cell based on the current theme before display.
        let isDark = darkMode.isDarkMode
        
        cell.backgroundColor = isDark ? UIColor(white: 0.06, alpha: 1) : .white

        cell.textLabel?.textColor = isDark ? .white : .black
        cell.textLabel?.font = UIFont(name: "Poppins-Bold", size: 14)

        cell.detailTextLabel?.textColor = isDark ? .lightGray : .darkGray
        cell.detailTextLabel?.font = UIFont(name: "Poppins-Bold", size: 13)

        cell.tintColor = .systemIndigo

        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(isDark ? 0.25 : 0.12)
        cell.selectedBackgroundView = selectedView
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "showTuningSelector", sender: nil)
        case 2:
            showGuitarTypePicker()
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTuningSelector",
           let vc = segue.destination as? TuningSelectorViewController {

            vc.options = tuningOptions
            vc.selectedOption = selectedTuning

            vc.onSelect = { selected in
                self.selectedTuning = selected
                self.updateLabels()
                self.saveSettings()
            }
        }
    }

    // MARK: - Pickers

    func showTuningPicker() {
        let alert = UIAlertController(title: "Select Tuning", message: nil, preferredStyle: .actionSheet)
        for option in tuningOptions {
            alert.addAction(UIAlertAction(title: option, style: .default) { _ in
                self.selectedTuning = option
                self.updateLabels()
                self.saveSettings()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func showGuitarTypePicker() {
        // Shows an action sheet for choosing electric or acoustic guitar.
        let alert = UIAlertController(title: "Guitar Type", message: nil, preferredStyle: .actionSheet)
        for option in guitarTypes {
            alert.addAction(UIAlertAction(title: option, style: .default) { _ in
                self.selectedGuitarType = option
                self.updateLabels()
                self.saveSettings()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// Project: ToneDeaf
// EID: ztb456
// Course: CS329E

import UIKit
import FirebaseAuth
import FirebaseFirestore

class MainViewController: BaseViewController {

    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var dialView: DialView!
    @IBOutlet weak var tuningLabel: UILabel!
    @IBOutlet weak var referencePitchLabel: UILabel!
    
    var db = Firestore.firestore()
    var referencePitch: Int = 440
    var selectedTuning: String = "Standard"
    var tunerEngine = TunerEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: Notification.Name("darkModeChanged"), object: nil)
        updateTheme()

        noteLabel.text = "-"
        statusLabel.text = ""
        statusLabel.font = UIFont(name: "Poppins-Bold", size: 20)
        noteLabel.font = UIFont(name: "TiltPrism-Regular", size: 150)
        view.backgroundColor = .black
        noteLabel.textColor = .white
        updateTuningHeader()
        setupProfileButton()
        tunerEngine.onPitchDetected = { frequency, note, cents in
            self.updateUI(centsOff: cents, note: note)
        }
    }
    @objc func updateTheme() {
        let isDark = darkMode.isDarkMode
        view.backgroundColor = isDark ? .black : .white
        dialView.updateNeedleColor()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if Auth.auth().currentUser == nil {
            performSegue(withIdentifier: "mainToLogin", sender: nil)
        } else {
            loadTunerSettings()
            tunerEngine.start()
        }
    }
    func updateTuningHeader() {
        let tuning = selectedTuning
        let pitch = "\(referencePitch) Hz"
        let fullText = "\(tuning)  •  \(pitch)"

        let attributed = NSMutableAttributedString(string: fullText)

        let color = UIColor(red: 179/255, green: 179/255, blue: 179/255, alpha: 1)

        let regularFont = UIFont(name: "Poppins-Regular", size: 20)
            ?? UIFont.systemFont(ofSize: 20, weight: .regular)

        let boldFont = UIFont(name: "Poppins-Bold", size: 20)
            ?? UIFont.systemFont(ofSize: 20, weight: .bold)

        let bulletFont = UIFont(name: "Poppins-Regular", size: 26)
            ?? UIFont.systemFont(ofSize: 26, weight: .regular)

        attributed.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: fullText.count))
        attributed.addAttribute(.font, value: regularFont, range: NSRange(location: 0, length: fullText.count))

        attributed.addAttribute(.font, value: boldFont, range: NSRange(location: 0, length: tuning.count))

        if let bulletRange = fullText.range(of: "•") {
            attributed.addAttribute(.font, value: bulletFont, range: NSRange(bulletRange, in: fullText))
        }

        tuningLabel.attributedText = attributed
        referencePitchLabel.text = ""
    }
    
    func setupProfileButton() {
        let size: CGFloat = 34

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .systemIndigo
        container.layer.cornerRadius = size / 2
        container.layer.masksToBounds = true

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: size),
            container.heightAnchor.constraint(equalToConstant: size)
        ])

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "person.fill")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .black
        imageView.contentMode = .scaleAspectFit

        container.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 16),
            imageView.heightAnchor.constraint(equalToConstant: 16)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(profileButtonPressed))
        container.addGestureRecognizer(tap)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: container)
    }
    
    @objc func profileButtonPressed() {
        performSegue(withIdentifier: "mainToProfile", sender: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tunerEngine.stop()
    }

    func updateUI(centsOff: Float, note: String) {

        if note == "-" {
            noteLabel.text = "-"
            statusLabel.text = ""
            return
        }

        noteLabel.text = note

        if abs(centsOff) < 5 {
            statusLabel.text = "In Tune"
            statusLabel.textColor = .systemGreen
        } else if centsOff < 0 {
            statusLabel.text = "Flat"
            statusLabel.textColor = .systemYellow
        } else {
            statusLabel.text = "Sharp"
            statusLabel.textColor = .systemBlue
        }

        dialView.setNeedle(centsOff: centsOff)
    }
    
    func loadTunerSettings() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { snapshot, error in
            guard let data = snapshot?.data() else { return }

            self.selectedTuning = data["tuning"] as? String ?? "Standard"
            self.referencePitch = data["referencePitch"] as? Int ?? 440
            
            self.updateTuningHeader()
            
            self.tunerEngine.referencePitch = Float(self.referencePitch)
            self.tunerEngine.targetNotes = self.notesForTuning(self.selectedTuning)
        }
    }
    
    func notesForTuning(_ tuning: String) -> [String] {
        switch tuning {
        case "Drop D":
            return ["D2", "A2", "D3", "G3", "B3", "E4"]
        case "D Standard":
            return ["D2", "G2", "C3", "F3", "A3", "D4"]
        case "Eb Standard":
            return ["D#2", "G#2", "C#3", "F#3", "A#3", "D#4"]
        case "C# Standard":
            return ["C#2", "F#2", "B2", "E3", "G#3", "C#4"]
        default:
            return ["E2", "A2", "D3", "G3", "B3", "E4"]
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

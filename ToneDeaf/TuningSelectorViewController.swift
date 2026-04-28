// Project: ToneDeaf
// EID: ztb456
// Course: CS329E

import UIKit

class TuningSelectorViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var options: [String] = []
    var selectedOption: String = ""
    var onSelect: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tuning"

        view.backgroundColor = .black

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .black
        tableView.rowHeight = 62
        tableView.separatorColor = UIColor(white: 0.18, alpha: 1)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.isScrollEnabled = false
        NotificationCenter.default.addObserver(self,
                                                   selector: #selector(updateTheme),
                                                   name: Notification.Name("darkModeChanged"),
                                                   object: nil)
            
        updateTheme()
    }
    
    @objc func updateTheme() {
        let isDark = darkMode.isDarkMode
        
        view.backgroundColor = isDark ? .black : .white
        tableView.backgroundColor = isDark ? .black : .white
        tableView.separatorColor = isDark ? UIColor(white: 0.18, alpha: 1) : UIColor(white: 0.85, alpha: 1)
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "tuningOptionCell",
            for: indexPath
        )

        let isDark = darkMode.isDarkMode
        let option = options[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = option
        config.textProperties.color = isDark ? .white : .black
        config.textProperties.font = UIFont(name: "Poppins-Bold", size: 16)
            ?? UIFont.systemFont(ofSize: 16, weight: .semibold)

        cell.contentConfiguration = config

        cell.backgroundColor = isDark ? UIColor(white: 0.07, alpha: 1) : .white
        cell.layer.cornerRadius = 0
        cell.layer.masksToBounds = false

        cell.accessoryType = option == selectedOption ? .checkmark : .none
        cell.tintColor = .systemIndigo

        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(isDark ? 0.2 : 0.12)
        cell.selectedBackgroundView = selectedView

        return cell
    }
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let option = options[indexPath.row]
        selectedOption = option
        tableView.reloadData()

        onSelect?(option)
        navigationController?.popViewController(animated: true)
    }
}

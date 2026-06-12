// SettingsViewController.swift – Tab 3: Settings

import UIKit
import UserNotifications

final class SettingsViewController: UIViewController {

    // MARK: - UI

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: - State

    private var notificationsEnabled = false
    private var monthlyBudget: Double {
        get { UserDefaults.standard.double(forKey: "monthlyBudget") }
        set { UserDefaults.standard.set(newValue, forKey: "monthlyBudget") }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .smBackground
        title = "설정"
        navigationController?.navigationBar.prefersLargeTitles = false

        setupTableView()
        checkNotificationStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkNotificationStatus()
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .smBackground
        tableView.separatorColor = .smSeparator

        // Customize inset grouped appearance
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func checkNotificationStatus() {
        NotificationManager.shared.checkPermission { [weak self] granted in
            self?.notificationsEnabled = granted
            self?.tableView.reloadData()
        }
    }

    // MARK: - Actions

    private func showBudgetInput() {
        let alert = UIAlertController(title: "월 예산 설정", message: "이번 달 예산을 입력하세요", preferredStyle: .alert)
        alert.addTextField { [weak self] tf in
            tf.keyboardType = .numberPad
            tf.placeholder = "예산 (원)"
            if let self, self.monthlyBudget > 0 {
                tf.text = "\(Int(self.monthlyBudget))"
            }
            tf.textColor = .label
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "저장", style: .default) { [weak self] _ in
            guard let self, let text = alert.textFields?.first?.text else { return }
            let value = Double(text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
            self.monthlyBudget = value
            self.tableView.reloadData()
            NotificationCenter.default.post(name: .expenseDataChanged, object: nil)
        })
        present(alert, animated: true)
    }

    private func requestNotificationPermission(_ isOn: Bool) {
        if isOn {
            NotificationManager.shared.requestPermission { [weak self] granted in
                if !granted {
                    self?.showNotificationSettingsAlert()
                }
                self?.checkNotificationStatus()
            }
        } else {
            // Redirect to system settings
            showNotificationSettingsAlert()
        }
    }

    private func showNotificationSettingsAlert() {
        let alert = UIAlertController(
            title: "알림 설정",
            message: "시스템 설정에서 SpendMap의 알림을 켜주세요",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }

    private func confirmDataReset() {
        let step1 = UIAlertController(
            title: "데이터 초기화",
            message: "모든 지출 내역이 삭제됩니다.",
            preferredStyle: .alert
        )
        step1.addAction(UIAlertAction(title: "취소", style: .cancel))
        step1.addAction(UIAlertAction(title: "계속", style: .destructive) { [weak self] _ in
            let step2 = UIAlertController(
                title: "⚠️ 정말 삭제하시겠어요?",
                message: "이 작업은 되돌릴 수 없습니다.",
                preferredStyle: .alert
            )
            step2.addAction(UIAlertAction(title: "취소", style: .cancel))
            step2.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
                CoreDataManager.shared.deleteAll()
            })
            self?.present(step2, animated: true)
        })
        present(step1, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 3 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1  // Budget
        case 1: return 1  // Notifications
        case 2: return 1  // Reset
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.backgroundColor = .smSurface
        cell.textLabel?.textColor = .smTextPrimary
        cell.detailTextLabel?.textColor = .smTextSecondary
        cell.selectionStyle = .none

        switch indexPath.section {
        case 0:
            cell.imageView?.image = UIImage(systemName: "wonsign.circle.fill")
            cell.imageView?.tintColor = .smGold
            cell.textLabel?.text = "월 예산"
            if monthlyBudget > 0 {
                let f = NumberFormatter()
                f.numberStyle = .decimal
                cell.detailTextLabel?.text = "₩\(f.string(from: NSNumber(value: Int(monthlyBudget))) ?? "0")"
            } else {
                cell.detailTextLabel?.text = "설정 안 됨"
            }
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default

        case 1:
            cell.imageView?.image = UIImage(systemName: "bell.circle.fill")
            cell.imageView?.tintColor = .smPrimary
            cell.textLabel?.text = "예산 알림"
            let toggle = UISwitch()
            toggle.onTintColor = .smPrimary
            toggle.isOn = notificationsEnabled
            toggle.addTarget(self, action: #selector(notificationToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle

        case 2:
            cell.imageView?.image = UIImage(systemName: "trash.circle.fill")
            cell.imageView?.tintColor = .smDanger
            cell.textLabel?.text = "데이터 초기화"
            cell.textLabel?.textColor = .smDanger
            cell.selectionStyle = .default

        default: break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "예산 관리"
        case 1: return "알림"
        case 2: return "데이터"
        default: return nil
        }
    }

    @objc private func notificationToggled(_ toggle: UISwitch) {
        requestNotificationPermission(toggle.isOn)
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0: showBudgetInput()
        case 2: confirmDataReset()
        default: break
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .smTextSecondary
            header.textLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        }
    }
}

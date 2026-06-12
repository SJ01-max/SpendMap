// ListViewController.swift – Tab 2: Expense list with filter & search

import UIKit

final class ListViewController: UIViewController {

    // MARK: - UI

    private let searchBar = UISearchBar()
    private let filterScrollView = UIScrollView()
    private let filterStack = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .grouped)

    // MARK: - Data

    private let cdm = CoreDataManager.shared
    private var allExpenses: [Expense] = []
    private var filteredExpenses: [Expense] = []
    private var groupedExpenses: [(date: String, total: Double, items: [Expense])] = []

    private var selectedCategory: String = "전체"
    private var searchText: String = ""
    private var chipViews: [CategoryChipView] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .smBackground
        title = "내역"
        navigationController?.navigationBar.prefersLargeTitles = false

        setupSearchBar()
        setupFilterChips()
        setupTableView()

        NotificationCenter.default.addObserver(self,
            selector: #selector(refreshData),
            name: .expenseDataChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }

    // MARK: - Setup

    private func setupSearchBar() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "장소 검색"
        searchBar.barStyle = .black
        searchBar.searchBarStyle = .minimal
        searchBar.tintColor = .smPrimary
        searchBar.delegate = self
        if let tf = searchBar.value(forKey: "searchField") as? UITextField {
            tf.textColor = .smTextPrimary
            tf.backgroundColor = .smSurface
            tf.attributedPlaceholder = NSAttributedString(
                string: "장소 검색",
                attributes: [.foregroundColor: UIColor.smTextSecondary]
            )
        }
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func setupFilterChips() {
        filterScrollView.translatesAutoresizingMaskIntoConstraints = false
        filterScrollView.showsHorizontalScrollIndicator = false
        view.addSubview(filterScrollView)

        filterStack.translatesAutoresizingMaskIntoConstraints = false
        filterStack.axis = .horizontal
        filterStack.spacing = 8
        filterScrollView.addSubview(filterStack)

        let categories = ["전체"] + ExpenseCategory.allCases.map { $0.rawValue }
        for catName in categories {
            let chip = CategoryChipView(categoryName: catName)
            chip.setSelected(catName == selectedCategory)
            chip.onTap = { [weak self] in self?.selectCategory(catName) }
            chipViews.append(chip)
            filterStack.addArrangedSubview(chip)
        }

        NSLayoutConstraint.activate([
            filterScrollView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            filterScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterScrollView.heightAnchor.constraint(equalToConstant: 44),

            filterStack.topAnchor.constraint(equalTo: filterScrollView.topAnchor),
            filterStack.leadingAnchor.constraint(equalTo: filterScrollView.leadingAnchor, constant: 16),
            filterStack.trailingAnchor.constraint(equalTo: filterScrollView.trailingAnchor, constant: -16),
            filterStack.heightAnchor.constraint(equalTo: filterScrollView.heightAnchor)
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .smBackground
        tableView.separatorStyle = .none
        tableView.register(ExpenseTableCell.self, forCellReuseIdentifier: ExpenseTableCell.reuseIdentifier)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: filterScrollView.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Data

    @objc private func refreshData() {
        allExpenses = cdm.fetchAll()
        applyFilters()
    }

    private func selectCategory(_ category: String) {
        selectedCategory = category
        chipViews.forEach { $0.setSelected($0.categoryName == category) }
        applyFilters()
    }

    private func applyFilters() {
        var result = allExpenses

        if selectedCategory != "전체" {
            result = result.filter { $0.category == selectedCategory }
        }

        if !searchText.isEmpty {
            result = result.filter {
                ($0.placeName ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.memo ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        filteredExpenses = result
        groupExpenses()
        tableView.reloadData()
    }

    private func groupExpenses() {
        var groups: [String: (Double, [Expense])] = [:]
        var order: [String] = []

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "M월 d일 EEEE"
        displayFormatter.locale = Locale(identifier: "ko_KR")

        for expense in filteredExpenses {
            guard let date = expense.date else { continue }
            let key = dateFormatter.string(from: date)
            if groups[key] == nil {
                groups[key] = (0, [])
                order.append(key)
            }
            groups[key]!.0 += expense.amount
            groups[key]!.1.append(expense)
        }

        groupedExpenses = order.sorted(by: >).compactMap { key -> (String, Double, [Expense])? in
            guard let group = groups[key] else { return nil }
            // Convert key back to display string
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            if let date = f.date(from: key) {
                let display = displayFormatter.string(from: date)
                return (display, group.0, group.1)
            }
            return (key, group.0, group.1)
        }
    }
}

// MARK: - UITableViewDataSource

extension ListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        groupedExpenses.isEmpty ? 1 : groupedExpenses.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groupedExpenses.isEmpty ? 0 : groupedExpenses[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ExpenseTableCell.reuseIdentifier, for: indexPath) as! ExpenseTableCell
        let expense = groupedExpenses[indexPath.section].items[indexPath.row]
        cell.configure(with: expense)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !groupedExpenses.isEmpty else { return nil }
        let group = groupedExpenses[section]

        let header = UIView()
        header.backgroundColor = .smBackground

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.text = group.date
        dateLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        dateLabel.textColor = .smTextSecondary
        header.addSubview(dateLabel)

        let totalLabel = UILabel()
        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        let f = NumberFormatter()
        f.numberStyle = .decimal
        totalLabel.text = "₩\(f.string(from: NSNumber(value: Int(group.total))) ?? "0")"
        totalLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        totalLabel.textColor = .smTextPrimary
        totalLabel.textAlignment = .right
        header.addSubview(totalLabel)

        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            dateLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            totalLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            totalLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        groupedExpenses.isEmpty ? 0 : 40
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0 }
}

// MARK: - UITableViewDelegate

extension ListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 74 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !groupedExpenses.isEmpty else { return }
        let expense = groupedExpenses[indexPath.section].items[indexPath.row]
        let vc = ExpenseDetailViewController(expense: expense)
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completion in
            guard let self, !self.groupedExpenses.isEmpty else { completion(false); return }
            let expense = self.groupedExpenses[indexPath.section].items[indexPath.row]
            let alert = UIAlertController(title: "지출 삭제", message: "이 지출 내역을 삭제하시겠어요?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in completion(false) })
            alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
                self.cdm.delete(expense)
                self.refreshData()
                completion(true)
            })
            self.present(alert, animated: true)
        }
        delete.backgroundColor = .smDanger
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }

    // Empty state
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {}

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if groupedExpenses.isEmpty && tableView.backgroundView == nil {
            let label = UILabel(frame: tableView.bounds)
            label.text = "아직 지출 내역이 없어요\n+ 버튼으로 첫 지출을 기록해보세요"
            label.textColor = .smTextSecondary
            label.font = .systemFont(ofSize: 15)
            label.textAlignment = .center
            label.numberOfLines = 0
            tableView.backgroundView = label
        } else if !groupedExpenses.isEmpty {
            tableView.backgroundView = nil
        }
    }
}

// MARK: - UISearchBarDelegate

extension ListViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        applyFilters()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchText = ""
        searchBar.resignFirstResponder()
        applyFilters()
    }
}

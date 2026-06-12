// StatisticsViewController.swift – Tab 1: Charts & Statistics

import UIKit

final class StatisticsViewController: UIViewController {

    // MARK: - UI
    private let scrollView        = UIScrollView()
    private let contentView       = UIView()
    private let segmentControl    = UISegmentedControl(items: ["이번달", "지난달", "3개월"])
    private let totalCard         = UIView()
    private let donutCard         = UIView()
    private let weeklyCard        = UIView()
    private let categoryListCard  = UIView()

    private let totalAmountLabel  = UILabel()
    private let totalSubtitle     = UILabel()
    private let donutChart        = DonutChartView()
    private let legendStack       = UIStackView()
    private let weeklyBarChart    = BarChartView()
    private let categoryListStack = UIStackView()

    private let cdm = CoreDataManager.shared

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .smBackground
        title = "통계"
        navigationController?.navigationBar.prefersLargeTitles = false
        setupScrollView()
        setupAllCards()
        NotificationCenter.default.addObserver(self,
            selector: #selector(refreshData),
            name: .expenseDataChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }

    // MARK: - Setup

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func setupAllCards() {
        // Segment control
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        segmentControl.selectedSegmentIndex = 0
        segmentControl.backgroundColor = .smSurface
        segmentControl.selectedSegmentTintColor = .smPrimary
        segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.smTextSecondary], for: .normal)
        segmentControl.setTitleTextAttributes(
            [.foregroundColor: UIColor.smBackground,
             .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        segmentControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        contentView.addSubview(segmentControl)

        // Cards
        [totalCard, donutCard, weeklyCard, categoryListCard].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.backgroundColor = .smSurface
            $0.layer.cornerRadius = 14
            contentView.addSubview($0)
        }

        buildTotalCard()
        buildDonutCard()
        buildWeeklyCard()
        buildCategoryCard()

        let h: CGFloat = 16
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            segmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: h),
            segmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -h),
            segmentControl.heightAnchor.constraint(equalToConstant: 36),

            totalCard.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16),
            totalCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: h),
            totalCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -h),

            donutCard.topAnchor.constraint(equalTo: totalCard.bottomAnchor, constant: 12),
            donutCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: h),
            donutCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -h),

            weeklyCard.topAnchor.constraint(equalTo: donutCard.bottomAnchor, constant: 12),
            weeklyCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: h),
            weeklyCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -h),

            categoryListCard.topAnchor.constraint(equalTo: weeklyCard.bottomAnchor, constant: 12),
            categoryListCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: h),
            categoryListCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -h),
            categoryListCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func buildTotalCard() {
        totalSubtitle.translatesAutoresizingMaskIntoConstraints = false
        totalSubtitle.text = "총 지출"
        totalSubtitle.font = .systemFont(ofSize: 13, weight: .medium)
        totalSubtitle.textColor = .smTextSecondary

        totalAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        totalAmountLabel.text = "₩0"
        totalAmountLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 34, weight: .bold)
        totalAmountLabel.textColor = .smTextPrimary

        totalCard.addSubview(totalSubtitle)
        totalCard.addSubview(totalAmountLabel)
        NSLayoutConstraint.activate([
            totalSubtitle.topAnchor.constraint(equalTo: totalCard.topAnchor, constant: 16),
            totalSubtitle.leadingAnchor.constraint(equalTo: totalCard.leadingAnchor, constant: 20),

            totalAmountLabel.topAnchor.constraint(equalTo: totalSubtitle.bottomAnchor, constant: 6),
            totalAmountLabel.leadingAnchor.constraint(equalTo: totalCard.leadingAnchor, constant: 20),
            totalAmountLabel.trailingAnchor.constraint(equalTo: totalCard.trailingAnchor, constant: -20),
            totalAmountLabel.bottomAnchor.constraint(equalTo: totalCard.bottomAnchor, constant: -16)
        ])
    }

    private func buildDonutCard() {
        let title = makeSectionTitle("카테고리별 지출")
        donutChart.translatesAutoresizingMaskIntoConstraints = false
        donutChart.backgroundColor = .clear

        legendStack.translatesAutoresizingMaskIntoConstraints = false
        legendStack.axis = .vertical
        legendStack.spacing = 8

        donutCard.addSubview(title)
        donutCard.addSubview(donutChart)
        donutCard.addSubview(legendStack)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: donutCard.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: donutCard.leadingAnchor, constant: 16),

            donutChart.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
            donutChart.centerXAnchor.constraint(equalTo: donutCard.centerXAnchor),
            donutChart.widthAnchor.constraint(equalToConstant: 180),
            donutChart.heightAnchor.constraint(equalToConstant: 180),

            legendStack.topAnchor.constraint(equalTo: donutChart.bottomAnchor, constant: 20),
            legendStack.leadingAnchor.constraint(equalTo: donutCard.leadingAnchor, constant: 20),
            legendStack.trailingAnchor.constraint(equalTo: donutCard.trailingAnchor, constant: -20),
            legendStack.bottomAnchor.constraint(equalTo: donutCard.bottomAnchor, constant: -16)
        ])
    }

    private func buildWeeklyCard() {
        let title = makeSectionTitle("주간 지출")
        weeklyBarChart.translatesAutoresizingMaskIntoConstraints = false
        weeklyBarChart.backgroundColor = .clear

        weeklyCard.addSubview(title)
        weeklyCard.addSubview(weeklyBarChart)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: weeklyCard.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: weeklyCard.leadingAnchor, constant: 16),

            weeklyBarChart.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
            weeklyBarChart.leadingAnchor.constraint(equalTo: weeklyCard.leadingAnchor, constant: 16),
            weeklyBarChart.trailingAnchor.constraint(equalTo: weeklyCard.trailingAnchor, constant: -16),
            weeklyBarChart.heightAnchor.constraint(equalToConstant: 130),
            weeklyBarChart.bottomAnchor.constraint(equalTo: weeklyCard.bottomAnchor, constant: -16)
        ])
    }

    private func buildCategoryCard() {
        let title = makeSectionTitle("카테고리 순위")
        categoryListStack.translatesAutoresizingMaskIntoConstraints = false
        categoryListStack.axis = .vertical
        categoryListStack.spacing = 14

        categoryListCard.addSubview(title)
        categoryListCard.addSubview(categoryListStack)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: categoryListCard.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: categoryListCard.leadingAnchor, constant: 16),

            categoryListStack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
            categoryListStack.leadingAnchor.constraint(equalTo: categoryListCard.leadingAnchor, constant: 16),
            categoryListStack.trailingAnchor.constraint(equalTo: categoryListCard.trailingAnchor, constant: -16),
            categoryListStack.bottomAnchor.constraint(equalTo: categoryListCard.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Data refresh

    @objc private func refreshData() {
        let expenses = loadExpenses()
        updateTotal(expenses)
        updateDonut(expenses)
        updateWeekly()
        updateCategoryList(expenses)
    }

    private func loadExpenses() -> [Expense] {
        let cal = Calendar.current
        let now = Date()
        switch segmentControl.selectedSegmentIndex {
        case 0: return cdm.fetchForMonth(now)
        case 1:
            guard let last = cal.date(byAdding: .month, value: -1, to: now) else { return [] }
            return cdm.fetchForMonth(last)
        case 2:
            guard let start = cal.date(byAdding: .month, value: -2, to: now),
                  let compsDate = cal.date(from: cal.dateComponents([.year, .month], from: start)) else { return [] }
            return cdm.fetchForRange(from: compsDate, to: now)
        default: return []
        }
    }

    private func updateTotal(_ expenses: [Expense]) {
        let total = cdm.totalAmount(for: expenses)
        let f = NumberFormatter(); f.numberStyle = .decimal
        totalAmountLabel.text = "₩\(f.string(from: NSNumber(value: Int(total))) ?? "0")"
        let budget = UserDefaults.standard.double(forKey: "monthlyBudget")
        totalAmountLabel.textColor = (budget > 0 && total > budget) ? .smDanger : .smTextPrimary
    }

    private func updateDonut(_ expenses: [Expense]) {
        let byCategory = cdm.amountByCategory(for: expenses)
        let segments = ExpenseCategory.allCases.compactMap { cat -> DonutChartView.Segment? in
            guard let amt = byCategory[cat.rawValue], amt > 0 else { return nil }
            return DonutChartView.Segment(category: cat.rawValue, amount: amt, color: cat.color)
        }
        donutChart.segments = segments

        legendStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let total = cdm.totalAmount(for: expenses)
        let f = NumberFormatter(); f.numberStyle = .decimal
        let sorted = segments.sorted { $0.amount > $1.amount }
        for seg in sorted {
            let row = UIStackView()
            row.axis = .horizontal; row.spacing = 8; row.alignment = .center
            let dot = UIView()
            dot.backgroundColor = seg.color; dot.layer.cornerRadius = 5
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 10).isActive = true
            let cat = ExpenseCategory.from(seg.category)
            let catL = UILabel(); catL.text = cat.rawValue
            catL.font = .systemFont(ofSize: 12); catL.textColor = .smTextSecondary
            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            let amtL = UILabel()
            amtL.text = "₩\(f.string(from: NSNumber(value: Int(seg.amount))) ?? "0")"
            amtL.font = .systemFont(ofSize: 12, weight: .semibold); amtL.textColor = .smTextPrimary
            row.addArrangedSubview(dot); row.addArrangedSubview(catL)
            row.addArrangedSubview(spacer); row.addArrangedSubview(amtL)
            legendStack.addArrangedSubview(row)
        }
        if sorted.isEmpty {
            let lbl = UILabel()
            lbl.text = "이 기간에 지출이 없어요"; lbl.textAlignment = .center
            lbl.font = .systemFont(ofSize: 13); lbl.textColor = .smTextSecondary
            legendStack.addArrangedSubview(lbl)
        }
        _ = total  // suppress warning
    }

    private func updateWeekly() {
        let days = cdm.dailyTotals(days: 7)
        let dayLabels = ["일","월","화","수","목","금","토"]
        let cal = Calendar.current
        weeklyBarChart.bars = days.map { (date, amount) in
            let wd = cal.component(.weekday, from: date) - 1
            return BarChartView.Bar(label: dayLabels[wd], amount: amount)
        }
    }

    private func updateCategoryList(_ expenses: [Expense]) {
        categoryListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let byCategory = cdm.amountByCategory(for: expenses)
        let maxAmt = byCategory.values.max() ?? 1
        let f = NumberFormatter(); f.numberStyle = .decimal
        let sorted = ExpenseCategory.allCases
            .compactMap { cat -> (ExpenseCategory, Double)? in
                guard let amt = byCategory[cat.rawValue], amt > 0 else { return nil }
                return (cat, amt)
            }.sorted { $0.1 > $1.1 }

        if sorted.isEmpty {
            let lbl = UILabel()
            lbl.text = "이 기간에 지출이 없어요"; lbl.textAlignment = .center
            lbl.font = .systemFont(ofSize: 13); lbl.textColor = .smTextSecondary
            categoryListStack.addArrangedSubview(lbl)
            return
        }

        for (cat, amount) in sorted {
            let row = UIView(); row.translatesAutoresizingMaskIntoConstraints = false
            let iconView = UIImageView(); iconView.translatesAutoresizingMaskIntoConstraints = false
            let symConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            iconView.image = UIImage(systemName: cat.sfSymbol, withConfiguration: symConfig)
            iconView.tintColor = cat.color; iconView.contentMode = .scaleAspectFit
            let name = UILabel(); name.translatesAutoresizingMaskIntoConstraints = false
            name.text = cat.rawValue
            name.font = .systemFont(ofSize: 14, weight: .medium); name.textColor = .smTextPrimary
            let amt = UILabel(); amt.translatesAutoresizingMaskIntoConstraints = false
            amt.text = "₩\(f.string(from: NSNumber(value: Int(amount))) ?? "0")"
            amt.font = .systemFont(ofSize: 14, weight: .bold); amt.textColor = .smTextPrimary
            amt.textAlignment = .right
            let progress = UIProgressView(progressViewStyle: .default)
            progress.translatesAutoresizingMaskIntoConstraints = false
            progress.progressTintColor = cat.color; progress.trackTintColor = .smSurface2
            progress.layer.cornerRadius = 3; progress.clipsToBounds = true
            progress.setProgress(Float(amount / maxAmt), animated: false)
            row.addSubview(iconView); row.addSubview(name); row.addSubview(amt); row.addSubview(progress)
            NSLayoutConstraint.activate([
                iconView.topAnchor.constraint(equalTo: row.topAnchor),
                iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 24),
                iconView.heightAnchor.constraint(equalToConstant: 24),
                name.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
                name.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
                amt.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
                amt.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                progress.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
                progress.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                progress.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                progress.heightAnchor.constraint(equalToConstant: 6),
                progress.bottomAnchor.constraint(equalTo: row.bottomAnchor)
            ])
            categoryListStack.addArrangedSubview(row)
        }
    }

    // MARK: - Helpers
    private func makeSectionTitle(_ text: String) -> UILabel {
        let l = UILabel(); l.translatesAutoresizingMaskIntoConstraints = false
        l.text = text; l.font = .systemFont(ofSize: 15, weight: .semibold); l.textColor = .smTextPrimary
        return l
    }
}

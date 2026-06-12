// AddExpenseViewController.swift – Modal: Add new expense

import UIKit
import CoreLocation

final class AddExpenseViewController: UIViewController {

    // MARK: - Cards (kept as refs for layout chaining)
    private let scrollView  = UIScrollView()
    private let contentView = UIView()

    private let locationCard = UIView()
    private let amountCard   = UIView()
    private let categoryCard = UIView()
    private let memoCard     = UIView()
    private let dateCard     = UIView()
    private let saveButton   = UIButton(type: .system)

    // Inner controls
    private let locationLabel            = UILabel()
    private let locationLoadingIndicator = UIActivityIndicatorView(style: .medium)
    private let amountLabel              = UILabel()
    private let amountField              = UITextField()
    private let categoryStack            = UIStackView()
    private let memoField                = UITextField()
    private let datePicker               = UIDatePicker()

    // MARK: - State
    private var selectedCategory: ExpenseCategory? { didSet { updateCategoryButtons(); validateForm() } }
    private var amountValue: Double = 0 { didSet { validateForm() } }
    private var selectedDate = Date()
    private var currentLocation: CLLocation?
    private var placeName = "위치 확인 중..."
    private var categoryButtons: [UIButton] = []
    private var categoryNameLabels: [UILabel] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .smBackground
        setupNavBar()
        setupScrollView()
        buildLayout()
        fetchLocation()
        setupKeyboardDismiss()
    }

    // MARK: - Nav Bar

    private func setupNavBar() {
        title = "지출 추가"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"), style: .plain,
            target: self, action: #selector(close))
        navigationController?.navigationBar.tintColor = .smTextSecondary
    }

    // MARK: - ScrollView

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

    // MARK: - Build all sections in one place (explicit chaining, no fragile subview search)

    private func buildLayout() {
        // Style all cards
        [locationCard, amountCard, categoryCard, memoCard, dateCard].forEach { card in
            card.translatesAutoresizingMaskIntoConstraints = false
            card.backgroundColor = .smSurface
            card.layer.cornerRadius = 14
            contentView.addSubview(card)
        }
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(saveButton)

        // Location card contents
        buildLocationCard()
        // Amount card contents
        buildAmountCard()
        // Category card contents
        buildCategoryCard()
        // Memo card contents
        buildMemoCard()
        // Date card contents
        buildDateCard()
        // Save button
        buildSaveButton()

        // ─── Card layout constraints (explicit chain) ───
        let h: CGFloat = 16  // horizontal padding
        NSLayoutConstraint.activate([
            // Location card
            locationCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            locationCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: h),
            locationCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -h),

            // Amount card
            amountCard.topAnchor.constraint(equalTo: locationCard.bottomAnchor, constant: 12),
            amountCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: h),
            amountCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -h),

            // Category card
            categoryCard.topAnchor.constraint(equalTo: amountCard.bottomAnchor, constant: 12),
            categoryCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: h),
            categoryCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -h),

            // Memo card
            memoCard.topAnchor.constraint(equalTo: categoryCard.bottomAnchor, constant: 12),
            memoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: h),
            memoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -h),

            // Date card
            dateCard.topAnchor.constraint(equalTo: memoCard.bottomAnchor, constant: 12),
            dateCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: h),
            dateCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -h),

            // Save button
            saveButton.topAnchor.constraint(equalTo: dateCard.bottomAnchor, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: h),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -h),
            saveButton.heightAnchor.constraint(equalToConstant: 54),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func buildLocationCard() {
        let pin = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
        pin.tintColor = .smPrimary
        pin.translatesAutoresizingMaskIntoConstraints = false

        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.text = "위치 확인 중..."
        locationLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        locationLabel.textColor = .smTextPrimary

        locationLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        locationLoadingIndicator.color = .smPrimary
        locationLoadingIndicator.startAnimating()
        locationLoadingIndicator.setContentHuggingPriority(.required, for: .horizontal)

        locationCard.addSubview(pin)
        locationCard.addSubview(locationLabel)
        locationCard.addSubview(locationLoadingIndicator)

        NSLayoutConstraint.activate([
            pin.leadingAnchor.constraint(equalTo: locationCard.leadingAnchor, constant: 16),
            pin.centerYAnchor.constraint(equalTo: locationCard.centerYAnchor),
            pin.widthAnchor.constraint(equalToConstant: 22),
            pin.heightAnchor.constraint(equalToConstant: 22),

            locationLabel.topAnchor.constraint(equalTo: locationCard.topAnchor, constant: 16),
            locationLabel.leadingAnchor.constraint(equalTo: pin.trailingAnchor, constant: 10),
            locationLabel.bottomAnchor.constraint(equalTo: locationCard.bottomAnchor, constant: -16),

            locationLoadingIndicator.leadingAnchor.constraint(equalTo: locationLabel.trailingAnchor, constant: 8),
            locationLoadingIndicator.centerYAnchor.constraint(equalTo: locationCard.centerYAnchor),
            locationLoadingIndicator.trailingAnchor.constraint(lessThanOrEqualTo: locationCard.trailingAnchor, constant: -16)
        ])
    }

    private func buildAmountCard() {
        let title = makeSectionLabel("금액")
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.text = "₩ 0"
        amountLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .bold)
        amountLabel.textColor = .smTextPrimary

        amountField.translatesAutoresizingMaskIntoConstraints = false
        amountField.keyboardType = .numberPad
        amountField.alpha = 0.01
        amountField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)

        amountCard.addSubview(title)
        amountCard.addSubview(amountLabel)
        amountCard.addSubview(amountField)

        let tap = UITapGestureRecognizer(target: self, action: #selector(focusAmount))
        amountCard.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: amountCard.topAnchor, constant: 14),
            title.leadingAnchor.constraint(equalTo: amountCard.leadingAnchor, constant: 16),

            amountLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            amountLabel.leadingAnchor.constraint(equalTo: amountCard.leadingAnchor, constant: 16),
            amountLabel.trailingAnchor.constraint(equalTo: amountCard.trailingAnchor, constant: -16),
            amountLabel.bottomAnchor.constraint(equalTo: amountCard.bottomAnchor, constant: -14),

            amountField.centerXAnchor.constraint(equalTo: amountCard.centerXAnchor),
            amountField.centerYAnchor.constraint(equalTo: amountCard.centerYAnchor),
            amountField.widthAnchor.constraint(equalToConstant: 1),
            amountField.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func buildCategoryCard() {
        let title = makeSectionLabel("카테고리")
        categoryStack.translatesAutoresizingMaskIntoConstraints = false
        categoryStack.axis = .horizontal
        categoryStack.distribution = .fillEqually
        categoryStack.spacing = 8

        categoryCard.addSubview(title)
        categoryCard.addSubview(categoryStack)

        for cat in ExpenseCategory.allCases {
            let btn = UIButton(type: .custom)
            btn.backgroundColor = .smSurface2
            btn.layer.cornerRadius = 10
            btn.tag = ExpenseCategory.allCases.firstIndex(of: cat) ?? 0
            btn.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)

            let symConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            let emojiLbl = UIImageView(image: UIImage(systemName: cat.sfSymbol, withConfiguration: symConfig))
            emojiLbl.contentMode = .scaleAspectFit
            emojiLbl.tintColor = .smTextSecondary
            emojiLbl.isUserInteractionEnabled = false

            let nameLbl = UILabel()
            nameLbl.text = cat.rawValue
            nameLbl.font = .systemFont(ofSize: 11, weight: .medium)
            nameLbl.textColor = .smTextSecondary
            nameLbl.textAlignment = .center
            nameLbl.isUserInteractionEnabled = false

            let stack = UIStackView(arrangedSubviews: [emojiLbl, nameLbl])
            stack.axis = .vertical
            stack.spacing = 4
            NSLayoutConstraint.activate([
                emojiLbl.widthAnchor.constraint(equalToConstant: 28),
                emojiLbl.heightAnchor.constraint(equalToConstant: 28)
            ])
            stack.isUserInteractionEnabled = false
            stack.translatesAutoresizingMaskIntoConstraints = false
            btn.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: btn.centerYAnchor)
            ])

            categoryButtons.append(btn)
            categoryNameLabels.append(nameLbl)
            categoryStack.addArrangedSubview(btn)
        }

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: categoryCard.topAnchor, constant: 14),
            title.leadingAnchor.constraint(equalTo: categoryCard.leadingAnchor, constant: 16),

            categoryStack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            categoryStack.leadingAnchor.constraint(equalTo: categoryCard.leadingAnchor, constant: 16),
            categoryStack.trailingAnchor.constraint(equalTo: categoryCard.trailingAnchor, constant: -16),
            categoryStack.bottomAnchor.constraint(equalTo: categoryCard.bottomAnchor, constant: -14),
            categoryStack.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func buildMemoCard() {
        let title = makeSectionLabel("메모")
        memoField.translatesAutoresizingMaskIntoConstraints = false
        memoField.placeholder = "메모를 입력하세요 (선택)"
        memoField.font = .systemFont(ofSize: 15)
        memoField.textColor = .smTextPrimary
        memoField.attributedPlaceholder = NSAttributedString(
            string: "메모를 입력하세요 (선택)",
            attributes: [.foregroundColor: UIColor.smTextSecondary])

        memoCard.addSubview(title)
        memoCard.addSubview(memoField)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: memoCard.topAnchor, constant: 14),
            title.leadingAnchor.constraint(equalTo: memoCard.leadingAnchor, constant: 16),

            memoField.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            memoField.leadingAnchor.constraint(equalTo: memoCard.leadingAnchor, constant: 16),
            memoField.trailingAnchor.constraint(equalTo: memoCard.trailingAnchor, constant: -16),
            memoField.bottomAnchor.constraint(equalTo: memoCard.bottomAnchor, constant: -14)
        ])
    }

    private func buildDateCard() {
        let title = makeSectionLabel("날짜 및 시간")
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .compact
        datePicker.tintColor = .smPrimary
        datePicker.overrideUserInterfaceStyle = .dark
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

        dateCard.addSubview(title)
        dateCard.addSubview(datePicker)

        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: dateCard.topAnchor, constant: 10),
            datePicker.trailingAnchor.constraint(equalTo: dateCard.trailingAnchor, constant: -16),
            datePicker.bottomAnchor.constraint(equalTo: dateCard.bottomAnchor, constant: -10),

            title.centerYAnchor.constraint(equalTo: datePicker.centerYAnchor),
            title.leadingAnchor.constraint(equalTo: dateCard.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(lessThanOrEqualTo: datePicker.leadingAnchor, constant: -8)
        ])
    }

    private func buildSaveButton() {
        saveButton.setTitle("저장", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        saveButton.layer.cornerRadius = 14
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        validateForm()
    }

    // MARK: - Helpers

    private func makeSectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = text
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = .smTextSecondary
        return l
    }

    // MARK: - Location

    private func fetchLocation() {
        LocationManager.shared.fetchCurrentLocation { [weak self] location in
            guard let self else { return }
            let resolved = location ?? CLLocation(latitude: 37.5665, longitude: 126.9780)
            self.currentLocation = resolved
            LocationManager.shared.reverseGeocode(resolved) { name in
                self.placeName = name
                self.locationLabel.text = name
                self.locationLoadingIndicator.stopAnimating()
            }
        }
    }

    // MARK: - Actions

    @objc private func close() { dismiss(animated: true) }
    @objc private func focusAmount() { amountField.becomeFirstResponder() }

    @objc private func amountChanged() {
        let raw = amountField.text?
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined() ?? ""
        amountValue = Double(raw) ?? 0
        let f = NumberFormatter()
        f.numberStyle = .decimal
        amountLabel.text = amountValue > 0
            ? "₩ \(f.string(from: NSNumber(value: Int(amountValue))) ?? "0")"
            : "₩ 0"
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        let cats = ExpenseCategory.allCases
        guard sender.tag < cats.count else { return }
        selectedCategory = cats[sender.tag]
    }

    @objc private func dateChanged() { selectedDate = datePicker.date }

    @objc private func save() {
        guard let cat = selectedCategory, amountValue > 0 else { return }

        if currentLocation == nil {
            let alert = UIAlertController(
                title: "위치 없음",
                message: "현재 위치를 가져올 수 없어 서울 중심부로 저장됩니다. 그래도 저장하시겠어요?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "저장", style: .default) { [weak self] _ in
                self?.performSave(category: cat, lat: 37.5665, lon: 126.9780)
            })
            present(alert, animated: true)
        } else {
            let lat = currentLocation!.coordinate.latitude
            let lon = currentLocation!.coordinate.longitude
            performSave(category: cat, lat: lat, lon: lon)
        }
    }

    private func performSave(category: ExpenseCategory, lat: Double, lon: Double) {
        let name = (placeName == "위치 확인 중..." || placeName.isEmpty) ? "알 수 없는 위치" : placeName

        CoreDataManager.shared.createExpense(
            amount: amountValue, category: category.rawValue,
            memo: memoField.text?.isEmpty == true ? nil : memoField.text,
            date: selectedDate, latitude: lat, longitude: lon, placeName: name)

        let total = CoreDataManager.shared.totalAmount(for: CoreDataManager.shared.fetchForMonth(Date()))
        NotificationManager.shared.checkBudgetAndNotify(currentTotal: total)

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // 앱 실행 중 예산 초과/80% 시 인앱 알럿 표시
        let budget = UserDefaults.standard.double(forKey: "monthlyBudget")
        if budget > 0 {
            let ratio = total / budget
            let f = NumberFormatter()
            f.numberStyle = .decimal
            let remaining = f.string(from: NSNumber(value: Int(budget - total))) ?? "0"

            var alertTitle: String? = nil
            var alertMessage: String? = nil

            if ratio >= 1.0 {
                alertTitle = "예산 초과"
                alertMessage = "이번 달 예산을 초과했습니다.\n초과 금액: ₩\(f.string(from: NSNumber(value: Int(total - budget))) ?? "0")"
            } else if ratio >= 0.8 {
                alertTitle = "예산 80% 도달"
                alertMessage = "이번 달 예산의 \(Int(ratio * 100))%를 사용했습니다.\n남은 예산: ₩\(remaining)"
            }

            if let title = alertTitle, let message = alertMessage {
                dismiss(animated: true) {
                    let topVC = UIApplication.shared.connectedScenes
                        .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                        .first
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    topVC?.present(alert, animated: true)
                }
                return
            }
        }

        dismiss(animated: true)
    }

    private func updateCategoryButtons() {
        for (i, btn) in categoryButtons.enumerated() {
            let cat = ExpenseCategory.allCases[i]
            let isSelected = cat == selectedCategory
            let iconView = btn.subviews.compactMap { ($0 as? UIStackView)?.arrangedSubviews.first as? UIImageView }.first
            UIView.animate(withDuration: 0.15) {
                btn.backgroundColor = isSelected ? cat.color : .smSurface2
                self.categoryNameLabels[i].textColor = isSelected ? .white : .smTextSecondary
                iconView?.tintColor = isSelected ? .white : .smTextSecondary
                btn.transform = isSelected ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
            }
        }
    }

    private func validateForm() {
        let valid = amountValue > 0 && selectedCategory != nil
        saveButton.isEnabled = valid
        saveButton.backgroundColor = valid ? .smPrimary : .smPrimary.withAlphaComponent(0.35)
        saveButton.setTitleColor(valid ? .white : UIColor.white.withAlphaComponent(0.4), for: .normal)
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

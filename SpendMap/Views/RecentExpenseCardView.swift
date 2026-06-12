// RecentExpenseCardView.swift – Card in Map bottom sheet

import UIKit

final class RecentExpenseCardView: UIView {

    var onTap: (() -> Void)?

    private let categoryDot = UIView()
    private let placeLabel  = UILabel()
    private let amountLabel = UILabel()
    private let timeLabel   = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        backgroundColor = .smSurface2
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.smSeparator.cgColor

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        categoryDot.translatesAutoresizingMaskIntoConstraints = false
        categoryDot.layer.cornerRadius = 5
        addSubview(categoryDot)

        placeLabel.translatesAutoresizingMaskIntoConstraints = false
        placeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        placeLabel.textColor = .smTextPrimary
        placeLabel.numberOfLines = 2
        addSubview(placeLabel)

        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.font = .systemFont(ofSize: 15, weight: .bold)
        amountLabel.textColor = .smPrimary
        addSubview(amountLabel)

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = .smTextSecondary
        addSubview(timeLabel)

        NSLayoutConstraint.activate([
            categoryDot.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            categoryDot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            categoryDot.widthAnchor.constraint(equalToConstant: 10),
            categoryDot.heightAnchor.constraint(equalToConstant: 10),

            placeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            placeLabel.leadingAnchor.constraint(equalTo: categoryDot.trailingAnchor, constant: 8),
            placeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            amountLabel.topAnchor.constraint(equalTo: placeLabel.bottomAnchor, constant: 6),
            amountLabel.leadingAnchor.constraint(equalTo: placeLabel.leadingAnchor),

            timeLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: placeLabel.leadingAnchor),
            timeLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)
        ])
    }

    @objc private func handleTap() { onTap?() }

    func configure(with expense: Expense) {
        let cat = expense.categoryEnum
        categoryDot.backgroundColor = cat.color
        placeLabel.text = expense.placeName
        amountLabel.text = expense.formattedAmount

        if let date = expense.date {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            timeLabel.text = f.string(from: date)
        }
    }
}

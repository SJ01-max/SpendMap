// ExpenseTableCell.swift – Row in ListViewController

import UIKit

final class ExpenseTableCell: UITableViewCell {

    static let reuseIdentifier = "ExpenseTableCell"

    private let categoryCircle = UIView()
    private let emojiView      = UIImageView()
    private let placeLabel     = UILabel()
    private let memoLabel      = UILabel()
    private let amountLabel    = UILabel()
    private let chevron        = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        backgroundColor = .smBackground
        selectionStyle = .none

        // Selection highlight
        let bg = UIView()
        bg.backgroundColor = UIColor.smSurface2.withAlphaComponent(0.5)
        selectedBackgroundView = bg

        // Category circle
        categoryCircle.translatesAutoresizingMaskIntoConstraints = false
        categoryCircle.layer.cornerRadius = 22
        contentView.addSubview(categoryCircle)

        emojiView.translatesAutoresizingMaskIntoConstraints = false
        emojiView.contentMode = .scaleAspectFit
        emojiView.tintColor = .white
        contentView.addSubview(emojiView)

        // Labels
        placeLabel.translatesAutoresizingMaskIntoConstraints = false
        placeLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        placeLabel.textColor = .smTextPrimary
        contentView.addSubview(placeLabel)

        memoLabel.translatesAutoresizingMaskIntoConstraints = false
        memoLabel.font = .systemFont(ofSize: 12)
        memoLabel.textColor = .smTextSecondary
        contentView.addSubview(memoLabel)

        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.font = .systemFont(ofSize: 16, weight: .bold)
        amountLabel.textColor = .smTextPrimary
        amountLabel.textAlignment = .right
        contentView.addSubview(amountLabel)

        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.image = UIImage(systemName: "chevron.right")
        chevron.tintColor = .smTextSecondary
        chevron.contentMode = .scaleAspectFit
        contentView.addSubview(chevron)

        // Separator
        let sep = UIView()
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.backgroundColor = .smSeparator
        contentView.addSubview(sep)

        NSLayoutConstraint.activate([
            categoryCircle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            categoryCircle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoryCircle.widthAnchor.constraint(equalToConstant: 44),
            categoryCircle.heightAnchor.constraint(equalToConstant: 44),

            emojiView.centerXAnchor.constraint(equalTo: categoryCircle.centerXAnchor),
            emojiView.centerYAnchor.constraint(equalTo: categoryCircle.centerYAnchor),
            emojiView.widthAnchor.constraint(equalToConstant: 26),
            emojiView.heightAnchor.constraint(equalToConstant: 26),

            placeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            placeLabel.leadingAnchor.constraint(equalTo: categoryCircle.trailingAnchor, constant: 12),
            placeLabel.trailingAnchor.constraint(equalTo: amountLabel.leadingAnchor, constant: -8),

            memoLabel.topAnchor.constraint(equalTo: placeLabel.bottomAnchor, constant: 3),
            memoLabel.leadingAnchor.constraint(equalTo: placeLabel.leadingAnchor),
            memoLabel.trailingAnchor.constraint(equalTo: placeLabel.trailingAnchor),
            memoLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),

            amountLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -4),

            chevron.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 16),

            sep.leadingAnchor.constraint(equalTo: placeLabel.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    func configure(with expense: Expense) {
        let cat = expense.categoryEnum
        categoryCircle.backgroundColor = cat.color.withAlphaComponent(0.25)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        emojiView.image = UIImage(systemName: cat.sfSymbol, withConfiguration: config)
        emojiView.tintColor = cat.color
        placeLabel.text = expense.placeName
        memoLabel.text = expense.memo?.isEmpty == false ? expense.memo : cat.rawValue
        amountLabel.text = expense.formattedAmount
    }
}

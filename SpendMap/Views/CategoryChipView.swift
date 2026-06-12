// CategoryChipView.swift – Filter chip in ListViewController

import UIKit

final class CategoryChipView: UIView {

    var onTap: (() -> Void)?

    private let iconView  = UIImageView()
    private let nameLabel = UILabel()
    private let stack     = UIStackView()

    let categoryName: String

    init(categoryName: String) {
        self.categoryName = categoryName
        super.init(frame: .zero)
        setupViews()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        layer.cornerRadius = 16
        layer.borderWidth = 1

        nameLabel.font = .systemFont(ofSize: 13, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        stack.axis = .horizontal
        stack.spacing = 5
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        if categoryName == "전체" {
            nameLabel.text = "전체"
            stack.addArrangedSubview(nameLabel)
        } else if let cat = ExpenseCategory(rawValue: categoryName) {
            let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
            iconView.image = UIImage(systemName: cat.sfSymbol, withConfiguration: config)
            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: 16),
                iconView.heightAnchor.constraint(equalToConstant: 16)
            ])
            nameLabel.text = cat.rawValue
            stack.addArrangedSubview(iconView)
            stack.addArrangedSubview(nameLabel)
        }

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -7)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        setSelected(false)
    }

    func setSelected(_ selected: Bool) {
        if selected {
            backgroundColor = .smPrimary
            layer.borderColor = UIColor.smPrimary.cgColor
            nameLabel.textColor = .smBackground
            iconView.tintColor = .smBackground
        } else {
            backgroundColor = .smSurface2
            layer.borderColor = UIColor.smSeparator.cgColor
            nameLabel.textColor = .smTextSecondary
            iconView.tintColor = .smTextSecondary
        }
    }

    @objc private func handleTap() { onTap?() }
}

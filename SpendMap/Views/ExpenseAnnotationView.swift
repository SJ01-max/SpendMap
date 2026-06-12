// ExpenseAnnotationView.swift – Custom map pin

import MapKit

// MARK: - Annotation data model

final class ExpenseAnnotation: MKPointAnnotation {
    let expense: Expense

    init(expense: Expense) {
        self.expense = expense
        super.init()
        coordinate = CLLocationCoordinate2D(latitude: expense.latitude, longitude: expense.longitude)
        title = expense.placeName
        subtitle = expense.formattedAmount
    }
}

// MARK: - Custom annotation view

final class ExpenseAnnotationView: MKAnnotationView {

    static let reuseIdentifier = "ExpenseAnnotationView"

    private let circleView = UIView()
    private let emojiView  = UIImageView()
    private let calloutView = ExpenseCalloutView()

    override var annotation: MKAnnotation? {
        didSet { configure() }
    }

    // MARK: Init

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupViews()
        canShowCallout = false  // custom callout
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Setup

    private func setupViews() {
        frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        centerOffset = CGPoint(x: 0, y: -22)

        // Circle
        circleView.frame = bounds
        circleView.layer.cornerRadius = 22
        circleView.layer.borderWidth = 2
        circleView.layer.borderColor = UIColor.white.cgColor
        circleView.layer.shadowColor = UIColor.black.cgColor
        circleView.layer.shadowOpacity = 0.4
        circleView.layer.shadowRadius = 4
        circleView.layer.shadowOffset = CGSize(width: 0, height: 2)
        addSubview(circleView)

        // Emoji
        emojiView.frame = bounds.insetBy(dx: 10, dy: 10)
        emojiView.contentMode = .scaleAspectFit
        emojiView.tintColor = .white
        addSubview(emojiView)
    }

    private func configure() {
        guard let annotation = annotation as? ExpenseAnnotation else { return }
        let cat = annotation.expense.categoryEnum
        circleView.backgroundColor = cat.color
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        emojiView.image = UIImage(systemName: cat.sfSymbol, withConfiguration: config)
    }

    // MARK: Selection callout

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            guard let annotation = annotation as? ExpenseAnnotation else { return }
            calloutView.configure(with: annotation.expense)
            calloutView.frame = CGRect(x: -(calloutView.intrinsicContentSize.width / 2 - 22), y: -70, width: calloutView.intrinsicContentSize.width, height: 54)
            addSubview(calloutView)
            if animated {
                calloutView.alpha = 0
                calloutView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                UIView.animate(withDuration: 0.2) {
                    self.calloutView.alpha = 1
                    self.calloutView.transform = .identity
                }
            }
        } else {
            if animated {
                UIView.animate(withDuration: 0.15) { self.calloutView.alpha = 0 } completion: { _ in
                    self.calloutView.removeFromSuperview()
                }
            } else {
                calloutView.removeFromSuperview()
            }
        }
    }
}

// MARK: - Callout bubble

private final class ExpenseCalloutView: UIView {

    private let placeLabel = UILabel()
    private let amountLabel = UILabel()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        backgroundColor = UIColor(hex: "#112436")
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor(hex: "#00C896").withAlphaComponent(0.5).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 3)

        placeLabel.font = .systemFont(ofSize: 12, weight: .medium)
        placeLabel.textColor = .smTextSecondary
        placeLabel.textAlignment = .center

        amountLabel.font = .systemFont(ofSize: 15, weight: .bold)
        amountLabel.textColor = .smTextPrimary
        amountLabel.textAlignment = .center

        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .center
        stack.addArrangedSubview(placeLabel)
        stack.addArrangedSubview(amountLabel)

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: max(140, (placeLabel.intrinsicContentSize.width + 24)), height: 54)
    }

    func configure(with expense: Expense) {
        placeLabel.text = expense.placeName
        amountLabel.text = expense.formattedAmount
        invalidateIntrinsicContentSize()
    }
}

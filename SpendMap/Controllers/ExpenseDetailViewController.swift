// ExpenseDetailViewController.swift – Detail view pushed from ListViewController

import UIKit
import MapKit

final class ExpenseDetailViewController: UIViewController {

    private let expense: Expense

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let mapView = MKMapView()
    private let categoryBadge = UIView()
    private let categoryEmojiView = UIImageView()
    private let categoryNameLabel = UILabel()
    private let placeNameLabel = UILabel()
    private let amountLabel = UILabel()

    init(expense: Expense) {
        self.expense = expense
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .smBackground
        title = expense.placeName
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain, target: self, action: #selector(confirmDelete))
        navigationItem.rightBarButtonItem?.tintColor = .smDanger
        setupScrollView()
        setupMap()
        setupDetailsCard()
    }

    // MARK: - Setup

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
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

    private func setupMap() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.overrideUserInterfaceStyle = .dark
        mapView.isUserInteractionEnabled = false
        mapView.layer.cornerRadius = 14
        mapView.clipsToBounds = true
        contentView.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mapView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mapView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mapView.heightAnchor.constraint(equalToConstant: 200)
        ])

        let coord = CLLocationCoordinate2D(latitude: expense.latitude, longitude: expense.longitude)
        let region = MKCoordinateRegion(center: coord, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: false)

        let pin = MKPointAnnotation()
        pin.coordinate = coord
        pin.title = expense.placeName
        mapView.addAnnotation(pin)
    }

    private func setupDetailsCard() {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .smSurface
        card.layer.cornerRadius = 14
        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        let cat = expense.categoryEnum

        // Category badge
        categoryBadge.translatesAutoresizingMaskIntoConstraints = false
        categoryBadge.backgroundColor = cat.color.withAlphaComponent(0.2)
        categoryBadge.layer.cornerRadius = 24
        card.addSubview(categoryBadge)

        categoryEmojiView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        categoryEmojiView.image = UIImage(systemName: cat.sfSymbol, withConfiguration: config)
        categoryEmojiView.tintColor = cat.color
        categoryEmojiView.contentMode = .scaleAspectFit
        card.addSubview(categoryEmojiView)

        categoryNameLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryNameLabel.text = cat.rawValue
        categoryNameLabel.font = .systemFont(ofSize: 12, weight: .medium)
        categoryNameLabel.textColor = cat.color
        categoryNameLabel.textAlignment = .center
        card.addSubview(categoryNameLabel)

        // Amount
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.text = expense.formattedAmount
        amountLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .bold)
        amountLabel.textColor = .smTextPrimary
        amountLabel.textAlignment = .center
        card.addSubview(amountLabel)

        // Info rows
        let rows: [(String, String)] = [
            ("📍 장소", expense.placeName ?? "-"),
            ("📅 날짜", expense.formattedDateTime),
            ("📝 메모", expense.memo?.isEmpty == false ? expense.memo! : "없음")
        ]

        let infoStack = UIStackView()
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoStack.axis = .vertical
        infoStack.spacing = 0
        card.addSubview(infoStack)

        for (i, (key, value)) in rows.enumerated() {
            let row = makeInfoRow(key: key, value: value)
            infoStack.addArrangedSubview(row)

            if i < rows.count - 1 {
                let sep = UIView()
                sep.backgroundColor = .smSeparator
                sep.translatesAutoresizingMaskIntoConstraints = false
                infoStack.addArrangedSubview(sep)
                NSLayoutConstraint.activate([sep.heightAnchor.constraint(equalToConstant: 0.5)])
            }
        }

        NSLayoutConstraint.activate([
            categoryBadge.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            categoryBadge.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            categoryBadge.widthAnchor.constraint(equalToConstant: 64),
            categoryBadge.heightAnchor.constraint(equalToConstant: 64),

            categoryEmojiView.centerXAnchor.constraint(equalTo: categoryBadge.centerXAnchor),
            categoryEmojiView.centerYAnchor.constraint(equalTo: categoryBadge.centerYAnchor),
            categoryEmojiView.widthAnchor.constraint(equalToConstant: 36),
            categoryEmojiView.heightAnchor.constraint(equalToConstant: 36),

            categoryNameLabel.topAnchor.constraint(equalTo: categoryBadge.bottomAnchor, constant: 6),
            categoryNameLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            amountLabel.topAnchor.constraint(equalTo: categoryNameLabel.bottomAnchor, constant: 12),
            amountLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            amountLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            infoStack.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 24),
            infoStack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            infoStack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            infoStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8)
        ])
    }

    private func makeInfoRow(key: String, value: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let keyLabel = UILabel()
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        keyLabel.text = key
        keyLabel.font = .systemFont(ofSize: 14)
        keyLabel.textColor = .smTextSecondary

        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .medium)
        valueLabel.textColor = .smTextPrimary
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0

        container.addSubview(keyLabel)
        container.addSubview(valueLabel)
        NSLayoutConstraint.activate([
            keyLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            keyLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            keyLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),

            valueLabel.leadingAnchor.constraint(equalTo: keyLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            valueLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])
        return container
    }

    @objc private func confirmDelete() {
        let alert = UIAlertController(title: "지출 삭제", message: "이 지출 내역을 삭제하시겠어요?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self else { return }
            CoreDataManager.shared.delete(self.expense)
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

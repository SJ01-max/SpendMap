// MapViewController.swift – Tab 0: Map with expense pins

import UIKit
import MapKit
import CoreLocation

final class MapViewController: UIViewController {

    // MARK: - UI
    private let mapView = MKMapView()
    private let addButton = UIButton(type: .system)
    private let bottomSheet = UIView()
    private let sheetHandleBar = UIView()
    private let recentLabel = UILabel()
    private let recentScrollView = UIScrollView()
    private let recentStack = UIStackView()

    private let cdm = CoreDataManager.shared

    // 현재 위치 커스텀 핀 (시뮬레이터 GPS 버그 대비)
    private let userLocationAnnotation = MKPointAnnotation()
    private var userLocationAnnotationAdded = false

    private let collapsedHeight: CGFloat = 170
    private var expandedHeight: CGFloat { view.bounds.height * 0.75 }
    private var sheetHeightConstraint: NSLayoutConstraint!
    private var panStartHeight: CGFloat = 170

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .smBackground
        setupMap()
        setupAddButton()
        setupZoomButtons()
        setupBottomSheet()
        setupNavigationBar()

        LocationManager.shared.onPermissionDenied = { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(
                title: "위치 권한 필요",
                message: "지도에서 현재 위치를 보려면 설정에서 위치 권한을 허용해주세요.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "나중에", style: .cancel))
            alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            self.present(alert, animated: true)
        }

        LocationManager.shared.onLocationUpdated = { [weak self] loc in
            guard let self else { return }
            self.updateUserLocationAnnotation(to: loc.coordinate)
        }

        LocationManager.shared.requestPermission()

        NotificationCenter.default.addObserver(self,
            selector: #selector(expenseDataChanged),
            name: .expenseDataChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAnnotations()
        loadRecentExpenses()
    }

    // MARK: - 현재 위치 커스텀 애노테이션

    private func updateUserLocationAnnotation(to coord: CLLocationCoordinate2D) {
        userLocationAnnotation.coordinate = coord
        if !userLocationAnnotationAdded {
            userLocationAnnotationAdded = true
            mapView.addAnnotation(userLocationAnnotation)
            // 첫 위치 수신 시 지도 이동
            let region = MKCoordinateRegion(center: coord,
                latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
        }
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar() {
        title = "SpendMap"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "location.fill"),
            style: .plain, target: self, action: #selector(centerOnCurrentLocation)
        )
    }

    // MARK: - Map

    private func setupMap() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.overrideUserInterfaceStyle = .dark
        mapView.showsUserLocation = true  // 실제 기기용 파란 점
        mapView.register(ExpenseAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: ExpenseAnnotationView.reuseIdentifier)

        // 서울 기본 위치
        let seoul = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        let region = MKCoordinateRegion(center: seoul, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: false)

        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - FAB Button

    private func setupAddButton() {
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.backgroundColor = .smPrimary
        addButton.tintColor = .white
        addButton.setImage(UIImage(systemName: "plus",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)), for: .normal)
        addButton.layer.cornerRadius = 28
        addButton.layer.shadowColor = UIColor.smPrimary.cgColor
        addButton.layer.shadowOpacity = 0.5
        addButton.layer.shadowRadius = 8
        addButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addButton.addTarget(self, action: #selector(showAddExpense), for: .touchUpInside)
        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -130),
            addButton.widthAnchor.constraint(equalToConstant: 56),
            addButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - Zoom Buttons

    private func setupZoomButtons() {
        let inBtn  = makeZoomButton(symbol: "plus")
        let outBtn = makeZoomButton(symbol: "minus")

        let stack = UIStackView(arrangedSubviews: [inBtn, outBtn])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 1
        stack.backgroundColor = .smSeparator
        stack.layer.cornerRadius = 10
        stack.clipsToBounds = true

        inBtn.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)
        outBtn.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            inBtn.widthAnchor.constraint(equalToConstant: 44),
            inBtn.heightAnchor.constraint(equalToConstant: 44),
            outBtn.widthAnchor.constraint(equalToConstant: 44),
            outBtn.heightAnchor.constraint(equalToConstant: 44),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -200)
        ])
    }

    private func makeZoomButton(symbol: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor = UIColor(hex: "#0A1520").withAlphaComponent(0.9)
        btn.tintColor = .smTextPrimary
        btn.setImage(UIImage(systemName: symbol,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)), for: .normal)
        return btn
    }

    @objc private func zoomIn() {
        mapView.userTrackingMode = .none
        var region = mapView.region
        region.span.latitudeDelta  = max(region.span.latitudeDelta  * 0.5, 0.001)
        region.span.longitudeDelta = max(region.span.longitudeDelta * 0.5, 0.001)
        mapView.setRegion(region, animated: true)
    }

    @objc private func zoomOut() {
        mapView.userTrackingMode = .none
        var region = mapView.region
        region.span.latitudeDelta  = min(region.span.latitudeDelta  * 2, 90)
        region.span.longitudeDelta = min(region.span.longitudeDelta * 2, 180)
        mapView.setRegion(region, animated: true)
    }

    // MARK: - Bottom Sheet

    private func setupBottomSheet() {
        bottomSheet.translatesAutoresizingMaskIntoConstraints = false
        bottomSheet.backgroundColor = UIColor(hex: "#0A1520").withAlphaComponent(0.95)
        bottomSheet.layer.cornerRadius = 20
        bottomSheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(bottomSheet)

        sheetHandleBar.translatesAutoresizingMaskIntoConstraints = false
        sheetHandleBar.backgroundColor = .smSeparator
        sheetHandleBar.layer.cornerRadius = 2.5
        bottomSheet.addSubview(sheetHandleBar)

        recentLabel.translatesAutoresizingMaskIntoConstraints = false
        recentLabel.text = "최근 지출"
        recentLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        recentLabel.textColor = .smTextPrimary
        bottomSheet.addSubview(recentLabel)

        recentScrollView.translatesAutoresizingMaskIntoConstraints = false
        recentScrollView.showsHorizontalScrollIndicator = false
        bottomSheet.addSubview(recentScrollView)

        recentStack.translatesAutoresizingMaskIntoConstraints = false
        recentStack.axis = .vertical
        recentStack.spacing = 10
        recentScrollView.addSubview(recentStack)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleSheetPan(_:)))
        bottomSheet.addGestureRecognizer(pan)

        sheetHeightConstraint = bottomSheet.heightAnchor.constraint(equalToConstant: collapsedHeight)
        NSLayoutConstraint.activate([
            bottomSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheet.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sheetHeightConstraint,

            sheetHandleBar.topAnchor.constraint(equalTo: bottomSheet.topAnchor, constant: 10),
            sheetHandleBar.centerXAnchor.constraint(equalTo: bottomSheet.centerXAnchor),
            sheetHandleBar.widthAnchor.constraint(equalToConstant: 36),
            sheetHandleBar.heightAnchor.constraint(equalToConstant: 5),

            recentLabel.topAnchor.constraint(equalTo: sheetHandleBar.bottomAnchor, constant: 10),
            recentLabel.leadingAnchor.constraint(equalTo: bottomSheet.leadingAnchor, constant: 20),

            recentScrollView.topAnchor.constraint(equalTo: recentLabel.bottomAnchor, constant: 8),
            recentScrollView.leadingAnchor.constraint(equalTo: bottomSheet.leadingAnchor),
            recentScrollView.trailingAnchor.constraint(equalTo: bottomSheet.trailingAnchor),
            recentScrollView.bottomAnchor.constraint(equalTo: bottomSheet.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            recentStack.topAnchor.constraint(equalTo: recentScrollView.topAnchor, constant: 4),
            recentStack.leadingAnchor.constraint(equalTo: recentScrollView.leadingAnchor, constant: 16),
            recentStack.trailingAnchor.constraint(equalTo: recentScrollView.trailingAnchor, constant: -16),
            recentStack.bottomAnchor.constraint(equalTo: recentScrollView.bottomAnchor, constant: -8),
            recentStack.widthAnchor.constraint(equalTo: recentScrollView.widthAnchor, constant: -32)
        ])
    }

    // MARK: - Data

    private func loadAnnotations() {
        let toRemove = mapView.annotations.filter {
            !($0 is MKUserLocation) && $0 !== userLocationAnnotation
        }
        mapView.removeAnnotations(toRemove)
        let annotations = cdm.fetchAll().map { ExpenseAnnotation(expense: $0) }
        mapView.addAnnotations(annotations)
    }

    private func loadRecentExpenses() {
        recentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let recent = cdm.fetchAll()
        if recent.isEmpty {
            let lbl = UILabel()
            lbl.text = "+ 버튼으로 첫 지출을 기록해보세요"
            lbl.font = .systemFont(ofSize: 13)
            lbl.textColor = .smTextSecondary
            lbl.textAlignment = .center
            recentStack.addArrangedSubview(lbl)
        } else {
            for expense in recent {
                let card = RecentExpenseCardView()
                card.configure(with: expense)
                card.onTap = { [weak self] in
                    let vc = ExpenseDetailViewController(expense: expense)
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
                recentStack.addArrangedSubview(card)
            }
        }
    }

    // MARK: - Actions

    @objc private func centerOnCurrentLocation() {
        // 실제 GPS 또는 주입된 위치 모두 커버
        if let loc = LocationManager.shared.currentLocation {
            let region = MKCoordinateRegion(center: loc.coordinate,
                latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
        } else {
            mapView.setUserTrackingMode(.follow, animated: true)
        }
    }

    @objc private func showAddExpense() {
        let nav = UINavigationController(rootViewController: AddExpenseViewController())
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    @objc private func expenseDataChanged() {
        loadAnnotations()
        loadRecentExpenses()
    }

    // MARK: - Bottom Sheet Pan

    @objc private func handleSheetPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            panStartHeight = sheetHeightConstraint.constant
        case .changed:
            let newHeight = panStartHeight - translation.y
            sheetHeightConstraint.constant = max(collapsedHeight, min(expandedHeight, newHeight))
        case .ended, .cancelled:
            let midpoint = (collapsedHeight + expandedHeight) / 2
            let shouldExpand = sheetHeightConstraint.constant > midpoint || velocity.y < -500
            animateSheet(to: shouldExpand ? expandedHeight : collapsedHeight)
        default: break
        }
    }

    private func animateSheet(to height: CGFloat) {
        sheetHeightConstraint.constant = height
        UIView.animate(withDuration: 0.35, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }

        // 현재 위치 커스텀 파란 점
        if annotation === userLocationAnnotation {
            let id = "UserLocation"
            let v = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            v.annotation = annotation
            v.canShowCallout = false
            v.layer.zPosition = 999

            let size: CGFloat = 24
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
            v.image = renderer.image { ctx in
                // 흰 테두리
                UIColor.white.setFill()
                ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
                // 파란 원
                UIColor.systemBlue.setFill()
                ctx.cgContext.fillEllipse(in: CGRect(x: 3, y: 3, width: size - 6, height: size - 6))
            }
            return v
        }

        // 지출 핀
        let view = mapView.dequeueReusableAnnotationView(
            withIdentifier: ExpenseAnnotationView.reuseIdentifier,
            for: annotation) as? ExpenseAnnotationView
        view?.annotation = annotation
        return view
    }

    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        if annotation === userLocationAnnotation {
            mapView.deselectAnnotation(annotation, animated: false)
            return
        }
        guard let a = annotation as? ExpenseAnnotation else { return }
        let vc = ExpenseDetailViewController(expense: a.expense)
        navigationController?.pushViewController(vc, animated: true)
    }
}

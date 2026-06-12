// LocationManager.swift

import CoreLocation

final class LocationManager: NSObject {

    static let shared = LocationManager()
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
    }

    private let manager = CLLocationManager()
    private var pendingCompletions: [(CLLocation?) -> Void] = []
    private var injectedLocation: CLLocation?

    // 실제 GPS 또는 주입된 위치
    var currentLocation: CLLocation? { manager.location ?? injectedLocation }

    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }
    var onLocationUpdated: ((CLLocation) -> Void)?
    var onPermissionDenied: (() -> Void)?

    // MARK: - Permission + 추적 시작

    func requestPermission() {
        DispatchQueue.main.async {
            switch self.manager.authorizationStatus {
            case .notDetermined:
                self.manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                self.startTracking()
            case .denied, .restricted:
                self.onPermissionDenied?()
            @unknown default:
                break
            }
        }
    }

    func startTracking() {
        manager.startUpdatingLocation()
        // 시뮬레이터 GPS 버그 대비: 3초 내 위치 없으면 서울 자동 주입
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self else { return }
            if self.manager.location == nil && self.injectedLocation == nil {
                self.injectLocation(CLLocation(latitude: 37.5665, longitude: 126.9780))
            }
        }
    }

    func injectLocation(_ loc: CLLocation) {
        injectedLocation = loc
        DispatchQueue.main.async { self.onLocationUpdated?(loc) }
    }

    // MARK: - 일회성 위치 요청

    func fetchCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        if let loc = currentLocation { completion(loc); return }
        pendingCompletions.append(completion)
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self, !self.pendingCompletions.isEmpty else { return }
            let completions = self.pendingCompletions
            self.pendingCompletions.removeAll()
            // 타임아웃 시 서울 폴백
            completions.forEach { $0(CLLocation(latitude: 37.5665, longitude: 126.9780)) }
        }
    }

    // MARK: - Geocode

    func reverseGeocode(_ location: CLLocation, completion: @escaping (String) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            let pm = placemarks?.first
            let name = pm?.name ?? pm?.thoroughfare ?? pm?.subLocality ?? pm?.locality ?? "현재 위치"
            DispatchQueue.main.async { completion(name) }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async {
            self.injectedLocation = nil // 실제 GPS 왔으면 주입값 제거
            let completions = self.pendingCompletions
            self.pendingCompletions.removeAll()
            completions.forEach { $0(loc) }
            self.onLocationUpdated?(loc)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        // 일시적 오류는 무시 (시뮬레이터에서 자주 발생)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startTracking()
            case .denied, .restricted:
                self.onPermissionDenied?()
            default:
                break
            }
        }
    }
}

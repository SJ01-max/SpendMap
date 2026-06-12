// MainTabBarController.swift

import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupViewControllers()
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "#0A1520")

        let normal: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.smTextSecondary
        ]
        let selected: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.smPrimary
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = .smTextSecondary
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normal
        appearance.stackedLayoutAppearance.selected.iconColor = .smPrimary
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selected

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }

    private func setupViewControllers() {
        let mapNav  = makeNav(root: MapViewController(),        title: "지도",  icon: "map")
        let statsNav = makeNav(root: StatisticsViewController(), title: "통계",  icon: "chart.bar")
        let listNav  = makeNav(root: ListViewController(),       title: "목록",  icon: "list.bullet")
        let settNav  = makeNav(root: SettingsViewController(),   title: "설정",  icon: "gearshape")

        viewControllers = [mapNav, statsNav, listNav, settNav]
    }

    private func makeNav(root: UIViewController, title: String, icon: String) -> UINavigationController {
        root.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: icon),
            selectedImage: UIImage(systemName: icon + ".fill")
        )

        let nav = UINavigationController(rootViewController: root)
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = .smBackground
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.smTextPrimary]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.smTextPrimary]
        nav.navigationBar.standardAppearance = navAppearance
        nav.navigationBar.scrollEdgeAppearance = navAppearance
        nav.navigationBar.tintColor = .smPrimary
        return nav
    }
}

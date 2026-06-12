// BarChartView.swift – Weekly bar chart with CoreGraphics

import UIKit

final class BarChartView: UIView {

    struct Bar {
        let label: String  // e.g. "월", "화"
        let amount: Double
    }

    var bars: [Bar] = [] {
        didSet { setNeedsDisplay() }
    }

    var barColor: UIColor = .smPrimary

    private let bottomPadding: CGFloat = 28
    private let topPadding: CGFloat = 12
    private let barCornerRadius: CGFloat = 4

    override func draw(_ rect: CGRect) {
        guard !bars.isEmpty, let ctx = UIGraphicsGetCurrentContext() else { return }

        let maxAmount = bars.map(\.amount).max() ?? 1
        let count = bars.count
        let availableWidth = rect.width
        let barWidth: CGFloat = max(8, (availableWidth / CGFloat(count)) - 8)
        let chartHeight = rect.height - bottomPadding - topPadding

        for (i, bar) in bars.enumerated() {
            let x = (availableWidth / CGFloat(count)) * CGFloat(i) + (availableWidth / CGFloat(count) - barWidth) / 2
            let ratio = maxAmount > 0 ? bar.amount / maxAmount : 0
            let barH = max(barCornerRadius * 2, CGFloat(ratio) * chartHeight)
            let barY = rect.height - bottomPadding - barH

            // Background bar
            let bgPath = UIBezierPath(
                roundedRect: CGRect(x: x, y: topPadding, width: barWidth, height: chartHeight),
                cornerRadius: barCornerRadius
            )
            ctx.setFillColor(UIColor.smSurface2.cgColor)
            bgPath.fill()

            // Colored bar
            if bar.amount > 0 {
                let barPath = UIBezierPath(
                    roundedRect: CGRect(x: x, y: barY, width: barWidth, height: barH),
                    cornerRadius: barCornerRadius
                )
                let alpha: CGFloat = bar.amount == maxAmount ? 1.0 : 0.6
                ctx.setFillColor(barColor.withAlphaComponent(alpha).cgColor)
                barPath.fill()
            }

            // Day label
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.smTextSecondary
            ]
            let labelStr = NSAttributedString(string: bar.label, attributes: attrs)
            let labelSize = labelStr.size()
            labelStr.draw(at: CGPoint(x: x + barWidth / 2 - labelSize.width / 2, y: rect.height - bottomPadding + 6))
        }
    }
}

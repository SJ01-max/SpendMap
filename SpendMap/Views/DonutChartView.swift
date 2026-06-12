// DonutChartView.swift – Custom donut chart with CoreGraphics

import UIKit

final class DonutChartView: UIView {

    struct Segment {
        let category: String
        let amount: Double
        let color: UIColor
    }

    var segments: [Segment] = [] {
        didSet { setNeedsDisplay() }
    }

    private let lineWidth: CGFloat = 28

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2 - 4

        let total = segments.reduce(0) { $0 + $1.amount }
        guard total > 0 else {
            // Draw empty ring
            ctx.setStrokeColor(UIColor.smSurface2.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.strokePath()
            return
        }

        var startAngle: CGFloat = -.pi / 2
        let gap: CGFloat = segments.count > 1 ? 0.04 : 0

        for segment in segments {
            let sweep = CGFloat(segment.amount / total) * .pi * 2
            let endAngle = startAngle + sweep - gap

            ctx.setStrokeColor(segment.color.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.setLineCap(.round)
            ctx.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            ctx.strokePath()

            startAngle = endAngle + gap
        }

        // Center text
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.smTextSecondary
        ]
        let totalStr = formatAmount(total)
        let bigAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let labelStr = NSAttributedString(string: "총 지출", attributes: attrs)
        let amountStr = NSAttributedString(string: totalStr, attributes: bigAttrs)

        let labelSize = labelStr.size()
        let amountSize = amountStr.size()
        let spacing: CGFloat = 4
        let totalH = labelSize.height + spacing + amountSize.height

        labelStr.draw(at: CGPoint(x: center.x - labelSize.width / 2, y: center.y - totalH / 2))
        amountStr.draw(at: CGPoint(x: center.x - amountSize.width / 2, y: center.y - totalH / 2 + labelSize.height + spacing))
    }

    private func formatAmount(_ amount: Double) -> String {
        if amount >= 10000 {
            return "₩\(Int(amount / 10000))만"
        }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return "₩\(f.string(from: NSNumber(value: Int(amount))) ?? "0")"
    }
}

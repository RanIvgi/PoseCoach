import Foundation


final class EMA {
private let alpha: Double
private var y: Double?
init(alpha: Double) { self.alpha = alpha }
func update(value: Double) -> Double {
if let yp = y { y = alpha * value + (1 - alpha) * yp } else { y = value }
return y!
}
}

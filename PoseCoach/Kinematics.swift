import CoreGraphics


func angle(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
let ba = CGPoint(x: a.x - b.x, y: a.y - b.y)
let bc = CGPoint(x: c.x - b.x, y: c.y - b.y)
let dot = ba.x * bc.x + ba.y * bc.y
let mag = (hypot(ba.x, ba.y) * hypot(bc.x, bc.y)).clamped(min: 1e-6, max: 1e9)
let cosv = max(-1.0, min(1.0, Double(dot) / Double(mag)))
return CGFloat(acos(cosv) * 180.0 / .pi)
}


extension CGFloat {
func clamped(min: CGFloat, max: CGFloat) -> CGFloat { return Swift.max(min, Swift.min(self, max)) }
}

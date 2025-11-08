import Foundation
import CoreGraphics
import Combine


final class RepCounter: ObservableObject {
@Published var reps: Int = 0
@Published var feedback: String = "—"


enum Phase { case up, down }
private var phase: Phase = .up


// Tunable thresholds (example for squats)
var bottomKneeAngle: CGFloat = 100 // ≤ this = deep enough
var topKneeAngle: CGFloat = 160 // ≥ this = standing
var maxTorsoLeanDeg: CGFloat = 40 // keep torso reasonably upright


func update(kneeAngle: CGFloat, hipAngle: CGFloat) {
// Simple torso-lean proxy: if hip angle gets too small, we warn.
if hipAngle < (180 - maxTorsoLeanDeg) { feedback = "Torso too forward" }


switch phase {
case .up:
if kneeAngle <= bottomKneeAngle { phase = .down; feedback = "Good depth" }
case .down:
if kneeAngle >= topKneeAngle { reps += 1; phase = .up; feedback = "Nice rep!" }
}
}
}

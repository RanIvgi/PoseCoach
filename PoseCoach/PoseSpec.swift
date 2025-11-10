import Foundation

struct PoseSpec {
    // MediaPipe landmark indexing (33 points typical)
    // Minimal subset for this demo
    static let leftShoulder = 11
    static let rightShoulder = 12
    static let leftHip = 23
    static let rightHip = 24
    static let leftKnee = 25
    static let rightKnee = 26
    static let leftAnkle = 27
    static let rightAnkle = 28

    // Common connections for drawing (subset)
    static let connections: [(Int, Int)] = [
        (11, 12), (11, 23), (12, 24), (23, 24),  // torso
        (11, 25), (25, 27),  // left leg
        (12, 26), (26, 28),  // right leg
    ]
}

struct Landmark {
    let x: CGFloat
    let y: CGFloat
    let z: CGFloat
    let c: CGFloat
}

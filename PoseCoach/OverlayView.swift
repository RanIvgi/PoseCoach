import SwiftUI


struct OverlayView: View {
@ObservedObject var engine: PoseEngine
@ObservedObject var repCounter: RepCounter


// Map normalized [0,1] to screen space
private func mapPoint(_ p: Landmark, _ size: CGSize) -> CGPoint {
// Camera is mirrored (front); flip X for natural selfie layout if desired
CGPoint(x: (1 - p.x) * size.width, y: p.y * size.height)
}


var body: some View {
GeometryReader { geo in
ZStack(alignment: .topLeading) {
// Skeleton paths
Canvas { ctx, size in
let lms = engine.landmarks
guard !lms.isEmpty else { return }


var path = Path()
for (a, b) in engine.connections {
if a < lms.count, b < lms.count {
let pa = mapPoint(lms[a], size)
let pb = mapPoint(lms[b], size)
path.move(to: pa)
path.addLine(to: pb)
}
}
ctx.stroke(path, with: .color(.green), lineWidth: 3)


for lm in lms {
let p = mapPoint(lm, size)
let r = CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)
ctx.fill(Path(ellipseIn: r), with: .color(.yellow))
}
}
.allowsHitTesting(false)


VStack(alignment: .leading, spacing: 6) {
Text("FPS: \(Int(engine.fps.rounded()))")
Text("Knee: \(Int(engine.kneeAngle))° Hip: \(Int(engine.hipAngle))°")
Text("Reps: \(repCounter.reps)")
Text(repCounter.feedback)
.fontWeight(.semibold)
.foregroundStyle(.white)
.padding(6)
.background(.black.opacity(0.4))
.clipShape(RoundedRectangle(cornerRadius: 8))
}
.font(.system(.body, design: .rounded))
.padding(10)
.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
.padding()
}
.onChange(of: engine.kneeAngle) { _, _ in
repCounter.update(kneeAngle: engine.kneeAngle, hipAngle: engine.hipAngle)
}
}
}
}

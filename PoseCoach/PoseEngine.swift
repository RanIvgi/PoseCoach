import AVFoundation
import Combine
import CoreVideo
import Foundation
import MediaPipeTasksVision  // from the SPM package
import UIKit

final class PoseEngine: NSObject, ObservableObject {
    // Published outputs for UI/overlay
    @Published var landmarks: [Landmark] = []
    @Published var connections: [(Int, Int)] = PoseSpec.connections

    @Published var kneeAngle: CGFloat = 180
    @Published var hipAngle: CGFloat = 180
    @Published var fps: Double = 0

    let camera = CameraSession()

    // MediaPipe landmarker
    private var landmarker: PoseLandmarker?
    private var lastTimestamp = CFAbsoluteTimeGetCurrent()

    // Smoothers
    private var kneeEMA = EMA(alpha: 0.25)
    private var hipEMA = EMA(alpha: 0.25)

    override init() {
        super.init()
        camera.sampleBufferHandler = { [weak self] buffer in
            self?.process(buffer: buffer)
        }
        setupLandmarker()
    }

    func start() {
        camera.start()
    }

    func stop() {
        camera.stop()
    }

    private func setupLandmarker() {
        let options = PoseLandmarkerOptions()
        // Prefer HEAVY model if present, otherwise fall back to LITE
        var modelUsed = "pose_landmarker_lite"
        if let full = Bundle.main.path(
            forResource: "pose_landmarker_full",
            ofType: "task"
        ) {
            options.baseOptions.modelAssetPath = full
            modelUsed = "pose_landmarker_full"
        } else if let lite = Bundle.main.path(
            forResource: "pose_landmarker_lite",
            ofType: "task"
        ) {
            options.baseOptions.modelAssetPath = lite
            modelUsed = "pose_landmarker_lite"
        } else {
            print(
                "⚠️ No pose model found. Add pose_landmarker_heavy.task or pose_landmarker_lite.task to the target."
            )
        }
        print("✅ Using model: \(modelUsed)")

        options.numPoses = 1
        options.runningMode = .video
        options.minPoseDetectionConfidence = 0.5
        options.minPosePresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5

        do {
            self.landmarker = try PoseLandmarker(options: options)
            print("✅ PoseLandmarker initialized")
        } catch {
            print("❌ Failed to create PoseLandmarker: \(error)")
        }
    }

    private func process(buffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer),
            let landmarker = landmarker
        else { return }
        let pts = CMSampleBufferGetPresentationTimeStamp(buffer)
        let timeMs = Int(pts.seconds * 1000)
        guard let videoFrame = try? MPImage(pixelBuffer: pixelBuffer) else {
            return
        }
        var result: PoseLandmarkerResult?
        do {
            result = try landmarker.detect(
                videoFrame: videoFrame,
                timestampInMilliseconds: timeMs
            )
        } catch {
            // Throttle error logs to avoid spamming
            let now = CFAbsoluteTimeGetCurrent()
            if now - self.lastNoLandmarkLogTime > 1.0 {
                print("❌ Pose detection failed: \(error)")
                self.lastNoLandmarkLogTime = now
            }
            result = nil
        }

        DispatchQueue.main.async {
            self.updateFPS()
            guard let pose = result?.landmarks.first, !pose.isEmpty else {
                self.landmarks = []
                let now = CFAbsoluteTimeGetCurrent()
                if now - self.lastNoLandmarkLogTime > 1.0 {
                    print("(i) No landmarks detected this frame")
                    self.lastNoLandmarkLogTime = now
                }
                return
            }

            self.landmarks = pose.map {
                Landmark(
                    x: CGFloat($0.x),
                    y: CGFloat($0.y),
                    z: CGFloat($0.z ?? 0),
                    c: CGFloat($0.visibility ?? 0)
                )
            }
            // Update angles once landmarks are set
            self.updateAnglesIfPossible()
        }
    }

    private func updateAnglesIfPossible() {
        // Adjust indices to match your PoseSpec; using left side as in existing code
        guard landmarks.count > max(PoseSpec.leftAnkle, PoseSpec.leftShoulder)
        else { return }

        let hipIdx = PoseSpec.leftHip
        let kneeIdx = PoseSpec.leftKnee
        let ankleIdx = PoseSpec.leftAnkle
        let shoulderIdx = PoseSpec.leftShoulder

        let hipPt = CGPoint(x: landmarks[hipIdx].x, y: landmarks[hipIdx].y)
        let kneePt = CGPoint(x: landmarks[kneeIdx].x, y: landmarks[kneeIdx].y)
        let anklePt = CGPoint(
            x: landmarks[ankleIdx].x,
            y: landmarks[ankleIdx].y
        )
        let shoulderPt = CGPoint(
            x: landmarks[shoulderIdx].x,
            y: landmarks[shoulderIdx].y
        )

        let kneeDeg = angle(a: hipPt, b: kneePt, c: anklePt)
        let hipDeg = angle(a: shoulderPt, b: hipPt, c: kneePt)

        let smoothedKnee = CGFloat(kneeEMA.update(value: Double(kneeDeg)))
        let smoothedHip = CGFloat(hipEMA.update(value: Double(hipDeg)))

        self.kneeAngle = smoothedKnee
        self.hipAngle = smoothedHip
    }

    private func angle(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        // angle at point b formed by a-b-c
        let v1 = CGPoint(x: a.x - b.x, y: a.y - b.y)
        let v2 = CGPoint(x: c.x - b.x, y: c.y - b.y)
        let dot = v1.x * v2.x + v1.y * v2.y
        let mag1 = sqrt(v1.x * v1.x + v1.y * v1.y)
        let mag2 = sqrt(v2.x * v2.x + v2.y * v2.y)
        guard mag1 > 0 && mag2 > 0 else { return 0 }
        let cosVal = max(-1.0, min(1.0, Double(dot / (mag1 * mag2))))
        return CGFloat(acos(cosVal)) * 180 / .pi
    }

    private var lastNoLandmarkLogTime: CFAbsoluteTime = 0
    private var frameTimes: [CFAbsoluteTime] = []
    private func updateFPS() {
        let now = CFAbsoluteTimeGetCurrent()
        frameTimes.append(now)
        // Keep last 30 samples
        if frameTimes.count > 30 {
            frameTimes.removeFirst(frameTimes.count - 30)
        }
        if let first = frameTimes.first, let last = frameTimes.last,
            last > first
        {
            let duration = last - first
            let frames = Double(frameTimes.count - 1)
            self.fps = max(0, frames / duration)
        }
    }
}

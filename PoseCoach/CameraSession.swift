import AVFoundation
import UIKit


final class CameraSession: NSObject {
let session = AVCaptureSession()
var sampleBufferHandler: ((CMSampleBuffer) -> Void)?


private let queue = DispatchQueue(label: "camera.queue")


override init() {
super.init()
configure()
}


private func configure() {
session.beginConfiguration()
session.sessionPreset = .high


guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
let input = try? AVCaptureDeviceInput(device: device) else {
print("Camera not available"); return
}
if session.canAddInput(input) { session.addInput(input) }


let output = AVCaptureVideoDataOutput()
output.alwaysDiscardsLateVideoFrames = true
output.setSampleBufferDelegate(self, queue: queue)
output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
if session.canAddOutput(output) { session.addOutput(output) }


if let connection = output.connection(with: .video) {
if connection.isVideoRotationAngleSupported(90) {
connection.videoRotationAngle = 90 // portrait
}
}


session.commitConfiguration()
}


func start() { queue.async { if !self.session.isRunning { self.session.startRunning() } } }
func stop() { queue.async { if self.session.isRunning { self.session.stopRunning() } } }
}


extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
sampleBufferHandler?(sampleBuffer)
}
}

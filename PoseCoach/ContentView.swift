import SwiftUI

struct ContentView: View {
    @StateObject private var engine = PoseEngine()
    @StateObject private var repCounter = RepCounter()

    var body: some View {
        ZStack(alignment: .topLeading) {
            CameraView(engine: engine)
                .ignoresSafeArea()

            OverlayView(engine: engine, repCounter: repCounter)
                .padding(12)
        }
        .onAppear { engine.start() }  // object, not $engine
        .onDisappear { engine.stop() }  // object, not $engine
    }
}

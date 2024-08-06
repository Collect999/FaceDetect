//
//  ContentView.swift
//  FaceDetectDemo
//
//  Created by Will Wade on 06/08/2024.
//

import SwiftUI
import ARKit

struct ContentView: View {
    @StateObject private var cameraModel = CameraModel()
    @State private var countdown = 3
    @State private var isCountingDown = false // Start countdown manually
    @State private var message = "Press Start to Calibrate"
    @State private var baselineGestures: [ARFaceAnchor.BlendShapeLocation: Float] = [:]
    @State private var gestureChanges: [(String, Float, Float, Float, Float)] = [] // Including before and after averages
    @State private var showTable = false
    
    var body: some View {
        ZStack {
            ARViewContainer(session: cameraModel.session)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if isCountingDown {
                    Text("\(countdown)")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                } else {
                    Text(message)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                    
                    Button(action: startCountdown) {
                        Text("Start")
                            .font(.system(size: 20))
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.top, 20)
                    }
                    
                    if showTable {
                        List(gestureChanges, id: \.0) { (gestureName, change, percentage, beforeAvg, afterAvg) in
                            VStack(alignment: .leading) {
                                Text("Gesture: \(gestureName)")
                                Text("Before Avg: \(String(format: "%.2f", beforeAvg))")
                                Text("After Avg: \(String(format: "%.2f", afterAvg))")
                                Text("Change: \(String(format: "%.2f", change))")
                                Text("Percentage: \(String(format: "%.2f", percentage))%")
                            }
                            .padding()
                        }
                        .frame(maxHeight: 300)
                    }
                }
            }
        }
        .onAppear {
            cameraModel.startCapture() // Initialize camera view
        }
        .alert(isPresented: $cameraModel.showAlert) {
            Alert(title: Text("Unsupported Device"), message: Text("Your device does not support AR features."), dismissButton: .default(Text("OK")))
        }
    }
    
    func startCountdown() {
        isCountingDown = true
        countdown = 3
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
                cameraModel.captureBaselines { capturedGestures in
                    for (gesture, value) in capturedGestures {
                        baselineGestures[gesture, default: 0] += value / 3 // Average over 3 seconds
                    }
                }
            } else {
                timer.invalidate()
                isCountingDown = false
                message = "Detecting gestures..."
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    cameraModel.stopCapture()
                    gestureChanges = cameraModel.getGestureChanges(baselineGestures: baselineGestures)
                    showTable = true
                    
                    if let strongestGesture = gestureChanges.first {
                        message = "Strongest gesture: \(strongestGesture.0) - Change: \(String(format: "%.2f", strongestGesture.1))%"
                    } else {
                        message = "No significant gesture detected."
                    }
                }
            }
        }
    }
    
    func resetDetection() {
        message = "Press Start to Calibrate"
        isCountingDown = false
        baselineGestures.removeAll()
        showTable = false
        gestureChanges.removeAll()
        startCountdown()
    }
}

class CameraModel: NSObject, ObservableObject, ARSessionDelegate {
    @Published var session = ARSession()
    private var gestures: [ARFaceAnchor.BlendShapeLocation: Float] = [:]
    @Published var showAlert = false
    
    override init() {
        super.init()
        setupARKit()
    }
    
    func setupARKit() {
        guard ARFaceTrackingConfiguration.isSupported else {
            DispatchQueue.main.async {
                self.showAlert = true
            }
            return
        }
        
        let configuration = ARFaceTrackingConfiguration()
        session.delegate = self
        session.run(configuration)
    }
    
    func startCapture() {
        session.run(ARFaceTrackingConfiguration(), options: [.resetTracking, .removeExistingAnchors])
    }
    
    func stopCapture() {
        session.pause()
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let faceAnchor = anchor as? ARFaceAnchor {
                processBlendShapes(faceAnchor.blendShapes)
            }
        }
    }
    
    private func processBlendShapes(_ blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
        gestures.removeAll()
        for (blendShape, value) in blendShapes {
            gestures[blendShape] = value.floatValue
        }
    }
    
    func captureBaselines(completion: @escaping ([ARFaceAnchor.BlendShapeLocation: Float]) -> Void) {
        if !gestures.isEmpty {
            completion(gestures)
        }
    }
    
    func getGestureChanges(baselineGestures: [ARFaceAnchor.BlendShapeLocation: Float]) -> [(String, Float, Float, Float, Float)] {
        var changes: [(String, Float, Float, Float, Float)] = []
        
        for (gesture, afterValue) in gestures {
            let beforeValue = baselineGestures[gesture] ?? 0
            let change = afterValue - beforeValue
            let percentageChange = (beforeValue != 0) ? (change / beforeValue) * 100 : 0
            changes.append((gesture.rawValue, change, percentageChange, beforeValue, afterValue))
        }
        
        return changes.sorted(by: { abs($0.1) > abs($1.1) })
    }
    
    func getAllGestures() -> [String: Float] {
        return gestures.reduce(into: [:]) { result, gesture in
            result[gesture.key.rawValue] = gesture.value
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    let session: ARSession
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: UIScreen.main.bounds)
        arView.session = session
        arView.automaticallyUpdatesLighting = true
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

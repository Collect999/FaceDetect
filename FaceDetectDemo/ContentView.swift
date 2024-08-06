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
    @State private var isCountingDown = true
    @State private var message = ""
    @State private var baselineGestures: [ARFaceAnchor.BlendShapeLocation: Float] = [:]
    
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
                }
            }
        }
        .onAppear {
            startCountdown()
        }
    }
    
    func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
                cameraModel.captureBaselines { capturedGestures in
                    for (gesture, value) in capturedGestures {
                        baselineGestures[gesture] = value
                    }
                }
            } else {
                timer.invalidate()
                isCountingDown = false
                message = "Detecting gestures..."
                cameraModel.startCapture()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    cameraModel.stopCapture()
                    let strongestGesture = cameraModel.getStrongestGesture(baselineGestures: baselineGestures)
                    
                    print("Detected gestures: \(cameraModel.getAllGestures())")
                    
                    if strongestGesture.1 > 0 {
                        message = "Strongest gesture: \(strongestGesture.0) (\(String(format: "%.2f", strongestGesture.1)))"
                    } else {
                        message = "No significant gesture detected, restarting..."
                        resetDetection()
                    }
                }
            }
        }
    }
    
    func resetDetection() {
        countdown = 3
        isCountingDown = true
        baselineGestures.removeAll()
        startCountdown()
    }
}

class CameraModel: NSObject, ObservableObject, ARSessionDelegate {
    @Published var session = ARSession()
    private var gestures: [ARFaceAnchor.BlendShapeLocation: Float] = [:]
    private var baselineGestures: [ARFaceAnchor.BlendShapeLocation: Float] = [:]
    
    override init() {
        super.init()
        setupARKit()
    }
    
    func setupARKit() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print("AR Face Tracking is not supported on this device.")
            return
        }
        
        let configuration = ARFaceTrackingConfiguration()
        session.delegate = self
        session.run(configuration)
    }
    
    func startCapture() {
        session.run(ARFaceTrackingConfiguration())
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
        gestures.removeAll() // Clear previous data
        for (blendShape, value) in blendShapes {
            gestures[blendShape] = value.floatValue
        }
    }
    
    func captureBaselines(completion: @escaping ([ARFaceAnchor.BlendShapeLocation: Float]) -> Void) {
        if !gestures.isEmpty {
            completion(gestures)
        }
    }
    
    func getStrongestGesture(baselineGestures: [ARFaceAnchor.BlendShapeLocation: Float]) -> (String, Float) {
        // Calculate the change from baseline for each gesture
        let changes = gestures.mapValues { current in
            current - (baselineGestures[gestures.first?.key ?? ARFaceAnchor.BlendShapeLocation(rawValue: "Unknown")] ?? 0)
        }
        
        // Find the gesture with the most significant change
        guard let strongestChange = changes.max(by: { abs($0.value) < abs($1.value) }) else {
            return ("No significant gesture detected", 0)
        }
        return (strongestChange.key.rawValue, strongestChange.value)
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

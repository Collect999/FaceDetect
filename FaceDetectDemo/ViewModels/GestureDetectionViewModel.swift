//
//  GestureDetectionViewModel.swift
//  FaceDetectDemo
//
//  Created by netzwelt on 20/08/24.
//

import Foundation
import ARKit

class GestureDetectionViewModel: NSObject, ObservableObject, ARSessionDelegate {
    enum DetectionState {
        case countDown
        case detecting
        case stopped
        case none
    }
    
    enum DetectMode {
        case auto
        case manual
        case none
    }

    @Published var session = ARSession()
    @Published var showAlert = false
    @Published var detectionState: DetectionState = .none
    @Published var detectionMode: DetectMode = .auto
    @Published var selectedGesture: Set<String> = []
    @Published var countdownTime = 3
    @Published var detectionTime: CGFloat = 3
    @Published var message = AppStrings.startMessage
    @Published var thresholdValue: Float = 0.5 /// Keeping 0.5 as default
    @Published var manualSelectedGestureFound = false
    
    private var gestures: [ARFaceAnchor.BlendShapeLocation: Float] = [:]
    
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
        detectionState = .stopped
        session.pause()
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard detectionState == .detecting else { return }
        for anchor in anchors {
            if let faceAnchor = anchor as? ARFaceAnchor {
                processBlendShapes(faceAnchor.blendShapes) /// Step 1. When ARView runs, it adds the blend shapes to gestures array.
            }
        }
    }
    
    func captureBaselines(completion: @escaping ([ARFaceAnchor.BlendShapeLocation: Float]) -> Void) {
        if !gestures.isEmpty {
            completion(gestures) /// Step 2. Returns the array back to View after each second in timer.
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
    
    func resetAllGestures() {
        gestures = [:]
    }
    
    private func processBlendShapes(_ blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
        gestures.removeAll()
        for (blendShape, value) in blendShapes {
            gestures[blendShape] = value.floatValue
        }
        
        guard detectionMode == .manual else { return }

        if let selectedBlendShape = blendShapes.first(where: { selectedGesture.contains($0.key.rawValue) })  {
            if selectedBlendShape.value.floatValue > thresholdValue {
                manualSelectedGestureFound = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {[weak self] in
                    self?.manualSelectedGestureFound = false
                })
            }
        }
    }
}

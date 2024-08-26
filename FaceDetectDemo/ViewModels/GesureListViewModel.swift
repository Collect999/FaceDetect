//
//  GesureListViewModel.swift
//  FaceDetectDemo
//
//  Created by netzwelt on 20/08/24.
//

import Foundation
import ARKit

class GesureListViewModel: ObservableObject {
    @Published var selectedItem: String = ""
    @Published var blendShapes = [String]()
    @Published var selectedDetectionMode: GestureDetectionViewModel.DetectMode = .auto
    
    func getAllBlendShapes() {
        let shapes: [ARFaceAnchor.BlendShapeLocation] = [
            .browDownLeft, .browDownRight, .browInnerUp, .browOuterUpLeft, .browOuterUpRight,
            .cheekPuff, .cheekSquintLeft, .cheekSquintRight,
            .eyeBlinkLeft, .eyeBlinkRight, .eyeLookDownLeft, .eyeLookDownRight,
            .eyeLookInLeft, .eyeLookInRight, .eyeLookOutLeft, .eyeLookOutRight,
            .eyeLookUpLeft, .eyeLookUpRight, .eyeSquintLeft, .eyeSquintRight,
            .jawForward, .jawLeft, .jawOpen, .jawRight,
            .mouthClose, .mouthDimpleLeft, .mouthDimpleRight, .mouthFrownLeft,
            .mouthFrownRight, .mouthLeft, .mouthLowerDownLeft, .mouthLowerDownRight,
            .mouthPressLeft, .mouthPressRight, .mouthPucker, .mouthRight,
            .mouthRollLower, .mouthRollUpper, .mouthShrugLower, .mouthShrugUpper,
            .mouthSmileLeft, .mouthSmileRight, .mouthStretchLeft, .mouthStretchRight,
            .mouthUpperUpLeft, .mouthUpperUpRight,
            .noseSneerLeft, .noseSneerRight,
            .tongueOut
        ]
        blendShapes = shapes.map({ $0.rawValue })
    }
}

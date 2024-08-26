//
//  ARViewContainer.swift
//  FaceDetectDemo
//
//  Created by netzwelt on 20/08/24.
//

import Foundation
import RealityKit
import ARKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    let session: ARSession
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: UIScreen.main.bounds)
        arView.session = session
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

//
//  ContentView.swift
//  FaceDetectDemo
//
//  Created by Will Wade on 06/08/2024.
//

import SwiftUI
import ARKit
import RealityKit

struct GestureDetectionView: View {
    @StateObject private var viewModel = GestureDetectionViewModel()
    
    @State private var baselineGestures: [ARFaceAnchor.BlendShapeLocation: Float] = [:]
    @State private var gestureChanges: [(String, Float, Float, Float, Float)] = []
    @State private var isDetectingGestures = false
    @State private var displayDetectionResults = false
    
    var body: some View {
        NavigationView {
            VStack {
                ARViewContainer(session: viewModel.session)
                    .edgesIgnoringSafeArea(.top)
                
                Spacer()
                
                VStack {
                    Text("**\(AppStrings.detectionMode)**: \(viewModel.detectionMode == .auto ? AppStrings.autoDetect : AppStrings.manual)")
                        .padding(.top)
                    /// Show Slider for manual case only
                    if viewModel.detectionMode == .manual {
                        slider()
                    }
                    
                    actionButtons()
                }
                .foregroundStyle(Color.black)
                .padding(.bottom, 8)
                .padding(.horizontal)
                .frame(minHeight: viewModel.detectionMode == .manual ?
                       UIScreen.main.bounds.height * 0.2 :
                        UIScreen.main.bounds.height * 0.15
                )
            }
            .onAppear {
                viewModel.startCapture()
                restoreUserSelections()
            }
            .onDisappear(perform: {
                viewModel.detectionState = .none
            })
            .overlay(
                ZStack {
                    Text(viewModel.message)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(8)
                        .padding(.horizontal, 8)
                        .background(Color.green.opacity(0.5))
                        .cornerRadius(10)
                        .multilineTextAlignment(.center)
                        .opacity((viewModel.message != "") && viewModel.detectionMode == .auto ? 1 : 0)
                    
                    if viewModel.manualSelectedGestureFound {
                        Text("\(viewModel.selectedGesture) gesture found")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.green)
                    }
                },
                alignment: .top
            )
            .overlay(
                VStack {
                    if viewModel.detectionState == .countDown {
                        Text("\(Int(viewModel.countdownTime))")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                            .offset(y: -50)
                    }
                },
                alignment: .center
            )
            .overlay(
                ZStack {
                    if viewModel.detectionState == .stopped && viewModel.detectionMode == .auto {
                        Color.black.opacity(0.3).ignoresSafeArea().onAppear { displayResults() }
                        activityIndicatorView()
                    }
                }
            )
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text(AppStrings.unsupportedDevice), message: Text(AppStrings.arNotSupported), dismissButton: .default(Text(AppStrings.okay)))
            }
            .sheet(isPresented: $displayDetectionResults, content: {
                DetectionResultsView(gestureChanges: gestureChanges, strongestGesture: getStrongestGesture())
            })
            .navigationTitle(viewModel.detectionMode == .auto ? AppStrings.appTitle : viewModel.selectedGesture.joined(separator: ", "))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        GesturesListView { selectedDetectionMode, selectedGestures in
                                viewModel.detectionMode = selectedDetectionMode
                                viewModel.selectedGesture = selectedGestures
                            }
                    } label: {
                        ZStack {
                            Image(systemName: "faceid")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22)
                                .foregroundStyle(Color.white)
                        }
                        .frame(width: 40, height: 40)
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                    .opacity(viewModel.detectionState == .detecting ? 0.5 : 1)
                    .disabled(viewModel.detectionState == .detecting)
                }
            })
        }
    }
    
    private func slider() -> some View {
        VStack {
            HStack {
                Text("0")
                Slider(value: $viewModel.thresholdValue)
                    .tint(Color.green)
                Text("1")
            }
            .font(.system(size: 15, weight: .semibold))
            .padding(.top)
            
            Text(AppStrings.thresholdValue + ": \(viewModel.thresholdValue.formatDecimal())")
                .font(.system(size: 15, weight: .regular))
        }
    }
    
    private func actionButtons() -> some View {
        HStack(spacing: 32) {
            if viewModel.detectionState == .stopped || viewModel.detectionState == .none {
                Button(action: startCountdown) {
                    Text(AppStrings.start)
                        .font(.system(size: 20, weight: .semibold))
                        .frame(minWidth: 150, minHeight: 40)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                        .cornerRadius(10)
                        .padding(.top)
                }
            }
            
            if viewModel.detectionMode == .manual && viewModel.detectionState == .detecting {
                Button(action: stopDetection) {
                    Text(AppStrings.stop)
                        .font(.system(size: 20, weight: .semibold))
                        .frame(minWidth: 150, minHeight: 40)
                        .background(Color.yellow)
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                        .cornerRadius(10)
                        .padding(.top)
                }
            }
        }
    }
    
    private func activityIndicatorView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .black))
            Text(AppStrings.generatingResults)
                .font(.system(size: 13))
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(10)
    }
    
    private func startCountdown() {
        resetCountDown()
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if viewModel.countdownTime > 1 {
                viewModel.countdownTime -= 1
            } else {
                timer.invalidate()
                viewModel.detectionState = .detecting
                startDetection()
            }
        }
    }
    
    private func stopDetection() {
        viewModel.message = AppStrings.pressStart
        //        viewModel.stopCapture()
        viewModel.detectionState = .stopped
        gestureChanges = viewModel.getGestureChanges(baselineGestures: baselineGestures)
    }
    
    private func resetDetection() {
        viewModel.message = AppStrings.pressStart
        baselineGestures.removeAll()
        gestureChanges = []
        viewModel.resetAllGestures()
    }
    
    private func getStrongestGesture() -> String? {
        if let strongestGesture = gestureChanges.first {
            return "\(strongestGesture.0) - \(AppStrings.change): \(String(format: "%.2f", strongestGesture.1))%"
        }
        return nil
    }
    
    private func resetCountDown() {
        if viewModel.countdownTime <= 1 {
            viewModel.startCapture()
            resetDetection()
            viewModel.countdownTime = 3
        }
        viewModel.message = ""
        viewModel.detectionState = .countDown
    }
    
    private func displayResults() {
        guard viewModel.detectionMode == .auto else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            displayDetectionResults = true
            viewModel.detectionState = .none
        }
    }
    
    private func restoreUserSelections() {
        if let selectedDetectionMode =  UserDefaults.standard.value(forKey: StorageKeys.detectionMode) as? Int {
            viewModel.detectionMode = selectedDetectionMode == 1 ? .auto : .manual
        }
        if let selectedGesture = UserDefaults.standard.value(forKey: StorageKeys.selectedGesture) as? String, selectedGesture.isEmpty == false {
            viewModel.selectedGesture = Set([selectedGesture]) 
        }
    }
    
    private func startDetection() {
        viewModel.message = AppStrings.detectingGestures
        
        /// If user has chosen Auto mode then we need to stop the detection automatically afer 3 seconds as of now.
        /// If user chooses manual, then, detection will be stopped based on the tap gesture from user.
        guard viewModel.detectionMode == .auto else { return }
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { detectionTimer in
            if viewModel.detectionTime > 1 {
                viewModel.detectionTime -= 1
                viewModel.captureBaselines { capturedGestures in
                    for (gesture, value) in capturedGestures {
                        baselineGestures[gesture, default: 0] += value / Float(viewModel.detectionTime)
                    }
                }
            } else {
                detectionTimer.invalidate()
                stopDetection()
                viewModel.detectionTime = 3
            }
        }
    }
}

#Preview {
    GestureDetectionView()
}

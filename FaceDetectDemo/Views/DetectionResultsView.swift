//
//  DetectionResultsView.swift
//  FaceDetectDemo
//
//  Created by netzwelt on 21/08/24.
//

import SwiftUI

struct DetectionResultsView: View {
    let gestureChanges: [(String, Float, Float, Float, Float)]
    let strongestGesture: String?
    
    @ObservedObject var viewModel: GesureListViewModel
    @Environment(\.presentationMode) var presentationMode

    
    var body: some View {
        VStack {
            HStack(alignment: strongestGesture == nil ? .center : .top, spacing: 16) {
                Image(systemName: "faceid")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                    .padding(.top, 4)
                
                if let strongestGesture = strongestGesture {
                    VStack(spacing: 20) {
                        Button(action: {
                            // Update the selectedItems with the strongest gesture
                            viewModel.selectedItems = Set([strongestGesture])
                            // Optionally, persist this selection if needed
                        }) {
                            Text("Set \(AppStrings.gestureNames[strongestGesture] ?? strongestGesture) as Selected Gesture")
                                .frame(minWidth: 200, minHeight: 50)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            // Switch to manual mode if needed
                            viewModel.selectedDetectionMode = .manual
                            // Trigger the preview/trigger mode, navigate to the appropriate view
                            presentationMode.wrappedValue.dismiss() // Close the current view if needed
                            // Add logic to navigate or trigger preview
                        }) {
                            Text("Move to Preview/Trigger Mode")
                                .frame(minWidth: 200, minHeight: 50)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 20)
                }
                Spacer()
            }
            .foregroundStyle(Color.white)
            .padding()
            .background(Color.green)
            .cornerRadius(10)
            .padding(.top, 24)
                        
            Text(AppStrings.allDetectedGestures)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
            
            ScrollView{
                ForEach(gestureChanges, id: \.0) { (gestureName, change, percentage, beforeAvg, afterAvg) in
                    LazyVStack(alignment: .leading) {
                        Text("\(AppStrings.gesture): \(gestureName)")
                        Text("\(AppStrings.beforeAvg): \(String(format: "%.2f", beforeAvg))")
                        Text("\(AppStrings.afterAvg): \(String(format: "%.2f", afterAvg))")
                        Text("\(AppStrings.change): \(String(format: "%.2f", change))")
                        Text("\(AppStrings.percentage): \(String(format: "%.2f", percentage))%")
                        Divider()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    DetectionResultsView(
        gestureChanges: [],
        strongestGesture: "Hello may dsdsdssd huue iioueje gjbaest gestures inline in the test",
        viewModel: GesureListViewModel()
    )
}

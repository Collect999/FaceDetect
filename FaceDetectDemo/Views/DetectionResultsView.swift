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
    
    var body: some View {
        VStack {
            HStack(alignment: strongestGesture == nil ? .center : .top, spacing: 16) {
                Image(systemName: "faceid")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                    .padding(.top, 4)
                
                if let strongestGesture {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppStrings.strongestGesture)
                            .font(.system(size: 17, weight: .bold))
                        
                        Text(strongestGesture)
                            .font(.system(size: 17, weight: .medium))
                    }
                } else {
                    Text(AppStrings.noSignificantGestureDetected)
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
    DetectionResultsView(gestureChanges: [], strongestGesture: "Hello may dsdsdssd huue iioueje gjbaest gestures inline in the test")
}

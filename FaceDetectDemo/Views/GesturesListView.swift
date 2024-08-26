//
//  GesturesListView.swift
//  FaceDetectDemo
//
//  Created by netzwelt on 20/08/24.
//

import SwiftUI

struct GesturesListView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject private var viewModel = GesureListViewModel()
    
    var isPreviewEnabled: Bool {
        guard viewModel.selectedDetectionMode == .manual else { return true }
        return viewModel.selectedItem != ""
    }
    var callback: ((GestureDetectionViewModel.DetectMode, String) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(AppStrings.chooseDetection)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            .padding([.leading, .top])
            
            detectionModeActionButtons()
            
            HStack {
                Text(AppStrings.chooseGesture)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            .padding([.leading, .top, .bottom])
            .opacity(viewModel.selectedDetectionMode == .auto ? 0.5 : 1)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    ForEach(viewModel.blendShapes, id: \.self) { blendShape in
                        gestureListRow(shape: blendShape)
                            .opacity(viewModel.selectedDetectionMode == .auto ? 0.5 : 1)
                            .disabled(viewModel.selectedDetectionMode == .auto)
                    }
                }
            }
            .padding(.bottom, 8)
            
            Button(action: {
                callback?(viewModel.selectedDetectionMode, viewModel.selectedItem)
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text(AppStrings.preview)
                    .frame(minWidth: 200, minHeight: 50)
                    .background(isPreviewEnabled ? Color.green : Color("AppGray"))
                    .cornerRadius(10)
            })
            .padding(.vertical)
            .foregroundStyle(Color.white)
            .font(.system(size: 17, weight: .semibold))
            .disabled(!isPreviewEnabled)
        }
        .onAppear(perform: {
            restoreUserSelections()
            viewModel.getAllBlendShapes()
        })
        .navigationTitle(AppStrings.settings)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    func gestureListRow(shape: String) -> some View {
        VStack {
            HStack {
                Image(systemName: viewModel.selectedItem == shape ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                    .foregroundColor(.black)
                Text(shape)
                    .font(.system(size: 16, weight: .medium))
                Spacer()
            }
            
            Divider()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .background(Color.white)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.selectedItem = shape
            }
        }
    }
    
    private func detectionModeActionButtons() -> some View {
        HStack(spacing: 32) {
            Button(action: {
                viewModel.selectedDetectionMode = .auto
                viewModel.selectedItem = ""
            }) {
                Text(AppStrings.autoDetect)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(minWidth: 120, minHeight: 40)
                    .background(viewModel.selectedDetectionMode == .auto ? Color.green : Color("AppGray"))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                    .cornerRadius(20)
                    .padding(.top)
            }
            
            Button(action: {
                viewModel.selectedDetectionMode = .manual
            }) {
                Text(AppStrings.manual)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(minWidth: 120, minHeight: 40)
                    .background(viewModel.selectedDetectionMode == .manual ? Color.green : Color("AppGray"))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                    .cornerRadius(20)
                    .padding(.top)
            }
        }
    }
    
    private func restoreUserSelections() {
        if let selectedDetectionMode =  UserDefaults.standard.value(forKey: StorageKeys.detectionMode) as? Int {
            viewModel.selectedDetectionMode = selectedDetectionMode == 1 ? .auto : .manual
        }
        if let selectedGesture = UserDefaults.standard.value(forKey: StorageKeys.selectedGesture) as? String, selectedGesture.isEmpty == false {
            viewModel.selectedItem = selectedGesture
        }
    }
}

#Preview {
    NavigationView {
        GesturesListView()
    }
}

//
//  ComponentSelectorView.swift
//  Components_AR
//
//  Created by Main on 2025-12-17.
//

import SwiftUI

/// Bottom toolbar for selecting models to place
struct ComponentSelectorView: View {
    @ObservedObject var sessionManager: ARSessionManager
    @State private var showScalePicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Action buttons for selected model
            if sessionManager.activeModel != nil {
                SelectedModelActions(sessionManager: sessionManager, showScalePicker: $showScalePicker)
                    .padding(.bottom, 8)
            }

            // Scale picker sheet
            if showScalePicker {
                ScalePickerView(sessionManager: sessionManager, isPresented: $showScalePicker)
                    .padding(.bottom, 8)
            }

            // Model type selector
            ModelTypeSelectorView(sessionManager: sessionManager)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

/// Actions for the currently selected model
struct SelectedModelActions: View {
    @ObservedObject var sessionManager: ARSessionManager
    @Binding var showScalePicker: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Scale button
            Button(action: {
                withAnimation {
                    showScalePicker.toggle()
                }
            }) {
                VStack {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 20))
                    Text("Scale")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .frame(width: 60, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.8))
                )
            }

            // Duplicate button
            Button(action: {
                Task {
                    await sessionManager.duplicateActiveModel()
                }
            }) {
                VStack {
                    Image(systemName: "plus.square.on.square")
                        .font(.system(size: 20))
                    Text("Copy")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .frame(width: 60, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green.opacity(0.8))
                )
            }

            // Delete button
            Button(action: {
                sessionManager.deleteActiveModel()
            }) {
                VStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20))
                    Text("Delete")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .frame(width: 60, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(0.8))
                )
            }

            // Deselect button
            Button(action: {
                sessionManager.deselectAll()
            }) {
                VStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                    Text("Deselect")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .frame(width: 60, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.8))
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.6))
        )
    }
}

/// Scale picker for adjusting model size
struct ScalePickerView: View {
    @ObservedObject var sessionManager: ARSessionManager
    @Binding var isPresented: Bool

    var body: some View {
        HStack(spacing: 16) {
            ForEach(ARModelScale.allCases) { scale in
                Button(action: {
                    sessionManager.updateActiveModelScale(scale)
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    VStack {
                        Image(systemName: scale.iconName)
                            .font(.system(size: 24))
                        Text(scale.rawValue)
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .frame(width: 70, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(sessionManager.selectedScale == scale
                                ? Color.blue.opacity(0.8)
                                : Color.gray.opacity(0.6))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.6))
        )
    }
}

/// Selector for model types
struct ModelTypeSelectorView: View {
    @ObservedObject var sessionManager: ARSessionManager

    var body: some View {
        HStack(spacing: 12) {
            ForEach(ARModelType.allCases) { modelType in
                Button(action: {
                    sessionManager.selectedModelType = modelType
                }) {
                    VStack {
                        Image(systemName: modelType.iconName)
                            .font(.system(size: 24))
                        Text(modelType.displayName)
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(.white)
                    .frame(width: 80, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(sessionManager.selectedModelType == modelType
                                ? Color.orange.opacity(0.8)
                                : Color.gray.opacity(0.6))
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.6))
        )
    }
}

/// Top toolbar with utility actions
struct TopToolbarView: View {
    @ObservedObject var sessionManager: ARSessionManager
    @State private var showClearAlert = false

    var body: some View {
        HStack {
            // Model count
            HStack(spacing: 8) {
                if sessionManager.isLoadingModel {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text("\(sessionManager.placedModels.count) objects")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.6))
            )

            Spacer()

            // Clear all button
            Button(action: {
                showClearAlert = true
            }) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.8))
                            .frame(width: 36, height: 36)
                    )
            }
            .alert("Clear All Objects", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    sessionManager.clearAllModels()
                }
            } message: {
                Text("Are you sure you want to remove all placed objects?")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
}

/// Instructions overlay
struct InstructionsView: View {
    var body: some View {
        VStack {
            Text("Tap on a surface to place models")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.6))
                )

            Text("Drag models to move them")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.4))
                )
        }
    }
}

#Preview {
    ZStack {
        Color.gray
        VStack {
            Spacer()
            ComponentSelectorView(sessionManager: ARSessionManager())
        }
    }
}

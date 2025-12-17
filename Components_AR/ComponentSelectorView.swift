//
//  ComponentSelectorView.swift
//  Components_AR
//
//  Created by Main on 2025-12-17.
//

import SwiftUI

/// Bottom toolbar for selecting components to place
struct ComponentSelectorView: View {
    @ObservedObject var sessionManager: ARSessionManager
    @State private var showColorPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Action buttons for selected component
            if sessionManager.activeComponent != nil {
                SelectedComponentActions(sessionManager: sessionManager, showColorPicker: $showColorPicker)
                    .padding(.bottom, 8)
            }

            // Color picker sheet
            if showColorPicker {
                ColorPickerView(sessionManager: sessionManager, isPresented: $showColorPicker)
                    .padding(.bottom, 8)
            }

            // Component type selector
            ComponentTypeSelectorView(sessionManager: sessionManager)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

/// Actions for the currently selected component
struct SelectedComponentActions: View {
    @ObservedObject var sessionManager: ARSessionManager
    @Binding var showColorPicker: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Color button
            Button(action: {
                withAnimation {
                    showColorPicker.toggle()
                }
            }) {
                VStack {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 20))
                    Text("Color")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .frame(width: 60, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(sessionManager.activeComponent?.color.swiftUIColor ?? .blue)
                )
            }

            // Duplicate button
            Button(action: {
                sessionManager.duplicateActiveComponent()
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
                        .fill(Color.blue.opacity(0.8))
                )
            }

            // Delete button
            Button(action: {
                sessionManager.deleteActiveComponent()
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

/// Color picker for changing component colors
struct ColorPickerView: View {
    @ObservedObject var sessionManager: ARSessionManager
    @Binding var isPresented: Bool

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(ARComponentColor.allCases) { color in
                Button(action: {
                    sessionManager.selectedColor = color
                    sessionManager.updateActiveComponentColor(color)
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: sessionManager.selectedColor == color ? 3 : 0)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
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

/// Selector for component types
struct ComponentTypeSelectorView: View {
    @ObservedObject var sessionManager: ARSessionManager

    var body: some View {
        HStack(spacing: 12) {
            ForEach(ARComponentType.allCases) { componentType in
                Button(action: {
                    sessionManager.selectedComponentType = componentType
                }) {
                    VStack {
                        Image(systemName: componentType.iconName)
                            .font(.system(size: 24))
                        Text(componentType.rawValue)
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(sessionManager.selectedComponentType == componentType
                                ? sessionManager.selectedColor.swiftUIColor.opacity(0.8)
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
            // Component count
            Text("\(sessionManager.placedComponents.count) objects")
                .font(.headline)
                .foregroundColor(.white)
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
                    sessionManager.clearAllComponents()
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
            Text("Tap on a surface to place objects")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.6))
                )

            Text("Drag objects to move them")
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

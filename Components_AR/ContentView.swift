//
//  ContentView.swift
//  Components_AR
//
//  Created by Main on 2025-12-17.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    @StateObject private var sessionManager = ARSessionManager()
    @State private var showInstructions = true

    var body: some View {
        ZStack {
            // AR View
            ARViewContainer(sessionManager: sessionManager)
                .edgesIgnoringSafeArea(.all)

            // UI Overlay
            VStack {
                // Top toolbar
                TopToolbarView(sessionManager: sessionManager)

                // Instructions (auto-hide after first placement)
                if showInstructions && sessionManager.placedModels.isEmpty {
                    InstructionsView()
                        .padding(.top, 20)
                }

                Spacer()

                // Bottom component selector
                ComponentSelectorView(sessionManager: sessionManager)
            }

            // Loading overlay
            if sessionManager.isLoadingModel {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Loading model...")
                        .foregroundColor(.white)
                        .padding(.top, 10)
                }
            }
        }
        .onChange(of: sessionManager.placedModels.count) { oldValue, newValue in
            if newValue > 0 {
                withAnimation {
                    showInstructions = false
                }
            }
        }
    }
}

/// Container for the AR view with gesture handling
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var sessionManager: ARSessionManager

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }

        arView.session.run(configuration)

        // Add coaching overlay for better UX
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)

        // Setup scene anchor
        let anchor = AnchorEntity(plane: .horizontal)
        arView.scene.addAnchor(anchor)

        // Store reference to anchor in coordinator and session manager
        context.coordinator.sceneAnchor = anchor
        context.coordinator.arView = arView
        sessionManager.sceneAnchor = anchor

        // Add gesture recognizers
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)

        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        arView.addGestureRecognizer(longPressGesture)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Update coordinator references
        context.coordinator.sessionManager = sessionManager
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(sessionManager: sessionManager)
    }

    class Coordinator: NSObject {
        var sessionManager: ARSessionManager
        var sceneAnchor: AnchorEntity?
        var arView: ARView?
        var draggedEntity: ModelEntity?
        var dragStartPosition: SIMD3<Float>?

        init(sessionManager: ARSessionManager) {
            self.sessionManager = sessionManager
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }

            let location = gesture.location(in: arView)

            // First, check if we tapped on an existing entity
            if let hitEntity = arView.entity(at: location) {
                // Find the model entity (might be a child)
                if let modelEntity = findModelEntity(from: hitEntity) {
                    Task { @MainActor in
                        if let model = findModel(for: modelEntity) {
                            sessionManager.selectModel(model)
                        }
                    }
                    return
                }
            }

            // If no entity was tapped, try to place a new model
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)

            if let firstResult = results.first {
                let position = simd_make_float3(firstResult.worldTransform.columns.3)

                // Convert to local space relative to anchor
                if let anchor = sceneAnchor {
                    let localPosition = anchor.convert(position: position, from: nil)

                    Task { @MainActor in
                        await addNewModel(at: localPosition)
                    }
                }
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = arView else { return }

            let location = gesture.location(in: arView)

            switch gesture.state {
            case .began:
                // Check if we're starting to drag an entity
                if let hitEntity = arView.entity(at: location),
                   let modelEntity = findModelEntity(from: hitEntity) {
                    draggedEntity = modelEntity
                    dragStartPosition = modelEntity.position

                    Task { @MainActor in
                        if let model = findModel(for: modelEntity) {
                            sessionManager.selectModel(model)
                            sessionManager.isDragging = true
                        }
                    }
                }

            case .changed:
                guard let draggedEntity = draggedEntity else { return }

                // Raycast to find new position
                let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)

                if let firstResult = results.first {
                    let worldPosition = simd_make_float3(firstResult.worldTransform.columns.3)

                    // Convert to local space
                    if let anchor = sceneAnchor {
                        let localPosition = anchor.convert(position: worldPosition, from: nil)

                        // Maintain the Y position (height) from the original placement
                        var newPosition = localPosition
                        if let startY = dragStartPosition?.y {
                            newPosition.y = startY
                        }

                        draggedEntity.position = newPosition

                        Task { @MainActor in
                            if let model = findModel(for: draggedEntity) {
                                model.position = newPosition
                            }
                        }
                    }
                }

            case .ended, .cancelled:
                Task { @MainActor in
                    sessionManager.isDragging = false
                }
                draggedEntity = nil
                dragStartPosition = nil

            default:
                break
            }
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let arView = arView, gesture.state == .began else { return }

            let location = gesture.location(in: arView)

            // Check if we long-pressed on an entity
            if let hitEntity = arView.entity(at: location),
               let modelEntity = findModelEntity(from: hitEntity) {

                Task { @MainActor in
                    if let model = findModel(for: modelEntity) {
                        sessionManager.selectModel(model)
                    }
                }
            }
        }

        private func findModelEntity(from entity: Entity) -> ModelEntity? {
            if let modelEntity = entity as? ModelEntity {
                return modelEntity
            }

            // Check children
            for child in entity.children {
                if let found = findModelEntity(from: child) {
                    return found
                }
            }

            // Check parent
            var current: Entity? = entity
            while let parent = current?.parent {
                if let modelEntity = parent as? ModelEntity {
                    return modelEntity
                }
                current = parent
            }

            return nil
        }

        private func findModel(for entity: ModelEntity) -> PlacedARModel? {
            return sessionManager.placedModels.first { model in
                guard let modelEntity = model.entity else { return false }
                return modelEntity === entity || modelEntity.name == entity.name
            }
        }

        private func addNewModel(at position: SIMD3<Float>) async {
            guard let anchor = sceneAnchor else { return }

            let model = PlacedARModel(
                modelType: sessionManager.selectedModelType,
                position: position,
                scale: sessionManager.selectedScale
            )

            sessionManager.isLoadingModel = true

            await model.loadModel()

            guard let entity = model.entity else {
                sessionManager.isLoadingModel = false
                return
            }

            anchor.addChild(entity)
            sessionManager.placedModels.append(model)
            sessionManager.selectModel(model)
            sessionManager.isLoadingModel = false
        }
    }
}

#Preview {
    ContentView()
}

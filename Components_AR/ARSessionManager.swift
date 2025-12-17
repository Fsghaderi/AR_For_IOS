//
//  ARSessionManager.swift
//  Components_AR
//
//  Created by Main on 2025-12-17.
//

import Foundation
import SwiftUI
import RealityKit
import Combine

/// Manages the AR session state and placed models
@MainActor
class ARSessionManager: ObservableObject {
    /// All placed models in the scene
    @Published var placedModels: [PlacedARModel] = []

    /// Currently selected model type for placement
    @Published var selectedModelType: ARModelType = .logFort

    /// Currently selected scale for new models
    @Published var selectedScale: ARModelScale = .medium

    /// Currently selected/active model in the scene (for editing)
    @Published var activeModel: PlacedARModel?

    /// Whether the user is currently dragging a model
    @Published var isDragging: Bool = false

    /// Whether a model is currently being loaded
    @Published var isLoadingModel: Bool = false

    /// The anchor entity that holds all placed models
    var sceneAnchor: AnchorEntity?

    init() {}

    /// Add a new model at the specified position
    func addModel(at position: SIMD3<Float>) async {
        guard let anchor = sceneAnchor else { return }

        isLoadingModel = true

        let model = PlacedARModel(
            modelType: selectedModelType,
            position: position,
            scale: selectedScale
        )

        // Load the model asynchronously
        await model.loadModel()

        guard let entity = model.entity else {
            isLoadingModel = false
            return
        }

        anchor.addChild(entity)
        placedModels.append(model)

        // Select the newly placed model
        selectModel(model)
        isLoadingModel = false
    }

    /// Remove a model from the scene
    func removeModel(_ model: PlacedARModel) {
        model.entity?.removeFromParent()
        placedModels.removeAll { $0.id == model.id }

        if activeModel?.id == model.id {
            activeModel = nil
        }
    }

    /// Remove all models from the scene
    func clearAllModels() {
        for model in placedModels {
            model.entity?.removeFromParent()
        }
        placedModels.removeAll()
        activeModel = nil
    }

    /// Select a model for editing
    func selectModel(_ model: PlacedARModel?) {
        // Deselect previous model
        activeModel?.setHighlighted(false)

        // Select new model
        activeModel = model
        model?.setHighlighted(true)
    }

    /// Deselect the active model
    func deselectAll() {
        activeModel?.setHighlighted(false)
        activeModel = nil
    }

    /// Find a model by its entity
    func findModel(by entity: Entity) -> PlacedARModel? {
        return placedModels.first { $0.entity === entity || $0.entity?.name == entity.name }
    }

    /// Find a model by its ID
    func findModel(by id: UUID) -> PlacedARModel? {
        return placedModels.first { $0.id == id }
    }

    /// Update the scale of the active model
    func updateActiveModelScale(_ scale: ARModelScale) {
        activeModel?.updateScale(scale)
        selectedScale = scale
    }

    /// Move the active model to a new position
    func moveActiveModel(to position: SIMD3<Float>) {
        activeModel?.updatePosition(position)
    }

    /// Delete the currently selected model
    func deleteActiveModel() {
        guard let model = activeModel else { return }
        removeModel(model)
    }

    /// Duplicate the active model
    func duplicateActiveModel() async {
        guard let model = activeModel else { return }

        isLoadingModel = true

        // Create offset position
        let offset: SIMD3<Float> = [0.15, 0, 0.15]
        let newPosition = model.position + offset

        let newModel = PlacedARModel(
            modelType: model.modelType,
            position: newPosition,
            scale: model.scale
        )

        await newModel.loadModel()

        guard let entity = newModel.entity else {
            isLoadingModel = false
            return
        }

        sceneAnchor?.addChild(entity)
        placedModels.append(newModel)
        selectModel(newModel)
        isLoadingModel = false
    }
}

//
//  ARComponent.swift
//  Components_AR
//
//  Created by Main on 2025-12-17.
//

import Foundation
import SwiftUI
import RealityKit

/// Represents different types of 3D models that can be placed in AR
enum ARModelType: String, CaseIterable, Identifiable {
    case logFort = "LogFort"
    case logMash = "LogMash"
    case stumpvilleHouse = "StumpvilleHouse"

    var id: String { rawValue }

    /// Display name for the model
    var displayName: String {
        switch self {
        case .logFort: return "Log Fort"
        case .logMash: return "Log Mash"
        case .stumpvilleHouse: return "Stumpville House"
        }
    }

    /// Icon name for the component selector
    var iconName: String {
        switch self {
        case .logFort: return "building.fill"
        case .logMash: return "house.lodge.fill"
        case .stumpvilleHouse: return "house.fill"
        }
    }

    /// File name of the USD model
    var fileName: String {
        return rawValue + ".usdc"
    }

    /// Load the 3D model entity
    func loadModel() async -> ModelEntity? {
        do {
            let entity = try await ModelEntity(named: fileName)
            entity.generateCollisionShapes(recursive: true)
            return entity
        } catch {
            print("Failed to load model \(fileName): \(error)")
            // Return a fallback box if model fails to load
            return createFallbackEntity()
        }
    }

    /// Create a fallback entity if model loading fails
    private func createFallbackEntity() -> ModelEntity {
        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.generateCollisionShapes(recursive: false)
        return entity
    }
}

/// Available scale options for AR models
enum ARModelScale: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var id: String { rawValue }

    var scaleFactor: Float {
        switch self {
        case .small: return 0.005
        case .medium: return 0.01
        case .large: return 0.02
        }
    }

    var iconName: String {
        switch self {
        case .small: return "s.circle.fill"
        case .medium: return "m.circle.fill"
        case .large: return "l.circle.fill"
        }
    }
}

/// Represents a placed AR model in the scene
class PlacedARModel: Identifiable, ObservableObject {
    let id: UUID
    let modelType: ARModelType
    var entity: ModelEntity?
    var anchorEntity: AnchorEntity?
    var position: SIMD3<Float>
    var scale: ARModelScale
    @Published var isSelected: Bool = false
    @Published var isLoading: Bool = true

    init(modelType: ARModelType, position: SIMD3<Float>, scale: ARModelScale = .medium) {
        self.id = UUID()
        self.modelType = modelType
        self.position = position
        self.scale = scale
    }

    /// Load the model asynchronously
    func loadModel() async {
        guard let loadedEntity = await modelType.loadModel() else {
            await MainActor.run {
                self.isLoading = false
            }
            return
        }

        await MainActor.run {
            self.entity = loadedEntity
            self.entity?.name = id.uuidString
            self.entity?.scale = SIMD3<Float>(repeating: scale.scaleFactor)
            self.entity?.position = position
            self.isLoading = false
        }
    }

    /// Update the entity's position
    func updatePosition(_ newPosition: SIMD3<Float>) {
        self.position = newPosition
        self.entity?.position = newPosition
    }

    /// Update the entity's scale
    func updateScale(_ newScale: ARModelScale) {
        self.scale = newScale
        self.entity?.scale = SIMD3<Float>(repeating: newScale.scaleFactor)
    }

    /// Highlight or unhighlight the entity when selected
    func setHighlighted(_ highlighted: Bool) {
        isSelected = highlighted
        // Visual feedback could be added here (e.g., outline shader)
    }
}

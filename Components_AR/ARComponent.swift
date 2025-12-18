//
//  ARComponent.swift
//  Components_AR
//
//  Created by Main on 2025-12-17.
//

import Foundation
import SwiftUI
import RealityKit
import Combine

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

    /// Load the 3D model entity - creates procedural models
    func loadModel() async -> ModelEntity? {
        // Create procedural models instead of loading from files
        return createProceduralModel()
    }

    /// Create a procedural 3D model based on the model type
    private func createProceduralModel() -> ModelEntity {
        let entity = ModelEntity()

        switch self {
        case .logFort:
            // Create a fort-like structure with multiple boxes
            let baseSize: Float = 0.15
            let wallHeight: Float = 0.12
            let wallThickness: Float = 0.02

            let woodMaterial = SimpleMaterial(color: .init(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0), roughness: 0.8, isMetallic: false)

            // Front wall
            let frontWall = ModelEntity(
                mesh: .generateBox(size: [baseSize, wallHeight, wallThickness]),
                materials: [woodMaterial]
            )
            frontWall.position = [0, wallHeight/2, -baseSize/2]

            // Back wall
            let backWall = ModelEntity(
                mesh: .generateBox(size: [baseSize, wallHeight, wallThickness]),
                materials: [woodMaterial]
            )
            backWall.position = [0, wallHeight/2, baseSize/2]

            // Left wall
            let leftWall = ModelEntity(
                mesh: .generateBox(size: [wallThickness, wallHeight, baseSize]),
                materials: [woodMaterial]
            )
            leftWall.position = [-baseSize/2, wallHeight/2, 0]

            // Right wall
            let rightWall = ModelEntity(
                mesh: .generateBox(size: [wallThickness, wallHeight, baseSize]),
                materials: [woodMaterial]
            )
            rightWall.position = [baseSize/2, wallHeight/2, 0]

            // Add towers at corners
            let towerMaterial = SimpleMaterial(color: .init(red: 0.5, green: 0.3, blue: 0.15, alpha: 1.0), roughness: 0.8, isMetallic: false)
            let towerHeight: Float = 0.18
            let towerSize: Float = 0.03

            let corners: [SIMD3<Float>] = [
                [-baseSize/2, towerHeight/2, -baseSize/2],
                [baseSize/2, towerHeight/2, -baseSize/2],
                [-baseSize/2, towerHeight/2, baseSize/2],
                [baseSize/2, towerHeight/2, baseSize/2]
            ]

            for corner in corners {
                let tower = ModelEntity(
                    mesh: .generateBox(size: [towerSize, towerHeight, towerSize]),
                    materials: [towerMaterial]
                )
                tower.position = corner
                entity.addChild(tower)
            }

            entity.addChild(frontWall)
            entity.addChild(backWall)
            entity.addChild(leftWall)
            entity.addChild(rightWall)

        case .logMash:
            // Create a mash/shelter structure
            let roofMaterial = SimpleMaterial(color: .init(red: 0.7, green: 0.5, blue: 0.3, alpha: 1.0), roughness: 0.7, isMetallic: false)
            let baseMaterial = SimpleMaterial(color: .init(red: 0.55, green: 0.35, blue: 0.2, alpha: 1.0), roughness: 0.8, isMetallic: false)

            // Base platform
            let base = ModelEntity(
                mesh: .generateBox(size: [0.12, 0.02, 0.12]),
                materials: [baseMaterial]
            )
            base.position = [0, 0.01, 0]

            // Support pillars
            let pillarHeight: Float = 0.08
            let pillarPositions: [SIMD3<Float>] = [
                [-0.04, pillarHeight/2 + 0.02, -0.04],
                [0.04, pillarHeight/2 + 0.02, -0.04],
                [-0.04, pillarHeight/2 + 0.02, 0.04],
                [0.04, pillarHeight/2 + 0.02, 0.04]
            ]

            for pos in pillarPositions {
                let pillar = ModelEntity(
                    mesh: .generateBox(size: [0.015, pillarHeight, 0.015]),
                    materials: [baseMaterial]
                )
                pillar.position = pos
                entity.addChild(pillar)
            }

            // Angled roof
            let roof = ModelEntity(
                mesh: .generateBox(size: [0.14, 0.02, 0.14], cornerRadius: 0.005),
                materials: [roofMaterial]
            )
            roof.position = [0, 0.11, 0]
            roof.orientation = simd_quatf(angle: .pi / 12, axis: [1, 0, 0])

            entity.addChild(base)
            entity.addChild(roof)

        case .stumpvilleHouse:
            // Create a house structure
            let wallMaterial = SimpleMaterial(color: .init(red: 0.8, green: 0.7, blue: 0.5, alpha: 1.0), roughness: 0.6, isMetallic: false)
            let roofMaterial = SimpleMaterial(color: .init(red: 0.5, green: 0.2, blue: 0.1, alpha: 1.0), roughness: 0.9, isMetallic: false)

            // Main house body
            let houseBody = ModelEntity(
                mesh: .generateBox(size: [0.12, 0.1, 0.12]),
                materials: [wallMaterial]
            )
            houseBody.position = [0, 0.05, 0]

            // Roof (pyramid)
            let roof = ModelEntity(
                mesh: .generateBox(size: [0.14, 0.06, 0.14]),
                materials: [roofMaterial]
            )
            roof.position = [0, 0.13, 0]
            roof.scale = [1, 0.7, 1]

            // Door
            let doorMaterial = SimpleMaterial(color: .init(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0), roughness: 0.5, isMetallic: false)
            let door = ModelEntity(
                mesh: .generateBox(size: [0.03, 0.06, 0.01]),
                materials: [doorMaterial]
            )
            door.position = [0, 0.03, -0.061]

            // Window
            let windowMaterial = SimpleMaterial(color: .init(red: 0.6, green: 0.8, blue: 1.0, alpha: 0.8), roughness: 0.1, isMetallic: true)
            let window = ModelEntity(
                mesh: .generateBox(size: [0.025, 0.025, 0.01]),
                materials: [windowMaterial]
            )
            window.position = [0.035, 0.07, -0.061]

            entity.addChild(houseBody)
            entity.addChild(roof)
            entity.addChild(door)
            entity.addChild(window)
        }

        entity.generateCollisionShapes(recursive: true)
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

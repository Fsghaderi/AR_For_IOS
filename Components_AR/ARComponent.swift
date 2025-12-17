//
//  ARComponent.swift
//  Components_AR
//
//  Created by Main on 2025-12-17.
//

import Foundation
import SwiftUI
import RealityKit

/// Represents different types of 3D components that can be placed in AR
enum ARComponentType: String, CaseIterable, Identifiable {
    case cube = "Cube"
    case sphere = "Sphere"
    case cylinder = "Cylinder"
    case cone = "Cone"
    case plane = "Plane"

    var id: String { rawValue }

    /// Icon name for the component selector
    var iconName: String {
        switch self {
        case .cube: return "cube.fill"
        case .sphere: return "circle.fill"
        case .cylinder: return "cylinder.fill"
        case .cone: return "cone.fill"
        case .plane: return "square.fill"
        }
    }

    /// Generate the mesh for this component type
    func generateMesh(size: Float = 0.1) -> MeshResource {
        switch self {
        case .cube:
            return MeshResource.generateBox(size: size, cornerRadius: 0.005)
        case .sphere:
            return MeshResource.generateSphere(radius: size / 2)
        case .cylinder:
            return MeshResource.generateCylinder(height: size, radius: size / 2)
        case .cone:
            return MeshResource.generateCone(height: size, radius: size / 2)
        case .plane:
            return MeshResource.generatePlane(width: size, depth: size)
        }
    }
}

/// Available colors for AR components
enum ARComponentColor: String, CaseIterable, Identifiable {
    case red = "Red"
    case blue = "Blue"
    case green = "Green"
    case yellow = "Yellow"
    case orange = "Orange"
    case purple = "Purple"
    case gray = "Gray"
    case white = "White"

    var id: String { rawValue }

    var uiColor: UIColor {
        switch self {
        case .red: return .systemRed
        case .blue: return .systemBlue
        case .green: return .systemGreen
        case .yellow: return .systemYellow
        case .orange: return .systemOrange
        case .purple: return .systemPurple
        case .gray: return .systemGray
        case .white: return .white
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .purple: return .purple
        case .gray: return .gray
        case .white: return .white
        }
    }
}

/// Represents a placed AR component in the scene
class PlacedARComponent: Identifiable, ObservableObject {
    let id: UUID
    let type: ARComponentType
    var color: ARComponentColor
    var entity: ModelEntity
    var position: SIMD3<Float>
    @Published var isSelected: Bool = false

    init(type: ARComponentType, color: ARComponentColor, position: SIMD3<Float>, size: Float = 0.1) {
        self.id = UUID()
        self.type = type
        self.color = color
        self.position = position

        // Create the entity
        let mesh = type.generateMesh(size: size)
        let material = SimpleMaterial(color: color.uiColor, roughness: 0.15, isMetallic: true)
        self.entity = ModelEntity(mesh: mesh, materials: [material])
        self.entity.name = id.uuidString
        self.entity.position = position

        // Enable collision for gesture recognition
        self.entity.generateCollisionShapes(recursive: false)
    }

    /// Update the entity's position
    func updatePosition(_ newPosition: SIMD3<Float>) {
        self.position = newPosition
        self.entity.position = newPosition
    }

    /// Update the entity's color
    func updateColor(_ newColor: ARComponentColor) {
        self.color = newColor
        let material = SimpleMaterial(color: newColor.uiColor, roughness: 0.15, isMetallic: true)
        self.entity.model?.materials = [material]
    }

    /// Highlight or unhighlight the entity when selected
    func setHighlighted(_ highlighted: Bool) {
        isSelected = highlighted
        if highlighted {
            // Add a slight glow/emission effect when selected
            var material = SimpleMaterial(color: color.uiColor, roughness: 0.05, isMetallic: true)
            self.entity.model?.materials = [material]
        } else {
            let material = SimpleMaterial(color: color.uiColor, roughness: 0.15, isMetallic: true)
            self.entity.model?.materials = [material]
        }
    }
}

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

/// Manages the AR session state and placed components
@MainActor
class ARSessionManager: ObservableObject {
    /// All placed components in the scene
    @Published var placedComponents: [PlacedARComponent] = []

    /// Currently selected component type for placement
    @Published var selectedComponentType: ARComponentType = .cube

    /// Currently selected color for new components
    @Published var selectedColor: ARComponentColor = .blue

    /// Currently selected/active component in the scene (for editing)
    @Published var activeComponent: PlacedARComponent?

    /// Whether the user is currently dragging a component
    @Published var isDragging: Bool = false

    /// Size for new components
    @Published var componentSize: Float = 0.1

    /// The anchor entity that holds all placed components
    var sceneAnchor: AnchorEntity?

    /// Reference to the RealityKit content for adding/removing entities
    var realityContent: RealityViewContent?

    init() {}

    /// Set up the scene anchor
    func setupScene(content: RealityViewContent) {
        self.realityContent = content

        // Create a horizontal plane anchor
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        content.add(anchor)
        self.sceneAnchor = anchor

        // Enable spatial tracking
        content.camera = .spatialTracking
    }

    /// Add a new component at the specified position
    func addComponent(at position: SIMD3<Float>) {
        guard let anchor = sceneAnchor else { return }

        let component = PlacedARComponent(
            type: selectedComponentType,
            color: selectedColor,
            position: position,
            size: componentSize
        )

        anchor.addChild(component.entity)
        placedComponents.append(component)

        // Select the newly placed component
        selectComponent(component)
    }

    /// Remove a component from the scene
    func removeComponent(_ component: PlacedARComponent) {
        component.entity.removeFromParent()
        placedComponents.removeAll { $0.id == component.id }

        if activeComponent?.id == component.id {
            activeComponent = nil
        }
    }

    /// Remove all components from the scene
    func clearAllComponents() {
        for component in placedComponents {
            component.entity.removeFromParent()
        }
        placedComponents.removeAll()
        activeComponent = nil
    }

    /// Select a component for editing
    func selectComponent(_ component: PlacedARComponent?) {
        // Deselect previous component
        activeComponent?.setHighlighted(false)

        // Select new component
        activeComponent = component
        component?.setHighlighted(true)
    }

    /// Deselect the active component
    func deselectAll() {
        activeComponent?.setHighlighted(false)
        activeComponent = nil
    }

    /// Find a component by its entity
    func findComponent(by entity: Entity) -> PlacedARComponent? {
        return placedComponents.first { $0.entity === entity || $0.entity.name == entity.name }
    }

    /// Find a component by its ID
    func findComponent(by id: UUID) -> PlacedARComponent? {
        return placedComponents.first { $0.id == id }
    }

    /// Update the color of the active component
    func updateActiveComponentColor(_ color: ARComponentColor) {
        activeComponent?.updateColor(color)
    }

    /// Move the active component to a new position
    func moveActiveComponent(to position: SIMD3<Float>) {
        activeComponent?.updatePosition(position)
    }

    /// Delete the currently selected component
    func deleteActiveComponent() {
        guard let component = activeComponent else { return }
        removeComponent(component)
    }

    /// Duplicate the active component
    func duplicateActiveComponent() {
        guard let component = activeComponent else { return }

        // Create offset position
        let offset: SIMD3<Float> = [0.15, 0, 0.15]
        let newPosition = component.position + offset

        let newComponent = PlacedARComponent(
            type: component.type,
            color: component.color,
            position: newPosition,
            size: componentSize
        )

        sceneAnchor?.addChild(newComponent.entity)
        placedComponents.append(newComponent)
        selectComponent(newComponent)
    }
}

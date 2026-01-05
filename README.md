# AR Components

An iOS AR app for placing and manipulating 3D Furniture models in augmented reality.

## What it does

Point your iPhone at a surface, tap to place buildings. Drag them around, scale them, duplicate or delete them. That's it.

## The models

- **Log Fort** - A fort with walls and corner towers
- **Log Mash** - A shelter with pillars and a roof
- **Stumpville House** - A little house with a door and window

All models are procedurally generated, no external files needed.

## Running it

You'll need:
- A Mac with Xcode
- An iPhone (6s or newer)

Open `Components_AR.xcodeproj` in Xcode, plug in your phone, hit run. You might need to sign it with your Apple ID in the project settings.

AR doesn't work great in the simulator, use a real device.

## Using the app

1. Move your phone around until it detects a floor or table
2. Tap to place a model
3. Drag models to move them
4. Tap a model to select it, then use the buttons:
   - Scale - make it bigger or smaller
   - Copy - duplicate it
   - Delete - remove it
   - Deselect - unselect it

Switch between the three model types using the buttons at the bottom.

## Tech

SwiftUI + RealityKit + ARKit

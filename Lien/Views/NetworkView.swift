import SwiftUI
import SpriteKit // Import SpriteKit

struct NetworkView: View {
    @ObservedObject var viewModel: LienViewModel
    @Environment(\.colorScheme) var colorScheme // Read color scheme

    // Create and configure the scene
    // We use @State here because the scene itself has state (node positions etc)
    // that shouldn't be recreated every time the view redraws. 
    // Pass initial data, but updates might need a different mechanism later if scene doesn't observe ViewModel directly.
    @State private var scene: NetworkScene = {
        let scene = NetworkScene(size: CGSize(width: 300, height: 400)) // Initial size, will update
        scene.people = [] // Start empty, will be updated
        scene.links = [] // Start empty, will be updated
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear // Use clear to allow SwiftUI background
        return scene
    }()

    var body: some View {
        NavigationView {
            // Use SpriteView to present the SKScene
            SpriteView(scene: scene)
                // .ignoresSafeArea() // REMOVED: This likely caused tabs to disappear
                .onAppear {
                    scene.colorScheme = colorScheme // Pass initial color scheme
                    scene.people = viewModel.personStore.people
                    scene.links = viewModel.linkStore.links
                }
                .onChange(of: viewModel.personStore.people) { _, newPeople in
                    // Update scene data if people array changes
                     scene.people = newPeople
                 }
                 // Update scene's color scheme when environment changes
                .onChange(of: colorScheme) { _, newScheme in
                     scene.colorScheme = newScheme // Assign directly, didSet in scene will handle update
                     scene.people = viewModel.personStore.people
                     scene.links = viewModel.linkStore.links
                 }
                .navigationTitle("Network")
                .navigationBarTitleDisplayMode(.inline)
                 // Combine Panning and Tapping Drag Gestures
                .simultaneousGesture(DragGesture(minimumDistance: 0)
                    .onEnded { value in // Use onEnded for tap location
                        handleTap(at: value.location)
                    }
                )
                .simultaneousGesture(DragGesture(minimumDistance: 5) // Keep original pan gesture with min distance > 0
                    .onChanged(handlePan)
                    .onEnded(resetPanLocation)
                )
                .simultaneousGesture(MagnificationGesture() // Zoom needs simultaneous too
                    .onChanged(handleZoom)
                    .onEnded(resetZoomScale)
                )
        }
    }
    
    // --- Gesture Handling State ---
    @State private var previousPanLocation: CGPoint? = nil
    @State private var previousZoomScale: CGFloat = 1.0
    // --- End Gesture State ---
    
    // MARK: - Gesture Handlers
    
    private func handlePan(_ value: DragGesture.Value) {
        guard let camera = scene.camera else { return }
        let currentLocation = value.location
        
        if let previousLocation = previousPanLocation {
            let translation = CGPoint(x: currentLocation.x - previousLocation.x,
                                      y: currentLocation.y - previousLocation.y)
            
            // Convert translation to scene coordinates based on camera scale
            let moveX = -translation.x * camera.xScale 
            let moveY = translation.y * camera.yScale // Y is inverted between UIView and SKScene
            
            var newX = camera.position.x + moveX
            var newY = camera.position.y + moveY
            
            // --- Add Camera Position Clamping ---
            // Use scene size to estimate rough bounds. Assumes boundary is ~1.5x scene size.
            // This needs refinement if scene size isn't reliable initially.
            let sceneWidth = scene.size.width * 1.5
            let sceneHeight = scene.size.height * 1.5
            let xLimit = sceneWidth / 2.0 - (scene.view?.bounds.width ?? sceneWidth) * camera.xScale / 2.0
            let yLimit = sceneHeight / 2.0 - (scene.view?.bounds.height ?? sceneHeight) * camera.yScale / 2.0
            
            newX = max(-xLimit, min(xLimit, newX))
            newY = max(-yLimit, min(yLimit, newY))
            // --- End Clamping ---
            
            camera.position = CGPoint(x: newX, y: newY)
        }
        previousPanLocation = currentLocation
    }

    private func resetPanLocation(_ value: DragGesture.Value) {
        previousPanLocation = nil // Reset on gesture end
    }
    
    private func handleZoom(_ value: MagnificationGesture.Value) {
        guard let camera = scene.camera else { return }
        let deltaScale = value / previousZoomScale
        var newScale = camera.xScale / deltaScale
        
        // Clamp scale to reasonable limits
        newScale = max(0.1, min(3.0, newScale))
        
        camera.setScale(newScale)
        previousZoomScale = value
    }

    private func resetZoomScale(_ value: MagnificationGesture.Value) {
        // Reset to 1.0 to ensure the next zoom starts fresh
        previousZoomScale = 1.0 
    }
    
    // NEW function to handle tap at a specific location
    private func handleTap(at location: CGPoint) {
        // Convert tap location from SwiftUI view coordinates to SKScene coordinates
        guard let view = scene.view else { return }
        let sceneLocation = scene.convertPoint(fromView: location)
        
        print("Tap detected at Scene Location: \(sceneLocation)")
        scene.selectNode(at: sceneLocation) // Call method on scene to handle selection
    }
    
    // REMOVED Canvas-based drawing logic and layout simulation functions
    // func initializeLayout(...) { ... }
    // func updateNodePositions(...) { ... }
    // func drawNode(...) { ... }
}

#Preview {
    // Preview remains the same, using the ViewModel with sample data
    let previewViewModel = LienViewModel()
    previewViewModel.personStore.people = [
        Person(name: "Alice", relationshipType: .friend, meetFrequency: .monthly),
        Person(name: "Bob", relationshipType: .family, meetFrequency: .weekly, isCorePerson: true),
        Person(name: "Charlie", relationshipType: .colleague, meetFrequency: .quarterly),
        Person(name: "Diana", relationshipType: .friend, meetFrequency: .monthly),
        Person(name: "Ethan", relationshipType: .family, meetFrequency: .weekly)
    ]
    return NetworkView(viewModel: previewViewModel)
} 
import SpriteKit
import SwiftUI

class NetworkScene: SKScene {
    
    var people: [Person] = [] {
        didSet {
            // TODO: Rebuild nodes when people data changes
            setupNodes()
        }
    }
    
    var links: [RelationshipLink] = [] { // Added property to hold links
         didSet {
             // TODO: Rebuild links when data changes (if needed)
             setupLinks()
         }
     }
    
    // Store nodes by person ID
    var personNodes: [UUID: SKNode] = [:] // Using SKNode allows SKShapeNode or SKSpriteNode
    
    // Camera for panning/zooming
    let cameraNode = SKCameraNode()
    
    // Property to hold the current color scheme
    var colorScheme: ColorScheme = .light { // Default value
        didSet {
            updateBackgroundColor()
        }
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5) // Set anchor to center
        updateBackgroundColor() // Set initial background based on scheme
        setupPhysics()
        
        // Setup Camera
        camera = cameraNode
        cameraNode.position = CGPoint.zero // Start camera at center (anchor point)
        addChild(cameraNode)
        
        // Enable interaction
        isUserInteractionEnabled = true
        
        // Add gesture recognizers (will be done in NetworkView)
        
        // setupNodes() will be called when people data is set or size becomes valid
    }
    
    func updateBackgroundColor() {
        // Update background color based on the scheme
        backgroundColor = (colorScheme == .dark) ? .black : .white // Or use UIColor.systemBackground
        // backgroundColor = SKColor(Color(UIColor.systemBackground)) // Alternative
    }
    
    func setupPhysics() {
        physicsWorld.gravity = .zero
        // Add boundary based on scene frame
        // Make the boundary slightly larger than the visible frame to allow panning
        // Use the full scene frame as the boundary
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.1 // Slightly reduce boundary friction
        
        // Center attraction field setup moved to setupNodes
    }
    
    func setupNodes() {
        print("NetworkScene: setupNodes called. People count: \(people.count)")
        // Check if frame size is valid
        guard frame.size != .zero else {
            print("NetworkScene: Frame size is zero, deferring node setup.")
            return // Don't setup nodes if size isn't determined yet
        }
        
        // Remove existing nodes before adding new ones
        removeAllChildren()
        personNodes.removeAll()
        
        guard !people.isEmpty else { return }
        
        // Calculations now relative to anchor point (0,0) because frame is based on it
        let center = CGPoint.zero // Center is now (0,0) due to anchorPoint
        let radius = min(frame.width, frame.height) * 0.35 // Reduced radius slightly
        let angleStep = 2 * .pi / Double(people.count)
        
        // Add center attraction field HERE, using current center
        let centerAttraction = SKFieldNode.radialGravityField()
        centerAttraction.strength = 0.1 
        centerAttraction.falloff = 0.5 
        centerAttraction.position = center // Position at anchor point
        addChild(centerAttraction)
        
        for (index, person) in people.enumerated() {
            let nodeRadius: CGFloat = 15 // Base radius for physics/mask
            
            // --- Create Node Content (Image or Placeholder) ---
            var nodeTexture: SKTexture?
            var fallbackColor = SKColor(AppColor.avatarColor(for: person.id)) // Use existing helper
            
            if let imageData = person.image, let uiImage = UIImage(data: imageData) {
                nodeTexture = SKTexture(image: uiImage)
            }
            
            // Create the main sprite node
            let spriteNode = SKSpriteNode(texture: nodeTexture, color: fallbackColor, size: CGSize(width: nodeRadius * 2, height: nodeRadius * 2))
            spriteNode.colorBlendFactor = (nodeTexture == nil) ? 1.0 : 0.0 // Only show color if no texture

            // --- Create Circular Mask ---
            let maskNode = SKShapeNode(circleOfRadius: nodeRadius)
            maskNode.fillColor = .black // Color doesn't matter, just needs to be filled
            maskNode.strokeColor = .clear
            
            let cropNode = SKCropNode()
            cropNode.maskNode = maskNode
            cropNode.addChild(spriteNode) // Put the sprite inside the crop node
            // --- End Mask ---
            
            // Initial positioning (position the CROP node)
            let angle = Double(index) * angleStep
            cropNode.position = CGPoint(x: center.x + radius * CGFloat(cos(angle)), 
                                      y: center.y + radius * CGFloat(sin(angle)))
            
            // Add physics body to the CROP node
            cropNode.physicsBody = SKPhysicsBody(circleOfRadius: nodeRadius)
            cropNode.physicsBody?.affectedByGravity = false
            cropNode.physicsBody?.allowsRotation = false
            cropNode.physicsBody?.mass = 1.0
            cropNode.physicsBody?.linearDamping = 1.5 // Increased linear damping
            cropNode.physicsBody?.angularDamping = 0.9 // Increased angular damping
            
            // Store reference (store CROP node) and add to scene
            cropNode.name = person.id.uuidString 
            personNodes[person.id] = cropNode // Store the crop node
            addChild(cropNode)
            
            // Add repulsion field to the CROP node
            let repulsionField = SKFieldNode.radialGravityField()
            repulsionField.strength = -0.5 
            repulsionField.falloff = 1.5 
            repulsionField.minimumRadius = Float(nodeRadius * 2) 
            cropNode.addChild(repulsionField) // Add field to the crop node
        }
        
        // Setup spring joints using LinkStore data
        setupLinks()
    }
    
    func setupLinks() {
        // Remove existing joints first?
        physicsWorld.removeAllJoints()
        
        var createdJoints = Set<Set<UUID>>() // Prevent duplicate joints (optional, LinkStore prevents duplicates)
        
        // Iterate through LinkStore links
        for link in links {
            let person1ID = link.person1ID
            let person2ID = link.person2ID
            
            let linkPair = Set([person1ID, person2ID])
            if createdJoints.contains(linkPair) { continue }
            
            if let node1 = personNodes[person1ID], let body1 = node1.physicsBody,
               let node2 = personNodes[person2ID], let body2 = node2.physicsBody {
                
                // Prevent joint creation if nodes are too close (potential NaN source)
                let distance = node1.position.distance(to: node2.position)
                guard distance > 1.0 else { // Avoid joint if nodes are practically overlapping
                    print("Skipping joint between \(link.person1ID) and \(link.person2ID) due to close proximity.")
                    continue 
                }
                
                let joint = SKPhysicsJointSpring.joint(withBodyA: body1,
                                                         bodyB: body2,
                                                         anchorA: CGPoint.zero, // Anchors relative to node center
                                                         anchorB: CGPoint.zero)
                joint.damping = 5.0 // Significantly increased damping to reduce oscillation
                joint.frequency = 0.5 // Reduced frequency to make springs less stiff
                physicsWorld.add(joint)
                createdJoints.insert(linkPair)
            }
        }
        
        // --- Draw Edges --- 
        // (Could be done once in setupLinks if they don't need updating per frame)
        // For simplicity, redraw edges each frame for now.
        // First, remove previous edge nodes if they exist.
        children.filter { $0.name == "edge" }.forEach { $0.removeFromParent() }
        
        for link in links {
             if let node1Pos = personNodes[link.person1ID]?.position, 
                let node2Pos = personNodes[link.person2ID]?.position {
                
                let path = CGMutablePath()
                path.move(to: node1Pos)
                path.addLine(to: node2Pos)
                
                let edgeNode = SKShapeNode(path: path)
                edgeNode.strokeColor = SKColor.gray.withAlphaComponent(0.4)
                edgeNode.lineWidth = 0.5
                edgeNode.name = "edge" // Mark edge nodes for easy removal
                edgeNode.zPosition = -1 // Draw edges behind nodes
                addChild(edgeNode)
             }
        }
        // --- End Edge Drawing ---
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // If nodes weren't set up initially due to zero frame size, try again
        if personNodes.isEmpty && !people.isEmpty && frame.size != .zero {
            print("NetworkScene: Retrying setupNodes from update().")
            setupNodes()
        }
        
        // --- Draw Edges --- 
        // (Could be done once in setupLinks if they don't need updating per frame)
        // For simplicity, redraw edges each frame for now.
        // First, remove previous edge nodes if they exist.
        children.filter { $0.name == "edge" }.forEach { $0.removeFromParent() }
        
        for link in links {
             if let node1Pos = personNodes[link.person1ID]?.position, 
                let node2Pos = personNodes[link.person2ID]?.position {
                
                let path = CGMutablePath()
                path.move(to: node1Pos)
                path.addLine(to: node2Pos)
                
                let edgeNode = SKShapeNode(path: path)
                edgeNode.strokeColor = SKColor.gray.withAlphaComponent(0.4)
                edgeNode.lineWidth = 0.5
                edgeNode.name = "edge" // Mark edge nodes for easy removal
                edgeNode.zPosition = -1 // Draw edges behind nodes
                addChild(edgeNode)
             }
        }
        // --- End Edge Drawing ---
        
        // Update node appearance based on pulseScore
        // TODO: Update node appearance based on pulseScore
        // TODO: Apply custom forces if needed
    }
    
    // MARK: - Touch Handling
    
    var selectedNode: SKNode? = nil // Keep track of selected node
    
    func selectNode(at point: CGPoint) {
        let tappedNodes = nodes(at: point)
        print("Nodes at point: \(tappedNodes.count)")
        
        // Reset previous selection first
        if let previouslySelected = selectedNode {
            previouslySelected.run(SKAction.scale(to: 1.0, duration: 0.1))
            selectedNode = nil
        }
        
        // Find the top-most node that is a person node (has a name/UUID)
        if let topNode = tappedNodes.first(where: { $0.name != nil && $0 is SKCropNode }) {
            print("Tapped node: \(topNode.name ?? "Unknown")")
            selectedNode = topNode
            // Add visual feedback (e.g., scale up)
            topNode.run(SKAction.scale(to: 1.3, duration: 0.1))
            
            // TODO: Trigger display of mini-profile in SwiftUI view
            // (e.g., using a callback or binding passed from NetworkView)
            if let personIdString = topNode.name, let personId = UUID(uuidString: personIdString) {
                 print("Selected Person ID: \(personId)")
                // Find person details if needed
                if let person = people.first(where: { $0.id == personId }) {
                    print("Selected Person Name: \(person.name)")
                }
            }
        } else {
            print("No person node tapped at this location.")
        }
    }
    
    // REMOVED: Old touch handling methods if present
    /*
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // ...
    }
    */
}

// Helper extension for distance
extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return hypot(point.x - self.x, point.y - self.y)
    }
} 
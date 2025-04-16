import SwiftUI

struct NetworkView: View {
    @ObservedObject var viewModel: LienViewModel
    
    // State for force-directed node positions 
    @State private var nodePositions: [UUID: CGPoint] = [:]
    @State private var nodeVelocities: [UUID: CGVector] = [:]
    
    // Animation state
    @State private var isSimulating: Bool = true
    @State private var timer: Timer? = nil
    
    // State for pan/zoom
    @State private var currentScale: CGFloat = 1.0
    @State private var previousScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var previousOffset: CGSize = .zero

    // Configuration constants
    let nodeSize: CGFloat = 40.0 
    let coreNodeSize: CGFloat = 45.0
    let userNodeSize: CGFloat = 55.0
    let connectionLineWidth: CGFloat = 1.0
    
    // Force-directed layout constants
    let springLength: CGFloat = 120.0
    let springStiffness: CGFloat = 0.1
    let repulsionStrength: CGFloat = 1500.0
    let dampingFactor: CGFloat = 0.8
    let centerAttraction: CGFloat = 0.01
    
    // Special UUID for the user node in the center
    let userNodeID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    
    // Color relationships
    let relationshipColors: [Person.RelationshipType: Color] = [
        .family: .red,
        .closeFriend: .orange,
        .friend: .yellow,
        .colleague: .green,
        .acquaintance: .blue,
        .other: .purple
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Legend at the bottom
                VStack {
                    Spacer()
                    relationshipLegend
                        .padding()
                }
                
                // Network graph
                Canvas { context, size in
                    // Apply pan/zoom transform
                    context.translateBy(x: currentOffset.width + size.width / 2, y: currentOffset.height + size.height / 2)
                    context.scaleBy(x: currentScale, y: currentScale)
                    context.translateBy(x: -size.width / 2, y: -size.height / 2)

                    // --- Drawing ---
                    drawConnectionLines(context: context)
                    drawNodes(context: context, size: size)
                }
                .gesture(dragGesture(size: geometry.size))
                .gesture(magnificationGesture(size: geometry.size))
                .onAppear {
                    initializeNodePositions(size: geometry.size)
                    startSimulation()
                }
                .onDisappear {
                    stopSimulation()
                }
                
                // Controls overlay
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { isSimulating.toggle() }) {
                            Image(systemName: isSimulating ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
                 }
                .navigationTitle("Network")
                .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - UI Components
    
    private var relationshipLegend: some View {
        HStack(spacing: 12) {
            ForEach(Array(relationshipColors.keys.sorted { $0.rawValue < $1.rawValue }), id: \.self) { type in
                HStack(spacing: 4) {
                    Circle()
                        .fill(relationshipColors[type] ?? .gray)
                        .frame(width: 10, height: 10)
                    Text(type.displayName)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }

    // MARK: - Simulation Methods
    
    private func initializeNodePositions(size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Position user at center
        nodePositions[userNodeID] = center
        nodeVelocities[userNodeID] = .zero
        
        // Initialize other nodes in a circle
        let allPeople = viewModel.personStore.people
        let radius = min(size.width, size.height) * 0.3
        
        for (index, person) in allPeople.enumerated() {
            let angle = Double(index) * (2 * .pi / Double(allPeople.count))
            let x = center.x + radius * CGFloat(cos(angle))
            let y = center.y + radius * CGFloat(sin(angle))
            
            nodePositions[person.id] = CGPoint(x: x, y: y)
            nodeVelocities[person.id] = .zero
        }
    }
    
    private func startSimulation() {
        // Cancel any existing timer
        stopSimulation()
        
        // Restart simulation if it was enabled
        if isSimulating {
            timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
                self.updateForces()
            }
        }
    }
    
    private func stopSimulation() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateForces() {
        // Skip if simulation is paused
        guard isSimulating else { return }
        
        // Get all nodes, with user node first
        var allPeople = viewModel.personStore.people
        
        // Create a temp copy of positions for calculation
        var newPositions = nodePositions
        var newVelocities = nodeVelocities
        
        // Calculate forces for each node
        for person in allPeople {
            let id = person.id
            guard let position = nodePositions[id], 
                  var velocity = nodeVelocities[id] else { continue }
            
            // Initialize force vector for this node
            var force = CGVector.zero
            
            // 1. Spring forces (connections)
            let connections = viewModel.linkStore.links.filter { $0.person1ID == id || $0.person2ID == id }
            
            for connection in connections {
                let otherId = connection.person1ID == id ? connection.person2ID : connection.person1ID
                guard let otherPos = nodePositions[otherId] else { continue }
                
                let displacement = position - otherPos
                let distance = displacement.magnitude
                
                // Calculate spring force (attraction)
                if distance > 0 {
                    // Add extra attraction strength for connected nodes
                    let connectionStrength = 1.5 // Mock strength since RelationshipLink doesn't have strength property
                    let springForce = displacement.normalized * (distance - springLength) * -springStiffness * connectionStrength
                    force += springForce
                }
            }
            
            // 2. Repulsion forces (all nodes repel each other)
            for otherId in nodePositions.keys {
                if otherId != id {
                    guard let otherPos = nodePositions[otherId] else { continue }
                    let displacement = position - otherPos
                    let distance = displacement.magnitude
                    
                    // Avoid division by zero and excessive forces
                    if distance > 1 {
                        let repulsionForce = displacement.normalized * (repulsionStrength / (distance * distance))
                        force += repulsionForce
                    }
                }
            }
            
            // 3. Center attraction (mild force pulling toward center)
            let centerPos = nodePositions[userNodeID] ?? CGPoint(x: 0, y: 0)
            let toCenter = centerPos - position
            force += toCenter * centerAttraction
            
            // Update velocity (with damping)
            velocity += force
            velocity = velocity * dampingFactor
            
            // Apply velocity to position
            var newPosition = position
            newPosition += velocity
            
            // Update temp values
            newPositions[id] = newPosition
            newVelocities[id] = velocity
        }
        
        // Apply the new calculated positions
        DispatchQueue.main.async {
            self.nodePositions = newPositions
            self.nodeVelocities = newVelocities
        }
    }

    // MARK: - Drawing Methods
    
    private func drawConnectionLines(context: GraphicsContext) {
        // First pass - draw connection lines
        for link in viewModel.linkStore.links {
            guard let pos1 = nodePositions[link.person1ID], let pos2 = nodePositions[link.person2ID] else { continue }
            
            // Just use a fixed strength since RelationshipLink doesn't have a strength property
            let mockStrength = 0.7 // Mock fixed value between 0-1
            let lineWidth = connectionLineWidth * (0.5 + mockStrength * 0.5)
            
            // Draw connection with opacity based on mock strength
            var path = Path()
            path.move(to: pos1)
            path.addLine(to: pos2)
            context.stroke(path, with: .color(Color.white.opacity(0.3)), lineWidth: lineWidth)
        }
    }
    
    private func drawNodes(context: GraphicsContext, size: CGSize) {
        // First, draw user node
        if let userPosition = nodePositions[userNodeID] {
            let rect = CGRect(x: userPosition.x - userNodeSize/2, y: userPosition.y - userNodeSize/2, width: userNodeSize, height: userNodeSize)
            let placeholderUser = Person(id: userNodeID, name: "You", relationshipType: .other, meetFrequency: .monthly)
            drawNodeFallback(context: context, person: placeholderUser, rect: rect, nodeRadius: userNodeSize/2, includeBorder: true, borderColor: .white)
        }
        
        // Draw all people nodes
        for person in viewModel.personStore.people {
            guard let position = nodePositions[person.id] else { continue }
            
            // Determine node size based on type
            let nodeRadius = (person.isCorePerson ? coreNodeSize : nodeSize) / 2.0
            let rect = CGRect(x: position.x - nodeRadius, y: position.y - nodeRadius, width: nodeRadius * 2, height: nodeRadius * 2)
            
            // Get relationship color for border
            let relationshipColor = relationshipColors[person.relationshipType] ?? .gray
            
            // If person has an image, draw it
            if let imageData = person.image, let uiImage = UIImage(data: imageData) {
                let swiftUIImage = Image(uiImage: uiImage)
                
                // Draw bordered circle
                drawNodeWithImage(context: context, person: person, rect: rect, image: swiftUIImage, borderColor: relationshipColor)
            } else {
                // Draw fallback with initials
                drawNodeFallback(context: context, person: person, rect: rect, nodeRadius: nodeRadius, includeBorder: true, borderColor: relationshipColor)
            }
            
            // Label node with name
            if currentScale > 0.8 {
                let fontSize = min(14 * currentScale, 16)
                let nameText = Text(person.name)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(.white)
                
                // Draw name below the node
                context.draw(nameText, at: CGPoint(x: position.x, y: position.y + nodeRadius + 15), anchor: .top)
            }
        }
    }
    
    private func drawNodeWithImage(context: GraphicsContext, person: Person, rect: CGRect, image: Image, borderColor: Color) {
        // Draw background circle (will be visible if image has transparency)
        let circlePath = Path(ellipseIn: rect)
        let avatarColor = AppColor.avatarColor(for: person.id)
        context.fill(circlePath, with: .color(avatarColor))
        
        // Convert SwiftUI Image to UIImage for custom drawing
        if let uiImage = person.image.flatMap(UIImage.init(data:)) {
            // Create a temporary context to mask the image
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: rect.width, height: rect.height))
            let circularImage = renderer.image { context in
                // Create circle path for clipping
                let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
                circlePath.addClip()
                
                // Draw the image within the clipping path
                uiImage.draw(in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
            }
            
            // Draw the masked circular image
            if let cgImage = circularImage.cgImage {
                context.draw(Image(uiImage: UIImage(cgImage: cgImage)), in: rect)
            }
        }
        
        // Draw border over the top
        context.stroke(circlePath, with: .color(borderColor), lineWidth: 2.0)
    }
    
    private func drawNodeFallback(context: GraphicsContext, person: Person, rect: CGRect, nodeRadius: CGFloat, includeBorder: Bool = true, borderColor: Color = .white) {
        let initials = person.initials
        let circlePath = Path(ellipseIn: rect)
        
        // Background color for node
        let avatarColor = AppColor.avatarColor(for: person.id)
        context.fill(circlePath, with: .color(avatarColor))
        
        // Border
        if includeBorder {
            context.stroke(circlePath, with: .color(borderColor), lineWidth: 2.0)
        }
        
        // Draw initials
        let text = Text(initials)
                    .font(.system(size: nodeRadius * 0.9, weight: .medium))
                    .foregroundColor(.white)
        context.draw(text, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
    }
    
    // MARK: - Gestures
    
    private func dragGesture(size: CGSize) -> some Gesture {
         DragGesture()
            .onChanged { value in
                // Pause simulation while dragging
                let wasSimulating = isSimulating
                isSimulating = false
                
                currentOffset = CGSize(
                    width: value.translation.width + previousOffset.width,
                    height: value.translation.height + previousOffset.height
                )
                
                // Resume if it was simulating
                isSimulating = wasSimulating
            }
            .onEnded { _ in
                previousOffset = currentOffset
            }
     }

    private func magnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                 let delta = value / previousScale
                 previousScale = value
                 currentScale *= delta
                 currentScale = max(0.5, min(currentScale, 3.0)) // Clamp scale
             }
            .onEnded { _ in
                 previousScale = 1.0
             }
    }
}

// MARK: - Extensions

// Add display name property to RelationshipType
extension Person.RelationshipType {
    var displayName: String {
        switch self {
        case .family: return "Family"
        case .closeFriend: return "Close Friend"
        case .friend: return "Friend"
        case .colleague: return "Colleague"
        case .acquaintance: return "Acquaintance"
        case .other: return "Other"
        }
    }
}

// MARK: - CGPoint/CGVector Helpers
extension CGPoint {
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGVector { CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y) }
    static func +=(lhs: inout CGPoint, rhs: CGVector) { lhs.x += rhs.dx; lhs.y += rhs.dy }
    var magnitude: CGFloat { sqrt(x*x + y*y) }
    var normalized: CGPoint { let mag = self.magnitude; return mag == 0 ? .zero : CGPoint(x: x / mag, y: y / mag) }
    static func *(point: CGPoint, scalar: CGFloat) -> CGVector { CGVector(dx: point.x * scalar, dy: point.y * scalar) }
}

extension CGVector {
     static func +(lhs: CGVector, rhs: CGVector) -> CGVector { CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy) }
     static func +=(lhs: inout CGVector, rhs: CGVector) { lhs.dx += rhs.dx; lhs.dy += rhs.dy }
     static func -(lhs: CGVector, rhs: CGVector) -> CGVector { CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy) }
     static func -=(lhs: inout CGVector, rhs: CGVector) { lhs.dx -= rhs.dx; lhs.dy -= rhs.dy }
     static func *(vector: CGVector, scalar: CGFloat) -> CGVector { CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar) }
     static func /(vector: CGVector, scalar: CGFloat) -> CGVector { scalar == 0 ? .zero : CGVector(dx: vector.dx / scalar, dy: vector.dy / scalar) }
     var magnitude: CGFloat { sqrt(dx*dx + dy*dy) }
     var normalized: CGVector { let mag = magnitude; return mag == 0 ? .zero : CGVector(dx: dx / mag, dy: dy / mag) }
     static var zero: CGVector { CGVector(dx: 0, dy: 0) }
}

#Preview {
    NetworkView(viewModel: LienViewModel())
} 
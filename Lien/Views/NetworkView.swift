import SwiftUI

struct NetworkView: View {
    @ObservedObject var viewModel: LienViewModel
    
    // State for node positions and simulation
    @State private var nodePositions: [UUID: CGPoint] = [:]
    @State private var nodeVelocities: [UUID: CGVector] = [:]
    @State private var isSimulating: Bool = true
    @State private var timer: Timer? = nil
    @State private var showConnectionLabels: Bool = false // State for label visibility (default false)
    @State private var hiddenRelationshipTypes: Set<Person.RelationshipType> = [] // State for filtering
    
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

    // Helper to get people excluding hidden types
    private var visiblePeople: [Person] {
        viewModel.personStore.people.filter { !hiddenRelationshipTypes.contains($0.relationshipType) }
    }
    
    // Helper to check if a link should be visible
    private func isLinkVisible(_ link: RelationshipLink) -> Bool {
        guard let person1 = viewModel.personStore.people.first(where: { $0.id == link.person1ID }),
              let person2 = viewModel.personStore.people.first(where: { $0.id == link.person2ID }) else {
            return false // Don't show link if persons aren't found (shouldn't happen)
        }
        return !hiddenRelationshipTypes.contains(person1.relationshipType) && 
               !hiddenRelationshipTypes.contains(person2.relationshipType)
    }

    var body: some View {
        GeometryReader { geometry in
            // Use ZStack instead of Canvas
            ZStack {
                // Use adaptive background
                AppColor.primaryBackground.edgesIgnoringSafeArea(.all)

                // Layer for Explicit Peer-to-Peer Connection Lines (drawn behind nodes)
                ForEach(viewModel.linkStore.links.filter { isLinkVisible($0) }) { link in
                    if let pos1 = nodePositions[link.person1ID], let pos2 = nodePositions[link.person2ID] {
                        let mockStrength = 0.7 // Keep mock strength for peer links for now
                        let lineWidth = connectionLineWidth * (0.5 + mockStrength * 0.5)
                        
                        // Draw the line
                        Path { path in
                            path.move(to: pos1)
                            path.addLine(to: pos2)
                        }
                        .stroke(Color.gray.opacity(0.5), lineWidth: lineWidth * 0.8)
                        
                        // Conditionally add the label
                        if showConnectionLabels { 
                             Text(link.label)
                                 .font(.system(size: 8)) // Keep font size small
                                 .padding(2)
                                 .foregroundColor(AppColor.text.opacity(0.9)) // Use adaptive text color
                                 .background(AppColor.cardBackground.opacity(0.6)) // Use adaptive background
                                 .cornerRadius(4)
                                 .position(x: (pos1.x + pos2.x) / 2, y: (pos1.y + pos2.y) / 2)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height) 
                .offset(x: currentOffset.width, y: currentOffset.height)
                .scaleEffect(currentScale)
                
                // Layer for Implicit "You"-to-Person Connection Lines (drawn behind nodes)
                if let userPos = nodePositions[userNodeID] {
                    ForEach(visiblePeople) { person in
                        if let personPos = nodePositions[person.id] {
                            Path { path in
                                path.move(to: userPos)
                                path.addLine(to: personPos)
                            }
                            // Style based on relationship health
                            .stroke(
                                person.relationshipHealth.color.opacity(0.7), // Use health color with some opacity
                                lineWidth: connectionLineWidth * CGFloat(person.relationshipHealth.thicknessMultiplier) // Vary thickness
                            )
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height) 
                    .offset(x: currentOffset.width, y: currentOffset.height)
                    .scaleEffect(currentScale)
                }

                // Layer for Nodes (drawn on top of lines)
                ForEach(visiblePeople) { person in
                    if let position = nodePositions[person.id] {
                        // Wrap Node in NavigationLink
                        NavigationLink(destination: PersonDetailView(viewModel: viewModel, person: person)) {
                            NodeView(person: person, size: person.isCorePerson ? coreNodeSize : nodeSize)
                        }
                        .position(x: position.x, y: position.y) // Position the link
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height) // Ensure nodes are positioned within bounds
                .offset(x: currentOffset.width, y: currentOffset.height)
                .scaleEffect(currentScale)
                
                // User Node (centered, can be separate or part of the loop if needed)
                if let userPosition = nodePositions[userNodeID] {
                    // Use UserProfile image data if available
                    Group {
                        if let imageData = viewModel.userProfile.profileImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: userNodeSize, height: userNodeSize)
                                .clipShape(Circle())
                        } else {
                            // Fallback placeholder
                            Circle()
                                .fill(AppColor.cardBackground) // Use adaptive card background
                                .frame(width: userNodeSize, height: userNodeSize)
                                .overlay(Text("You").font(.caption).foregroundColor(AppColor.text)) // Adaptive text
                        }
                    }
                    .overlay(Circle().stroke(Color.gray, lineWidth: 2)) // Keep overlay border
                    .position(x: userPosition.x, y: userPosition.y)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: currentOffset.width, y: currentOffset.height)
                    .scaleEffect(currentScale)
                }
                
                // Legend and Controls can stay on top
                VStack {
                    HStack {
                        // Toggle for labels on the left
                        Toggle(isOn: $showConnectionLabels) {
                             Label("Show Labels", systemImage: "tag.fill")
                         }
                         .toggleStyle(.button)
                         .tint(AppColor.secondaryText) // Adaptive tint
                         .font(.caption)
                         .padding(.leading)
                        
                        Spacer()
                        
                        // Simulation button on the right
                        Button(action: { isSimulating.toggle() }) {
                            Image(systemName: isSimulating ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title)
                                .foregroundColor(AppColor.text) // Adaptive color
                        }
                        .padding(.trailing)
                    }
                    Spacer()
                    relationshipLegend
                        .padding()
                }
            }
            .clipped() // Clip content to bounds
            .contentShape(Rectangle()) // Make entire area interactive for gestures
            .gesture(dragGesture(size: geometry.size))
            .gesture(magnificationGesture(size: geometry.size))
            .onAppear {
                initializeNodePositions(size: geometry.size)
                startSimulation()
            }
            .onDisappear {
                stopSimulation()
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
                        .foregroundColor(AppColor.text)
                }
                // Add visual feedback and tap gesture
                .opacity(hiddenRelationshipTypes.contains(type) ? 0.4 : 1.0) // Dim if hidden
                .onTapGesture {
                    toggleRelationshipTypeVisibility(type)
                }
            }
        }
        .padding(8)
        .background(AppColor.cardBackground.opacity(0.7)) // Adaptive background
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

    // MARK: - Drawing Methods (No longer needed - functionality moved to ZStack)
    // private func drawConnectionLines(context: GraphicsContext) { ... }
    // private func drawNodes(context: GraphicsContext, size: CGSize) { ... }
    
    // MARK: - Gesture Handlers
    
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

    // MARK: - Filtering Logic
    
    private func toggleRelationshipTypeVisibility(_ type: Person.RelationshipType) {
        if hiddenRelationshipTypes.contains(type) {
            hiddenRelationshipTypes.remove(type)
        } else {
            hiddenRelationshipTypes.insert(type)
        }
    }
}

// MARK: - Helper View for Node

struct NodeView: View {
    let person: Person
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Use relationship color for background?
            // Or keep simple avatar?
            AvatarView(person: person, size: size)
            // Add border or other styling?
            Circle().stroke(person.relationshipHealth.color, lineWidth: 2)
        }
        .frame(width: size, height: size)
        // Ensure taps pass through ZStack layers if needed, but NavigationLink should handle it
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

// Add thickness multiplier to RelationshipHealthStatus (Corrected Cases)
extension Person.RelationshipHealthStatus {
    var thicknessMultiplier: Double {
        switch self {
        case .thriving: return 1.8
        case .stable: return 1.2
        case .needsAttention: return 0.8
        case .unknown: return 0.6 // Thinner for unknown
        case .automatic: return 0.6 // Handle the automatic case (same as unknown)
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
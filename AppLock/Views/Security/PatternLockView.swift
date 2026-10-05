import SwiftUI

public enum PatternState {
    case normal
    case success
    case error
    
    var color: Color {
        switch self {
        case .normal: return AppColors.cyan
        case .success: return AppColors.emerald
        case .error: return AppColors.coral
        }
    }
}

public struct PatternLockView: View {
    @Binding var selectedIndices: [Int]
    var state: PatternState = .normal
    var onComplete: ([Int]) -> Void
    
    @State private var currentDragPosition: CGPoint? = nil
    @State private var dotPositions: [Int: CGPoint] = [:]
    
    public init(
        selectedIndices: Binding<[Int]>,
        state: PatternState = .normal,
        onComplete: @escaping ([Int]) -> Void
    ) {
        self._selectedIndices = selectedIndices
        self.state = state
        self.onComplete = onComplete
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let dotRadius: CGFloat = 16
            let activeDotRadius: CGFloat = 22
            let spacing = size / 3
            
            ZStack {
                // Background line paths
                Canvas { context, _ in
                    guard selectedIndices.count > 0 else { return }
                    
                    var path = Path()
                    if let firstIndex = selectedIndices.first, let startPoint = dotPositions[firstIndex] {
                        path.move(to: startPoint)
                        
                        for index in selectedIndices.dropFirst() {
                            if let point = dotPositions[index] {
                                path.addLine(to: point)
                            }
                        }
                        
                        if let dragPos = currentDragPosition, state == .normal {
                            path.addLine(to: dragPos)
                        }
                    }
                    
                    context.stroke(
                        path,
                        with: .color(state.color.opacity(0.8)),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
                }
                
                // 3x3 Grid Dots
                VStack(spacing: spacing - dotRadius * 2) {
                    ForEach(0..<3) { row in
                        HStack(spacing: spacing - dotRadius * 2) {
                            ForEach(0..<3) { col in
                                let index = row * 3 + col
                                let isSelected = selectedIndices.contains(index)
                                
                                ZStack {
                                    // Outer ring
                                    Circle()
                                        .stroke(
                                            isSelected ? state.color : AppColors.cardBorder,
                                            lineWidth: isSelected ? 2.5 : 1.5
                                        )
                                        .frame(width: isSelected ? activeDotRadius * 2 : dotRadius * 2,
                                               height: isSelected ? activeDotRadius * 2 : dotRadius * 2)
                                        .background(
                                            Circle().fill(isSelected ? state.color.opacity(0.15) : AppColors.cardBackground)
                                        )
                                        .shadow(color: isSelected ? state.color.opacity(0.6) : Color.clear, radius: 8)
                                    
                                    // Center inner dot
                                    Circle()
                                        .fill(isSelected ? state.color : AppColors.textSecondary.opacity(0.6))
                                        .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                                }
                                .background(
                                    GeometryReader { dotGeo in
                                        Color.clear
                                            .onAppear {
                                                let frame = dotGeo.frame(in: .named("PatternSpace"))
                                                dotPositions[index] = CGPoint(x: frame.midX, y: frame.midY)
                                            }
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .coordinateSpace(name: "PatternSpace")
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("PatternSpace"))
                    .onChanged { value in
                        currentDragPosition = value.location
                        checkHitDot(at: value.location, radius: spacing * 0.4)
                    }
                    .onEnded { _ in
                        currentDragPosition = nil
                        if selectedIndices.count >= 3 {
                            onComplete(selectedIndices)
                        } else {
                            selectedIndices.removeAll()
                        }
                    }
            )
        }
        .frame(width: 280, height: 280)
    }
    
    private func checkHitDot(at location: CGPoint, radius: CGFloat) {
        for (index, center) in dotPositions {
            let distance = hypot(location.x - center.x, location.y - center.y)
            if distance < radius && !selectedIndices.contains(index) {
                selectedIndices.append(index)
                HapticManager.shared.impact(.light)
            }
        }
    }
}

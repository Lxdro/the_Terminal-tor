import SwiftUI

struct RetroComputerView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(15)
            .background(
                ZStack {
                    // Base monitor frame
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "2b2b2b"))
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    // Monitor inner frame
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "1a1a1a"), lineWidth: 2)
                        .padding(4)
                    
                    // Scanlines effect
                    ScanlinesEffect()
                        .blendMode(.softLight)
                        .opacity(0.1)
                    
                    // CRT corners overlay
                    CRTCornersOverlay()
                    
                    // Glare effect
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 300
                    )
                }
            )
    }
}

struct ScanlinesEffect: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                stride(from: 0, to: geometry.size.height, by: 2).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.black.opacity(0.1), lineWidth: 1)
        }
    }
}

struct CRTCornersOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Corner gradients
                Path { path in
                    let radius: CGFloat = min(geometry.size.width, geometry.size.height) * 0.2
                    
                    // Top left corner
                    path.move(to: .zero)
                    path.addQuadCurve(
                        to: CGPoint(x: radius, y: 0),
                        control: CGPoint(x: radius/2, y: radius/2)
                    )
                    path.addLine(to: .zero)
                    
                    // Top right corner
                    path.move(to: CGPoint(x: geometry.size.width, y: 0))
                    path.addQuadCurve(
                        to: CGPoint(x: geometry.size.width - radius, y: 0),
                        control: CGPoint(x: geometry.size.width - radius/2, y: radius/2)
                    )
                    path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                    
                    // Bottom left corner
                    path.move(to: CGPoint(x: 0, y: geometry.size.height))
                    path.addQuadCurve(
                        to: CGPoint(x: 0, y: geometry.size.height - radius),
                        control: CGPoint(x: radius/2, y: geometry.size.height - radius/2)
                    )
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                    
                    // Bottom right corner
                    path.move(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                    path.addQuadCurve(
                        to: CGPoint(x: geometry.size.width, y: geometry.size.height - radius),
                        control: CGPoint(x: geometry.size.width - radius/2, y: geometry.size.height - radius/2)
                    )
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.5),
                            Color.clear
                        ]),
                        startPoint: .center,
                        endPoint: .leading
                    )
                )
                
                // Additional subtle inner glow
                Path { path in
                    let radius: CGFloat = min(geometry.size.width, geometry.size.height) * 0.3
                    
                    // Draw curved lines from corners towards center
                    // Top left
                    path.move(to: .zero)
                    path.addCurve(
                        to: CGPoint(x: radius, y: radius),
                        control1: CGPoint(x: radius/2, y: 0),
                        control2: CGPoint(x: 0, y: radius/2)
                    )
                    
                    // Top right
                    path.move(to: CGPoint(x: geometry.size.width, y: 0))
                    path.addCurve(
                        to: CGPoint(x: geometry.size.width - radius, y: radius),
                        control1: CGPoint(x: geometry.size.width - radius/2, y: 0),
                        control2: CGPoint(x: geometry.size.width, y: radius/2)
                    )
                    
                    // Bottom left
                    path.move(to: CGPoint(x: 0, y: geometry.size.height))
                    path.addCurve(
                        to: CGPoint(x: radius, y: geometry.size.height - radius),
                        control1: CGPoint(x: radius/2, y: geometry.size.height),
                        control2: CGPoint(x: 0, y: geometry.size.height - radius/2)
                    )
                    
                    // Bottom right
                    path.move(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                    path.addCurve(
                        to: CGPoint(x: geometry.size.width - radius, y: geometry.size.height - radius),
                        control1: CGPoint(x: geometry.size.width - radius/2, y: geometry.size.height),
                        control2: CGPoint(x: geometry.size.width, y: geometry.size.height - radius/2)
                    )
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                
                // Vignette effect
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.2)
                    ]),
                    center: .center,
                    startRadius: min(geometry.size.width, geometry.size.height) * 0.4,
                    endRadius: min(geometry.size.width, geometry.size.height) * 0.8
                )
            }
        }
    }
}

// Extension for hex colors
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xff0000) >> 16) / 255.0
        let g = Double((rgbValue & 0xff00) >> 8) / 255.0
        let b = Double(rgbValue & 0xff) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

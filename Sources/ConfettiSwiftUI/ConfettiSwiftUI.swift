//
//  ConfettiView.swift
//  Confetti
//
//  Created by Simon Bachmann on 24.11.20.
//

import SwiftUI

@available(iOS 14.0, *)
public struct ConfettiCannon: View {
    @Binding var counter:Int
    @ObservedObject var confettiConfig:ConfettiConfig

    @State var animate:[Bool] = []
    @State var finishedAnimationCouter = 0
    @State var firtAppear = false
    @State var error = ""
    
    /// renders configurable confetti animaiton
    /// - Parameters:
    ///   - counter: on any change of this variable the animation is run
    ///   - num: amount of confettis
    ///   - emojis: list of emojis
    ///   - includeDefaultShapes: include default confetti shapes such as circle and square
    ///   - colors: list of colors that is applied to the default shapes
    ///   - confettiSize: size that confettis and emojis are scaled to
    ///   - rainHeight: vertical distance that confettis pass
    ///   - fadesOut: reduce opacity towards the end of the animation
    ///   - opacity: maximum opacity that is reached during the animation
    ///   - openingAngle: boundary that defines the opening angle in degrees
    ///   - closingAngle: boundary that defines the opening angle in degrees
    ///   - radius: explosion radius
    ///   - repetitions: number of repetitions of the explosion
    ///   - repetitionInterval: duration between the repetitions
    public init(counter:Binding<Int>,
         num:Int = 20,
         emojis:[String] = [String](),
         includeDefaultShapes:Bool = false,
         colors:[Color] = [.blue, .red, .green, .yellow, .pink, .purple, .orange],
         confettiSize:CGFloat = 10.0,
         rainHeight: CGFloat = 600,
         fadesOut:Bool = true,
         opacity:Double = 1.0,
         openingAngle:Angle = .degrees(60),
         closingAngle:Angle = .degrees(120),
         radius:CGFloat = 300,
         repetitions:Int = 0,
         repetitionInterval:Double = 1.0
         
    ) {
        self._counter = counter
        
        var shapes = [AnyView]()
        if(emojis.count > 0){
            for emoji in emojis{
                shapes.append(AnyView(Text("\(emoji)").font(.system(size: confettiSize))))
            }
        }
        
        if includeDefaultShapes || emojis.count == 0{
            shapes.append(AnyView(Rectangle().frame(width: confettiSize, height: confettiSize, alignment: .center)))
            shapes.append(AnyView(Circle().frame(width: confettiSize, height: confettiSize, alignment: .center)))
        }
    
        confettiConfig = ConfettiConfig(
            num: num,
            shapes: shapes,
            colors: colors,
            confettiSize: confettiSize,
            rainHeight: rainHeight,
            fadesOut: fadesOut,
            opacity: opacity,
            openingAngle: openingAngle,
            closingAngle: closingAngle,
            radius: radius,
            repetitions: repetitions,
            repetitionInterval: repetitionInterval
        )
    }

    public var body: some View {
        ZStack{
            ForEach(finishedAnimationCouter..<animate.count, id:\.self){ i in
                ConfettiContainer(
                    finishedAnimationCouter: $finishedAnimationCouter,
                    confettiConfig: confettiConfig
                )
            }
        }
        .onAppear(){
            firtAppear = true
        }
        .onChange(of: counter){value in
            if firtAppear{
                for i in 0...confettiConfig.repetitions{
                    DispatchQueue.main.asyncAfter(deadline: .now() + confettiConfig.repetitionInterval * Double(i)) {
                        animate.append(false)
                        animate[value-1].toggle()
                    }
                }
            }
        }
    }
}

struct ConfettiContainer: View {
    @Binding var finishedAnimationCouter:Int
    @ObservedObject var confettiConfig:ConfettiConfig
    @State var firstAppear = true

    var body: some View{
        ZStack{
            ForEach(0...confettiConfig.num-1, id:\.self){_ in
                Confetti(confettiConfig: confettiConfig)
            }
        }
        .onAppear(){
            if firstAppear{
                DispatchQueue.main.asyncAfter(deadline: .now() + confettiConfig.animationDuration) {
                    self.finishedAnimationCouter += 1
                }
                firstAppear = false
            }
        }
    }
}

struct Confetti: View{
    @State var location:CGPoint = CGPoint(x: 0, y: 0)
    @State var opacity:Double = 1.0
    @ObservedObject var confettiConfig:ConfettiConfig

    
    func getShape() -> AnyView {
        return confettiConfig.shapes.randomElement()!
    }
    
    func getColor() -> Color {
        return confettiConfig.colors.randomElement()!
    }
    
    func getSpinDirection() -> CGFloat {
        let spinDirections:[CGFloat] = [-1.0, 1.0]
        return spinDirections.randomElement()!
    }

    var body: some View{
        ConfettiView(shape:getShape(), color:getColor(), spinDirX: getSpinDirection(), spinDirZ: getSpinDirection())
//            .frame(width: confettiConfig.confettiSize, height: confettiConfig.confettiSize, alignment: .center)
            .offset(x: location.x, y: location.y)
//            .scaleEffect(movement.z)
            .opacity(opacity)
            .onAppear(){
                withAnimation(Animation.timingCurve(0.61, 1, 0.88, 1, duration: confettiConfig.explosionAnimationDuration)) {
                    opacity = confettiConfig.opacity
                    
                    let randomAngle:CGFloat
                    if confettiConfig.openingAngle.degrees <= confettiConfig.closingAngle.degrees{
                        randomAngle = CGFloat.random(in: CGFloat(confettiConfig.openingAngle.degrees)...CGFloat(confettiConfig.closingAngle.degrees))
                    }else{
                        randomAngle = CGFloat.random(in: CGFloat(confettiConfig.openingAngle.degrees)...CGFloat(confettiConfig.closingAngle.degrees + 360)).truncatingRemainder(dividingBy: 360)
                    }
                    
                    let distance = CGFloat.random(in: 0.5...1) * confettiConfig.radius
                    
                    location.x = distance * cos(deg2rad(randomAngle))
                    location.y = -distance * sin(deg2rad(randomAngle))
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + confettiConfig.explosionAnimationDuration) {
                    withAnimation(Animation.timingCurve(0.12, 0, 0.39, 0, duration: confettiConfig.rainAnimationDuration)) {
                        location.y += confettiConfig.rainHeight
                        opacity = confettiConfig.fadesOut ? 0 : confettiConfig.opacity
                    }
                }
            }
    }
    
    func deg2rad(_ number: CGFloat) -> CGFloat {
        return number * CGFloat.pi / 180
    }
    
}

struct ConfettiView: View {
    @State var shape: AnyView
    @State var color: Color
    @State var spinDirX: CGFloat
    @State var spinDirZ: CGFloat
    @State var firstAppear = true

    
    @State var move = false
//    @State var xSpeed = Double.random(in: 0.7...3)
    @State var xSpeed:Double = Double.random(in: 1...2)

    @State var zSpeed = Double.random(in: 1...2)
    @State var anchor = CGFloat.random(in: 0...1).rounded()
    
    var body: some View {
        shape
            .foregroundColor(color)
            .rotation3DEffect(.degrees(move ? 360:0), axis: (x: spinDirX, y: 0, z: 0))
            .animation(Animation.linear(duration: xSpeed).repeatCount(10, autoreverses: false), value: move)
            .rotation3DEffect(.degrees(move ? 360:0), axis: (x: 0, y: 0, z: spinDirZ), anchor: UnitPoint(x: anchor, y: anchor))
            .animation(Animation.linear(duration: zSpeed).repeatForever(autoreverses: false), value: move)
            .onAppear() {
                if firstAppear {
                    move = true
                    firstAppear = true
                }
            }
    }
}


struct Movement{
    var x: CGFloat
    var y: CGFloat
    var z: CGFloat
    var opacity: Double
}


class ConfettiConfig: ObservableObject {
    internal init(num: Int, shapes: [AnyView], colors: [Color], confettiSize: CGFloat, rainHeight: CGFloat, fadesOut: Bool, opacity: Double, openingAngle:Angle, closingAngle:Angle, radius:CGFloat, repetitions:Int, repetitionInterval:Double) {
        self.num = num
        self.shapes = shapes
        self.colors = colors
        self.confettiSize = confettiSize
        self.rainHeight = rainHeight
        self.fadesOut = fadesOut
        self.opacity = opacity
        self.openingAngle = openingAngle
        self.closingAngle = closingAngle
        self.radius = radius
        self.repetitions = repetitions
        self.repetitionInterval = repetitionInterval
        self.explosionAnimationDuration = Double(radius / 1500)
        self.rainAnimationDuration = Double((rainHeight + radius) / 200)
    }
    
    @Published var num:Int
    @Published var shapes:[AnyView]
    @Published var colors:[Color]
    @Published var confettiSize:CGFloat
    @Published var rainHeight:CGFloat
    @Published var fadesOut:Bool
    @Published var opacity:Double
    @Published var openingAngle:Angle
    @Published var closingAngle:Angle
    @Published var radius:CGFloat
    @Published var repetitions:Int
    @Published var repetitionInterval:Double
    @Published var explosionAnimationDuration:Double
    @Published var rainAnimationDuration:Double

    
    var animationDuration:Double{
        return explosionAnimationDuration + rainAnimationDuration
    }
    
    var openingAngleRad:CGFloat{
        return CGFloat(openingAngle.degrees) * 180 / .pi
    }
    
    var closingAngleRad:CGFloat{
        return CGFloat(closingAngle.degrees) * 180 / .pi
    }
}

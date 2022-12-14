//
//  LoadingView.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import UIKit
import SwiftUI

struct LoadingView: View {
    
    var body: some View {
        ZStack {
            Color(uiColor: .white.withAlphaComponent(0.5))
                .ignoresSafeArea()
            LoadingWrapView()
                .frame(width: 30.0, height: 30.0)
                .offset(x: 15, y: 15)
        }
    }
}

struct LoadingWrapView: UIViewRepresentable {
    func makeUIView(context: Context) -> CustomLoadingView {
        let view = CustomLoadingView(CGRect(origin: .zero, size: CGSize(width: 30, height: 30)))
        return view
    }
    
    func updateUIView(_ uiView: CustomLoadingView, context: Context) {
        
    }
}

class CustomLoadingView: UIView {
    private var tint: UIColor = UIColor(red: 222.0/255.0, green: 4.0/255.0, blue: 4.0/255.0, alpha: 1.0)
    
    private var firstInit: Bool = false
    
    init(_ frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !firstInit {
            firstInit = true
            self.addCirclePath()
        }
    }
    
    private func addCirclePath() {
        let circlePath = UIBezierPath(arcCenter: .zero, radius: bounds.height/2.0, startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2 - 1.0), clockwise: true)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        
        // Change the fill color
        shapeLayer.fillColor = UIColor.clear.cgColor
        // You can change the stroke color
        shapeLayer.strokeColor = tint.cgColor
        // You can change the line width
        shapeLayer.lineWidth = 2.0
        
        self.layer.addSublayer(shapeLayer)
        
        let rotation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = Double.pi * 2
        rotation.duration = 1.0
        rotation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        rotation.repeatCount = .greatestFiniteMagnitude
        rotation.isCumulative = true
        shapeLayer.add(rotation, forKey: "rotationAnimation")
    }
    
}

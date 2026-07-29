//
//  LottieLoadingView.swift
//  TrinhsGroup
//
//  Created by long on 03/08/2022.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    typealias UIViewType = UIView
    let filename: String
    let isStop: Bool

    /// Owns the one `LottieAnimationView` that is actually in the view hierarchy.
    ///
    /// This must not be a stored property on the struct: SwiftUI re-creates the struct on
    /// every render pass, so an inline `LottieAnimationView()` would hand `updateUIView` a
    /// fresh, detached instance and every `play()`/`stop()` would miss the visible animation.
    final class Coordinator {
        let animationView = LottieAnimationView()
        /// What `animationView.animation` currently holds, so we only pay for a reload when
        /// the caller actually switches files.
        var loadedFilename: String?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = context.coordinator.animationView

        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
        ])

        return view
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<LottieView>) {
        let coordinator = context.coordinator
        let animationView = coordinator.animationView

        // Swap the composition when the caller changes files — an order moving from
        // processing to ready keeps the same view identity, so this is the only place the
        // new animation can be picked up.
        if coordinator.loadedFilename != filename {
            coordinator.loadedFilename = filename
            animationView.animation = LottieAnimation.named(filename)
        }

        // Guarded because `updateUIView` runs on every re-render and a bare `play()` on an
        // already-playing animation restarts it from frame zero, which reads as a stutter.
        if isStop {
            if animationView.isAnimationPlaying { animationView.stop() }
        } else if !animationView.isAnimationPlaying {
            animationView.play()
        }
    }
}

struct ActivityIndicator: UIViewRepresentable {
    
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct LottieLoadingView<Content>: View where Content: View {
    
    @Binding var isShowing: Bool
    var content: () -> Content
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                self.content()
                    .disabled(self.isShowing)
                    .blur(radius: self.isShowing ? 3 : 0)
                VStack {
                    LottieView(filename: "cookLoading", isStop: !isShowing)
                }
                .frame(width: geometry.size.width / 2,
                       height: geometry.size.height / 5)
                .background(Color.secondary.colorInvert())
                .foregroundColor(Color.primary)
                .cornerRadius(20)
                .opacity(self.isShowing ? 1 : 0)
            }
        }
    }
}

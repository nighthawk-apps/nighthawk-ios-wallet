//
//  LottieView.swift
//  lottie-test
//
//  Created by Francisco Gindre on 1/30/20.
//  Copyright © 2020 Francisco Gindre. All rights reserved.
//

import Foundation
import SwiftUI
import Lottie

public struct LottieAnimation: UIViewRepresentable {
    public enum AnimationType {
        case progress(progress: Float)
        case frameProgress(startFrame: Float, endFrame: Float, progress: Float, loop: Bool)
        case circularLoop
        case playOnce
    }
    var isPlaying = false
    var filename: String
    var animationType: AnimationType
    
    public init(isPlaying: Bool = false, filename: String, animationType: AnimationType) {
        self.isPlaying = isPlaying
        self.filename = filename
        self.animationType = animationType
    }
    
    public class Coordinator: NSObject {
        var lastProgress: Float
        var parent: LottieAnimation
        
        init(parent: LottieAnimation) {
            self.parent = parent
            
            if case AnimationType.frameProgress(let startFrame, _, _, _) = self.parent.animationType {
                self.lastProgress = startFrame
            } else {
                self.lastProgress = 0
            }
        }
    }
    
    public func makeUIView(context: UIViewRepresentableContext<LottieAnimation>) -> AnimationViewProxy {
        return AnimationViewProxy(
            isPlaying: isPlaying,
            filename: filename,
            animationType: animationType
        )
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public func updateUIView(_ uiView: AnimationViewProxy, context: UIViewRepresentableContext<LottieAnimation>) {
        guard isPlaying else {
            uiView.stop()
            return
        }
        
        switch self.animationType {
        case .circularLoop:
            if !uiView.isAnimationPlaying {
                uiView.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
            }
        case .progress(let progress):
            uiView.currentProgress = AnimationProgressTime(progress)
            if !uiView.isAnimationPlaying {
                uiView.play(fromProgress: 0, toProgress: 1, loopMode: .loop, completion: nil)
            }
        case let .frameProgress(startFrame, endFrame, progress, loop):
            let progressTimeFrame = AnimationFrameTime(startFrame + (progress * (endFrame - startFrame)))
            
            uiView.play(fromFrame: nil, toFrame: progressTimeFrame, loopMode: loop ? .loop : .none, completion: nil)
            context.coordinator.lastProgress = progress
        case .playOnce:
            uiView.play()
        }
    }
    
    public final class AnimationViewProxy : UIView  {
        private let animationView = LottieAnimationView()
        var isAnimationPlaying: Bool {
            get {
                animationView.isAnimationPlaying
            }
        }
        
        var currentProgress: AnimationProgressTime {
            get {
                animationView.currentProgress
            }
            
            set {
                animationView.currentProgress = newValue
            }
        }
        
        init(isPlaying: Bool = false, filename: String, animationType: AnimationType) {
            super.init(frame: .zero)
            
            animationView.animation = Lottie.LottieAnimation.named(filename)
            animationView.contentMode = .scaleAspectFit
            self.addSubview(animationView)
            animationView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                animationView.widthAnchor.constraint(equalTo: self.widthAnchor),
                animationView.heightAnchor.constraint(equalTo: self.heightAnchor)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func play(completion: Lottie.LottieCompletionBlock? = nil) {
            self.animationView.play(completion: completion)
        }
        
        func play(
            fromProgress: Lottie.AnimationProgressTime? = nil,
            toProgress: Lottie.AnimationProgressTime,
            loopMode: Lottie.LottieLoopMode? = nil,
            completion: Lottie.LottieCompletionBlock? = nil
        ) {
            self.animationView.play(
                fromProgress: fromProgress,
                toProgress: toProgress,
                loopMode: loopMode,
                completion: completion
            )
        }
        
        func play(
            fromFrame: Lottie.AnimationFrameTime? = nil,
            toFrame: Lottie.AnimationFrameTime,
            loopMode: Lottie.LottieLoopMode? = nil,
            completion: Lottie.LottieCompletionBlock? = nil
        ) {
            self.animationView.play(
                fromFrame: fromFrame,
                toFrame: toFrame,
                loopMode: loopMode,
                completion: completion
            )
        }
        
        func stop() {
            self.animationView.stop()
        }
    }
}

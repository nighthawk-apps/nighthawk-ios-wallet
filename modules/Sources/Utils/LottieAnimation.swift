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
    
    public func makeUIView(context: UIViewRepresentableContext<LottieAnimation>) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        
        let animation = Lottie.LottieAnimation.named(filename)
        
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        
        return animationView
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public func updateUIView(_ uiView: LottieAnimationView, context: UIViewRepresentableContext<LottieAnimation>) {
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
}

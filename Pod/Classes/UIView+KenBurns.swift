//
//  UIView+KenBurns.swift
//  APKenBurnsView
//
//  Created by Ryan Grimm on 7/12/18.
//

import Foundation

@objc extension UIView {
    public func applyKenBurnsAnimation(image: UIImage,
                                forViewPortSize viewPortSize: CGSize,
                                duration: Double,
                                scaleFactorDeviation: Float = 1.0,
                                faceRecognition: Bool = false) {
        
        let faceRecognitionMode = faceRecognition ? APKenBurnsViewFaceRecognitionMode.Group : APKenBurnsViewFaceRecognitionMode.None
        
        let animationDependencies = ImageAnimationDependencies(scaleFactorDeviation: scaleFactorDeviation,
                                                               imageAnimationDuration: duration,
                                                               imageAnimationDurationDeviation: 0.0)
        let animationDataSourceFactory = AnimationDataSourceFactory(animationDependencies: animationDependencies,
                                                                    faceRecognitionMode: faceRecognitionMode)
        let animationDataSource = animationDataSourceFactory.buildAnimationDataSource()
        
        var animation = animationDataSource.buildAnimationForImage(image: image, forViewPortSize: viewPortSize, durationOverride: nil)
        
        animation = ImageAnimation(startState: animation.startState,
                                   endState: animation.endState,
                                   duration: animation.duration)
        
        self.animateWithImageAnimation(animation: animation)
    }
    
    public func pauseAnimations() {
        self.backupAnimations()
        layer.pauseAnimations()
    }
    
    public func resumeAnimations() {
        self.restoreAnimations()
        layer.resumeAnimations()
    }
    
    public func stopAnimations() {
        layer.removeAllAnimations()
    }
}

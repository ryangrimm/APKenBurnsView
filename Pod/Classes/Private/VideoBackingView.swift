//
//  VideoBackingView.swift
//  APKenBurnsView
//
//  Created by Ryan Grimm on 6/24/18.
//

import AVFoundation

internal class VideoBackingView: UIView {
    override class var layerClass: AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }
    
    var finishedPlayingBlock: (() -> Void)?
    
    var playerLayer: AVPlayerLayer {
        get {
            return self.layer as! AVPlayerLayer
        }
    }
    
    var player: AVPlayer? {
        get {
            return self.playerLayer.player;
        }
        set {
            if let oldPlayer = player {                
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: oldPlayer.currentItem)
            }
            
            if let newPlayer = newValue {
                NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishAction), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
                
                self.playerLayer.player = newPlayer
                self.playerLayer.videoGravity = .resizeAspect
            }
        }
    }
    
    @objc func playerDidFinishAction() {
        if let finishedPlayingBlock = self.finishedPlayingBlock {
            finishedPlayingBlock()
        }
    }
    
    deinit {
        if (self.player != nil) {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
        }
    }
}

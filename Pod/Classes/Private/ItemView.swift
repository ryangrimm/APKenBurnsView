//
//  KenBurnsItemView.swift
//  APKenBurnsView
//
//  Created by Ryan Grimm on 6/24/18.
//

import UIKit
import AVFoundation

internal class ItemView: UIView {
    var item: APKenBurnsItem? {
        didSet {
            if item == nil {
                self.videoPlayer = nil
            }
            else if item?.itemType == .image {
                self.image = item?.image
            }
            else {
                self.videoPlayer = item?.player
            }
        }
    }
    
    var imageView: UIImageView? = nil
    var videoView: VideoBackingView? = nil
    private var image: UIImage? {
        get {
            return self.imageView?.image
        }
        set {
            if self.imageView == nil {
                let imageView = UIImageView(frame: bounds)
                imageView.frame = bounds
                imageView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                imageView.contentMode = .center
                self.addSubview(imageView)
                
                self.imageView = imageView
            }
            
            self.imageView?.image = newValue
            
            self.imageView?.isHidden = false
            if self.videoView != nil {
                self.videoView?.removeFromSuperview()
                self.videoView = nil
            }
        }
    }
    
    private var videoPlayer: AVPlayer? {
        get {
            return self.videoView?.player
        }
        set {
            if self.videoView != nil {
                self.videoView?.removeFromSuperview()
                self.videoView = nil
            }
            if newValue == nil {
                return
            }
            
            let videoView = VideoBackingView(frame: CGRect.zero)
            videoView.frame = bounds
            videoView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            videoView.contentMode = .center

            self.addSubview(videoView)
            
            self.videoView = videoView

            self.videoView?.player = newValue
            self.imageView?.isHidden = true
        }
    }
}

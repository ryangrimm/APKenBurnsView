//
// Created by Nickolay Sheika on 4/25/16.
//

import Foundation
import UIKit
import QuartzCore
import AVFoundation

@objc public protocol APKenBurnsViewDataSource {
    
    /*
     The total number of items that the view will display.
     */
    func numberOfItemsIn(kenBurnsView: APKenBurnsView) -> Int
    
    /*
     Provides the actual items for the view to display. Once the
     item is ready, use the `setItem` callback to provide it.
     */
    func item(forKenBurnsView: APKenBurnsView, atIndex: Int, setItem:((APKenBurnsItem)->Void)) -> Void
}


@objc public protocol APKenBurnsViewDelegate {

    /*
        Called when transition starts from one image to another
    */
    @objc optional func kenBurnsViewDidStartTransition(kenBurnsView: APKenBurnsView, toItem: APKenBurnsItem)

    /*
        Called when transition from one image to another is finished
    */
    @objc optional func kenBurnsViewDidFinishTransition(kenBurnsView: APKenBurnsView)
}


public enum APKenBurnsViewFaceRecognitionMode {
    case None         // no face recognition, simple Ken Burns effect
    case Biggest      // recognizes biggest face in image, if any then transition will start or will finish (chosen randomly) in center of face rect.
    case Group        // recognizes all faces in image, if any then transition will start or will finish (chosen randomly) in center of compound rect of all faces.
}

public class APKenBurnsView: UIView {

    // MARK: - DataSource

    /*
        NOTE: Interface Builder does not support connecting to an outlet in a Swift file when the outlet’s type is a protocol.
        Workaround: Declare the outlet's type as AnyObject or NSObject, connect objects to the outlet using Interface Builder, then change the outlet's type back to the protocol.
    */
    @IBOutlet public weak var dataSource: APKenBurnsViewDataSource?


    // MARK: - Delegate

    /*
        NOTE: Interface Builder does not support connecting to an outlet in a Swift file when the outlet’s type is a protocol.
        Workaround: Declare the outlet's type as AnyObject or NSObject, connect objects to the outlet using Interface Builder, then change the outlet's type back to the protocol.
    */
    @IBOutlet public weak var delegate: APKenBurnsViewDelegate?


    // MARK: - Animation Setup

    /*
        Face recognition mode. See APKenBurnsViewFaceRecognitionMode docs for more information.
    */
    public var faceRecognitionMode: APKenBurnsViewFaceRecognitionMode = .None

    /*
        Allowed deviation of scale factor.

        Example: If scaleFactorDeviation = 0.5 then allowed scale will be from 1.0 to 1.5.
        If scaleFactorDeviation = 0.0 then allowed scale will be from 1.0 to 1.0 - fixed scale factor.
    */
    @IBInspectable public var scaleFactorDeviation: Float = 1.0

    /*
        Animation duration of one image
    */
    @IBInspectable public var imageAnimationDuration: Double = 10.0

    /*
        Allowed deviation of animation duration of one image

        Example: if imageAnimationDuration = 10 seconds and imageAnimationDurationDeviation = 2 seconds then
        resulting image animation duration will be from 8 to 12 seconds
    */
    @IBInspectable public var imageAnimationDurationDeviation: Double = 0.0

    /*
        Duration of transition animation between images
    */
    @IBInspectable public var transitionAnimationDuration: Double = 4.0

    /*
        Allowed deviation of animation duration of one image
    */
    @IBInspectable public var transitionAnimationDurationDeviation: Double = 0.0

    /*
        If set to true then recognized faces will be shown as rectangles. Only applicable for debugging.
    */
    @IBInspectable public var showFaceRectangles: Bool = false

    public var numberOfItemsInView: Int = 0
    

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    @objc public func showPreviousItem() {
        stopAnimations()
        let onscreen = firstItemView.alpha > 0.5 ? firstItemView : secondItemView
        if let item = onscreen?.item {
            if item.itemType == .video {
                item.player?.pause()
            }
        }
        
        self.index -= 2
        if self.index < 0 {
            self.index = 0
        }
        startAnimations()
    }
    
    @objc public func showNextItem() {
        if timer != nil && timer!.isValid {
            let onscreen = firstItemView.alpha > 0.5 ? firstItemView : secondItemView
            UIView.animate(withDuration: 0.25, animations: {
                onscreen!.alpha = 0
            })
            timer!.fire()
        }
        else {
            stopAnimations()
            incrementIndex()
            startAnimations()
        }
    }
    
    // MARK: - Public

    @objc public func startAnimations() {
        stopAnimations()

        if let dataSource = dataSource {
            numberOfItemsInView = dataSource.numberOfItemsIn(kenBurnsView: self)
            if numberOfItemsInView == 0 {
                return;
            }
            if self.index >= numberOfItemsInView {
                self.index = 0
            }
            
            var asyncItem = AsyncItem()
            dataSource.item(forKenBurnsView: self, atIndex: self.index) { item in
                asyncItem.item = item
            }
            
            animationDataSource = buildAnimationDataSource()
            
            firstItemView.alpha = 1.0
            secondItemView.alpha = 0.0
            
            startTransitionToItem(asyncItem: asyncItem, itemView: firstItemView, nextItemView: secondItemView)
        }
    }

    @objc public func pauseAnimations() {
        firstItemView.backupAnimations()
        secondItemView.backupAnimations()

        timer?.pause()
        layer.pauseAnimations()
    }

    @objc public func resumeAnimations() {
        firstItemView.restoreAnimations()
        secondItemView.restoreAnimations()

        timer?.resume()
        layer.resumeAnimations()
    }

    @objc public func stopAnimations() {
        timer?.cancel()
        layer.removeAllAnimations()
    }


    // MARK: - Private Variables

    private var firstItemView: ItemView!
    private var secondItemView: ItemView!

    private var animationDataSource: AnimationDataSource!
    private var facesDrawer: FacesDrawerProtocol!

    private let notificationCenter = NotificationCenter.default

    private var timer: BlockTimer?

    var index = 0;
    var nextAsyncItem: AsyncItem?

    // MARK: - Setup

    private func setup() {
        self.index = 0
        
        firstItemView = buildDefaultItemView()
        secondItemView = buildDefaultItemView()
        facesDrawer = FacesDrawer()
    }


    // MARK: - Lifecycle

    public override func didMoveToSuperview() {
        guard superview == nil else {
            notificationCenter.addObserver(self,
                                           selector: #selector(applicationWillResignActive),
                                           name: NSNotification.Name.UIApplicationWillResignActive,
                                           object: nil)
            notificationCenter.addObserver(self,
                                           selector: #selector(applicationDidBecomeActive),
                                           name: NSNotification.Name.UIApplicationDidBecomeActive,
                                           object: nil)
            return
        }
        notificationCenter.removeObserver(self)

        // required to break timer retain cycle
        stopAnimations()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }


    // MARK: - Notifications

    @objc private func applicationWillResignActive(notification: NSNotification) {
        pauseAnimations()
    }

    @objc private func applicationDidBecomeActive(notification: NSNotification) {
        resumeAnimations()
    }


    // MARK: - Timer

    private func startTimerWithDelay(delay: Double, callback: @escaping () -> ()) {
        stopTimer()

        timer = BlockTimer(interval: delay, callback: callback)
    }

    private func stopTimer() {
        timer?.cancel()
    }


    // MARK: - Private

    private func buildAnimationDataSource() -> AnimationDataSource {
        let animationDependencies = ImageAnimationDependencies(scaleFactorDeviation: scaleFactorDeviation,
                                                               imageAnimationDuration: imageAnimationDuration,
                                                               imageAnimationDurationDeviation: imageAnimationDurationDeviation)
        let animationDataSourceFactory = AnimationDataSourceFactory(animationDependencies: animationDependencies,
                                                                    faceRecognitionMode: faceRecognitionMode)
        return animationDataSourceFactory.buildAnimationDataSource()
    }
    
    private func startTransitionToItem(asyncItem: AsyncItem, itemView: ItemView, nextItemView: ItemView) {
        guard isValidAnimationDurations() else {
            fatalError("Animation durations setup is invalid!")
        }
        
        self.incrementIndex()
        
        // Prefetch the next item
        var nextAsyncItem = AsyncItem()
        if let dataSource = self.dataSource {
            dataSource.item(forKenBurnsView: self, atIndex: self.index) { item in
                nextAsyncItem.item = item
            }
        }
        
        var asyncItem = asyncItem
        asyncItem.itemReady = { item in
            DispatchQueue.main.async {
                let duration = self.buildAnimationDuration()
                var delay: Double
                
                itemView.item = item
                
                if item.itemType == .image {
                    var animation = self.animationDataSource.buildAnimationForImage(image: item.image!, forViewPortSize: self.bounds.size, durationOverride: item.duration)
                    
                    animation = ImageAnimation(startState: animation.startState,
                                               endState: animation.endState,
                                               duration: animation.duration)
                    
                    itemView.animateWithImageAnimation(animation: animation)
                    
                    if self.showFaceRectangles {
                        self.facesDrawer.drawFacesInView(view: itemView.imageView!, image: item.image!)
                    }
                    
                    delay = animation.duration - duration / 2
                }
                else {
                    delay = item.duration != nil ? item.duration! : self.imageAnimationDuration
                    let itemDuration = Double(CMTimeGetSeconds((item.player?.currentItem?.asset.duration)!))
                    if delay > itemDuration {
                        delay = itemDuration
                    }
                    
                    delay = delay - duration / 2

                    itemView.transform = CGAffineTransform.identity
                    item.player?.seek(to: CMTimeMake(0, 30))
                    item.player?.play()
                }
                
                self.startTimerWithDelay(delay: delay) {
                    self.delegate?.kenBurnsViewDidStartTransition?(kenBurnsView: self, toItem: item)
                    
                    self.animateTransitionWithDuration(duration: duration, itemView: itemView, nextItemView: nextItemView) {
                        if item.itemType == .video {
                            if let player = item.player {
                                player.pause()
                            }
                        }
                        
                        self.delegate?.kenBurnsViewDidFinishTransition?(kenBurnsView: self)
                        if self.showFaceRectangles && item.itemType == .image {
                            self.facesDrawer.cleanUpForView(view: nextItemView.imageView!)
                        }
                    }
                    
                    self.startTransitionToItem(asyncItem: nextAsyncItem, itemView: nextItemView, nextItemView: itemView)
                }
            }
        }
    }

    private func incrementIndex() {
        self.index += 1
        if self.index == self.numberOfItemsInView {
            self.index = 0
        }
    }

    private func animateTransitionWithDuration(duration: Double, itemView: ItemView, nextItemView: ItemView, completion: @escaping () -> ()) {
        UIView.animate(withDuration: duration,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions.curveEaseInOut,
                                   animations: {
                                       itemView.alpha = 0.0
                                       nextItemView.alpha = 1.0
                                   },
                                   completion: { finished in
                                        completion()
                                   })
    }

    private func buildAnimationDuration() -> Double {
        var durationDeviation = 0.0
        if transitionAnimationDurationDeviation > 0.0 {
            durationDeviation = RandomGenerator().randomDouble(min: -transitionAnimationDurationDeviation,
                                                               max: transitionAnimationDurationDeviation)
        }
        let duration = transitionAnimationDuration + durationDeviation
        return duration
    }

    private func isValidAnimationDurations() -> Bool {
        return imageAnimationDuration - imageAnimationDurationDeviation -
               (transitionAnimationDuration - transitionAnimationDurationDeviation) / 2 > 0.0
    }

    private func buildDefaultItemView() -> ItemView {
        let itemView = ItemView(frame: bounds)
        itemView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        itemView.contentMode = UIViewContentMode.center
        self.addSubview(itemView)

        return itemView
    }
}

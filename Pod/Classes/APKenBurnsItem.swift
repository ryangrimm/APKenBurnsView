
import AVFoundation

@objc public class APKenBurnsItem: NSObject {
    public enum ItemType {
        case image
        case video
    }
    
    public let itemType: ItemType
    public let image: UIImage?
    public let player: AVPlayer?
    public let duration: Double?
    
    @objc static public func withImage(_ image: UIImage, duration: NSNumber? = nil) -> APKenBurnsItem {
        return APKenBurnsItem(withImage: image, duration: duration?.doubleValue)
    }

    public init(withImage image: UIImage, duration: Double? = nil) {
        self.itemType = .image
        self.image = image
        self.duration = duration
        self.player = nil
    }
    
    @objc static public func withVideoPlayer(_ player: AVPlayer, duration: NSNumber? = nil) -> APKenBurnsItem {
        return APKenBurnsItem(withVideoPlayer: player, duration: duration?.doubleValue)
    }

    public init(withVideoPlayer player: AVPlayer, duration: Double? = nil) {
        self.itemType = .video
        self.player = player
        self.duration = duration
        self.image = nil
    }
}

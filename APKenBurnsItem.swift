
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
    
    public init(withImage image: UIImage, duration: Double? = nil) {
        self.itemType = .image
        self.image = image
        self.duration = duration
        self.player = nil
    }
    
    public init(withVideoPlayer player: AVPlayer, duration: Double? = nil) {
        self.itemType = .video
        self.player = player
        self.duration = duration
        self.image = nil
    }
}

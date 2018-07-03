
import Foundation

internal class AsyncItem {
    var ready: Bool = false
    
    var itemReady: ((APKenBurnsItem) -> Void)? {
        didSet {
            if ready {
                itemReady!(self.item!)
            }
        }
    }
    
    var item: APKenBurnsItem? {
        didSet {
            if let item = self.item {
                self.ready = true
                if let itemReady = self.itemReady {
                    itemReady(item)
                }
            }
            else {
                self.ready = false
            }
        }
    }
}

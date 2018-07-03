//
//  KenBurnsViewController.swift
//  APKenBurnsView
//
//  Created by Nickolay Sheika on 04/21/2016.
//  Copyright (c) 2016 Nickolay Sheika. All rights reserved.
//

import UIKit
import APKenBurnsView
import AVFoundation

class KenBurnsViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var kenBurnsView: APKenBurnsView!

    // MARK: - Public Variables

    var faceRecoginitionMode: APKenBurnsViewFaceRecognitionMode = .None
    var dataSource: [String]!
    
    var items: [APKenBurnsItem]? = nil

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let url = Bundle.main.path(forResource: "big_buck_bunny", ofType: "mp4")!
        let asset = AVURLAsset.init(url: URL(fileURLWithPath: url))
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.isMuted = false
        
        items = [
            APKenBurnsItem(withImage: UIImage(named: "nature1")!),
            APKenBurnsItem(withVideoPlayer: player, duration: 8),
            APKenBurnsItem(withImage: UIImage(named: "nature2")!),
            APKenBurnsItem(withImage: UIImage(named: "family1")!),
            APKenBurnsItem(withImage: UIImage(named: "family2")!),
        ]

        navigationController!.isNavigationBarHidden = true

        kenBurnsView.faceRecognitionMode = faceRecoginitionMode
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.kenBurnsView.startAnimations()
    }
}

extension KenBurnsViewController: APKenBurnsViewDataSource {
    func numberOfItemsIn(kenBurnsView: APKenBurnsView) -> Int {
        if let items = self.items {
            return items.count
        }
        else {
            return 0
        }
    }
    
    func item(forKenBurnsView: APKenBurnsView, atIndex: Int, setItem: ((APKenBurnsItem) -> Void)) {
         setItem(items![atIndex])
    }
}

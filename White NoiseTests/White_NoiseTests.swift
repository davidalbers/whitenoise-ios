//
//  White_NoiseTests.swift
//  White NoiseTests
//
//  Created by David Albers on 4/9/17.
//  Copyright © 2017 David Albers. All rights reserved.
//

import XCTest
@testable import White_Noise

class White_NoiseTests: XCTestCase {
    var viewController: ViewController!
    var presenter: MainPresenter!
    
    override func setUp() {
        super.setUp()
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        viewController = storyboard.instantiateInitialViewController()
            as! ViewController
        presenter = MainPresenter(viewController: viewController)
        presenter.volume = 1.0
        presenter.resettingVolume = false
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFade() {
        presenter.enableFadeVolume(enabled: true)
        XCTAssert(presenter.fadeEnabled)
        presenter.tick()
        XCTAssert(!isVolumeEqual(volume1: 1.0, volume2: presenter.volume))
        XCTAssert(!isVolumeEqual(volume1: 1.0, volume2: presenter.maxVolume))
    }
    
    func testWave() {
        presenter.enableWavyVolume(enabled: true)
        presenter.increasing = false
        presenter.tick()
        XCTAssert(isVolumeEqual(volume1: 1.0 - presenter.volumeIncrement,
                                volume2: presenter.volume))
        presenter.increasing = true
        presenter.tick()
        XCTAssert(isVolumeEqual(volume1: 1.0, volume2: presenter.volume))
    }
    
    func testFadeAndWave() {
        
    }
    
    func isVolumeEqual(volume1: Float, volume2: Float) -> Bool {
        return volume2 < volume1 + 0.00001 && volume2 > volume1 - 0.00001
    }
    
//    func testPerformanceExample() {
//        self.measure {
//        }
//    }
    
}

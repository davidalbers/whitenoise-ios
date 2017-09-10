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
    var viewController: ViewControllerMock!
    var presenter: MainPresenter!
    
    class ViewControllerMock : ViewController {
        
        public var playCalled : Bool = false
        public var getTimeCalled : Bool = false
        public var addTimerCalled : Bool = false
        let timerPickerTime : Double = 60.0
        public var timerText : String = ""
        public var mediaTitle : String = ""
        
        override func play() {
            playCalled = true
        }
        override func getTimerPickerTime() -> Double {
            getTimeCalled = true
            return timerPickerTime
        }
        
        override func addTimer(timerText: String) {
            addTimerCalled = true
            self.timerText = timerText
        }
        
        override func setColor(color: MainPresenter.NoiseColors) {
            //mock has nothing to do
        }
        
        override func setMediaTitle(title: String) {
            mediaTitle = title
        }
    }
    
    override func setUp() {
        super.setUp()
        
        viewController = ViewControllerMock()
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
        presenter.enableWavyVolume(enabled: true)
        presenter.enableFadeVolume(enabled: true)
        presenter.increasing = false
        presenter.volume = 0.5
        presenter.tick()
        XCTAssert(isVolumeEqual(volume1: 0.5 - presenter.volumeIncrement,
                                volume2: presenter.volume))
        XCTAssert(!isVolumeEqual(volume1: 0.5, volume2: presenter.maxVolume))
    }
    
    func isVolumeEqual(volume1: Float, volume2: Float) -> Bool {
        return volume2 < volume1 + 0.00001 && volume2 > volume1 - 0.00001
    }
    
    func testChangeColor() {
        presenter.changeColor(color: MainPresenter.NoiseColors.Pink);
        XCTAssert(presenter.getColor() == MainPresenter.NoiseColors.Pink)
        XCTAssertTrue(viewController.mediaTitle == "Pink Noise")
    }
    
    func testPlay() {
        presenter.isPlaying = false
        presenter.playPause()
        
        XCTAssertTrue(viewController.playCalled)
        XCTAssert(presenter.isPlaying)
        XCTAssertTrue(viewController.mediaTitle == "White Noise")
    }
    
    func testAddTimer() {
        presenter.addDeleteTimer()
        XCTAssert(presenter.timerDisplayed)
        XCTAssert(presenter.timerActive)
        XCTAssert(viewController.addTimerCalled)
        XCTAssert(viewController.getTimeCalled)
        print(viewController.timerText)
        XCTAssert(viewController.timerText == "01:00")
    }
    
}

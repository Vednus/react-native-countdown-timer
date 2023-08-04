@objc(CountdownTimer)
class CountdownTimer: NSObject {
  // Default sound file name
  let defaultSoundFileName = "bell"
  var timer: Timer?
  var remainingSeconds: Int = 0
  var timerCallback: RCTResponseSenderBlock?
  var soundPlayer: AVAudioPlayer?
  var soundFileURL: URL?

  @objc(multiply:withB:withResolver:withRejecter:)
  func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    resolve(a*b)
  }


  private func getSoundFileURLFromPackage(_ fileName: String) -> URL? {
      guard let soundFileURL = Bundle(for: TimerManager.self).url(forResource: fileName, withExtension: "mp3") else {
          return nil
      }
      return soundFileURL
  }

  @objc(setSoundFileURI: withResolver: withRejecter:)
  func setSoundFileURI(soundFileURLString: String, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    if let url = URL(string: uriString) {
        soundFileURL = url
    } else {
        // Use the default sound file if the provided URL is invalid
        if let defaultSoundFileURL = getSoundFileURLFromPackage(defaultSoundFileName) {
            soundFileURL = defaultSoundFileURL
        } else {
            print("Default sound file not found.")
        }
    }
    resolve(soundFileURI)
  }

  @objc(startTimer:withCallback:withResolver:withRejecter:)
  func startTimer(seconds: Int, callback: @escaping RCTResponseSenderBlock, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    remainingSeconds = seconds
    self.timerCallback = callback

    let countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
        remainingSeconds -= 1.0

        if remainingSeconds <= 0.0 {
            self?.stopTimer()
            self?.playSoundInBackground()
            callback([NSNull(), true]) // Callback to the JavaScript with true as the second parameter to indicate the timer reached zero.
        } else {
            callback([NSNull(), remainingSeconds])
        }
    }

    // Save the timer reference to the module so we can stop it later
    timer = countdownTimer

    // Start the timer immediately
    timer?.fire()
    resolve(true)
  }

  @objc(stopTimer:withResolver:withRejecter:)
  func stopTimer(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    timer?.invalidate()
    timer = nil
  }

  @objc(pauseTimer:withResolver:withRejecter:)
  func pauseTimer(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    timer?.invalidate()
    timer = nil
  }

  @objc(resumeTimer:withResolver:withRejecter:)
  func resumeTimer(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
        remainingSeconds -= 1.0
        if remainingSeconds <= 0.0 {
            self?.stopTimer()
            self?.playSoundInBackground()
            self?.timerCallback([NSNull(), true]) // Callback to the JavaScript with true as the second parameter to indicate the timer reached zero.
        } else {
            self?.timerCallback([NSNull(), remainingSeconds])
        }
    }
  }

  private func playSoundInBackground() {
      guard let soundFileURL = soundFileURL else {
          return
      }

      do {
          try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
          try AVAudioSession.sharedInstance().setActive(true)

          soundPlayer = try AVAudioPlayer(contentsOf: soundFileURL)
          soundPlayer?.prepareToPlay()
          soundPlayer?.play()
      } catch let error {
          print(error.localizedDescription)
      }
  }

}

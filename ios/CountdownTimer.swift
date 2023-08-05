import AVFAudio

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
        guard let soundFileURL = Bundle(for: CountdownTimer.self).url(forResource: fileName, withExtension: "mp3") else {
            return nil
        }
        return soundFileURL
    }
    
    @objc(setSoundFileURI: withResolver: withRejecter:)
    func setSoundFileURI(uriString: String, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
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
        resolve(soundFileURL)
    }
    
    @objc func fireTimer() {
        print("Timer fired!")
        remainingSeconds -= 1
        if remainingSeconds <= 0 {
            timer?.invalidate()
            self.playSoundInBackground()
            timerCallback!([NSNull(), true]) // Callback to the JavaScript with true as the second parameter to indicate the timer reached zero.
        } else {
            timerCallback!([NSNull(), remainingSeconds])
        }
    }
    
    @objc(startTimer:withCallback:withResolver:withRejecter:)
    func startTimer(seconds: Int, callback: @escaping RCTResponseSenderBlock, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        remainingSeconds = seconds
        self.timerCallback = callback
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        
        // Start the timer immediately
        timer?.fire()
        resolve(true)
    }
    
    @objc(stopTimer:withRejecter:)
    func stopTimer(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        timer?.invalidate()
        timer = nil
    }
    
    @objc(pauseTimer:withRejecter:)
    func pauseTimer(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        timer?.invalidate()
        timer = nil
    }
    
    @objc(resumeTimer:withRejecter:)
    func resumeTimer(resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        
        // Start the timer immediately
        timer?.fire()
    }
    
    private func playSoundInBackground() {
        guard let soundFileURL = soundFileURL else {
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            soundPlayer = try AVAudioPlayer(contentsOf: soundFileURL)
            soundPlayer?.prepareToPlay()
            soundPlayer?.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
}

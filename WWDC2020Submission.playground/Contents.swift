import SceneKit
import CoreLocation
import GLKit
import PlaygroundSupport
import AVFoundation
import AVKit
import UIKit

var earthNodeRotationSpeed: CGFloat = CGFloat(Double.pi/40)

class EarthScene: SCNScene  {
    let observerNode: SCNNode = SCNNode()
    let sunNode: SCNNode = SCNNode()
    let earthNode: SCNNode = SCNNode()
    let cloudNode: SCNNode = SCNNode()
    let sunNodeRotationSpeed: CGFloat  = CGFloat(Double.pi/6)
    //let earthNodeRotationSpeed: CGFloat = CGFloat(Double.pi/40)
    var earthNodeRotation: CGFloat = 0
    var sunNodeRotation: CGFloat = CGFloat(Double.pi/2)
    
    override init()
    {
        super.init()
        setUpObserver()
        setUpSun()
        setUpEarth()
        setUpCloudsAndHalo()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpObserver()
    {
        //Set up initial camera's position
        observerNode.camera = SCNCamera()
        observerNode.position = SCNVector3(x: 0, y: 0, z: 11)
        
        let observerLight = SCNLight()
        observerLight.type = SCNLight.LightType.ambient
        observerLight.color = UIColor(white: 0.01, alpha: 1.0)
        observerNode.light = observerLight
        
        rootNode.addChildNode(observerNode)
    }
    
    func setUpSun()
    {
        //Set up sunlights postion
        let sunNodeLight = SCNLight()
        sunNodeLight.type = SCNLight.LightType.directional
        sunNode.light = sunNodeLight
        
        // Set up roation vector
        sunNode.rotation = SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: Float(CGFloat(sunNodeRotation)))
        rootNode.addChildNode(sunNode)
        
    }
    
    func setUpEarth()
    {
        //Set up earth material with 4 different images
        let earthMaterial = SCNMaterial()
        earthMaterial.ambient.contents = UIColor(white:  0.7, alpha: 1)
        earthMaterial.diffuse.contents = UIImage(named: "diffuse.jpg")
        
        earthMaterial.specular.contents = UIImage(named: "specular.jpg")
        
        earthMaterial.specular.intensity = 1
        
        earthMaterial.emission.contents = UIImage(named: "lights.jpg")
        earthMaterial.normal.contents = UIImage(named: "normal.jpg")
        
        earthMaterial.shininess = 0.05
        earthMaterial.multiply.contents = UIColor(white:  0.7, alpha: 1)
        
        //Earth is a sphere with radius 5
        let earthGeometry = SCNSphere(radius: 4)
        earthGeometry.firstMaterial = earthMaterial
        earthNode.geometry = earthGeometry
        
        rootNode.addChildNode(earthNode)
    }
    
    func setUpCloudsAndHalo()
    {
        //Set up clouds material radius slightly bigger than earth
        let clouds = SCNSphere(radius: 5.075)
        clouds.segmentCount = 120
        
        let cloudsMaterial = SCNMaterial()
        cloudsMaterial.diffuse.contents = UIColor.white
        cloudsMaterial.transparent.contents = UIImage(named: "clouds.jpg")
        cloudsMaterial.transparencyMode = SCNTransparencyMode.rgbZero
        cloudsMaterial.locksAmbientWithDiffuse = true
        cloudsMaterial.writesToDepthBuffer = false
        
        // Load GLSL code snippet for Halo effects
        do {
            if let path = Bundle.main.path(forResource: "halo", ofType: "glsl")
            {
                let shaderSource = try NSString(contentsOf: URL(fileURLWithPath: path), encoding: String.Encoding.utf8.rawValue)
                cloudsMaterial.shaderModifiers = [SCNShaderModifierEntryPoint.fragment : shaderSource as String]
            }
        } catch {
            //Catch errors
        }
        
        clouds.firstMaterial = cloudsMaterial;
        cloudNode.geometry = clouds
        cloudNode.opacity = 0.3
        
        //Set roation vector
        cloudNode.rotation = SCNVector4Make(0, 1, 0, 0);
        earthNode.addChildNode(cloudNode)
        
    }
    
    //function to revole any node to the left
    func revolve(node: SCNNode ,value: CGFloat, increase: CGFloat) -> CGFloat
    {
        var rotation = value
        
        if value < CGFloat(-Double.pi*2)
        {
            rotation = value + CGFloat(Double.pi*2)
            node.rotation = SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: Float(rotation))
        }
        
        return rotation - increase
    }
    //To animate all the nodes in the whole scene
    func animateEarthScene()
    {
        sunNodeRotation = revolve(node: sunNode, value: sunNodeRotation, increase: sunNodeRotationSpeed)
        
        earthNodeRotation = revolve(node: earthNode, value: earthNodeRotation, increase: earthNodeRotationSpeed)
        
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = (CAMediaTimingFunction(name:CAMediaTimingFunctionName.linear))
        
        SCNTransaction.animationDuration = 1
        SCNTransaction.completionBlock = {
            self.animateEarthScene()
        }
        sunNode.rotation = SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: Float(sunNodeRotation))
        earthNode.rotation = SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: Float(earthNodeRotation))
        SCNTransaction.commit()
    }
}

//SCNView for presenting the Scene

class EarthView: SCNView {
    let earthScene: EarthScene = EarthScene()
    let timeFormatter: DateFormatter = DateFormatter()
    let timerLabel = UILabel()
    let slider = UISlider()
    let trebleSlider = UISlider()
    let distortionSlider = UISlider()
    let volumeSlider = UISlider()
    let freqSlider = UISlider()
    let playButton = UIButton()
    let stopButton = UIButton()
    // 2: create the audio player
    
    
    override init(frame: CGRect, options: [String : Any]? = nil)
    {
        super.init(frame: frame, options: nil)
        //Allow user to adjust viewing angle
        allowsCameraControl = false
        backgroundColor = .black
        autoenablesDefaultLighting = true
        scene = earthScene
        earthScene.animateEarthScene()
        setUpTimerLabel()
        setupSlidersView()
        timeFormatter.dateFormat = "MMM d, yyyy \n h:mm a"
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (Timer) in
            self?.timerTick()
        }
    }
    
    func setupSlidersView() {
        slider.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        slider.minimumValue = 0.0
        slider.maximumValue = 100.0
        
        volumeSlider.frame = CGRect(x: 0, y: 60, width: 100, height: 40)
        volumeSlider.minimumValue = 0.0
        volumeSlider.maximumValue = 100.0
        
        distortionSlider.frame = CGRect(x: 150, y: 0, width: 100, height: 40)
        distortionSlider.minimumValue = 0.0
        distortionSlider.maximumValue = 100.0
        
        trebleSlider.frame = CGRect(x: 150, y: 60, width: 100, height: 40)
        trebleSlider.minimumValue = 0.0
        trebleSlider.maximumValue = 100.0
        
        freqSlider.frame = CGRect(x: 150, y: 120, width: 100, height: 40)
        freqSlider.minimumValue = 0.0
        freqSlider.maximumValue = 1000.0
        
        playButton.frame = CGRect(x: 300, y: 0, width: 100, height: 40)
        playButton.setTitle("Play", for: .normal)
//        playButton.minimumValue = 0.0
//        playButton.maximumValue = 100.0
        
        stopButton.frame = CGRect(x: 300, y: 60, width: 100, height: 40)
        stopButton.setTitle("Pause", for: .normal)
//        stopButton.minimumValue = 0.0
//        stopButton.maximumValue = 100.0
        
        slider.addTarget(self, action: #selector(sliderDidChange(_:)), for: .touchUpInside)
        volumeSlider.addTarget(self, action: #selector(setUpVolumeSlider(_:)), for: .touchUpInside)
        distortionSlider.addTarget(self, action: #selector(setUpDistortionSlider(_:)), for: .touchUpInside)
        trebleSlider.addTarget(self, action: #selector(setUpTrebleSlider(_:)), for: .touchUpInside)
        freqSlider.addTarget(self, action: #selector(setUpFreqSlider(_:)), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(setUpPlayButton(_:)), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(setUpStopButton(_:)), for: .touchUpInside)
        
        addSubview(slider)
        addSubview(volumeSlider)
        addSubview(distortionSlider)
        addSubview(trebleSlider)
        addSubview(freqSlider)
        addSubview(playButton)
        addSubview(stopButton)
    }
    
    @objc func sliderDidChange(_ sender: UISlider) {
        //print(sender.value)
        speedControl.rate = sender.value / 10
        //pitchControl.pitch = sender.value * 10
        earthNodeRotationSpeed = CGFloat(Double.pi/40) + CGFloat(sender.value)
    }
    
    @objc func setUpVolumeSlider(_ sender: UISlider) {
        //print(sender.value)
        audioPlayer.volume = sender.value / 10
    }
    
    @objc func setUpTrebleSlider(_ sender: UISlider) {
        //print(sender.value)
        audioPlayer.volume = sender.value / 10
    }
    
    @objc func setUpDistortionSlider(_ sender: UISlider) {
        //print(sender.value)
        // audioPlayer.volume = sender.value / 10
        // distort.wetDryMix = sender.value
        
    }
    
    @objc func setUpFreqSlider(_ sender: UISlider) {
        //print(sender.value)
        print(eq.bands[0].frequency)
        print(sender.value)
        eq.bands[0].frequency = sender.value
    }
    
    @objc func setUpPlayButton(_ sender: UIButton) {
        //print(sender.value)
        audioPlayer.play()
    }
    
    @objc func setUpStopButton(_ sender: UIButton) {
        //print(sender.value)
        audioPlayer.pause()
    }
    
    func setUpTimerLabel() {
        timerLabel.frame = CGRect(x: 230, y: frame.height - 100, width: 150, height: 80)
        timerLabel.textColor = .white
        timerLabel.font = .systemFont(ofSize: 18)
        timerLabel.backgroundColor = .clear
        //timerLabel.drawsBackground = false
        timerLabel.textAlignment = .right
        timerLabel.numberOfLines = 0

        addSubview(timerLabel)
    }
    
    func timerTick() {
        //Update display time
        timerLabel.text = timeFormatter.string(from: Date())
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// Creates music player
var player: AVAudioPlayer?
let audioPlayer = AVAudioPlayerNode()
let audioEngine = AVAudioEngine()
let engine = AVAudioEngine()
let speedControl = AVAudioUnitVarispeed()
let pitchControl = AVAudioUnitTimePitch()
let reverb = AVAudioUnitReverb()
let echo = AVAudioUnitDelay()
let mixer = AVAudioMixerNode()
let eq = AVAudioUnitEQ(numberOfBands: 1)
let distort = AVAudioUnitDistortion()


func play(_ url: URL) throws {
    // 1: load the file
    let earthView = EarthView(frame:CGRect(x: 0, y: 0, width: 600, height: 600))
    PlaygroundPage.current.liveView = earthView
    
    let file = try AVAudioFile(forReading: url)
    let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))!
    try file.read(into: buffer)

    // 3: connect the components to our playback engine
    engine.attach(audioPlayer)
    engine.attach(pitchControl)
    engine.attach(speedControl)
    engine.attach(reverb)
    engine.attach(echo)
    engine.attach(mixer)
    engine.attach(distort)
    
//    var filterParams = eq.bands[0] as AVAudioUnitEQFilterParameters
//    filterParams.filterType = .lowPass
//    filterParams.frequency = 20
//    filterParams.bypass = false
//
//    filterParams.gain = 200
    eq.bands[0].filterType = .lowPass
    eq.bands[0].frequency = 200
    eq.bands[0].bandwidth = 1.0
    eq.bands[0].gain = -96.0
    eq.bands[0].bypass = false
    // engine.attach(eq)

    // 4: arrange the parts so that output from one is input to another
    engine.connect(audioPlayer, to: speedControl, format: file.processingFormat)
    engine.connect(speedControl, to: pitchControl, format: nil)
    engine.connect(pitchControl, to: engine.mainMixerNode, format: nil)
    engine.connect(reverb, to: distort, format: nil)
    engine.connect(echo, to: reverb, format: nil)
    engine.connect(mixer, to: engine.mainMixerNode, format: nil)
    // engine.connect(audioPlayer, to: eq, format: file.processingFormat)
    // engine.connect(eq, to: engine.mainMixerNode, format: file.processingFormat)
    engine.connect(distort, to: engine.mainMixerNode, format: buffer.format)
    
    
    // 5: prepare the player to play its file from the beginning
    audioPlayer.scheduleFile(file, at: nil)
    audioPlayer.volume = 0.5
    echo.delayTime = 0.2
    reverb.loadFactoryPreset(.mediumHall)
    echo.feedback = 100
    echo.wetDryMix = 0
    reverb.wetDryMix = 50
    distort.wetDryMix = 25.0
    // distort.preGain = 6.0
    distort.loadFactoryPreset(.speechAlienChatter)

    // 6: start the engine and player
    audioPlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
    engine.prepare()
    try engine.start()
    
    audioPlayer.play()
}

if let url = Bundle.main.url(forResource: "YACHT", withExtension: "mp3") {
    try play(url)
}



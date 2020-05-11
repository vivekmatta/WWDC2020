//Texture images are from: http://www.shadedrelief.com/natural3/pages/textures.html


import Cocoa
import SceneKit
import CoreLocation
import GLKit
import PlaygroundSupport
import AVFoundation
import AVKit



class EarthScene: SCNScene  {
    
    let observerNode: SCNNode = SCNNode()
    let sunNode: SCNNode = SCNNode()
    let earthNode: SCNNode = SCNNode()
    let cloudNode: SCNNode = SCNNode()
    let sunNodeRotationSpeed: CGFloat  = CGFloat(Double.pi/6)
    let earthNodeRotationSpeed: CGFloat = CGFloat(Double.pi/40)
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
        observerLight.color = NSColor(white: 0.01, alpha: 1.0)
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
        sunNode.rotation = SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: CGFloat(sunNodeRotation))
        rootNode.addChildNode(sunNode)
        
    }
    
    func setUpEarth()
    {
        //Set up earth material with 4 different images
        let earthMaterial = SCNMaterial()
        earthMaterial.ambient.contents = NSColor(white:  0.7, alpha: 1)
        earthMaterial.diffuse.contents = NSImage(named: "diffuse")
        
        earthMaterial.specular.contents = NSImage(named: "specular")
        
        earthMaterial.specular.intensity = 1
        
        earthMaterial.emission.contents = NSImage(named: "lights")
        earthMaterial.normal.contents = NSImage(named: "normal")
        
        earthMaterial.shininess = 0.05
        earthMaterial.multiply.contents = NSColor(white:  0.7, alpha: 1)
        
        //Earth is a sphere with radius 5
        let earthGeometry = SCNSphere(radius: 5)
        earthGeometry.firstMaterial = earthMaterial
        earthNode.geometry = earthGeometry
        
        rootNode.addChildNode(earthNode)
    }
    
    func setUpCloudsAndHalo()
    {
        //Set up clouds material radius slightly bigger than earth
        let clouds = SCNSphere(radius: 5.075)
        clouds.segmentCount = 120;
        
        let cloudsMaterial = SCNMaterial()
        cloudsMaterial.diffuse.contents = NSColor.white
        cloudsMaterial.transparent.contents = NSImage(named: "clouds")
        cloudsMaterial.transparencyMode = SCNTransparencyMode.rgbZero;
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
            node.rotation = SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: rotation)
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
        sunNode.rotation = SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: sunNodeRotation)
        earthNode.rotation = SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: earthNodeRotation)
        SCNTransaction.commit()
    }
}

//SCNView for presenting the Scene

class EarthView: SCNView {
    let earthScene: EarthScene = EarthScene()
    let timeFormatter: DateFormatter = DateFormatter()
    let timerLabel: NSTextField = NSTextField()
    let slider = NSSlider()
    
    override init(frame: NSRect, options: [String : Any]? = nil)
    {
        super.init(frame: frame, options: nil)
        //Allow user to adjust viewing angle
        allowsCameraControl = true
        backgroundColor = NSColor.black
        autoenablesDefaultLighting = true
        scene = earthScene
        earthScene.animateEarthScene()
        setUpTimerLabel()
        setupSliderView()
        timeFormatter.dateFormat = "MMM d, yyyy \n h:mm a"
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (Timer) in
            self?.timerTick()
        }
    }
    
    func setupSliderView() {
        slider.frame = CGRect(x: 0, y: frame.height - 500, width: 100, height: 40)
        slider.minValue = 0.0
        slider.maxValue = 100.0
        addSubview(slider)
    }
    
    func setUpTimerLabel() {
        timerLabel.frame = CGRect(x: 230, y:frame.height - 100, width: 150, height:80)
        timerLabel.textColor = NSColor.white
        timerLabel.font = NSFont .systemFont(ofSize: 18)
        timerLabel.backgroundColor = NSColor.clear
        timerLabel.drawsBackground = false
        timerLabel.alignment = .right
        timerLabel.isBezeled = false
        timerLabel.isEditable = false
        addSubview(timerLabel)
    }
    
    func timerTick() {
        //Update display time
        timerLabel.stringValue = timeFormatter.string(from: Date())
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// Creates music player
var player: AVAudioPlayer?

let audioEngine = AVAudioEngine()

func playSound() {
    guard let url = Bundle.main.url(forResource: "night", withExtension: "mp3") else {
        return
    }
    
    do {
//        player = try AVAudioPlayer(contentsOf: url)
//        guard let player = player else {
//            return
//        }
        
        let audioPlayerNode = AVAudioPlayerNode()
//        audioEngine.attach(audioPlayerNode)
//        audioEngine.attach(reverb)
//        audioEngine.attach(echo)
//        audioEngine.attach(audioMixer)
//        audioEngine.attach(micMixer)
        
        let file = try AVAudioFile(forReading: url)
        audioPlayerNode.scheduleFile(file, at: nil, completionHandler: nil)
//        try engine.start()
        audioPlayerNode.play()

//        player.setVolume(0.2, fadeDuration: 4)
//        player.prepareToPlay()
//        player.play()
    } catch let error as NSError {
        print(error.description)
    }
}

let engine = AVAudioEngine()
let speedControl = AVAudioUnitVarispeed()
let pitchControl = AVAudioUnitTimePitch()
let reverb = AVAudioUnitReverb()
let echo = AVAudioUnitDelay()
let mixer = AVAudioMixerNode()

func play(_ url: URL) throws {
    // 1: load the file
    let earthView = EarthView(frame:CGRect(x: 0, y: 0, width: 600, height: 600))
    PlaygroundPage.current.liveView = earthView
    
    let file = try AVAudioFile(forReading: url)

    // 2: create the audio player
    let audioPlayer = AVAudioPlayerNode()

    // 3: connect the components to our playback engine
    engine.attach(audioPlayer)
    engine.attach(pitchControl)
    engine.attach(speedControl)
    engine.attach(reverb)
    engine.attach(echo)
    engine.attach(mixer)

    // 4: arrange the parts so that output from one is input to another
    engine.connect(audioPlayer, to: speedControl, format: nil)
    engine.connect(speedControl, to: pitchControl, format: nil)
    engine.connect(pitchControl, to: engine.mainMixerNode, format: nil)
    engine.connect(reverb, to: engine.mainMixerNode, format: nil)
    engine.connect(echo, to: engine.mainMixerNode, format: nil)
    engine.connect(mixer, to: engine.mainMixerNode, format: nil)
    
    
    // 5: prepare the player to play its file from the beginning
    audioPlayer.scheduleFile(file, at: nil)
    audioPlayer.volume = 0.5
    // reverb.wetDryMix = 100
    speedControl.rate += 0.3
    pitchControl.pitch += 1000
    echo.delayTime = 0.2
    reverb.loadFactoryPreset(.mediumHall)
    echo.feedback = 100
    echo.wetDryMix = 0
    reverb.wetDryMix = 50

    // 6: start the engine and player
    try engine.start()
    audioPlayer.play()
}

if let url = Bundle.main.url(forResource: "YACHT", withExtension: "mp3") {
    try play(url)
}



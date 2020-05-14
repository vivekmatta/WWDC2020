import SceneKit
import CoreLocation
import GLKit
import PlaygroundSupport
import AVFoundation
import AVKit
import UIKit

var earthNodeRotationSpeed: CGFloat = CGFloat(Double.pi/40)
var earthNode: SCNNode = SCNNode()
var earthGeometry = SCNSphere(radius: 4.5)

class EarthScene: SCNScene  {
    let observerNode: SCNNode = SCNNode()
    let sunNode: SCNNode = SCNNode()
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
        observerNode.position = SCNVector3(x: 0, y: -2, z: 17)
        
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
        sunNode.rotation = SCNVector4(x: 0.0, y: 1, z: 0.0, w: Float(CGFloat(sunNodeRotation)))
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
        earthGeometry.firstMaterial = earthMaterial
        earthNode.geometry = earthGeometry
        
        rootNode.addChildNode(earthNode)
    }
    
    func setUpCloudsAndHalo()
    {
        //Set up clouds material radius slightly bigger than earth
        let clouds = SCNSphere(radius: 5.75)
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
    let songSpeedSlider = UISlider()
    let volumeSlider = UISlider()
    let freqSlider = UISlider()
    let playButton = UIButton()
    let stopButton = UIButton()
    
    let earthSpeedLabel = UILabel()
    let volumeLabel = UILabel()
    let freqLabel = UILabel()
    let songSpeedLabel = UILabel()
    
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
        // setUpTimerLabel()
        setupSlidersView()
        setUpLabels()
        timeFormatter.dateFormat = "MMM d, yyyy \n h:mm a"
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (Timer) in
            self?.timerTick()
        }
        // playEarth()
        startEarthBeat()
        
    }
    
    func setUpLabels() {
        earthSpeedLabel.frame = CGRect(x: 10, y: frame.height - 85, width: 100, height: 30)
        earthSpeedLabel.text = "Earth Speed:"
        earthSpeedLabel.textColor = .lightGray
        earthSpeedLabel.textAlignment = .center
        
        songSpeedLabel.frame = CGRect(x: 10, y: frame.height - 155, width: 100, height: 30)
        songSpeedLabel.text = "Song Speed:"
        songSpeedLabel.textColor = .lightGray
        songSpeedLabel.textAlignment = .center
        
        volumeLabel.frame = CGRect(x: 160, y: frame.height - 155, width: 100, height: 30)
        volumeLabel.text = "Volume:"
        volumeLabel.textColor = .lightGray
        volumeLabel.textAlignment = .center
        
        freqLabel.frame = CGRect(x: 310, y: frame.height - 85, width: 100, height: 30)
        freqLabel.text = "Frequency:"
        freqLabel.textColor = .lightGray
        freqLabel.textAlignment = .center
        
        addSubview(earthSpeedLabel)
        addSubview(volumeLabel)
        addSubview(freqLabel)
        addSubview(songSpeedLabel)
    }
    
    func setupSlidersView() {
        slider.frame = CGRect(x: 10, y: frame.height - 50, width: 100, height: 20)
        slider.minimumValue = 0.0
        slider.maximumValue = 100.0
        
        songSpeedSlider.frame = CGRect(x: 10, y: frame.height - 120, width: 100, height: 20)
        songSpeedSlider.minimumValue = 0.0
        songSpeedSlider.maximumValue = 100.0
        
        volumeSlider.frame = CGRect(x: 160, y: frame.height - 50, width: 100, height: 20)
        volumeSlider.minimumValue = 0.0
        volumeSlider.maximumValue = 100.0
        
        trebleSlider.frame = CGRect(x: 160, y: frame.height - 120, width: 100, height: 20)
        trebleSlider.minimumValue = 0.0
        trebleSlider.maximumValue = 100.0
        
        freqSlider.frame = CGRect(x: 310, y: frame.height - 50, width: 100, height: 20)
        freqSlider.minimumValue = 0.0
        freqSlider.maximumValue = 1000.0
        
        playButton.frame = CGRect(x: 460, y: frame.height - 120, width: 100, height: 20)
        playButton.setTitle("Play", for: .normal)
        //        playButton.minimumValue = 0.0
        //        playButton.maximumValue = 100.0
        
        stopButton.frame = CGRect(x: 460, y: frame.height - 50, width: 100, height: 20)
        stopButton.setTitle("Pause", for: .normal)
        //        stopButton.minimumValue = 0.0
        //        stopButton.maximumValue = 100.0
        
        slider.addTarget(self, action: #selector(sliderDidChange(_:)), for: .touchUpInside)
        volumeSlider.addTarget(self, action: #selector(setUpVolumeSlider(_:)), for: .touchUpInside)
        songSpeedSlider.addTarget(self, action: #selector(setUpSongSpeedSlider(_:)), for: .touchUpInside)
        trebleSlider.addTarget(self, action: #selector(setUpTrebleSlider(_:)), for: .touchUpInside)
        freqSlider.addTarget(self, action: #selector(setUpFreqSlider(_:)), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(setUpPlayButton(_:)), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(setUpStopButton(_:)), for: .touchUpInside)
        
        addSubview(slider)
        addSubview(volumeSlider)
        addSubview(songSpeedSlider)
        addSubview(trebleSlider)
        addSubview(freqSlider)
        addSubview(playButton)
        addSubview(stopButton)
    }
    
    @objc func sliderDidChange(_ sender: UISlider) {
        //print(sender.value)
        earthNodeRotationSpeed = CGFloat(Double.pi/40) + CGFloat(sender.value)
    }
    
    @objc func setUpVolumeSlider(_ sender: UISlider) {
        //print(sender.value)
        player?.volume = sender.value / 10
    }
    
    @objc func setUpTrebleSlider(_ sender: UISlider) {
        //print(sender.value)
        player?.volume = sender.value / 10
    }
    
    @objc func setUpSongSpeedSlider(_ sender: UISlider) {
        // print(sender.value)
        player?.rate = sender.value / 10
    }
    
    @objc func setUpFreqSlider(_ sender: UISlider) {
        //print(sender.value)
    }
    
    @objc func setUpPlayButton(_ sender: UIButton) {
        //print(sender.value)
        player?.play()
    }
    
    @objc func setUpStopButton(_ sender: UIButton) {
        //print(sender.value)
        player?.pause()
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
    
    func averagePowerFromAllChannels() -> CGFloat {
        var power : CGFloat = 0
        guard let numChannels = player?.numberOfChannels else {
            return 1.0
        }
        
        (0..<numChannels).forEach { (index) in
            power = power + CGFloat(player?.averagePower(forChannel: index) ?? 0.0)
        }
        return power / CGFloat(numChannels)
    }

    @objc func updateMeters() {
        player?.updateMeters()
        let power = averagePowerFromAllChannels()
        UIView.animate(withDuration: animationDuration, animations: {
            self.animate(to: power)
        })
    }

    func startEarthBeat() {
        Timer.scheduledTimer(timeInterval: updateInterval, target: self, selector: #selector(updateMeters), userInfo: nil, repeats: true)
    }

    func animate(to power : CGFloat) {
        let powerDelta = (maxPowerDelta + power) * 2 / 50
        let compute : CGFloat = minScale + powerDelta
        let scale : CGFloat = CGFloat.maximum(compute, minScale)
//        let earthMaterial = SCNMaterial()
//        earthMaterial.ambient.contents = UIColor(white:  0.7, alpha: 0)
//        earthMaterial.diffuse.contents = UIImage(named: "diffuse.jpg")
//
//        earthMaterial.specular.contents = UIImage(named: "specular.jpg")
//
//        earthMaterial.specular.intensity = 1
//
//        earthMaterial.emission.contents = UIImage(named: "lights.jpg")
//        earthMaterial.normal.contents = UIImage(named: "normal.jpg")
//
//        earthMaterial.shininess = 0.05
//        earthMaterial.multiply.contents = UIColor(white:  0.7, alpha: 1)
//
//        //Earth is a sphere with radius 5
//        earthNode.geometry = SCNSphere(radius: scale + 4)
        var radius = earthNode.geometry as! SCNSphere
        radius.radius = scale + 3
        // earthNode.geometry?.firstMaterial = earthMaterial
    }
    
}

// Creates music player
var player: AVAudioPlayer?

func playEarth() {
    // 1: load the file
    let earthView = EarthView(frame:CGRect(x: 0, y: 0, width: 600, height: 600))
    PlaygroundPage.current.liveView = earthView
        
    if let url = Bundle.main.url(forResource: "YACHT", withExtension: "mp3") {
        do {
            player = try AVAudioPlayer(contentsOf: url)
        }
        catch {
            print(error)
        }
    }
    
    player?.numberOfLoops = -1
    player?.enableRate = true
    player?.isMeteringEnabled = true
    player?.play()
}

let updateInterval = 0.05
let animationDuration = 0.05
let maxPowerDelta : CGFloat = 30
let minScale : CGFloat = 0.9

// play()
playEarth()



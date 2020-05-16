import SceneKit
import CoreLocation
import GLKit
import PlaygroundSupport
import AVFoundation
import AVKit
import UIKit

// Global variables 
var earthNodeRotationSpeed: CGFloat = CGFloat(Double.pi/40)
var earthNode: SCNNode = SCNNode()
var earthGeometry = SCNSphere(radius: 4.5)
var cloudNode: SCNNode = SCNNode()
var observerNode: SCNNode = SCNNode()
let sunNode: SCNNode = SCNNode()
let sunNodeRotationSpeed: CGFloat  = CGFloat(Double.pi/6)
var earthNodeRotation: CGFloat = 0
var sunNodeRotation: CGFloat = CGFloat(Double.pi/2)

var player: AVAudioPlayer?
let updateInterval = 0.05
let animationDuration = 0.05
let maxPowerDelta : CGFloat = 30
let minScale : CGFloat = 0.9

class EarthScene: SCNScene  {
    override init() {
        super.init()
        setUpObserver()
        setUpSun()
        setUpEarth()
        setUpCloudsAndHalo()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Setting up the initial position of the camera
    func setUpObserver() {
        observerNode.camera = SCNCamera()
        observerNode.position = SCNVector3(x: 0, y: -2, z: 17)
        
        let observerLight = SCNLight()
        observerLight.type = SCNLight.LightType.ambient
        observerLight.color = UIColor(white: 0.01, alpha: 1.0)
        observerNode.light = observerLight
        
        rootNode.addChildNode(observerNode)
    }
    
    // Sets up sun node
    func setUpSun() {
        let sunNodeLight = SCNLight()
        sunNodeLight.type = SCNLight.LightType.directional
        sunNode.light = sunNodeLight
        
        sunNode.rotation = SCNVector4(x: 0.0, y: 1, z: 0.0, w: Float(CGFloat(sunNodeRotation)))
        rootNode.addChildNode(sunNode)
        
    }
    
    // Set up earth material with 4 images
    func setUpEarth() {
        let earthMaterial = SCNMaterial()
        earthMaterial.ambient.contents = UIColor(white:  0.7, alpha: 1)
        earthMaterial.diffuse.contents = UIImage(named: "diffuse.jpg")
        earthMaterial.specular.contents = UIImage(named: "specular.jpg")
        earthMaterial.emission.contents = UIImage(named: "lights.jpg")
        earthMaterial.normal.contents = UIImage(named: "normal.jpg")
        earthMaterial.specular.intensity = 1
        earthMaterial.shininess = 0.05
        earthMaterial.multiply.contents = UIColor(white:  0.7, alpha: 1)
        
        earthGeometry.firstMaterial = earthMaterial
        earthNode.geometry = earthGeometry
        
        rootNode.addChildNode(earthNode)
    }
    
    // Sets up clouds around the earth
    func setUpCloudsAndHalo() {
        let clouds = SCNSphere(radius: 5.75)
        clouds.segmentCount = 120
        
        let cloudsMaterial = SCNMaterial()
        cloudsMaterial.diffuse.contents = UIColor.white
        cloudsMaterial.transparent.contents = UIImage(named: "clouds.jpg")
        cloudsMaterial.transparencyMode = SCNTransparencyMode.rgbZero
        cloudsMaterial.locksAmbientWithDiffuse = true
        cloudsMaterial.writesToDepthBuffer = false
        
        do {
            if let path = Bundle.main.path(forResource: "halo", ofType: "glsl") {
                let shaderSource = try NSString(contentsOf: URL(fileURLWithPath: path), encoding: String.Encoding.utf8.rawValue)
                cloudsMaterial.shaderModifiers = [SCNShaderModifierEntryPoint.fragment : shaderSource as String]
            }
        } catch {
            print(error)
        }
        
        clouds.firstMaterial = cloudsMaterial
        cloudNode.geometry = clouds
        cloudNode.opacity = 0.3
        
        cloudNode.rotation = SCNVector4Make(0, 1, 0, 0);
        earthNode.addChildNode(cloudNode)
        
    }

    func revolve(node: SCNNode, value: CGFloat, increase: CGFloat) -> CGFloat {
        var rotation = value

        if value < CGFloat(-Double.pi * 2) {
            rotation = value + CGFloat(Double.pi * 2)
            node.rotation = SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: Float(rotation))
        }
        
        return rotation - increase
    }

    // Starts animation of earth and sun revolving
    func animateEarthScene() {
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

class EarthView: SCNView {
    let earthScene: EarthScene = EarthScene()
    let timerLabel = UILabel()
    let earthSpeedSlider = UISlider()
    let songSpeedSlider = UISlider()
    let volumeSlider = UISlider()
    let xAxisSlider = UISlider()
    let yAxisSlider = UISlider()
    let playButton = UIButton()
    let stopButton = UIButton()
    let earthSpeedLabel = UILabel()
    let volumeLabel = UILabel()
    let xAxisLabel = UILabel()
    let yAxisLabel = UILabel()
    let songSpeedLabel = UILabel()
    
    override init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: nil)
        allowsCameraControl = false
        backgroundColor = .black
        autoenablesDefaultLighting = true
        scene = earthScene
        setUpBackground()
        earthScene.animateEarthScene()
        setupSlidersView()
        setUpLabels()
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
        
        xAxisLabel.frame = CGRect(x: 160, y: frame.height - 85, width: 100, height: 30)
        xAxisLabel.text = "X Axis:"
        xAxisLabel.textColor = .lightGray
        xAxisLabel.textAlignment = .center
        
        yAxisLabel.frame = CGRect(x: 310, y: frame.height - 85, width: 100, height: 30)
        yAxisLabel.text = "Y Axis:"
        yAxisLabel.textColor = .lightGray
        yAxisLabel.textAlignment = .center
        
        addSubview(earthSpeedLabel)
        addSubview(volumeLabel)
        addSubview(xAxisLabel)
        addSubview(yAxisLabel)
        addSubview(songSpeedLabel)
    }
    
    func setupSlidersView() {
        earthSpeedSlider.frame = CGRect(x: 10, y: frame.height - 50, width: 100, height: 20)
        earthSpeedSlider.minimumValue = 0.0
        earthSpeedSlider.maximumValue = 100.0
        
        songSpeedSlider.frame = CGRect(x: 10, y: frame.height - 120, width: 100, height: 20)
        songSpeedSlider.minimumValue = 0.0
        songSpeedSlider.maximumValue = 100.0
        songSpeedSlider.value = 10.0
        
        volumeSlider.frame = CGRect(x: 160, y: frame.height - 120, width: 100, height: 20)
        volumeSlider.minimumValue = 0.0
        volumeSlider.maximumValue = 100.0
        
        xAxisSlider.frame = CGRect(x: 160, y: frame.height - 50, width: 100, height: 20)
        xAxisSlider.minimumValue = -5.0
        xAxisSlider.maximumValue = 5.0
        xAxisSlider.value = 0
        
        yAxisSlider.frame = CGRect(x: 310, y: frame.height - 50, width: 100, height: 20)
        yAxisSlider.minimumValue = -5.0
        yAxisSlider.maximumValue = 5.0
        yAxisSlider.value = -2
        
        playButton.frame = CGRect(x: 460, y: frame.height - 120, width: 100, height: 20)
        playButton.setTitle("Play", for: .normal)
        
        stopButton.frame = CGRect(x: 460, y: frame.height - 50, width: 100, height: 20)
        stopButton.setTitle("Pause", for: .normal)
        
        earthSpeedSlider.addTarget(self, action: #selector(sliderDidChange(_:)), for: .touchUpInside)
        volumeSlider.addTarget(self, action: #selector(setUpVolumeSlider(_:)), for: .touchUpInside)
        songSpeedSlider.addTarget(self, action: #selector(setUpSongSpeedSlider(_:)), for: .touchUpInside)
        yAxisSlider.addTarget(self, action: #selector(setUpYAxisSlider(_:)), for: .touchUpInside)
        xAxisSlider.addTarget(self, action: #selector(setUpXAxisSlider(_:)), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(setUpPlayButton(_:)), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(setUpStopButton(_:)), for: .touchUpInside)
        
        addSubview(earthSpeedSlider)
        addSubview(volumeSlider)
        addSubview(songSpeedSlider)
        addSubview(xAxisSlider)
        addSubview(yAxisSlider)
        addSubview(playButton)
        addSubview(stopButton)
    }
    
    // Add particle emitter in background
    func setUpBackground() {
        let particlesNode = SCNNode()
        let particleSystem = SCNParticleSystem(named: "Welcome.scnp", inDirectory: "")
        guard let particles = particleSystem else {
            return
        }
        particles.loops = true
        particlesNode.addParticleSystem(particles)
        earthScene.rootNode.addChildNode(particlesNode)
        backgroundColor = .black
        particlesNode.position = SCNVector3(0, 0, 0)
    }
    
    @objc func sliderDidChange(_ sender: UISlider) {
        earthNodeRotationSpeed = CGFloat(Double.pi/40) + CGFloat(sender.value)
    }
    
    @objc func setUpVolumeSlider(_ sender: UISlider) {
        player?.volume = sender.value / 10
    }
    
    @objc func setUpSongSpeedSlider(_ sender: UISlider) {
        player?.rate = sender.value / 10
    }
    
    @objc func setUpXAxisSlider(_ sender: UISlider) {
        observerNode.position = SCNVector3(x: sender.value, y: observerNode.position.y, z: 17)
    }
    
    @objc func setUpYAxisSlider(_ sender: UISlider) {
        observerNode.position = SCNVector3(x: observerNode.position.x, y: sender.value, z: 17)
    }
    
    @objc func setUpPlayButton(_ sender: UIButton) {
        player?.play()
    }
    
    @objc func setUpStopButton(_ sender: UIButton) {
        player?.pause()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Calculate the average power from the audio player
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

    // Animate the earth based on calculated average power
    @objc func updateMeters() {
        player?.updateMeters()
        let power = averagePowerFromAllChannels()
        UIView.animate(withDuration: animationDuration, animations: {
            self.animate(to: power)
        })
    }

    // Creates a timer to automatically update meters in a given interval
    func startEarthBeat() {
        Timer.scheduledTimer(timeInterval: updateInterval, target: self, selector: #selector(updateMeters), userInfo: nil, repeats: true)
    }

    // Animates earth to a specific radius and size
    func animate(to power : CGFloat) {
        let powerDelta = (maxPowerDelta + power) * 2 / 50
        let compute : CGFloat = minScale + powerDelta
        let scale : CGFloat = CGFloat.maximum(compute, minScale)
        guard let radius = earthNode.geometry as? SCNSphere else {
            return
        }
        radius.radius = scale + 3
    }
}

// This initializes the Playground view
func playEarth() {
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

playEarth()



//
//  GameViewController.swift
//  myScene
//
//  Created by Masanobu Sugawara on 2017/09/18.
//  Copyright © 2017年 Masanobu Sugawara. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    
    var scnView: SCNView!
    var scnScene: SCNScene!
    
    var cameraNode: SCNNode!
    
    var spawnTime: TimeInterval = 0
    
    var game = GameHelper.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupScene()
        setupCamera()
        setupHUD()
    }
    
    private func setupView() {
        scnView = self.view as! SCNView
        
        scnView.delegate = self
        
        scnView.showsStatistics = true
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true
    }
    
    private func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.png"
    }
    
    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    private func setupHUD() {
        game.hudNode.position = SCNVector3(x: 0, y: 10.0, z: 0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }
    
    // MARK: -
    fileprivate func spawnShape() {
        var geometry: SCNGeometry
        switch ShapeType.random() {
        case .box:
            geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        case .sphere:
            geometry = SCNSphere(radius: 0.5)
        case .pyramid:
            geometry = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
        case .torus:
            geometry = SCNTorus(ringRadius: 0.5, pipeRadius: 0.25)
        case .capsule:
            geometry = SCNCapsule(capRadius: 0.3, height: 2.5)
        case .cylinder:
            geometry = SCNCylinder(radius: 0.3, height: 2.5)
        case .cone:
            geometry = SCNCone(topRadius: 0.25, bottomRadius: 0.5, height: 1.0)
        case .tube:
            geometry = SCNTube(innerRadius: 0.25, outerRadius: 0.5, height: 1.0)
        }
        
        let geometryNode = SCNNode(geometry: geometry)
        // Physics
        geometryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        // Forces
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        let force = SCNVector3(x: randomX, y: randomY, z: 0)
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        geometryNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
        // Color
        let color = UIColor.random()
        geometry.materials.first?.diffuse.contents = color
        // Particle
        let trailEmitter = createTrail(color: color, geometry: geometry)
        geometryNode.addParticleSystem(trailEmitter)
        
        if color == .black {
            geometryNode.name = "BAD"
        } else {
            geometryNode.name = "GOOD"
        }
        
        scnScene.rootNode.addChildNode(geometryNode)
    }
    
    fileprivate func cleanScene() {
        for node in scnScene.rootNode.childNodes {
            if node.presentation.position.y < -2 {
                node.removeFromParentNode()
            }
        }
    }
    
    // MARK: - Particles
    fileprivate func createTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem {
        let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        trail.particleColor = color
        trail.emitterShape = geometry
        return trail
    }
    
    fileprivate func createExplosion(geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
        let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)!
        explosion.emitterShape = geometry
        explosion.birthLocation = .surface
        
        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        
        scnScene.addParticleSystem(explosion, transform: transformMatrix)
    }
    
    
    // MARK: - Actions
    func handleTouchFor(node: SCNNode) {
        createExplosion(geometry: node.geometry!, position: node.presentation.position, rotation: node.presentation.rotation)
        if node.name == "GOOD" {
            game.score += 1
            node.removeFromParentNode()
        } else if node.name == "BAD" {
            game.lives -= 1
            node.removeFromParentNode()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: scnView)
        let hitResults = scnView.hitTest(location, options: nil)
        if let result = hitResults.first {
            handleTouchFor(node: result.node)
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if time > spawnTime {
            cleanScene()
            spawnShape()
            
            spawnTime = time + TimeInterval(Float.random(min: 0.2, max: 1.5))
        }
        
        game.updateHUD()
    }
}

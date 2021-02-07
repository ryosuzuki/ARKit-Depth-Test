//
//  ViewController.swift
//  Depth-Test
//
//  Created by Ryo Suzuki on 2/6/21.
//

import RealityKit
import ARKit

let url = "http://10.0.0.68:3000"

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    
    let coachingOverlay = ARCoachingOverlayView()
    
    var modelsForClassification: [ARMeshClassification: ModelEntity] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("AR start")
        arView.session.delegate = self
        
        arView.environment.sceneUnderstanding.options = []
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        arView.environment.sceneUnderstanding.options.insert(.physics)

        arView.debugOptions.insert(.showSceneUnderstanding)
        
        arView.renderOptions = [.disablePersonOcclusion, .disableDepthOfField, .disableMotionBlur]
        
        arView.automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .meshWithClassification

        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)
                
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        print("test")
        let session = arView.session
        let frame = session.currentFrame
        let position = frame?.camera
    }
    
    struct Vector: Codable {
        var x:Float
        var y:Float
        var z:Float
    }

    struct Mesh: Codable {
        var id:String
        var vertices:[Vector]
    }
    
    struct Anchors: Codable {
        var meshes: [Mesh]
    }
        
    func syncMesh(_ meshAnchors: [ARMeshAnchor]) {
        var meshes:[Mesh] = []
        for anchor in meshAnchors {
            let id = anchor.identifier.uuidString
            var mesh = Mesh(id: id, vertices: [])
            for index in 0..<anchor.geometry.faces.count {
                let vertices = anchor.geometry.verticesOf(faceWithIndex: index)
                for vertex in vertices {
                    let v = Vector(x: vertex.0, y: vertex.1, z: vertex.2)
                    mesh.vertices.append(v)
                }
            }
            meshes.append(mesh)
        }
        let test = Anchors(meshes: meshes)
        
        print("send")
        let requestURL = URL(string: url)!
        let session = URLSession.shared
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        do {
            request.httpBody = try JSONEncoder().encode(test)
        } catch {
            print("error")
        }
        let task = session.dataTask(with: request)
        task.resume()
    }

    var count = 0
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let position = frame.camera
        let meshAnchors = frame.anchors.compactMap{ $0 as? ARMeshAnchor }
        count += 1
        if (count > 100) {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.0) {
                self.syncMesh(meshAnchors)
            }
            count = 0
        }
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
      
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("hello")
        guard error is ARError else { return }
    }

}

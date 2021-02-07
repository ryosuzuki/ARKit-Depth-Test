//
//  ViewController.swift
//  Depth-Test
//
//  Created by Ryo Suzuki on 2/6/21.
//

import RealityKit
import ARKit
import SocketIO

let url = "http://10.0.0.68:3000"
let manager = SocketManager(socketURL: URL(string: url)!, config: [.log(false), .compress])
let socket = manager.defaultSocket

var savedMeshes = Set<UUID>()
var updatedMeshes = Dictionary<UUID, Int>()

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    
    let coachingOverlay = ARCoachingOverlayView()
    
    var modelsForClassification: [ARMeshClassification: ModelEntity] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Connect socket.io")
        socket.connect()
        
        socket.on("connect") { data, ack in
            print("socket connected")
        }

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

    struct Test2: Codable {
        var id:String
        var vertices:[Vector]
    }
    
    struct Test3: Codable {
        var meshes: [Test2]
    }
        
    func syncMesh(_ meshAnchors: [ARMeshAnchor]) {
        var meshes:[Test2] = []
        for anchor in meshAnchors {
            let id = anchor.identifier.uuidString
            var test2 = Test2(id: id, vertices: [])
            for index in 0..<anchor.geometry.faces.count {
                let vertices = anchor.geometry.verticesOf(faceWithIndex: index)
                for vertex in vertices {
                    let v = Vector(x: vertex.0, y: vertex.1, z: vertex.2)
                    test2.vertices.append(v)
                }
            }
            meshes.append(test2)
        }
        let test = Test3(meshes: meshes)
        
        print("send")
        let url = URL(string: "https://8e408a9ce710.ngrok.io")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
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
        
//        do {
//            print("send")
//            let json = try JSONEncoder().encode(test)
//            socket.emit("test", json)
//        }
//        catch {
//            print("error")
//        }


    }

    var count = 0
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let position = frame.camera
//        print(position)
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

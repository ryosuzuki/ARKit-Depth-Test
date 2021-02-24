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
        
        guard let pointOfView = renderer.pointOfView else { return }
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = SCNVector3(orientation.x + location.x, orientation.y + location.y, orientation.z + location.z)
        print(currentPositionOfCamera)
        print(frame?.camera.transform.position)
        
    }
    
    var count = 0
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let meshAnchors = frame.anchors.compactMap{ $0 as? ARMeshAnchor }
        self.syncCamera(frame.camera)
        count += 1
        if (count > 100) {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.0) {
                self.syncMesh(meshAnchors)
            }
            count = 0
        }
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
    
    struct Camera: Codable {
        var position: Vector
        var rotation: Vector
    }
    
    struct  Json: Codable {
        var anchors: Anchors
        var camera: Camera
    }
    
    func syncCamera(_ arCamera: ARCamera) {
        let cp = arCamera.transform.position
        let cr = arCamera.eulerAngles
        let position = Vector(x: cp.x, y: cp.y, z: cp.z)
        let rotation = Vector(x: cr.x, y: cr.y, z: cr.z)
        let camera = Camera(position: position, rotation: rotation)
        do {
            let json = try JSONEncoder().encode(camera)
            sendJson(json)
//            print("success")
        } catch {
            print("error")
        }
    }
    
    func syncMesh(_ meshAnchors: [ARMeshAnchor]) {
        var meshes:[Mesh] = []
        for anchor in meshAnchors {
            let id = anchor.identifier.uuidString
            var mesh = Mesh(id: id, vertices: [])
            
            for index in 0..<anchor.geometry.faces.count {
                let geometricCenterOfFace = anchor.geometry.centerOf(faceWithIndex: index)
                var centerLocalTransform = matrix_identity_float4x4
                centerLocalTransform.columns.3 = SIMD4<Float>(geometricCenterOfFace.0, geometricCenterOfFace.1, geometricCenterOfFace.2, 1)
                let centerWorldPosition = (anchor.transform * centerLocalTransform).position
                
                let vertices = anchor.geometry.verticesOf(faceWithIndex: index)
                for vertex in vertices {
                    let v = Vector(
                        x: vertex.0 + centerWorldPosition.x,
                        y: vertex.1 + centerWorldPosition.y,
                        z: vertex.2 + centerWorldPosition.z
                    )
                    mesh.vertices.append(v)
                }
            }
            meshes.append(mesh)
        }
        let anchors = Anchors(meshes: meshes)
        do {
            let json = try JSONEncoder().encode(anchors)
            sendJson(json)
//            print("success")
        } catch {
            print("error")
        }
    }
    
    func sendJson(_ json: Data) {
        let requestURL = URL(string: url)!
        let session = URLSession.shared
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
//        print("send")
        request.httpBody = json
//        print(request.httpBody)
        let task = session.dataTask(with: request)
//        print("done")
        task.resume()
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

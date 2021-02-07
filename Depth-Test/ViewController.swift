//
//  ViewController.swift
//  Depth-Test
//
//  Created by Ryo Suzuki on 2/6/21.
//

import RealityKit
import ARKit
import SocketIO

let url = "https://bddee3dec219.ngrok.io"
let manager = SocketManager(socketURL: URL(string: url)!, config: [.log(true), .compress])
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
        socket.emit("test", "test")
        socket.connect()
        
        socket.on("connect") { data, ack in
            print("socket connected")
            socket.emit("test", "test 2")
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
                
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapRecognizer)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        print("test")
        let session = arView.session
        let frame = session.currentFrame
        let position = frame?.camera
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let meshAnchors = anchors.compactMap({ $0 as? ARMeshAnchor })
        addMeshAnchors(meshAnchors)
    }

    struct Vertex: Codable {
        var x:Float
        var y:Float
        var z:Float
    }
    
//    struct Test: Codable {
//        var geometry: ARMeshGeometry
//    }
    
    struct Vector: Codable {
        var x:Float
        var y:Float
        var z:Float
    }

//    struct Vertex:[Float]
    
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
            /*
            for index in 0..<anchor.geometry.vertices.count {
                let vertex = anchor.geometry.vertex(at: UInt32(index))
                let v = Vector(x: vertex.0, y: vertex.1, z: vertex.2)
                test.vertices.append(v)
            }
            */
            for index in 0..<anchor.geometry.faces.count {
                let vertices = anchor.geometry.verticesOf(faceWithIndex: index)
                for vertex in vertices {
                    let v = Vector(x: vertex.0, y: vertex.1, z: vertex.2)
                    test2.vertices.append(v)
                }
            }
            meshes.append(test2)
        }
        var test = Test3(meshes: meshes)
        do {
            let json = try JSONEncoder().encode(test)
            socket.emit("test", json)
        }
        catch {
            print("error")
        }


    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let position = frame.camera
//        print(position)
        let meshAnchors = frame.anchors.compactMap{ $0 as? ARMeshAnchor }
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.0) {
            self.syncMesh(meshAnchors)
        }
//        print(meshAnchors.count)

//        addMeshAnchors(meshAnchors)
//        updateMeshAnchors(meshAnchors)

//        for meshAnchor in meshAnchors {
//            print(meshAnchor.geometry.vertices.count)
//        }

//        do {
//            let data = try JSONEncoder().encode(position)
//            socket.emit("test", data)
//        }
    }
    
    func addMeshAnchors(_ meshAnchors: [ARMeshAnchor]) {
        for anchor in meshAnchors {
            updatedMeshes[anchor.identifier] = 0
        }
    }
    
    func updateMeshAnchors(_ meshAnchors: [ARMeshAnchor]) {
        for (id, value) in updatedMeshes {
            updatedMeshes[id] = value + 1
        }
        for anchor in meshAnchors {
            updatedMeshes[anchor.identifier] = 0
        }
        print(updatedMeshes.count)
        guard let currentMeshAnchors = arView.session.currentFrame?.anchors.compactMap({ $0 as? ARMeshAnchor }) else { return }
        
        for (id, value) in updatedMeshes {
//            guard value >= meshMaxUpdateCount else { continue }
            
            if let anchor = currentMeshAnchors.first(where: {$0.identifier == id}) {
                savedMeshes.insert(id)
                updatedMeshes.removeValue(forKey: id)
                let meshSaveDelay = 1000
                /*
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + meshSaveDelay) {
                    self.saveMeshAsJSON(anchor, self.extractAnchorToMesh)
                }
                */
                print(anchor)
            }
        }
    }
    
    /*
    struct ScannedMesh {
        var
        var vertices: [SCNVector3]
        var normals: [SCNVector3]
    }
    
    func extractAnchorToMesh(_ anchor:ARMeshAnchor) -> ScannedMesh {
        var scannedMesh = ScannedMesh(transform: anchor.transform.floatArray, triangles:[], vertices: [], normals: [])
        for index in 0..<anchor.geometry.vertices.count {
            let vertex = anchor.geometry.transformedVertex(index, anchor.transform)
            scannedMesh.vertices.append(Vector3(x: vertex.x, y: vertex.y, z: vertex.z))
        }
        for index in 0..<anchor.geometry.normals.count {
            let normal = anchor.geometry.normalOf(faceWithIndex: index)
            scannedMesh.normals.append(Vector3(x: normal.x, y: normal.y, z: normal.z))
        }
        for index in 0..<anchor.geometry.faces.count {
            let triangle = anchor.geometry.vertexIndicesOf(faceWithIndex: index)
            let classificationId = anchor.geometry.classificationOf(faceWithIndex: index).rawValue
            if let index = scannedMesh.triangles.firstIndex(where: { return $0.id == classificationId }) {
                scannedMesh.triangles[index].value += triangle
            }
            else {
                scannedMesh.triangles.append(ClassifiedTriangle(id: classificationId, value: triangle))
            }
        }
        return scannedMesh
    }
    
    func saveMeshAsJSON(_ anchor:ARMeshAnchor, _ func:(ARMeshAnchor) -> ScannedMesh) {
        do {
            let data = try JSONEncoder().encode(func(anchor))
            data.saveToDirectory(getMeshFolderName(), getMeshFileName(anchor.identifier)) {}
        }
        catch {
            print("Failed to encode JSON: \(error.localizedDescription)")
        }
    }
    */
    
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
    
    @objc
    func handleTap(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: arView)
        if let result = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .any).first {

            let resultAnchor = AnchorEntity(world: result.worldTransform)
            resultAnchor.addChild(sphere(radius: 0.01, color: .lightGray))
//            arView.scene.addAnchor(resultAnchor, removeAfter: 3)
        }
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("hello")
        guard error is ARError else { return }
    }
        
    func model(for classification: ARMeshClassification) -> ModelEntity {
        // Return cached model if available
        if let model = modelsForClassification[classification] {
            model.transform = .identity
            return model.clone(recursive: true)
        }
        
        let text = "hello"
        let color = UIColor.red
        let lineHeight: CGFloat = 0.05
        let font = MeshResource.Font.systemFont(ofSize: lineHeight)
        let textMesh = MeshResource.generateText(text, extrusionDepth: Float(lineHeight * 0.1), font: font)
        let textMaterial = SimpleMaterial(color: color, isMetallic: true)
        let model = ModelEntity(mesh: textMesh, materials: [textMaterial])
        // Move text geometry to the left so that its local origin is in the center
        model.position.x -= model.visualBounds(relativeTo: nil).extents.x / 2
        // Add model to cache
        modelsForClassification[classification] = model
        return model
    }
    
    func sphere(radius: Float, color: UIColor) -> ModelEntity {
        let sphere = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: false)])
        // Move sphere up by half its diameter so that it does not intersect with the mesh
        sphere.position.y = radius
        return sphere
    }
}

//
//  ScanViewController.swift
//  AugmentedRealityAppPOC
//
//  Created by user on 07/06/24.
//

import UIKit
import SceneKit
import ARKit

class ScanViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var markerDescriptionView: UIView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var descriptionSaveButton: UIButton!
    @IBOutlet weak var descriptionBoxHeading: UILabel!
    
    //MARK: - Properties
    let viewModel = ScanViewModel()
    var marksData: [ScanModel?] = []
    var descriptions = [SCNNode: String]()
    var descriptionDetail: [String: String] = [:]
    var mode: Modes = .scanning
    
    //MARK: - LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupUI()
        //FIXME: - In case of retrieving arWorld map will be assigned twice to initialworldMap
        startLoading()
        let configuration = ARWorldTrackingConfiguration()
        
        switch mode {
            
        case .scanning:
            self.viewModel.retrieveWorldMap { [weak self] arWorldMap, _ in
                guard let self = self else { return }
                
                stopLoading()
                // Create a session configuration
                
                configuration.initialWorldMap = arWorldMap
                configuration.planeDetection = [.horizontal, .vertical]
                
                // Run the view's session
                self.sceneView.session.run(configuration)
            }
        case .retrieving:
            self.retrieveData(configuration: configuration)
        }
        
        
        //        print("Session started")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: sceneView)
        
        switch mode {
            
        case .scanning:
            /// raycastQuery is used to convert the 2D coordinates to 3D coordinates, as user touches mobile screen
            /// which is 2D but we need to place object in real world which is 3D. So raycastQuery helps to detect the
            /// 3D coordinates of an existingPlaneGeometry in the real world on the basis of touch location of iPhone
            guard let raycastQuery = sceneView.raycastQuery(
                from: touchLocation,
                allowing: .existingPlaneGeometry,
                alignment: .any
            ) else { return }
            
            let raycastResults = sceneView.session.raycast(raycastQuery)
            
            guard let raycastFirstResult = raycastResults.first else { return }
            
            let position = SCNVector3(raycastFirstResult.worldTransform.columns.3.x,
                                      raycastFirstResult.worldTransform.columns.3.y,
                                      raycastFirstResult.worldTransform.columns.3.z)
            
            //FIXME: - Move to constants
            let anchorName = "ar-anchor-\(UUID().uuidString)"
            let arAnchor = ARAnchor(name: anchorName, transform: raycastFirstResult.worldTransform)
            let anchorID = arAnchor.identifier.uuidString
            let redDotNode = createRedDot(at: position, with: anchorID)
            sceneView.session.add(anchor: arAnchor)
            sceneView.scene.rootNode.addChildNode(redDotNode)
            
            viewModel.scannedModel = ScanModel(
                arSession: sceneView.session,
                position: position,
                anchorID: anchorID,
                description: nil
            )
            
            /// check if we acutally need dispatchqueue here
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.descriptionTextView.setEmpty()
                self.markerDescriptionView.showWithAnimation()
            }
        case .retrieving:
            let hitTests = sceneView.hitTest(touchLocation, options: [
                .boundingBoxOnly: false,
                .ignoreHiddenNodes: true
            ])
            var anchorID = ""
            hitTests.forEach { hitTest in
                if let _ = descriptionDetail[hitTest.node.name ?? ""] {
                    anchorID = hitTest.node.name ?? ""
                }
            }
            
            if let description = descriptionDetail[anchorID] {
                markerDescriptionView.showWithAnimation()
                descriptionTextView.text = description
                descriptionTextView.isEditable = false
                descriptionSaveButton.isUserInteractionEnabled = false
                descriptionSaveButton.alpha = 0.3
                //FIXME: - cnst
                descriptionBoxHeading.text = "Description"
            }
        }
        
    }
    
    //MARK: - IBActions
    @IBAction func descriptionCloseButtonPressed(_ sender: UIButton) {
        markerDescriptionView.hideWithAnimation()
    }
    
    @IBAction func saveDescriptionButtonPressed(_ sender: UIButton) {
        guard descriptionTextView.isNotEmpty() else {
            showAlert(ofType: .emptyDescription)
            return
        }
        
        startLoading()
        viewModel.scannedModel?.description = descriptionTextView.text
        
        viewModel.generateMarkDataAndSave(using: viewModel.scannedModel) { [weak self] error in
            guard let self = self else { return }
            
            stopLoading()
            
            if let e = error {
                showAlert(ofType: e)
            } else {
                showToast(ofType: .markerHosted)
                markerDescriptionView.hideWithAnimation()
            }
        }
    }
    
    //MARK: - UI Related Methods
    //FIXME: - doc
    func setupUI() {
        descriptionTextView.layer.borderColor = UIColor.brandPink.cgColor
        descriptionTextView.layer.borderWidth = 1.0
        descriptionTextView.layer.cornerRadius = 10
        markerDescriptionView.layer.cornerRadius = 12
        descriptionSaveButton.layer.cornerRadius = 8
        dismissKeyboardWhenTouchedAround()
    }
    
    //MARK: function to configure back navigation
    func configureBackButton() {
        if let backImage = UIImage(systemName: "chevron.backward") {
            let blackBackImage = backImage.withTintColor(.black, renderingMode: .alwaysOriginal)
            let backButton = UIBarButtonItem(image: blackBackImage, style: .plain, target: self, action: #selector(backButtonTapped))
            navigationItem.leftBarButtonItem = backButton
        }
    }
    
    @objc func backButtonTapped() {
        // Dismiss the view controller
        navigationController?.popViewController(animated: true)
    }
        
    func createRedDot(at position: SCNVector3, with anchorID: String) -> SCNNode {
        let dotGeometry = SCNSphere(radius: 0.05)
        let dotNode = SCNNode(geometry: dotGeometry)
        dotNode.position = position
        dotNode.name = anchorID
        dotNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        return dotNode
    }
    
    func retrieveData(configuration: ARWorldTrackingConfiguration) {
        viewModel.retrieveSavedMarksData { [weak self] worldMap, marksData, error in
            guard let self = self else { return }
            
            stopLoading()
            
            if let e = error {
                showAlert(ofType: e)
            } else if let marksData = marksData {
                configuration.initialWorldMap = worldMap
                /// check below line is needed or not try removing it and observe results
                configuration.planeDetection = [.horizontal, .vertical]
                configuration.isAutoFocusEnabled = true
                configuration.isLightEstimationEnabled = true
                self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                //FIXME: - Check if we can remove one of below data assignment
                self.marksData = marksData
                
                var descriptionDetail: [String: String] = [:]
                for scannedModel in marksData {
                    if let scannedModel = scannedModel {
                        descriptionDetail[scannedModel.anchorID] = scannedModel.description ?? ""
                    }
                }
                self.descriptionDetail = descriptionDetail
            }
        }
    }
}


// MARK: - ARSCNViewDelegate
extension ScanViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if mode == .scanning {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                //get the coordinates
                let center = planeAnchor.center, xCoordinate = center.x, yCoordinate = center.y
                print("Center: \(center), X: \(xCoordinate), Y: \(yCoordinate)")
                
                // Create a visual representation of the plane
                let plane = createPlaneNode(anchor: planeAnchor)
                node.addChildNode(plane)
                print("Added \(planeAnchor.alignment == .horizontal ? "horizontal" : "vertical") plane: \(anchor)")
                
                //extra - remove later
                //calculate distance between camera and plane
                let distance = calculateDistanceToPlane(anchor: planeAnchor)
                print("Detected \(planeAnchor.alignment == .horizontal ? "horizontal" : "vertical") plane at distance: \(distance) meters")
            }
        }
    }
    
    func createPlaneNode(anchor: ARPlaneAnchor) -> SCNNode {
        let planeGeometry = ARSCNPlaneGeometry(device: MTLCreateSystemDefaultDevice()!)!
        planeGeometry.update(from: anchor.geometry)
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.opacity = 0.25
        
        if anchor.alignment == .horizontal {
            planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        } else {
            planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        }
//        print("Plane node created for \(anchor.alignment == .horizontal ? "horizontal" : "vertical") plane")
        return planeNode
    }
    
    //extra - remove later
    func calculateDistanceToPlane(anchor: ARPlaneAnchor) -> Float {
        // Assuming the camera is at the origin (0,0,0) in ARKit's coordinate space
        let cameraPosition = sceneView.pointOfView?.position ?? SCNVector3Zero
        let planePosition = SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
        
        let distance = SCNVector3Distance(from: cameraPosition, to: planePosition)
        return distance
    }
    
    //extra - remove later
    func SCNVector3Distance(from: SCNVector3, to: SCNVector3) -> Float {
        let dx = from.x - to.x
        let dy = from.y - to.y
        let dz = from.z - to.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor,
           let planeNode = node.childNodes.first,
           let planeGeometry = planeNode.geometry as? ARSCNPlaneGeometry {
            // Update the plane geometry
            planeGeometry.update(from: planeAnchor.geometry)
//            print("Updated \(planeAnchor.alignment == .horizontal ? "horizontal" : "vertical") plane: \(anchor)")
        }
    }
    
    //MARK: ARSession error handling
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        showAlert(ofType: .externalError(error))
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        showAlert(ofType: .arSessionInterrupted)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        if let configuration = sceneView.session.configuration {
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
    }
}


extension ScanViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let anchorIDs = anchors.map { $0.identifier.uuidString }
        
        marksData.forEach { scannedModel in
            guard let anchorID = scannedModel?.anchorID, let position = scannedModel?.position else { return }
            
            if anchorIDs.contains(anchorID) {
                sceneView.debugOptions = []
                let redDot = self.createRedDot(at: position, with: anchorID)
                self.sceneView.scene.rootNode.addChildNode(redDot)
            }
        }
    }
}

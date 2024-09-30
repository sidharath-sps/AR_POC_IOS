//
//  ScanViewModel.swift
//  AugmentedRealityAppPOC
//
//  Created by Sharandeep Singh on 11/06/24.
//

import ARKit
import FirebaseFirestore
import FirebaseStorage

enum Modes {
    
    case scanning
    case retrieving
}


final class ScanViewModel {
    
    //MARK: - Properties
    var scannedModel: ScanModel?
    
    //MARK: - Networking Methods
    
    /// Helps to store world map data and marked point coordinates on Firebase
    /// - Parameters:
    ///   - session: ARSession of which we want to save world map
    ///   - coordinates: X Y Z coordinates of the point marked on world map
    ///   - anchorID: Unique identifier of an anchor where the point is marked
    ///   - completion: Completion called when some error gets occures with error type as parameter
    func generateMarkDataAndSave(using scannedModel: ScanModel?,
                                 completion: @escaping (Alerts?) -> Void) {
        var successCount = 0
        
        guard let x = scannedModel?.position.x,
              let y = scannedModel?.position.y,
              let z = scannedModel?.position.z,
              let arSession = scannedModel?.arSession,
              let anchorID = scannedModel?.anchorID,
              let description = scannedModel?.description else {
            return
        }
        
        let markCoordinates: [String: Any] = [
            "x": x,
            "y": y,
            "z": z,
            "description": description,
        ]
        
        self.saveMarkData(using: markCoordinates, and: anchorID) { error in
            if let e = error {
                completion(e)
            } else {
                successCount += 1
                
                if successCount == 2 {
                    completion(nil)
                }
            }
        }
        
        arSession.getCurrentWorldMap { worldMap, error in
            if let e = error {
                completion(.externalError(e))
            } else if let worldMap = worldMap {
                do {
                    let archivedWorldMap = try NSKeyedArchiver.archivedData(
                        withRootObject: worldMap,
                        requiringSecureCoding: true
                    )
                    
                    guard let compressedMapData = archivedWorldMap.compress() else {
                        completion(.worldMapCompressionFailed)
                        return
                    }
                    
                    self.saveWorldMap(using: compressedMapData) { error in
                        if let e = error {
                            completion(e)
                        } else {
                            successCount += 1
                            
                            if successCount == 2 {
                                completion(nil)
                            }
                        }
                    }
                } catch {
                    completion(.externalError(error))
                }
            }
        }
    }
    
    /// Saves the coordinates of marked points on firebase
    /// - Parameters:
    ///   - markData: A dictionary that contains Data (coordinates & anchor id) for marked point
    ///   - completion: Completion called when some error gets occures with error type as parameter
    ///   - anchorID: Unique identifier of an anchor where the point is marked
    private func saveMarkData(using markData: [String: Any],
                              and anchorID: String,
                              completion: @escaping (Alerts?) -> Void) {
        let firestore = Firestore.firestore()
        
        firestore.collection("marks").document(anchorID).setData(markData) { error in
            if let e = error {
                completion(.externalError(e))
            } else {
                completion(nil)
            }
        }
    }
    
    /// Saves ARWorldMap data on Firebase Storage i.e. Cloud Storage
    /// - Parameters:
    ///   - worldMapData: Actual data that needs to save on firebase
    ///   - completion: Completion called when some error gets occures with error type as parameter
    private func saveWorldMap(using worldMapData: Data, completion: @escaping (Alerts?) -> Void) {
        let cloudStorage = Storage.storage()
        let storageReference = cloudStorage.reference().child("ARWorldMap.data")
        
        storageReference.putData(worldMapData, metadata: nil) { _, error in
            if let e = error {
                completion(.externalError(e))
            } else {
                completion(nil)
            }
        }
    }
    
    /// Helps to retrieve the saved data of markers from firestore
    /// - Parameter completion: Completion called to provide either fetched data if data gets successfully fetched or error if fetching gets failed
    func retrieveSavedMarksData(completion: @escaping (ARWorldMap?, [ScanModel?]?, Alerts?) -> Void) {
        let firestore = Firestore.firestore()
        var marksData: [ScanModel?] = []
        
        firestore.collection("marks").getDocuments { querySnapshot, error in
            
            if let e = error {
                completion(nil, nil, .externalError(e))
                return
            } else if let documents = querySnapshot?.documents {
                marksData = documents.map { document in
                    guard let x = document.data()["x"] as? Float,
                          let y = document.data()["y"] as? Float,
                          let z = document.data()["z"] as? Float,
                          let description = document.data()["description"] as? String else {
                        completion(nil, nil, .markersDataMappingFailed)
                        return nil
                    }
                    
                    let position = SCNVector3(x: x, y: y, z: z)
                    let anchorID = document.documentID
                    return ScanModel(
                        arSession: nil,
                        position: position,
                        anchorID: anchorID,
                        description: description
                    )
                }
                
                self.retrieveWorldMap { arWorldMap, errorType  in
                    if let worldMap = arWorldMap {
                        completion(worldMap, marksData, nil)
                    } else {
                        completion(nil, nil, errorType)
                    }
                }
            }
        }
    }
    
    /// Retrieves the world map
    /// - Parameter completion: Called to provide either world map fetched from cloud or error occured while fetching world map
    func retrieveWorldMap(completion: @escaping (ARWorldMap?, Alerts?) -> Void) {
        let cloudStorage = Storage.storage()
        let storageRegerence = cloudStorage.reference().child("ARWorldMap.data")
        
        /// Maximum allowed read is set to 20 MB can be increased in future if needed
        storageRegerence.getData(maxSize: 20 * 1024 * 1024) { compressedWorldMap, error in
            if let e = error {
                completion(nil, .externalError(e))
                return
            }
            
            guard let archivedWorldMap = compressedWorldMap?.decompress() else {
                completion(nil, .worldMapDecompressionFailed)
                return
            }
            
            do {
                let arWorldMap = try NSKeyedUnarchiver.unarchivedObject(
                    ofClass: ARWorldMap.self,
                    from: archivedWorldMap
                )
                
                if let worldMap = arWorldMap {
                    completion(worldMap, nil)
                }
                
            } catch {
                completion(nil, .externalError(error))
            }
        }
    }
}

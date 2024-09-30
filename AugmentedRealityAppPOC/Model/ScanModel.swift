//
//  ScanModel.swift
//  AugmentedRealityAppPOC
//
//  Created by Sharandeep Singh on 20/06/24.
//

import ARKit

struct ScanModel {
    
    let arSession: ARSession?
    let position: SCNVector3
    let anchorID: String
    var description: String?
}

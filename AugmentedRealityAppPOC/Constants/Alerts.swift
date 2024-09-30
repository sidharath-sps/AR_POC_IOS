//
//  Alerts.swift
//  AugmentedRealityAppPOC
//
//  Created by Sharandeep Singh on 16/06/24.
//

import Foundation

enum Alerts {
    
    case externalError(Error)
    case arSessionInterrupted
    case worldMapCompressionFailed
    case worldMapDecompressionFailed
    case markersDataMappingFailed
    case emptyDescription
    case markerHosted
}


struct AlertMessage {
    
    let title: String
    let message: String
}


struct AlertMessages {
    
    static func giveMessage(ofType alerts: Alerts) -> AlertMessage {
        switch alerts {
            
        case .externalError(let error):
            let message = error.localizedDescription
            
            return AlertMessage(
                title: "External Error",
                message: message
            )
        case .arSessionInterrupted:
            return AlertMessage(
                title: "AR Session Interrupted",
                message: "The session will be reset once interruption has ended"
            )
        case .worldMapCompressionFailed:
            return AlertMessage(
                title: "Compression Failed",
                message: "Failed to compress world map"
            )
        case .worldMapDecompressionFailed:
            return AlertMessage(
                title: "Decompression Failed",
                message: "Failed to decompress world map"
            )
        case .markersDataMappingFailed:
            return AlertMessage(
                title: "Compression Failed",
                message: """
                         One of the markers data mapping gets failed, but you will still
                         be able to see other markers
                         """
            )
        case .emptyDescription:
            return AlertMessage(
                title: "Empty Description",
                message: "Sorry, you are not allowed to save empty description"
            )
        case .markerHosted:
            return AlertMessage(
                title: "Hosting Successful",
                message: "Marker successfully hosted on the cloud"
            )
        }
    }
}

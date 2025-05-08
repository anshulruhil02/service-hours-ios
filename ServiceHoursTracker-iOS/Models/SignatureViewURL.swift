//
//  SignatureViewURL.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-08.
//

import Foundation

struct ViewUrlResponse: Decodable {
    let viewUrl: String? // Make it optional to handle null from backend
}

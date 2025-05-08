//
//  UploadUrlResponse.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-08.
//

import Foundation

struct UploadUrlResponse: Decodable {
    let uploadUrl: String
    let key: String
}

//
//  DateFormatter.swift
//  ServiceHoursTracker-iOS
//
//  Created by Anshul Ruhil on 2025-05-13.
//

import Foundation

struct AppDateFormatter {
    static var isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Matches format like 2023-10-27T10:15:30.123Z
        return formatter
    }()
}

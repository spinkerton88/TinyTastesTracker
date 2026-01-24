//
//  ParentProfile.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/23/25.
//

import Foundation
import SwiftData

@Model
final class ParentProfile {
    @Attribute(.unique) var id: UUID = UUID()
    var parentName: String? = nil
    var joinedDate: Date = Date()
    var icloudStatus: String? = nil
    
    init(id: UUID = UUID(), parentName: String? = nil, joinedDate: Date = Date(), icloudStatus: String? = nil) {
        self.id = id
        self.parentName = parentName
        self.joinedDate = joinedDate
        self.icloudStatus = icloudStatus
    }
}

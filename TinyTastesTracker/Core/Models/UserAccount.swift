//
//  UserAccount.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 1/23/25.
//

import Foundation
import SwiftData

@Model
final class UserAccount {
    var id: UUID
    var parentName: String?
    var joinedDate: Date
    var icloudStatus: String?
    
    init(id: UUID = UUID(), parentName: String? = nil, joinedDate: Date = Date(), icloudStatus: String? = nil) {
        self.id = id
        self.parentName = parentName
        self.joinedDate = joinedDate
        self.icloudStatus = icloudStatus
    }
}

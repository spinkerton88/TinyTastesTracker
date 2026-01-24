//
//  NewbornLog.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import Foundation
import SwiftData

enum NursingSide: String, Codable {
    case left
    case right
}

enum DiaperType: String, Codable {
    case wet
    case dirty
    case both
}

enum SleepQuality: String, Codable {
    case poor
    case fair
    case good
    case excellent
}

// MARK: - Nursing Log

@Model
final class NursingLog: Codable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var duration: TimeInterval  // in seconds
    var side: NursingSide
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         duration: TimeInterval,
         side: NursingSide) {
        self.id = id
        self.timestamp = timestamp
        self.duration = duration
        self.side = side
    }
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, duration, side
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.duration = try container.decode(TimeInterval.self, forKey: .duration)
        self.side = try container.decode(NursingSide.self, forKey: .side)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(duration, forKey: .duration)
        try container.encode(side, forKey: .side)
    }
}

// MARK: - Sleep Log

@Model
final class SleepLog: Codable {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date
    var quality: SleepQuality
    
    init(id: UUID = UUID(),
         startTime: Date,
         endTime: Date,
         quality: SleepQuality = .fair) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.quality = quality
    }
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, quality
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
        self.endTime = try container.decode(Date.self, forKey: .endTime)
        self.quality = try container.decode(SleepQuality.self, forKey: .quality)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(quality, forKey: .quality)
    }
}

// MARK: - Diaper Log

@Model
final class DiaperLog: Codable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var type: DiaperType
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         type: DiaperType) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
    }
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.type = try container.decode(DiaperType.self, forKey: .type)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
    }
}

// MARK: - Bottle Feed Log

enum FeedingType: String, Codable {
    case breastMilk
    case formula
    case mixed
}

@Model
final class BottleFeedLog: Codable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var amount: Double  // in oz
    var feedType: FeedingType
    var notes: String?
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         amount: Double,
         feedType: FeedingType,
         notes: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.amount = amount
        self.feedType = feedType
        self.notes = notes
    }
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, amount, feedType, notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.amount = try container.decode(Double.self, forKey: .amount)
        self.feedType = try container.decode(FeedingType.self, forKey: .feedType)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(amount, forKey: .amount)
        try container.encode(feedType, forKey: .feedType)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}

// MARK: - Pumping Log

@Model
final class PumpingLog: Codable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var leftBreastOz: Double
    var rightBreastOz: Double
    var notes: String?
    
    var totalYield: Double {
        leftBreastOz + rightBreastOz
    }
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         leftBreastOz: Double,
         rightBreastOz: Double,
         notes: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.leftBreastOz = leftBreastOz
        self.rightBreastOz = rightBreastOz
        self.notes = notes
    }
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, leftBreastOz, rightBreastOz, notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.leftBreastOz = try container.decode(Double.self, forKey: .leftBreastOz)
        self.rightBreastOz = try container.decode(Double.self, forKey: .rightBreastOz)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(leftBreastOz, forKey: .leftBreastOz)
        try container.encode(rightBreastOz, forKey: .rightBreastOz)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}

// MARK: - Medication Log

@Model
final class MedicationLog: Codable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var medicineName: String
    var babyWeight: Double  // in lbs
    var dosage: String
    var safetyInfo: String?  // AI-generated safety information
    var notes: String?
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         medicineName: String,
         babyWeight: Double,
         dosage: String,
         safetyInfo: String? = nil,
         notes: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.medicineName = medicineName
        self.babyWeight = babyWeight
        self.dosage = dosage
        self.safetyInfo = safetyInfo
        self.notes = notes
    }
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, medicineName, babyWeight, dosage, safetyInfo, notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.medicineName = try container.decode(String.self, forKey: .medicineName)
        self.babyWeight = try container.decode(Double.self, forKey: .babyWeight)
        self.dosage = try container.decode(String.self, forKey: .dosage)
        self.safetyInfo = try container.decodeIfPresent(String.self, forKey: .safetyInfo)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(medicineName, forKey: .medicineName)
        try container.encode(babyWeight, forKey: .babyWeight)
        try container.encode(dosage, forKey: .dosage)
        try container.encodeIfPresent(safetyInfo, forKey: .safetyInfo)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}

// MARK: - Growth Measurement

@Model
final class GrowthMeasurement: Codable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var weight: Double?  // in lbs
    var height: Double?  // in inches
    var headCircumference: Double?  // in inches
    var notes: String?
    
    init(id: UUID = UUID(),
         date: Date = Date(),
         weight: Double? = nil,
         height: Double? = nil,
         headCircumference: Double? = nil,
         notes: String? = nil) {
        self.id = id
        self.date = date
        self.weight = weight
        self.height = height
        self.headCircumference = headCircumference
        self.notes = notes
    }
    
    enum CodingKeys: String, CodingKey {
        case id, date, weight, height, headCircumference, notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        self.height = try container.decodeIfPresent(Double.self, forKey: .height)
        self.headCircumference = try container.decodeIfPresent(Double.self, forKey: .headCircumference)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(headCircumference, forKey: .headCircumference)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}


//
//  AudioProfile.swift
//  UtilityToggle
//

import Foundation

public struct AudioProfile: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var targetOutputDeviceUID: String?
    public var targetInputDeviceUID: String?
    public var outputVolume: Float
    public var inputVolume: Float
    public var isOutputMuted: Bool
    public var isInputMuted: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        targetOutputDeviceUID: String? = nil,
        targetInputDeviceUID: String? = nil,
        outputVolume: Float = 0.75,
        inputVolume: Float = 0.80,
        isOutputMuted: Bool = false,
        isInputMuted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.targetOutputDeviceUID = targetOutputDeviceUID
        self.targetInputDeviceUID = targetInputDeviceUID
        self.outputVolume = outputVolume
        self.inputVolume = inputVolume
        self.isOutputMuted = isOutputMuted
        self.isInputMuted = isInputMuted
    }
    
    public static let defaultGeneral = AudioProfile(
        name: "General",
        targetOutputDeviceUID: nil,
        targetInputDeviceUID: nil,
        outputVolume: 0.75,
        inputVolume: 0.80,
        isOutputMuted: false,
        isInputMuted: false
    )
}

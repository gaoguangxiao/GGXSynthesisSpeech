//
//  SynthesisModel.swift
//  GGXSynthesisSpeech
//
//  Created by 高广校 on 2024/7/3.
//

import Foundation

public struct MSSynthesisConfig {
    
//    public var content: String = ""
    /// Xiaoshuang
    public var vocal: String = "zh-CN-XiaoshuangNeural"
    
    //播放速度
    public var rate: Double = 1.0
    public var transRate: String {
        let rateStr = rate * 100 - 100
        if rateStr >= 0 {
            return "+\(rateStr)%"
        }
        return "\(rateStr)%"
    }
    
    /// 音量  0 ~ max。0 75 ->
    public var volume: Double = 1.0
    public var transVolume: String {
        let volumeStr = volume * 100 - 100
        if volumeStr >= 0 {
            return "+\(volumeStr)%"
        }
        return "\(volumeStr)%"
    }
    //
    public var pitch: Double = 1.0
    public var transPitch: String {
        let pitchStr = pitch * 100 - 100
        if pitchStr >= 0 {
            return "+\(pitchStr)%"
        }
        return "\(pitchStr)%"
    }
    
    public init() {
        
    }
    
}

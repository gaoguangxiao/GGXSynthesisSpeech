//
//  MSSynthesisSpeechProtocol.swift
//  GGXSynthesisSpeech
//
//  Created by 高广校 on 2024/7/10.
//

import Foundation
import MicrosoftCognitiveServicesSpeech

@objc public protocol MSSynthesisSpeechProtocol: NSObjectProtocol {
    
    // start synthesis
    @objc optional func synthesisStarted()
    
    // stop synthesis callback
    @objc optional func synthesisCanceled(args: SPXSpeechSynthesisEventArgs)
    
//    delegate?.synthesisError(msg: "合成SDK报错，或因为网络")
    func synthesisError(error: NSError)
    
    // 合成进度，已经合成的单词数组
    @objc optional func wordBoundaried(words:Array<Any>)
    
    //可以播放合成音
    func synthesisCompleted(audioData data: Data?, wordBoundarys: Array<SPXSpeechSynthesisWordBoundaryEventArgs>)
    
    //结束播放合成音
//    func synthesisCompleted()

    @objc optional func visemeReceived(args: SPXSpeechSynthesisVisemeEventArgs)
    
    @objc optional func bookmarkReached(args: SPXSpeechSynthesisBookmarkEventArgs)
}

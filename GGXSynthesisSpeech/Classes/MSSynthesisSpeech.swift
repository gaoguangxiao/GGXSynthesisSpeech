//
//  MSSynthesisSpeech.swift
//  RSChatRobot
//
//  Created by 高广校 on 2024/7/2.
//

import Foundation
import PTDebugView
import MicrosoftCognitiveServicesSpeech

struct MSSConfig {
    static let sub = "13aeaa2db83748b2a1bde1af30d1d15e"
    static let region = "eastus"
}

public protocol MSSynthesisSpeechProtocol: NSObjectProtocol {
 
    //结束播放合成音
    func synthesisCompletedEventHandler()
    
    //当前播放的
    func synthesisPlayEventHandler(text: String)
    
    //可以播放合成音
    func synthesisStartedEventHandler()
    
}


public class MSSynthesisSpeech: NSObject {
    
    public var synthesisConfig: MSSynthesisConfig?
    
    public init(synthesizer: SPXSpeechSynthesizer? = nil) {
        self.synthesizer = synthesizer
    }
    
    public static let share: MSSynthesisSpeech = {
        return MSSynthesisSpeech()
    }()
    
    public weak var delegate: MSSynthesisSpeechProtocol?
    
    var speechConfig: SPXSpeechConfiguration?
    
    var synthesizer: SPXSpeechSynthesizer?
    
    public var isPlaying = false
    
    public override init() {
        super.init()
        launchConfiguration()
    }
    
    public func startSynthesis(text: String) {
        DispatchQueue.global().async {
            try? self.synthesizer?.stopSpeaking()
            
            guard let model = self.synthesisConfig else {
                let _ = try? self.synthesizer?.speakText(text)
                return
            }
            
            let ssmlText = """
            <speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='zh-CN'>
            <voice name='\(model.vocal)'>
    <prosody pitch='\(model.transPitch)' volume='\(model.transVolume)' rate='\(model.transRate)' >\(text)</prosody></voice></speak>
    """
            self.isPlaying = false
            self.synthesisToSpeaker(ssmlText: ssmlText)
//            let _ = try? self.synthesizer?.speakSsml(ssmlText)
        }
    }
      
    public func endSynthesis() {
        DispatchQueue.global(qos: .userInitiated).async {
            try? self.synthesizer?.stopSpeaking()
        }
    }
    
    func launchConfiguration() {
        
//        var speechConfig: SPXSpeechConfiguration?
        do {
            try speechConfig = SPXSpeechConfiguration(subscription: MSSConfig.sub, region: MSSConfig.region)
//            speechConfig?.speechSynthesisVoiceName = "zh-CN-XiaoshuangNeural"
//            speechConfig.sp
        } catch {
            print("error \(error) happened")
            speechConfig = nil
        }
    }
    
    func synthesisToSpeaker(ssmlText: String) {
        self.isPlaying = false
        
        if ssmlText.isEmpty {
            print("inputText is Empty")
            return
        }
        
        guard let sConfig = self.speechConfig else {
            return
        }
        
        self.synthesizer = try? SPXSpeechSynthesizer(sConfig)
        self.synthesizer?.addSynthesisStartedEventHandler({ synthesizer, args in
            ZKTLog("addSynthesisStartedEventHandler\(args)")
        })
        self.synthesizer?.addSynthesizingEventHandler({ synthesizer, args in
            ZKTLog(args)
            
            /// The synthesis result.
            let result: SPXSpeechSynthesisResult = args.result
            ZKTLog("addSynthesizingEventHandler\(result)")
            
            
//            ZKTLog("addSynthesizingEventHandler: result.resultId:\(result.resultId)")
//            ZKTLog("addSynthesizingEventHandler: result.reason:\(result.reason)")
//            ZKTLog("addSynthesizingEventHandler: result.properties:\(result.properties)")
//            ZKTLog("addSynthesizingEventHandler: result.audioDuration:\(result.audioDuration)")
//            ZKTLog("addSynthesizingEventHandler: result.audioData:\(result.audioData)")
            
//            result.audioDuration
            
//            ZKTLog("addSynthesizingEventHandler\(args.result)")
        })
        synthesizer?.addSynthesisCompletedEventHandler({ synthesizer, args in
            ZKTLog("addSynthesisCompletedEventHandler\(args)")
            self.delegate?.synthesisCompletedEventHandler()
            self.isPlaying = false
        })
        synthesizer?.addSynthesisCanceledEventHandler({ synthesizer, args in
//            args.result
            ZKTLog("addSynthesisCanceledEventHandler\(args.result)")
        })
        synthesizer?.addSynthesisWordBoundaryEventHandler({ synthesizer, args in
//            args.text
            let wordBoundaryEventArgs: SPXSpeechSynthesisWordBoundaryEventArgs = args
            ZKTLog("addSynthesisWordBoundaryEventHandler.wordBoundaryEventArgs.text:\(wordBoundaryEventArgs.text)")
        })
        synthesizer?.addVisemeReceivedEventHandler({ synthesizer, args in
            if self.isPlaying == false{
                self.isPlaying = true
//                ZKTLog("add可以播放")
                self.delegate?.synthesisStartedEventHandler()
            }
            ZKTLog(args)
            ZKTLog("addVisemeReceivedEventHandler\(args)")
        })
        synthesizer?.addBookmarkReachedEventHandler({ synthesizer, args in
            ZKTLog("addBookmarkReachedEventHandler\(args)")
        })
        
        let result = try? synthesizer?.speakSsml(ssmlText)
        print("可以播放语音")
//        if result?.reason == SPXResultReason.canceled
//        {
//            let cancellationDetails = try! SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: result)
//            print("cancelled, detail: \(cancellationDetails.errorDetails!) ")
//        }
    }
}

//
//  MSSynthesisSpeech.swift
//  RSChatRobot
//
//  Created by 高广校 on 2024/7/2.
//

import Foundation
import PTDebugView
import MicrosoftCognitiveServicesSpeech

public protocol MSSynthesisSpeechProtocol: NSObjectProtocol {
 
    //结束播放合成音
    func synthesisCompletedEventHandler()
    
    func synthesisCompletedEventHandler(progress: Double)
    
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
    
    var sub: String?
    
    var region: String?
    
    var speechConfig: SPXSpeechConfiguration?
    
    var synthesizer: SPXSpeechSynthesizer?
    
    public var isPlaying = false
    
    //定时
    var timer: Timer?
    
    var _pro: Double = 0.0
    
    /// 单词的截取
    var wordBoundarys: [SPXSpeechSynthesisWordBoundaryEventArgs] = []
    
    public init(sub: String, region: String) {
        super.init()
        self.sub = sub
        self.region = region
        launchConfiguration()
    }
    
    public func startSynthesis(text: String) {
        
        self.endSynthesis()
        self.wordBoundarys = []
        
        DispatchQueue.global().async {
//            try? self.synthesizer?.stopSpeaking()
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
        guard let sub, let region else { return  }
//        var speechConfig: SPXSpeechConfiguration?
        do {
            try speechConfig = SPXSpeechConfiguration(subscription: sub, region: region)
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
            if self.isPlaying == false{
                self.isPlaying = true
//                ZKTLog("add可以播放")
                self.startedEventHandler()
                
            }
            /// The synthesis result.
            let result: SPXSpeechSynthesisResult = args.result
            ZKTLog("addSynthesizingEventHandler\(result)")
            
            ZKTLog("addSynthesizingEventHandler: result.resultId:\(result.resultId)")
            ZKTLog("addSynthesizingEventHandler: result.reason:\(result.reason)")
            ZKTLog("addSynthesizingEventHandler: result.properties:\(result.properties)")
            ZKTLog("addSynthesizingEventHandler: result.audioDuration:\(result.audioDuration)")
            ZKTLog("addSynthesizingEventHandler: result.audioData:\(result.audioData)")
            
            let audioDatabi = result.audioData?.count
            ZKTLog("addSynthesizingEventHandler: result.audioData.count:\(audioDatabi)")
//            result.audioDuration
            
//            ZKTLog("addSynthesizingEventHandler\(args.result)")
        })
        synthesizer?.addSynthesisCompletedEventHandler({ synthesizer, args in
            ZKTLog("addSynthesisCompletedEventHandler\(args)")
            self.completedEventHandler()
        })
        synthesizer?.addSynthesisCanceledEventHandler({ synthesizer, args in
//            args.result
            ZKTLog("addSynthesisCanceledEventHandler\(args.result)")
        })
        synthesizer?.addSynthesisWordBoundaryEventHandler({ [weak self] synthesizer, args in
            let wordBoundaryEventArgs: SPXSpeechSynthesisWordBoundaryEventArgs = args
            self?.wordBoundarys.append(wordBoundaryEventArgs)
            
            ZKTLog("addSynthesisWordBoundaryEventHandler.wordBoundaryEventArgs.text:\(wordBoundaryEventArgs.text)、\naudioOffset：\(wordBoundaryEventArgs.audioOffset)、\nduration:\(wordBoundaryEventArgs.duration)、\nwordLength :\(wordBoundaryEventArgs.wordLength)、\nboundaryType: \(wordBoundaryEventArgs.boundaryType),\ntextOffset: \(wordBoundaryEventArgs.textOffset)")
        })
        synthesizer?.addVisemeReceivedEventHandler({ synthesizer, args in
            
//            ZKTLog(args)
//            ZKTLog("addVisemeReceivedEventHandler\(args)")
        })
        synthesizer?.addBookmarkReachedEventHandler({ synthesizer, args in
//            ZKTLog("addBookmarkReachedEventHandler\(args)")
        })
        
        let result = try? synthesizer?.speakSsml(ssmlText)
        print("语音完毕")
//        if result?.reason == SPXResultReason.canceled
//        {
//            let cancellationDetails = try! SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: result)
//            print("cancelled, detail: \(cancellationDetails.errorDetails!) ")
//        }
    }
}

/// 当前已经播放的文本
extension MSSynthesisSpeech {
    
    func completedEventHandler() {
        timer?.invalidate()
        timer = nil
        
        self.delegate?.synthesisCompletedEventHandler()
        self.isPlaying = false
        
//        self.play()
    }
    
    
    func startedEventHandler() {
        _pro = 0.0
        
        self.delegate?.synthesisStartedEventHandler()
        
        Task {
            await MainActor.run {
//                if let view = UIApplication.rootWindow {
//                    view.hideToastActivity()
//                }
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                    self?.updatePlayProgress()
                }
            }
        }
        
//        if let timer {
//            RunLoop.current.add(timer, forMode: .commonModes)
//            RunLoop.current.run()
//        }
        
    }
    
    func updatePlayProgress() {
        _pro = _pro + 0.1
        
        self.delegate?.synthesisCompletedEventHandler(progress: _pro)
        
        //当前播放的纳秒 100
        let currentAudio = _pro * pow(10, 7)
        ZKTLog("播放进度：\(currentAudio)")
//        print("播放的")
//        字边界音频偏移量，以刻度为单位(100纳秒)。 audioOffset
        
        //查询播放的文字
        let playText =  wordBoundarys.filter { $0.audioOffset < UInt(currentAudio) }
            .map { $0.text }
            .reduce("", +)
            
        self.delegate?.synthesisPlayEventHandler(text: playText)
    }
}

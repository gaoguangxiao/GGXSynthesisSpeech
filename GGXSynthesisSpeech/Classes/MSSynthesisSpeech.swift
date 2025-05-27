//
//  MSSynthesisSpeech.swift
//  RSChatRobot
//
//  Created by 高广校 on 2024/7/2.
//

import Foundation
import PTDebugView
import MicrosoftCognitiveServicesSpeech

public enum SynthesisSpeechError: Error {
    case outFilePathEmpty
}


public class MSSynthesisSpeech: NSObject, ResponseFailRetriedable {

    public var allFailCount: Int = 3
    
    public var failCount: Int = 0
    
//    public var retriedID: String = "0"
    
    public typealias T = MSSynthesisConfig
    
    public var retried: MSSynthesisConfig = MSSynthesisConfig()
    
    public func execute() {
        guard let speechConfiguration = self.speechConfig else {
            fatalError("`SPXSpeechConfiguration`需要提前初始化")
        }
        guard let ssmlText = getSsmlText(model: retried) else {
            return
        }
        self.checkConfig()
        let audioconfig = try? SPXAudioConfiguration(wavFileOutput: retried.localFilePath)
        self.synthesizer = try? SPXSpeechSynthesizer(speechConfiguration: speechConfiguration, audioConfiguration: audioconfig)
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.speakSsml(ssml: ssmlText)
        }
       
    }
    
    public func completeRetried(error: NSError) {
        delegate?.synthesisError(error: error)
    }
    
    @PTLogger(category: "synthesisSpeech")
    private var logger
    
    public var synthesisConfig: MSSynthesisConfig?
    
    public weak var delegate: MSSynthesisSpeechProtocol?
    
    var speechConfig: SPXSpeechConfiguration?
    
    var synthesizer: SPXSpeechSynthesizer?
    
    var isSynthesizerFinish = false
    
    //增加合成标签，用于判定是否手动停止，对cancen的回调区分，网络失败-手动停止都会触发，当`isUserStop`为true，在回调中改为用户取消，否则视为错误
    var isUserStop = false
    
    //建立一个协议，用于标志存储key-对象
    var requestProgress: Dictionary<String, Any> = [:]
    

    var startSpeakTime = 0.0
    
    /// 单词的截取
    var wordBoundarys: [SPXSpeechSynthesisWordBoundaryEventArgs] = []
    
    public init(sub: String, region: String) {
        super.init()
        do {
            try speechConfig = SPXSpeechConfiguration(subscription: sub, region: region)
        } catch {
            print("error \(error) happened")
            speechConfig = nil
        }
        
    }
    
    /*
     //        String resourceId = "Your Resource ID";
     //        String region = "Your Region";
     //
     //        // You need to include the "aad#" prefix and the "#" (hash) separator between resource ID and AAD access token.
     //        String authorizationToken = "aad#" + resourceId + "#" + token;
     //        SpeechConfig speechConfig = SpeechConfig.fromAuthorizationToken(authorizationToken, region);
     **/
    public init(token: String, region: String) throws {
        do {
            try speechConfig = SPXSpeechConfiguration(authorizationToken: token, region: region)
        } catch {
            print("error \(error) happened")
            throw error
        }
    }
    
    func getSsmlText(model: MSSynthesisConfig) -> String? {
        
        guard let content = model.content else {
            return nil
        }
        let ssmlText = """
        <speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='zh-CN'><voice name='\(model.vocal)'><prosody pitch='\(model.transPitch)' volume='\(model.transVolume)' rate='\(model.transRate)'>\(content)</prosody></voice></speak>
"""
        return ssmlText
    }

    
    func checkConfig() {
        self.stopSpeaking()
        self.wordBoundarys = []
        self.isUserStop = false
    }
    
    func resetSynthesisAllowFail(msgID: String, error: NSError) {
        
    }

    deinit {
        logger.debug("\(self) deinit")
    }
}

//MARK: init方法
extension MSSynthesisSpeech {
    
    /// 执行语音合成的结果，并播放合成的音频。
    public func startSynthesis(text: String, synthesisConfig: MSSynthesisConfig) {
        self.stopSpeaking()
        self.wordBoundarys = []
        DispatchQueue.global().async {
            self.isSynthesizerFinish = false
            self.initConfiguration()
            guard let ssmlText = self.getSsmlText(model: synthesisConfig) else { return  }
            self.speakSsml(ssml: ssmlText)
        }
    }
    
    func initConfiguration() {
        guard let speechConfiguration = self.speechConfig else {
            return
        }
        synthesizer = try? SPXSpeechSynthesizer(speechConfiguration)
    }
    
}

//MARK: - WavFileOutput
extension MSSynthesisSpeech {
    
    public func startSynthesisToFile(outFilePath: String, synthesisConfig: MSSynthesisConfig) throws -> Bool {
                
        self.retried = synthesisConfig
        
        self.execute()
        
//        guard let speechConfiguration = self.speechConfig else {
//            return false
//        }
//        
//        guard let ssmlText = getSsmlText(model: synthesisConfig) else { return false }
//        
//        self.checkConfig()
//        
//        let audioconfig = try? SPXAudioConfiguration(wavFileOutput: outFilePath)
//        self.synthesizer = try? SPXSpeechSynthesizer(speechConfiguration: speechConfiguration, audioConfiguration: audioconfig)
//        
//        DispatchQueue.global(qos: .userInteractive).async {
//            self.speakSsml(ssml: ssmlText)
//        }
//       
        return true
    }
}

//MARK: - OutputStream
extension MSSynthesisSpeech {
    
    public func startSynthesisToPullAudioOutputStream(outFilePath: String, synthesisConfig: MSSynthesisConfig) -> Bool {
        
        guard let speechConfiguration = self.speechConfig else {
            return false
        }
        
        guard let ssmlText = getSsmlText(model: synthesisConfig) else { return false }
        
        self.checkConfig()
        
        let audioOutStream = SPXPullAudioOutputStream()
        let audioconfig = try? SPXAudioConfiguration(streamOutput: audioOutStream)
        self.synthesizer = try? SPXSpeechSynthesizer(speechConfiguration: speechConfiguration, audioConfiguration: audioconfig)
        
        self.speakSsml(ssml: ssmlText)

        //文件句柄操作的文件需要存在
        if !FileManager.isFileExists(atPath: outFilePath) {
            FileManager.createFile(atPath: outFilePath)
        }
        
        //`FileHandle`的创建要求文件必须存在,`forUpdatingAtPath`读写
        guard let fileHandle = FileHandle(forWritingAtPath: outFilePath) else {
            logger.debug("failed to open file at \(outFilePath)")
            return false
        }
        
        guard let data = NSMutableData(capacity:1024) else {
            return false
        }
        
            //读取音频数据块并将其填充到给定的缓冲区
//            audioOutStream.read(NSMutableData, length: <#T##UInt#>)
//          填充到缓冲区的数据大小，0表示流结束
         var remainLenth = audioOutStream.read(data, length: 1024)
            while remainLenth > 0 {
                guard let data = NSMutableData(capacity:1024) else {
                    return false
                }
                remainLenth = audioOutStream.read(data, length: 1024)
                ZKTLog("remainLenth: \(remainLenth) \n dataStr: \(data)")
                if #available(iOS 13.4, *) {
                    let _ = try? fileHandle.seekToEnd()//移动至最后
                    try? fileHandle.write(contentsOf: data)
                } else {
                    //            Fallback on earlier versions
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data as Data)
                }
            }
//            ZKTLog("关闭---")
//            fileHandle.closeFile()
        return true
    }
    

    /*
     `SPXAudioOutputStream`为基类，
     `SPXPullAudioOutputStream`表示用于自定义音频输出的内存支持拉音频输出流
     **/
    
    // 执行语音合成使用拉音频输出流。
    
    /// 执行语音合成使用推音频输出流。
    public func startSynthesisToPushAudioOutputStream(outFilePath: String, synthesisConfig: MSSynthesisConfig) -> Bool {
        
        guard let speechConfiguration = self.speechConfig else {
            return false
        }
        
        guard let ssmlText = getSsmlText(model: synthesisConfig) else { return false }
        
        self.checkConfig()
        
        if !FileManager.isFileExists(atPath: outFilePath) {
            FileManager.createFile(atPath: outFilePath)
        }
        
        //`FileHandle`的创建要求文件必须存在,`forUpdatingAtPath`读写
        guard let fileHandle = FileHandle(forWritingAtPath: outFilePath) else {
            logger.debug("failed to open file at \(outFilePath)")
            return false
        }
        
        let audioOutStream = SPXPushAudioOutputStream { data in
            if #available(iOS 13.4, *) {
                let _ = try? fileHandle.seekToEnd()//移动至最后
                try? fileHandle.write(contentsOf: data)
            } else {
                //Fallback on earlier versions
                fileHandle.seekToEndOfFile()
                fileHandle.write(data as Data)
            }
            return UInt(data.count)
        } closeHandler: {
            fileHandle.closeFile()
        }

        if let audioOutStream {
            let audioconfig = try? SPXAudioConfiguration(streamOutput: audioOutStream)
            self.synthesizer = try? SPXSpeechSynthesizer(speechConfiguration: speechConfiguration, audioConfiguration: audioconfig)

            self.speakSsml(ssml: ssmlText)
        }
        
        return true
    }
}

//MARK: - 核心方法
extension MSSynthesisSpeech {
    
    public func stopSpeaking() {
        self.isUserStop = true
        DispatchQueue.global(qos: .userInitiated).async {
            try? self.synthesizer?.stopSpeaking()
            self.logger.debug("stopSpeaking")
        }
    }
    
    /// Analyze text and add text analysis callbacks
    func speakSsml(ssml: String) {
//        if ssml.isEmpty {
//            return
//        }
        addEventHandler()
        
        self.startSpeakTime = CFAbsoluteTimeGetCurrent()
        
        let _ = try? self.synthesizer?.speakSsml(ssml)
        
//        ZKTLog("speakSsml finish")
    }
    
    func addEventHandler() {
        
        synthesizer?.addSynthesisStartedEventHandler({ [weak self] synthesizer, args in
            let result: SPXSpeechSynthesisResult = args.result
            if result.reason == .synthesizingAudioStarted {
                guard let content = self?.retried.content else {
                    return
                }
                self?.delegate?.synthesisStarted?(content: content)
            }
        })
        
//        synthesizer?.addSynthesizingEventHandler({ [weak self] synthesizer, args in
//            guard let self else { return  }
//            let result: SPXSpeechSynthesisResult = args.result
//            if isSynthesizerFinish == false{
//                isSynthesizerFinish = true
//                startedEventHandler(result: result)
//            }
//        })
        synthesizer?.addSynthesisCompletedEventHandler({ [weak self] synthesizer, args in
//            ZKTLog("addSynthesisCompletedEventHandler\(args)")
            guard let self else { return }
//            delegate?.synthesisCompleted()
            synthesisCompleted(result: args.result)
        })
        
        synthesizer?.addSynthesisCanceledEventHandler({ [weak self]  synthesizer, args in
            guard let self else { return }
            guard isUserStop else {
//                delegate?.synthesisError(msg: "合成SDK报错，或因为网络")
                failCount += failCount + 1
                restartExecute(error: NSError(domain: "sy", code: -1,userInfo: ["msg":"合成SDK报错，或因为网络"]))
//                resetExecute(error: <#T##NSError#>)
                return
            }
            delegate?.synthesisCanceled?(args: args)
            logger.debug("addSynthesisCanceledEventHandler")
//            ZKTLog("addSynthesisCanceledEventHandler\(args.result)")
        })
        
        synthesizer?.addSynthesisWordBoundaryEventHandler({ [weak self] synthesizer, args in
            guard let self else { return }
            let wordBoundaryEventArgs: SPXSpeechSynthesisWordBoundaryEventArgs = args
            wordBoundarys.append(wordBoundaryEventArgs)
    
//            ZKTLog("addSynthesisWordBoundaryEventHandler\(wordBoundaryEventArgs.text)")
//            let playText = wordBoundarys.map { $0.text }.reduce("", +)
//            let floTotal = synthesisConfig?.contentFloat
//            let progress = Float(playText.count) / (floTotal ?? 1)
//            logger.debug("\(progress)")
            delegate?.wordBoundaried?(words: wordBoundarys)
//            ZKTLog("addSynthesisWordBoundaryEventHandler.wordBoundaryEventArgs.text:\(wordBoundaryEventArgs.text)、\naudioOffset：\(wordBoundaryEventArgs.audioOffset)、\nduration:\(wordBoundaryEventArgs.duration)、\nwordLength :\(wordBoundaryEventArgs.wordLength)、\nboundaryType: \(wordBoundaryEventArgs.boundaryType),\ntextOffset: \(wordBoundaryEventArgs.textOffset)")
        })
        synthesizer?.addVisemeReceivedEventHandler({ [weak self] synthesizer, args in
            guard let self else { return }
            delegate?.visemeReceived?(args: args)
            //            ZKTLog(args)
            //            ZKTLog("addVisemeReceivedEventHandler\(args)")
        })
        synthesizer?.addBookmarkReachedEventHandler({ [weak self] synthesizer, args in
            guard let self else { return }
            delegate?.bookmarkReached?(args: args)
            //            ZKTLog("addBookmarkReachedEventHandler\(args)")
        })
    }
}

/// 当前已经播放的文本
extension MSSynthesisSpeech {
    
//    func completedEventHandler() {
//        timer?.invalidate()
//        timer = nil
//        self.delegate?.synthesisCompletedEventHandler()
//        self.isPlaying = false
        //        self.play()
//    }
    
    func synthesisCompleted(result: SPXSpeechSynthesisResult) {
        //        _pro = 0.0
        
        let acquireResultTime = CFAbsoluteTimeGetCurrent()
        if #available(iOS 14.0, *) {
            logger.debug("语音合成完毕: \(acquireResultTime - self.startSpeakTime)")
        } else {
            // Fallback on earlier versions
            ZKTLog("合成可以播放")
        }
        
        guard let content = retried.content else {
            return
        }
        if let audioData = result.audioData {
            self.delegate?.synthesisCompleted(audioData: audioData, content: content, wordBoundarys: self.wordBoundarys)
        } else {
            self.delegate?.synthesisCompleted(audioData: nil, content: content, wordBoundarys: self.wordBoundarys)
        }
    }
}

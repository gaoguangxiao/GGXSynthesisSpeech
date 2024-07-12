//
//  PlayViewModel.swift
//  GGXSynthesisSpeech_Example
//
//  Created by 高广校 on 2024/7/5.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import GGXSynthesisSpeech
import PTDebugView
import MicrosoftCognitiveServicesSpeech
import SmartCodable

struct Config {
    static let sub = "13aeaa2db83748b2a1bde1af30d1d15e"
    static let region = "eastus"
}


class SynthesisSpeechManager: NSObject, ObservableObject {
    
    @PTLogger(category: "SynthesisSpeechManager")
    var logger
    
    var content = "这可能是由于视图的状态和UI更新之间的不一致性所致。为了解决这个问题，你可以采取以下几种方法"
    
    @Published var tprogress: Float = 0
    
    ///合成完毕的信息
    @Published var info: String = ""
    
    lazy var synthesisConfig: MSSynthesisConfig = {
        var model = MSSynthesisConfig()
        model.vocal = "zh-CN-XiaochenMultilingualNeural"
        model.rate = 0.75
        model.pitch = 1.2
        model.volume = 1
        model.path = "/1/2/m"
        model.content = content
        return model
    }()
    
    var ms: MSSynthesisSpeech?
    
    func play()  {
        tprogress = 0
        ms?.synthesisConfig = synthesisConfig
        ms?.startSynthesis(text: content)
    }
    
    func synthesisToFile()  {
        tprogress = 0

        //写入
        if let path = synthesisConfig.path {
            let outFilePath = FileManager.create(folder: folderName, path: "/file", fileExt: "wav")
            synthesisConfig.localFilePath = outFilePath
            let _ = try? ms?.startSynthesisToFile(outFilePath: outFilePath,synthesisConfig: synthesisConfig)
        } else {
            
        }
    }
    
    func handleSynthesisToPullAudioOutputStream()  {
        tprogress = 0
        synthesisConfig.path = "/stream"
        ms?.synthesisConfig = synthesisConfig
        if let path = synthesisConfig.path {
            let outFilePath = FileManager.create(folder: folderName, path: path, fileExt: "wav")
            synthesisConfig.localFilePath = outFilePath
            DispatchQueue.global().async {
                let _ =  self.ms?.startSynthesisToPullAudioOutputStream(outFilePath: outFilePath)
            }
        }
    }
    
    func handleSynthesisToPushAudioOutputStream()  {
        tprogress = 0
        synthesisConfig.path = "/pushstream"
        ms?.synthesisConfig = synthesisConfig
        if let path = synthesisConfig.path {
            let outFilePath = FileManager.create(folder: folderName, path: path, fileExt: "wav")
            synthesisConfig.localFilePath = outFilePath
            let _ =  ms?.startSynthesisToPushAudioOutputStream(outFilePath: outFilePath)
        }
        
    }
    
    func stop() {
        ms?.stopSpeaking()
    }
    
}

//NARK: life cycle
extension SynthesisSpeechManager {
    
    var folderName: String {
        "synthesizer"
    }
    
    func create() {
        ms = MSSynthesisSpeech(sub: Config.sub, region: Config.region)
        ms?.delegate = self
    }
    
    func destroy()  {
        ms = nil
    }
    
    func deleteFile() {
        FileManager.deleteFileByPath(synthesisConfig.path)
    }
    
    func deleteAllFile() {
        FileManager.deleteFileByPath()
    }
    
}

extension SynthesisSpeechManager: MSSynthesisSpeechProtocol {
    func synthesisCanceled(args: SPXSpeechSynthesisEventArgs) {
        ZKLog("停止: \(args.result.resultId)")
    }
    
    func synthesisCompleted() {
        
    }
    
    func synthesisStarted(audioData data: Data?, wordBoundarys: Array<SPXSpeechSynthesisWordBoundaryEventArgs>) {
        
        //业务获取到data
        let audioBase64 = data?.base64EncodedString()
        ZKLog("音频base64：\(audioBase64!)")
        //        if let path = self.synthesisConfig.path {
        //            if let outFilePath = self.create(folder: self.folderName, path: path, fileExt: "wav").toFileUrl {
        //                ZKTLog("输出音频路径：\(outFilePath)")
        //                try? data?.write(to: outFilePath)
        //            }
        //        }
        
        var jsonArrays: Array<Dictionary<String,Any>> = []
        wordBoundarys.forEach { wordBoundaryEventArgs in
            var wBoundary: Dictionary<String,Any> = [:]
            wBoundary["resultId"] = wordBoundaryEventArgs.resultId
            wBoundary["audioOffset"] = wordBoundaryEventArgs.audioOffset
            wBoundary["duration"] = wordBoundaryEventArgs.duration
            wBoundary["textOffset"] = wordBoundaryEventArgs.textOffset
            wBoundary["wordLength"] = wordBoundaryEventArgs.wordLength
            wBoundary["text"] = wordBoundaryEventArgs.text
            wBoundary["boundaryType"] = wordBoundaryEventArgs.boundaryType.rawValueStr
            jsonArrays.append(wBoundary)
        }
        
        if let jsonString = jsonArrays.toJSONString() {
            logger.info("字边界: \(jsonString)")
            Task {
                await MainActor.run {
                    info = "字边界:\(jsonString)\n本地路径：\(synthesisConfig.localFilePath)"
                }
            }
        }
    }
    
    //得到合成分析结果
    func synthesisCompletedEventHandler() {
        //        timer?.invalidate()
        //        timer = nil
        //        self.play()
    }
    
    func synthesisCompletedEventHandler(progress: Float) {
        tprogress = progress
    }
    
    func synthesisPlayEventHandler(text: String) {
        //        ZKLog("播放内容：\(text)")
        //已经播放的文本
        //        playText = text
    }
}

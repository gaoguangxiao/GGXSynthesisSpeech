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

struct Config {
    static let sub = "13aeaa2db83748b2a1bde1af30d1d15e"
    static let region = "eastus"
}


class PlayViewModel:NSObject, ObservableObject {
    
    var content = "这可能是由于视图的状态和UI更新之间的不一致性所致。为了解决这个问题，你可以采取以下几种方法"
    
    @Published var tprogress: Double = 0
    
    @Published var playText: String = ""
        
    lazy var ms: MSSynthesisSpeech = {
        var model = MSSynthesisConfig()
        model.vocal = "zh-CN-XiaochenMultilingualNeural"
        model.rate = 0.75
        model.pitch = 1.2
        model.volume = 1
        let ms = MSSynthesisSpeech(sub: Config.sub, region: Config.region)
        ms.synthesisConfig = model
        
        ms.delegate = self
        return ms
    }()
    
    func play()  {
        //            model.content = "今天天气怎么样"
        ms.startSynthesis(text: content)
        
//        if let view = UIApplication.rootWindow {
            //            if let view = UIApplication.rootWindow {
            //                view.makeToastActivity(.center)
            //            }
//        }
    }
    
}

extension PlayViewModel: MSSynthesisSpeechProtocol {
    func synthesisCompletedEventHandler() {
        //        timer?.invalidate()
        //        timer = nil
        
        //        self.play()
    }
    
    func synthesisCompletedEventHandler(progress: Double) {
        tprogress = progress
    }
    
    func synthesisPlayEventHandler(text: String) {
        ZKLog("播放内容：\(text)")
        
        //已经播放的文本
        playText = text
    }
    
    
    func synthesisStartedEventHandler() {
        
    }
}

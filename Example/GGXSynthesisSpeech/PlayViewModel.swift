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

class PlayViewModel:NSObject, ObservableObject {
    
    var content = "这可能是由于视图的状态和UI更新之间的不一致性所致。为了解决这个问题，你可以采取以下几种方法"
    
    var _pro: Double = 0.0
    
    @Published var progress: Double = 0
    
    @Published var playText: String?
    
    var timer: Timer?
    
    lazy var ms: MSSynthesisSpeech = {
        var model = MSSynthesisConfig()
        model.vocal = "zh-CN-XiaochenMultilingualNeural"
        model.rate = 0.75
        model.pitch = 1.2
        model.volume = 1
        let ms = MSSynthesisSpeech.share
        ms.synthesisConfig = model
        
        ms.delegate = self
        return ms
    }()
    
    func play()  {
    //            model.content = "今天天气怎么样"
        ms.startSynthesis(text: content)
    }
    
    func updatePlayProgress() {
        _pro = _pro + 0.2
        
        Task {
            await MainActor.run {
                progress = _pro
            }
        }
        ZKLog("播放进度：\(progress)")
    }
}

extension PlayViewModel: MSSynthesisSpeechProtocol {
    func synthesisCompletedEventHandler() {
        timer?.invalidate()
        timer = nil
        
        self.play()
    }
    
    func synthesisPlayEventHandler(text: String) {
        ZKLog("播放内容：\(text)")
    }
    
    func synthesisStartedEventHandler() {
        _pro = 0.0
        
        Task {
            await MainActor.run {
                timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
                    self?.updatePlayProgress()
                }
            }
        }
        
//        if let timer {
//            RunLoop.current.add(timer, forMode: .commonModes)
//            RunLoop.current.run()
//        }
    }
}

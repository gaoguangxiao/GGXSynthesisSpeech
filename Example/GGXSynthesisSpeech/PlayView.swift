//
//  PlayView.swift
//  GGXSynthesisSpeech_Example
//
//  Created by 高广校 on 2024/7/3.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import SwiftUI
import GGXSynthesisSpeech

struct PlayView: View {
    
   
    
    @StateObject var viewModel = PlayViewModel()
    
    var body: some View {
        
        VStack(spacing: 10, content: {
 
            Text("播放的内容：\(viewModel.content)")
            
            Button {
                viewModel.play()
            } label: {
                Text("播放")
            }
            
            Text("播放进度：\(viewModel.progress)")
            
            Text("当前播放的文本：\(viewModel.playText)")
            
        })

    }
}

#Preview {
    PlayView()
}

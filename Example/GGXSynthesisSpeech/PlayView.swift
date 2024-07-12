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
    
    
    
    @StateObject var viewModel = SynthesisSpeechManager()
    
    var body: some View {
        
        VStack(spacing: 10, content: {
            
            Spacer()
            
            Form {
                Text("\(viewModel.content)")
                
                Text("合成进度：\(viewModel.tprogress)")
                
                Section {
                    
                    Button {
                        viewModel.create()
                    } label: {
                        Text("初始化")
                    }
                    
                    Button {
                        viewModel.destroy()
                    } label: {
                        Text("释放")
                    }
                    
                    Button {
                        viewModel.deleteFile()
                    } label: {
                        Text("删除文件")
                    }
                    
                    Button {
                        viewModel.deleteAllFile()
                    } label: {
                        Text("删除所有文件夹")
                    }
                }
                
                Section {
                    Button {
                        viewModel.play()
                    } label: {
                        Text("合成-内置播放")
                    }
                    
                    Button {
                        viewModel.synthesisToFile()
                    } label: {
                        Text("合成-输出合成路径")
                    }
                    
                    Button {
                        viewModel.handleSynthesisToPullAudioOutputStream()
                    } label: {
                        Text("合成-音频流")
                    }
                    
                    Button {
                        viewModel.handleSynthesisToPushAudioOutputStream()
                    } label: { Text("合成-推音频流") }
                    
                    Button {
                        viewModel.stop()
                    } label: {
                        Text("停止合成")
                    }
                    
                    Text("info文本：\(viewModel.info)")
                }
            }
            
            
            //            Text("播放进度：\(viewModel.tprogress)")
            
            
            
        })
        .onAppear(perform: {
            viewModel.create()
        })
        
    }
}

#Preview {
    PlayView()
}

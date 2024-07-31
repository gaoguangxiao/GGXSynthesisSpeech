//
//  WordBoundaryEventArgs+Extensions.swift
//  GGXSynthesisSpeech
//
//  Created by 高广校 on 2024/7/8.
//

import Foundation
import MicrosoftCognitiveServicesSpeech

//扩展其OC枚举，实现原始值
extension SPXSpeechSynthesisBoundaryType {

    public var rawValueStr: String {
        switch self {
        case .word : "Word"
        case .punctuation : "Punctuation"
        case .sentence: "Sentence"
        @unknown case _: "Unknown" //与`@unknown default`一样
        }
    }
    
}

extension SPXSpeechSynthesisWordBoundaryEventArgs {
    
//    public var boundaryTypeStr: String {
        /*
         `boundaryType`是以`NS_ENUM`关键字声明的枚举，此枚举叫非冻结枚举，意味着将来可以添加新的`case`。
         而用`NS_CLOSED_ENUM`关键字声明的枚举叫冻结枚举，以后考虑增加`case`。swift用户中定义的都是冻结枚举。
         
         对于非冻结枚举来说，使用`swift`语句需要增加`@unknown default`：来做保底的处理，因为非冻结枚举未来还会继续增加case，系统希望你能尽可能处理这种变化情况。
         
         对于冻结枚举来说，未来不打算使用增加`case`，所以不需要使用`@unknown default:`处理
         
         `@unknown default:`也表示匹配其他任何值，如果直接使用default兜底，那么当版本有新增枚举时，可能导致异常情况
         **/
//        switch boundaryType {
//        case .word : "word"
//        case .punctuation : "punctuation"
//        case .sentence: "sentence"
//        @unknown case _: "unknown" //与`@unknown default`一样
//        default: "unknown"
//        @unknown default: "unknown"
//            fatalError()
//        }
//    }
}

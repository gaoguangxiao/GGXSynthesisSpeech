//
//  MultiRequestProgressProtocol.swift
//  GGXSynthesisSpeech
//
//  Created by 高广校 on 2024/7/19.
//

import Foundation

//响应失败时，可重试多次
public protocol ResponseFailRetriedable {
    
    //可供重新请求的模型-业务维护
    associatedtype T
    
    /// 每次请求的ID
    var retriedID: String { set get }
    
    // 失败的次数
    var failCount: Int {set get}
    
    // 可失败的次数,不计算首次
    var allFailCount: Int {set get}
    
    ///存储可再次执行的数据
    var retried: T {set get}
    
    //执行
    func execute()
    
    //业务中-需要重试的地方插入，需要键入失败的原因，失败数+1
    func restartExecute(error: NSError)
    
    //完成重试-仍旧失败，如果成功，走业务方法
    func completeRetried(error: NSError)
}

extension ResponseFailRetriedable {
    
    public func restartExecute(error: NSError) {
        guard failCount < allFailCount else {
            completeRetried(error: error)
            return
        }
        execute()
    }
    
}

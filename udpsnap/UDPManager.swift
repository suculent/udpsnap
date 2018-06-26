//
//  UDPManager.swift
//  udpsnap
//
//  Created by Matěj Sychra on 24/06/2018.
//  Copyright © 2018 THiNX. All rights reserved.
//

import Foundation

// This class is responsible for listening to UDP socket and messaging betweeen app and rotary pad device.

class UDPManager: NSObject {
    
    let port = 58266
    
    fileprivate var messageDelegate: UDPManagerProtocol!
    
    public var server: UDPServer! // should be private
    
    init(delegate: UDPManagerProtocol) {
        super.init()
        self.messageDelegate = delegate
        
        self.server = UDPServer(port: port, delegate: self)
        print("Swift Echo Server Sample")
        print("Connect with a command line window by entering 'telnet ::1 \(port)'")
        
        DispatchQueue.global(qos: .background).async {
            print("This is run on the background queue")            
            self.server.run()
        }
    }
    

    //
    // Device commands (optinal, to be done...)
    //
    
    /** Step rotary table +/-. */
    public func step(_: Int) {
        server.send(string: "STEP\(step)\n")
    }
    
    /** Reset rotary table back to step zero. */
    public func rewind() {
        server.send(string: "REWIND\n")
    }
    
    /** Set autorotation interval. */
    public func interval(seconds: Int) {
        server.send(string: "INT:\(seconds)\n")
    }
    
    /** Set autorotation jitter. */
    public func jitter(seconds: Int) {
        server.send(string: "JIT:\(seconds)\n")
    }
    
    /** Start autorotation. */
    public func start() {
        server.send(string: "START\n")
    }
    
    /** Stop autorotation. */
    public func stop() {
        server.send(string: "STOP\n")
    }
}

extension UDPManager: UDPServerDelegate {
    func receive(message: String) {
        DispatchQueue.main.async {
            if let d = self.messageDelegate {
                let indexString = message.replacingOccurrences(of: "P:", with: "").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "")
                let index = Int(indexString)!
                d.captureWhenCompleted(step: index)
            }
        }
    }
}

protocol UDPManagerProtocol {
    func captureWhenCompleted(step: Int)
}

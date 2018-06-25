//
//  UDPServer.swift
//  CocoaAsyncSocket
//
//  Created by Matěj Sychra on 24/06/2018.
//

import Foundation
import Socket
import Dispatch


/** Originally an EchoServer, should direct messages up to manager */

class UDPServer: NSObject {
    
    static let quitCommand: String = "QUIT"
    static let shutdownCommand: String = "SHUTDOWN"
    static let photoCommand: String = "P:"
    static let bufferSize = 4096
    
    let port: Int
    var listenSocket: Socket? = nil
    var continueRunning = true
    var connectedSockets = [Int32: Socket]()
    let socketLockQueue = DispatchQueue(label: "com.thinx.socketLockQueue")
    
    var delegate: UDPServerDelegate?
    
    init(port: Int, delegate: UDPServerDelegate) {
        self.port = port
        self.delegate = delegate
    }
    
    deinit {
        // Close all open sockets...
        for socket in connectedSockets.values {
            socket.close()
        }
        self.listenSocket?.close()
    }
    
    func queryForClient() {
        let service = NetService(domain: "local.", type: "_rotocam._udp", name: "rotocam", port: Int32(self.port))
        service.publish()
        print("Publishing netservice _rotocam._udp")
        
        let browser = NetServiceBrowser()
        browser.searchForServices(ofType: "_rotopad._udp.", inDomain: "local.")
        browser.delegate = self
        withExtendedLifetime((browser, delegate)) {
            RunLoop.main.run()
        }
    }
    
    func run() {
        
        queryForClient()
        
        let queue = DispatchQueue.global(qos: .background)
        
        queue.async(execute: { [unowned self] in
            
            do {
                // Create an IPV6 socket...
                try self.listenSocket = Socket.create(family: .inet)
                
                guard let socket = self.listenSocket else {
                    
                    print("Unable to unwrap socket...")
                    return
                }
                
                try socket.listen(on: self.port)
                
                print("Listening on port: \(socket.listeningPort)")
                
                repeat {
                    let newSocket = try socket.acceptClientConnection()
                    
                    print("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                    print("Socket Signature: \(newSocket.signature!.description)")
                    
                    self.addNewConnection(socket: newSocket)
                    
                } while self.continueRunning
                
            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error...")
                    return
                }
                
                if self.continueRunning {
                    
                    print("Error reported:\n \(socketError.description)")
                    
                }
            }
        })
        
    }
    
    func addNewConnection(socket: Socket) {
        
        // Add the new socket to the list of connected sockets...
        socketLockQueue.sync { [unowned self, socket] in
            self.connectedSockets[socket.socketfd] = socket
        }
        
        // Get the global concurrent queue...
        let queue = DispatchQueue.global(qos: .background)
        
        // Create the run loop work item and dispatch to the default priority global queue...
        queue.async { [unowned self, socket] in
            
            var shouldKeepRunning = true
            
            var readData = Data(capacity: UDPServer.bufferSize)
            
            do {
                // Write the welcome string...
                try socket.write(from: "Hello, type 'QUIT' to end session\nor 'SHUTDOWN' to stop server.\n")
                
                repeat {
                    let bytesRead = try socket.read(into: &readData)
                    
                    if bytesRead > 0 {
                        
                        guard let response = String(data: readData, encoding: .utf8) else {
                            print("Error decoding response...")
                            readData.count = 0
                            break
                        }
                        
                        print("Server received from connection at \(socket.remoteHostname):\(socket.remotePort): \(response) ")
                        
                        // Photo capture command
                        if response.hasPrefix(UDPServer.photoCommand) {
                            if let d = self.delegate {
                                d.receive(message: response)
                            }
                        }
                    }
                    
                    if bytesRead == 0 {
                        shouldKeepRunning = false
                        break
                    }
                    
                    readData.count = 0
                    
                } while shouldKeepRunning
                
                print("Socket: \(socket.remoteHostname):\(socket.remotePort) closed...")
                socket.close()
                
                self.socketLockQueue.sync { [unowned self, socket] in
                    self.connectedSockets[socket.socketfd] = nil
                }
                
            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                    return
                }
                if self.continueRunning {
                    print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
                }
            }
        }
    }
    
    /* Should be called on app termination. Wahaaa... */
    func shutdownServer() {
        print("\nShutdown in progress...")
        continueRunning = false
        
        // Close all open sockets...
        for socket in connectedSockets.values {
            socket.close()
        }
        
        listenSocket?.close()
    }
    
    public func broadcast(string: String) {
        if let socket = self.listenSocket {
            do {
                try socket.write(from: string)
            } catch let error {
                print(error)
            }
        }
    }
}

extension UDPServer: NetServiceBrowserDelegate {
    
    @objc public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("NetServiceBrowser did find service %s", service.domain)
        if moreComing {
            print("Warning, there are more services coming! Unexpected environment may result in failed communication between rotary stand and the app.")
        }
        
    }
    
}

protocol UDPServerDelegate {
    func receive(message: String)
}

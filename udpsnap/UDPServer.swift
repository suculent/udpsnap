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
    
    var browser: NetServiceBrowser?
    var service: NetService?
    
    var clientAddress: Socket.Address?
    
    init(port: Int, delegate: UDPServerDelegate) {
        self.port = port
        self.delegate = delegate
        super.init()
        self.initNetService()
    }
    
    deinit {
        // Close all open sockets...
        for socket in connectedSockets.values {
            socket.close()
        }
        self.listenSocket?.close()
    }
    
    func initNetService() {
        
        // Publish a netservice the device will connect to...
        let serviceType = "_camera._udp."
        service = NetService(domain: "local.", type: serviceType, name: "rotocam", port: Int32(self.port))
        service!.schedule(in: .main, forMode: .defaultRunLoopMode)
        service!.delegate = self
        service!.publish(options: []) // listener is TCP only!

        print("Publishing netservice \(serviceType)")        
        browser = NetServiceBrowser()
        browser!.searchForServices(ofType: "_rotopad._udp", inDomain: "local.")
        browser!.delegate = self
        browser!.schedule(in: .main, forMode: .defaultRunLoopMode)
    }
    
    // Will be used to send commands to device, untested
    public func send(string: String) {
        do {
            try self.listenSocket?.write(from: string, to: clientAddress!)
        }  catch let error {
            guard let socketError = error as? Socket.Error else {
                print("Unexpected error...")
                return
            }
            
            if self.continueRunning {
                
                print("Send Error reported:\n \(socketError.description)")
                
            }
        }
    }
    
    func run() {
        
        let queue = DispatchQueue.global(qos: .background)
        
        queue.async(execute: { [unowned self] in
            
            do {
                // Create an IPV4 UDP socket...
                try self.listenSocket = Socket.create(family: .inet, type: .datagram, proto: .udp)
                
                guard let socket = self.listenSocket else {
                    print("Unable to unwrap socket...")
                    return
                }
                
                print("Trying to listen on port: \(self.port)")
                
                var message = NSMutableData(capacity: UDPServer.bufferSize)
                let sockinfo = try socket.listen(forMessage: message!, on: self.port, maxBacklogSize: Socket.SOCKET_DEFAULT_MAX_BACKLOG)
                
                self.clientAddress = sockinfo.address
                
                print("Listening on port: \(socket.listeningPort)")
                
                repeat {
                    let datagram = try socket.readDatagram(into: message!)
                    
                    if datagram.bytesRead > 0 {
                        
                        let command = String(data: message! as Data, encoding: String.Encoding.ascii)
                            
                        // Photo capture command
                        if (command?.hasPrefix(UDPServer.photoCommand))! {
                            if let d = self.delegate {
                                d.receive(message: command!)
                            }
                        }
                        
                        print()
                        
                        // Cleanup the buffer after use.
                        message = NSMutableData(capacity: UDPServer.bufferSize)
                    }
                    
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

extension UDPServer: NetServiceDelegate {
    func netServiceWillPublish(_ sender: NetService) {
        print("Will publish: \(sender)")
    }
    
    func netServiceDidPublish(_ sender: NetService) {
        print("Did publish: \(sender)")
    }
    
    private func netService(_ sender: NetService, didNotPublish error: Error) {
        print("Did not publish: \(sender), because: \(error)")
    }
    
    func netServiceDidStop(_ sender: NetService) {
        print("Did stop: \(sender)")
    }
    
    func netService(_ sender: NetService, didAcceptConnectionWith socket: Socket) {
        print("Did accept connection: \(sender), from: \(socket.remoteHostname)")
        //print(try! socket.readString() ?? "")
        //try! socket.write(from: "HTTP/1.1 200 OK\r\nContent-Length: 13\r\n\r\nHello, world!")
        //socket.close()
    }
}

extension UDPServer: NetServiceBrowserDelegate {
    
    @objc public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("NetServiceBrowser did find service \(service.name)")
        
        if !moreComing {
            service.resolve(withTimeout: 10)
        } else {
            print("Warning, there are more services coming! Unexpected environment may result in failed communication between rotary stand and the app.")
        }
        
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("Resolve service at address \(sender.addresses![0])");        
        NotificationCenter.default.post(name: NSNotification.Name("Resolved"), object: nil)
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("Search for rotopad stopped.")
    }
    
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("Will search: \(browser)")
    }
    
    private func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch error: Error) {
        print("Did not search: \(error)")
    }
    
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("Did remove: \(service)")
    }
    
}

protocol UDPServerDelegate {
    func receive(message: String)
}


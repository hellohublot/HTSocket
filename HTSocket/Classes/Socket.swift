//
//  Socket.swift
//  Socket
//
//  Created by hublot on 2018/1/17.
//  Copyright © 2018年 hublot. All rights reserved.
//

import Foundation
import Darwin

open class Socket: NSObject {
	
    public let fd: Int32
	
    public let address: Address
	
	open var socketQueue = DispatchQueue.init(label: "com.hublot.socket.socketQueue")
	
    public static var callBackQueue = DispatchQueue.init(label: "com.hublot.socket.callBackQueue")
	
	open var socketSource: DispatchSourceRead?
	
	deinit {
		
	}
	
	open func close() {
        socketSource?.cancel()
		Darwin.close(self.fd)
		Darwin.shutdown(self.fd, SHUT_RDWR)
	}
	
	public init(_ translation: Int32, _ address: Address = Address(), _ fd: Int32 = 0) {
		let type = address.type
		self.address = address
		self.fd = (fd == 0) ? Darwin.socket(type, translation, 0) : fd
		super.init()
		setOption(SO_NOSIGPIPE, 1)
	}
	
	@discardableResult
	open func bind() -> Bool {
		return bind(address)
	}
	
	@discardableResult
	open func bind(_ address: Address) -> Bool {
		
		setOption(SO_REUSEADDR, 1)
		
		let result = Darwin.bind(fd, address.info.pointee.ai_addr, address.info.pointee.ai_addrlen)
		let issuccess = result >= 0
		return issuccess
	}
	
	func createSource(handler: DispatchSourceProtocol.DispatchSourceHandler?) {
		socketSource?.cancel()
		socketSource = DispatchSource.makeReadSource(fileDescriptor: fd, queue: socketQueue)
		socketSource?.setEventHandler(handler: handler)
		socketSource?.resume()
	}
	
	open func setOption(_ key: Int32, _ value: Int32) {
		var point = value
		setsockopt(fd, SOL_SOCKET, key, &point, socklen_t(MemoryLayout.size(ofValue: value)))
	}
	
	open func option(_ key: Int32) -> Any {
		var value = 0
		var size = socklen_t(MemoryLayout.size(ofValue: value))
		getsockopt(fd, SOL_SOCKET, key, &value, &size)
		return value
	}
	
}

//
//  IO.swift
//  CocoaLumberjack
//
//  Created by hublot on 2018/2/1.
//

public let readbuffersize = 65536

public func readsome(_ somesize: Int = readbuffersize, handler: ((_: UnsafeMutablePointer<UInt8>, _: Int) -> Int)) -> (Data, Bool) {
	var data = Data()
	var readbuffer = [UInt8].init(repeating: 0, count: somesize)
	let readsize = handler(&readbuffer, somesize)
	data.append(readbuffer, count: max(0, readsize))
	
	let loopRead = readsize == somesize
	return (data, loopRead)
}

public func readall(_ handler: ((_: UnsafeMutablePointer<UInt8>, _: Int) -> Int)) -> Data {
	var data = Data()
	let buffersize = readbuffersize
	var readbuffer = [UInt8].init(repeating: 0, count: buffersize)
	var length = 0
	repeat {
		length = handler(&readbuffer, buffersize)
		data.append(readbuffer, count: max(0, length))
	} while (length == buffersize)
	return data
}

extension TCP {
	
	func connectSource(_ address: Address, _ complete: CompleteHandler = nil) {
		let result = Darwin.connect(self.fd, address.info.pointee.ai_addr, address.info.pointee.ai_addrlen)
		let issuccess = result >= 0
		if issuccess {
			self.createReadSource()
			state = .connected
		}
		type(of: self).callBackQueue.async {
			complete?(issuccess, self)
		}
	}
	
	func acceptSource() {
		var sockaddress = sockaddr()
		var addresssize = socklen_t(MemoryLayout.size(ofValue: sockaddress))
		let result = Darwin.accept(fd, &sockaddress, &addresssize)
		let address = Address.init(sockaddress, addresssize)
		let client = TCP(address, result)
		client.delegate = delegate
		var clientState: State = .connected
		if case .willtls(let tls) = state {
			clientState = .willtls(tls: tls)
		}
		client.socketQueue.async {
			client.state = clientState
		}
		client.createReadSource()
		type(of: self).callBackQueue.async {
			self.delegate?.didAccept(server: self, client: client)
		}
	}
	
	func writeSource(_ data: Data, _ complete: CompleteHandler = nil) {
		let byte = [UInt8](data)
		let result: Int = {
			var result: Int
			if case .didtls(let context) = state {
				var process = 0
				result = SSLWrite(context, byte, byte.count, &process) == noErr ? 1 : 0
			} else {
				result = Darwin.write(fd, byte, byte.count)
			}
			return result
		}()
		let issuccess = result >= 0
		type(of: self).callBackQueue.async {
			complete?(issuccess, self)
		}
	}
	
	func readSource() {
		let (data, loopRead): (Data, Bool) = {
			var data: Data
			var loopRead = false
			if case .didtls(let context) = state {
				(data, loopRead) = readsome(handler: { (readbuffer, buffersize) -> Int in
					var length = 0
					var result = errno
					repeat {
						result = SSLRead(context, readbuffer, buffersize, &length)
					} while (result == errSSLWouldBlock && length <= 0)
					return length
				})
			} else {
				(data, loopRead) = readsome(handler: { (readbuffer, buffersize) -> Int in
					return read(fd, readbuffer, buffersize)
				})
			}
			return (data, loopRead)
		}()
		type(of: self).callBackQueue.async {
			self.delegate?.didRead(socket: self, data: data)
		}
		if data.count <= 0 {
			close()
		} else if loopRead {
			readSource()
		}
	}

}

extension UDP {
	
	func writeSource(_ data: Data, to address: Address, _ complete: CompleteHandler = nil) {
		let byte = [UInt8](data)
		let result: Int = {
			let result = sendto(fd, byte, byte.count, 0, address.info.pointee.ai_addr, address.info.pointee.ai_addrlen)
			return result
		}()
		let issuccess = result >= 0
		type(of: self).callBackQueue.async {
			complete?(issuccess, self)
		}
	}
	
	func readSource() {
		var sockaddress = sockaddr()
		var addresssize = socklen_t(MemoryLayout.size(ofValue: sockaddress))
		let data = readall { (readbuffer, buffersize) -> Int in
			return recvfrom(fd, readbuffer, buffersize, 0, &sockaddress, &addresssize)
		}
		let address = Address.init(sockaddress, addresssize)

		if data.count <= 0 {
			close()
		}
		type(of: self).callBackQueue.async {
			self.delegate?.didRead(socket: self, data: data, sendFrom: address)
		}
	}

}

//
//  UDP.swift
//  HTSocket
//
//  Created by hublot on 2018/2/1.
//

public protocol UDPDelegate: class {
	
	func didRead(socket: UDP, data: Data, sendFrom address: Address)
	
}

open class UDP: Socket {
	
	open weak var delegate: UDPDelegate?
	
	public typealias CompleteHandler = ((_: Bool, _ socket: UDP) -> Void)?

    deinit {

    }
	
	open override func close() {
		socketQueue.async {
			super.close()
		}
	}
	
	public convenience init(_ address: Address = Address()) {
		self.init(address, 0)
	}
	
	public init(_ address: Address = Address(), _ fd: Int32 = 0) {
		super.init(SOCK_DGRAM, address, fd)
		createReadSource()
	}
	
	open func write(_ data: Data, to address: Address, _ complete: CompleteHandler = nil) {
		socketQueue.async { [weak self] in
            self?.writeSource(data, to: address, complete)
		}
	}
	
	func createReadSource() {
		createSource { [weak self] in
			self?.readSource()
		}
	}
	
}


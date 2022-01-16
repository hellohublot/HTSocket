//
//  TCP.swift
//  HTSocket
//
//  Created by hublot on 2018/2/1.
//

public protocol TCPDelegate: class {
	
	func didAccept(server: TCP, client: TCP)
	
	func didRead(socket: TCP, data: Data)
	
}

public extension TCPDelegate {
	
	func didAccept(server: TCP, client: TCP) { }
	
	func didRead(socket: TCP, data: Data) { }
	
}


open class TCP: Socket {
	
	public enum State {
		case create
		case listened(count: Int32)
		case connected
		case willtls(tls: TLS)
		case didtls(context: SSLContext)
		case close
	}
	
	open var state: State
	
	open weak var delegate: TCPDelegate?
	
	public typealias CompleteHandler = ((_: Bool, _ socket: TCP) -> Void)?
	
	deinit {
		closeConnection()
	}
	
	open override func close() {
		socketQueue.async {
			switch self.state {
			case .close:
				return
			default:
				break
			}
			self.closeConnection()
			super.close()
			self.state = .close
		}
	}
	
	public func closeConnection() {
		if case .didtls(let context) = self.state {
			SSLClose(context)
			var connection: UnsafeRawPointer?
			SSLGetConnection(context, &connection)
            connection?.deallocate()
//			connection?.deallocate(bytes: MemoryLayout.stride(ofValue: self.fd), alignedTo: MemoryLayout.alignment(ofValue: self.fd))
			SSLSetConnection(context, nil)
		}
	}
	
	public convenience init(_ address: Address = Address()) {
		self.init(address, 0)
	}
	
	public init(_ address: Address = Address(), _ fd: Int32 = 0) {
		self.state = .create
		super.init(SOCK_STREAM, address, fd)
	}
	
	
	@discardableResult
	open func listen(_ count: Int32) -> Bool {
		let result = Darwin.listen(fd, count)
		let issuccess = result >= 0
		createAcceptSource()
		socketQueue.async {
			guard case .create = self.state else {
				return
			}
			self.state = .listened(count: count)
		}
		return issuccess
	}
	
	open func connect(_ complete: CompleteHandler = nil) {
		connect(address, complete)
	}
	
	open func connect(_ address: Address, _ complete: CompleteHandler = nil) {
		socketQueue.async { [weak self] in
			switch self?.state {
			case .create?:
				break
			default:
				return
			}
			self?.connectSource(address, complete)
		}
	}
	
	fileprivate func createAcceptSource() {
		createSource { [weak self] in
			switch self?.state {
			case .listened?, .willtls?:
				break
			default:
				return
			}
			self?.acceptSource()
		}
	}
	
	open func write(_ data: Data, _ complete: CompleteHandler = nil) {
		socketQueue.async { [weak self] in
			switch self?.state {
			case .connected?, .willtls?, .didtls?:
				break
			default:
				return
			}
			self?.writeSource(data, complete)
		}
	}
	
	func createReadSource() {
		createSource { [weak self] in
			switch self?.state {
			case .connected?, .didtls?:
				break
			case .willtls?:
				if let selfobject = self {
					TLS.hand(client: selfobject)
				}
				return
			default:
				return
			}
			self?.readSource()
		}
	}
	
}


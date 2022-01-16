//
//  WebProxy.swift
//  HTSocket-iOS
//
//  Created by hublot on 2018/2/1.
//

public struct Web {
	
	public static let kSeparator = "\r\n"
	
	public static let kContentSeparator = kSeparator + kSeparator
	
	public static let kSpace = " "
	
	public static let kStringDefault = ""
	
	public static let kSay = ":"
	
	public static let kSaySpace = kSay + kSpace
	
	public static let kHostPortPattern = "[\\w-]+[\\.]+[\\w]+[^?#/]+"
	
	public static let kDefaultPort: UInt16 = 80
	
	public static let kTLSDefaultPort: UInt16 = 443
	
	public static let kHeaderHostKey = "Host"
	
	public static let kTLSRequestMethod = "CONNECT"
	
	public static let kTLSProxyEstablish = "200 Connection Established\r\n\r\n"
	
	public static let kURLHTTPString = "http" + kSay + kURLPIEString + kURLPIEString
	
	public static let kURLHTTPSString = "https" + kSay + kURLPIEString + kURLPIEString
	
	public static let kURLPIEString = "/"
	
	public static let kDoubleDout = "\""
	
}

public struct TLSPair {
	public let clienttls: TLS
	public let remotetls: TLS
	public init(clienttls: TLS, remotetls: TLS) {
		self.clienttls = clienttls
		self.remotetls = remotetls
	}
}

public protocol WebProxyManager: class {
	
	func createConnectionIndex(address: Address, connectionIndex: Int)
	
	func clientRead(data: Data, isheaderMessage: Bool, host: String, connectionIndex: Int) -> Data
	
	func parseResult(parse: Parse.RequestParse, connectionIndex: Int) -> Parse.RequestParse
	
	func remoteRead(data: Data, isheaderMessage: Bool, host: String, requestData: Data, connectionIndex: Int) -> Data
	
	func tlsHandShakeFromHost(_ host: String, connectionIndex: Int) -> TLSPair?
	
	func clientHandShakeResult(_ host: String, _ success: Bool, connectionIndex: Int)
	
	func remoteHandShakeResult(_ host: String,  _ success: Bool, connectionIndex: Int)
	
	func closeConnection(connectionIndex: Int)
	
}

public extension WebProxyManager {
	
	func createConnectionIndex(address: Address, connectionIndex: Int) {
		
	}
	
	func clientRead(data: Data, isheaderMessage: Bool, host: String, connectionIndex: Int) -> Data {
		return data
	}
	
	func parseResult(parse: Parse.RequestParse, connectionIndex: Int) -> Parse.RequestParse {
		return parse
	}
	
	func remoteRead(data: Data, isheaderMessage: Bool, host: String, requestData: Data, connectionIndex: Int) -> Data {
		return data
	}
	
	func tlsHandShakeFromHost(_ host: String, connectionIndex: Int) -> TLSPair? {
		return nil
	}
	
	func clientHandShakeResult(_ host: String, _ success: Bool, connectionIndex: Int) {
		
	}
	
	func remoteHandShakeResult(_ host: String,  _ success: Bool, connectionIndex: Int) {
		
	}
	
	func closeConnection(connectionIndex: Int) {
		
	}
	
}

open class Connection: NSObject, TCPDelegate {
	
	public enum State {
		case createclient
		case requesthalf(data: Data)
		case readyforward(parseread: Bool, host: String, lastRequest: Data?, lastisremote: Bool)
	}
	
	open var client: TCP
	
	open var remote: TCP?
	
	open var state: State
	
	open var connectionIndex: Int
	
	static var connectionCount = 0
	
	init(_ client: TCP) {
		let selfclass = type(of: self)
		self.connectionIndex = selfclass.connectionCount
		selfclass.connectionCount += 1
		self.client = client
		self.state = .createclient
	}
	
}

public struct Parse {
	
	public enum RequestParse {
		case half(data: Data)
		case success(data: Data, main: [String], header: [[String: String]], body: Data, host: String, port: UInt16, istls: Bool, iftlsReply: Data)
		case fail(data: Data)
	}
	
	public static func parse(_ data: Data) -> RequestParse {
		
		let tempmessage = String.init(data: data, encoding: .ascii)
		guard let message = tempmessage, message.count > 0 else {
			return .fail(data: data)
		}
		
		let tempspacerange = message.range(of: Web.kSpace)
		let firstspaceallowd = 10
		guard let spacerange = tempspacerange, spacerange.lowerBound.encodedOffset < firstspaceallowd else {
			return message.count > firstspaceallowd ? .fail(data: data) : .half(data: data)
		}
		
		let temptitlerange = message.range(of: Web.kSeparator)
		guard let titlerange = temptitlerange else {
			let spaceCount = message.components(separatedBy: Web.kSpace)
			return spaceCount.count > 3 ? .fail(data: data) : .half(data: data)
		}
		
		let tempheaderrange = message.range(of: Web.kContentSeparator, range: titlerange.lowerBound..<message.endIndex)
		
		guard let headerrange = tempheaderrange else {
			return .half(data: data)
		}
		
		let titlestring = String(message[message.startIndex..<titlerange.lowerBound])
		let headerstring: String = String(message[min(titlerange.upperBound, headerrange.lowerBound)..<headerrange.lowerBound])
		let bodydata = Data(data[data.index(data.startIndex, offsetBy: headerrange.upperBound.encodedOffset)..<data.endIndex])
		
		var titlelist = titlestring.components(separatedBy: Web.kSpace)
		let headerlist = headerstring.components(separatedBy: Web.kSeparator)
		
		var headerkeyvaluelist = [[String: String]]()
		for headerkeyvalue in headerlist {
			if let range = headerkeyvalue.range(of: Web.kSaySpace) {
				let key = String(headerkeyvalue[headerkeyvalue.startIndex..<range.lowerBound])
				let value = String(headerkeyvalue[range.upperBound..<headerkeyvalue.endIndex])
				headerkeyvaluelist.append([key: value])
			}
		}
		
		guard titlelist.count >= 2 else {
			return .fail(data: data)
		}
		
		guard let method = titlelist.first, method.count > 0 else {
			return .fail(data: data)
		}
		
		let url = titlelist[1]
		guard url.count > 0 else {
			return .fail(data: data)
		}

        guard let version = titlelist.last else {
			return .fail(data: data)
		}
		
		var temphost = ""
		for item in headerlist {
			let range = item.range(of: Web.kSaySpace)
			if let range = range {
				let key = String(item[item.startIndex..<range.lowerBound])
				let value = String(item[range.upperBound..<item.endIndex])
				if key == Web.kHeaderHostKey {
					temphost = value
					break
				}
			}
		}
		
		let istls = method == Web.kTLSRequestMethod
		
		var port = istls ? Web.kTLSDefaultPort : Web.kDefaultPort
		
		let hostport: String = {
			let target = url
			let pattern = Web.kHostPortPattern
			let regular = try? NSRegularExpression.init(pattern: pattern, options: .caseInsensitive)
			let result = regular?.firstMatch(in: target, range: NSRange.init(location: 0, length: target.count))
			let range = target.index(target.startIndex, offsetBy: result?.range.location ?? 0)..<target.index(target.startIndex, offsetBy: ((result?.range.location ?? 0) + (result?.range.length ?? 0)))
			let hostport = String(target[range])
			return hostport
		}()
		
		if hostport.count > 0 {
			temphost = hostport
		}
		var host = temphost
		
		let list = host.components(separatedBy: Web.kSay)
		if list.count >= 2 {
			host = list.first ?? host
			if let tempport = UInt16(list[1]) {
				port = tempport
			}
		}
		
		let replyString = istls ? version + Web.kSpace + Web.kTLSProxyEstablish : Web.kStringDefault
		let replyData = replyString.data(using: .utf8) ?? Data()
		
		var titleurl = titlelist[1]
		let prefixURLString = Web.kURLHTTPString + host
		if titleurl.hasPrefix(prefixURLString) {
			titleurl.removeSubrange(titleurl.startIndex..<titleurl.index(titleurl.startIndex, offsetBy: prefixURLString.count))
		}
		let suffixURLString = Web.kURLPIEString
		if titleurl.hasSuffix(suffixURLString) {
			titleurl.removeSubrange(titleurl.index(titleurl.endIndex, offsetBy: -suffixURLString.count)..<titleurl.endIndex)
		}
		titlelist[1] = titleurl
		
		
		return .success(data: data, main: titlelist, header: headerkeyvaluelist, body: bodydata, host: host, port: port, istls: istls, iftlsReply: replyData)
		
	}
	
}

open class WebProxy: TCPDelegate {
	
	open var server: TCP
	
	open var connectionlist = [Connection]()
	
	open weak var manager: WebProxyManager?
	
	open var listenCount: Int32 = 5000
	
	open var proxyCenterQueue = DispatchQueue.init(label: "com.hublot.proxyQueue")
	
	open var factoryQueue = DispatchQueue.init(label: "com.hublot.factoryQueue", attributes: .concurrent)
	
	deinit {
		
	}
	
	public init(_ address: Address = Address.init("0.0.0.0", 9527)) {
		self.server = TCP.init(address)
		TCP.callBackQueue = proxyCenterQueue
	}

    @discardableResult
	open func start() -> Bool {
		let result = server.bind()
		server.listen(listenCount)
		server.delegate = self
		return result
	}
	
	open func stop() {
		server.close()
	}
	
	public func remove(_ connection: Connection) {
		connection.remote?.close()
		connection.client.close()
		for (i, item) in connectionlist.enumerated() {
			if item == connection {
				connectionlist.remove(at: i)
				manager?.closeConnection(connectionIndex: connection.connectionIndex)
				break
			}
		}
	}
	
	public func maybeFailHandler(_ connection: Connection) -> TCP.CompleteHandler {
		let maybeFailHandler: TCP.CompleteHandler = {(issuccess, remote) in
			if !issuccess {
				self.remove(connection)
			}
		}
		return maybeFailHandler
	}
	
	public func parseRequest(_ connection: Connection, data: Data) {
		factoryQueue.async {
			var parse = Parse.parse(data)
			self.proxyCenterQueue.async {
				parse = self.manager?.parseResult(parse: parse, connectionIndex: connection.connectionIndex) ?? parse
				switch parse {
				case .fail:
					self.remove(connection)
					return
				case .half(let prefixdata):
					connection.state = .requesthalf(data: prefixdata)
					return
				case .success(let (_, _, _, _, host, port, istls, iftlsReplyData)):
					let maybeFailHandler = self.maybeFailHandler(connection)
					connection.remote = TCP.init(Address.init(host, port))
					connection.remote?.delegate = self
					connection.remote?.connect({ (issuccess, remote) in
						if !issuccess {
							self.remove(connection)
						}
					})
					if istls {
						self.factoryQueue.async {
							let tlspair = self.manager?.tlsHandShakeFromHost(host, connectionIndex: connection.connectionIndex)
							self.proxyCenterQueue.async {
								if let tlspair = tlspair {
									connection.remote?.starttls(tlspair.remotetls, { (issuccess, client) in
										maybeFailHandler?(issuccess, client)
										self.manager?.remoteHandShakeResult(host, issuccess, connectionIndex: connection.connectionIndex)
									})
									connection.client.starttls(tlspair.clienttls, { (issuccess, client) in
										maybeFailHandler?(issuccess, client)
										self.manager?.clientHandShakeResult(host, issuccess, connectionIndex: connection.connectionIndex)
									})
									connection.client.write(iftlsReplyData, maybeFailHandler)
									connection.state = .readyforward(parseread: true, host: host, lastRequest: nil, lastisremote: true)
								} else {
									connection.client.write(iftlsReplyData, maybeFailHandler)
									connection.state = .readyforward(parseread: false, host: host, lastRequest: nil, lastisremote: true)
								}
							}
						}
					} else {
						connection.state = .readyforward(parseread: true, host: host, lastRequest: nil, lastisremote: true)
						self.forwardClientRead(connection, data: data)
					}
				}
			}
		}
	}
	
	public func didAccept(server: TCP, client: TCP) {
		client.delegate = self
		let connection = Connection(client)
		connectionlist.append(connection)
		manager?.createConnectionIndex(address: client.address, connectionIndex: connection.connectionIndex)
	}
	
	public func didRead(socket: TCP, data: Data) {
		var fromClient = false
		var temp: Connection?
		for item in connectionlist {
			if item.client == socket {
				temp = item
				fromClient = true
				break
			} else if (item.remote == socket) {
				temp = item
				break
			}
		}
		guard let connection = temp else {
			socket.close()
			return
		}
		guard data.count > 0 else {
			remove(connection)
			return
		}
		if fromClient {
			didReadClient(connection, data: data)
		} else {
			didReadRemote(connection, data: data)
		}
	}
	
	public func didReadClient(_ connection: Connection, data: Data) {
		switch connection.state {
		case .createclient:
			parseRequest(connection, data: data)
		case .requesthalf(let prefixdata):
			let alldata = prefixdata + data
			parseRequest(connection, data: alldata)
		case .readyforward:
			forwardClientRead(connection, data: data)
		}
	}
	
	public func forwardClientRead(_ connection: Connection, data: Data) {
		var isheaderMessage = false
		var host = ""
		if case .readyforward(let (parsehttp, connectionHost, lastRequest, lastisremote)) = connection.state {
			isheaderMessage = lastisremote == true
			host = connectionHost
			let requestData = lastRequest ?? Data() + data
			connection.state = .readyforward(parseread: parsehttp, host: connectionHost, lastRequest: requestData, lastisremote: false)
		}
		let data = manager?.clientRead(data: data, isheaderMessage: isheaderMessage, host: host, connectionIndex: connection.connectionIndex) ?? data
		connection.remote?.write(data, maybeFailHandler(connection))
	}
	
	public func didReadRemote(_ connection: Connection, data: Data) {
		var isheaderMessage = false
		var host = ""
		var lastRequestData = Data()
		if case .readyforward(let (parsehttp, connectionHost, lastRequest, lastisremote)) = connection.state {
			isheaderMessage = lastisremote == false
			lastRequestData = lastRequest ?? Data()
			host = connectionHost
			connection.state = .readyforward(parseread: parsehttp, host: connectionHost, lastRequest: nil, lastisremote: true)
		}
		let data = manager?.remoteRead(data: data, isheaderMessage: isheaderMessage, host: host, requestData: lastRequestData, connectionIndex: connection.connectionIndex) ?? data
		connection.client.write(data, maybeFailHandler(connection))
	}
	
}


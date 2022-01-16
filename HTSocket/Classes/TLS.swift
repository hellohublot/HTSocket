//
//  TLS.swift
//  CocoaLumberjack
//
//  Created by hublot on 2018/2/1.
//

public extension TCP {
	func starttls(_ tls: TLS = TLS(),
				  _ complete: CompleteHandler = nil) {
		socketQueue.async {
			switch self.state {
			case .listened, .connected:
				break
			default:
				return
			}
			self.state = .willtls(tls: tls)
		}
		if tls.side == .clientSide {
			TLS.hand(client: self, complete: complete)
		} else {
			complete?(true, self)
		}
	}
}

private func SSLRead(connection: SSLConnectionRef,
					 data: UnsafeMutableRawPointer,
					 dataLength: UnsafeMutablePointer<Int>) -> OSStatus {
	let fd = connection.assumingMemoryBound(to: Int32.self).pointee
	let willlength = dataLength.pointee
	let readlength = read(fd, data, willlength)
	dataLength.initialize(to: max(0, readlength))
	if readlength <= 0 {
		switch errno {
		case EAGAIN: return errSSLWouldBlock
		case ENOENT: return errSSLClosedGraceful
		case ECONNRESET: return errSSLClosedAbort
		default: return errSecIO
		}
	} else {
		if (willlength > readlength) {
			return errSSLWouldBlock
		} else {
			return noErr
		}
	}
}

private func SSLWrite(connection: SSLConnectionRef,
					  data: UnsafeRawPointer,
					  dataLength: UnsafeMutablePointer<Int>) -> OSStatus {
	let fd = connection.assumingMemoryBound(to: Int32.self).pointee
	let willlength = dataLength.pointee
	let writelength = write(fd, data, willlength)
	dataLength.initialize(to: max(0, writelength))
	if writelength <= 0 {
		switch errno {
		case EAGAIN: return errSSLWouldBlock
		default: return errSecIO
		}
	} else {
		if (willlength > writelength) {
			return errSSLWouldBlock
		} else {
			return noErr
		}
	}
}

open class TLS: NSObject {
	
	public enum Validate {
		
		case require
		
		case none
		
	}
	
	open var side: SSLProtocolSide
	
	open var pk12: Data
	
	open var password: String
	
	open var validate: Validate
	
	public init(side: SSLProtocolSide = .clientSide,
				pk12: Data = Data(),
				password: String = "",
				validate: Validate = .none) {
		self.side = side
		self.pk12 = pk12
		self.password = password
		self.validate = validate
	}
	
}

public extension TLS {
	
	static func readCertificate(tls: TLS) -> [Any] {
		let key: NSString = kSecImportExportPassphrase as NSString
		let option = [key: tls.password as AnyObject]
		var pkcslist: CFArray? = nil
		SecPKCS12Import(tls.pk12 as CFData, option as CFDictionary, &pkcslist)
		var pkcs: AnyObject?
		if let list = pkcslist {
			let array: NSArray = list as [AnyObject] as NSArray
			pkcs = array.firstObject as AnyObject
		}
		var secIdentity = pkcs?.value(forKey: kSecImportItemKeyID as String)
		secIdentity = pkcs?.value(forKey: "identity")
		if let secIdentity = secIdentity {
			var list = [secIdentity]
			let array: Array<SecCertificate>? = pkcs?.value(forKey: kSecImportItemCertChain as String) as? Array<SecCertificate>
			if let array = array {
				for i in 1..<array.count {
					list += [array[i] as AnyObject]
				}
			}
			return list
		}
		return [Any]()
	}
	
	static func createContext(tls: TLS) -> SSLContext? {
		let context = SSLCreateContext(kCFAllocatorDefault, tls.side, .streamType)
		var breakAuth: Bool = false
		switch tls.validate {
		case .none:
			breakAuth = true
		case .require:
			breakAuth = false
		}
		if let context = context {
			let certificatelist = readCertificate(tls: tls)
			SSLSetCertificate(context, certificatelist as CFArray)
			SSLSetSessionOption(context, .breakOnServerAuth, breakAuth)
			SSLSetSessionOption(context, .breakOnClientAuth, breakAuth)
			if tls.side == .serverSide && tls.validate == .require {
				SSLSetClientSideAuthenticate(context, .alwaysAuthenticate)
			}
			SSLSetIOFuncs(context, SSLRead, SSLWrite)
		}
		return context
	}
	
	static func hand(client: TCP, complete: TCP.CompleteHandler = nil) {
		client.socketQueue.async {
			var issuccess: Bool = false
			if case .willtls(let tls) = client.state, let context = createContext(tls: tls) {
				let connection = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
				connection.pointee = client.fd
				SSLSetConnection(context, connection)
				var status: OSStatus = noErr
				repeat {
					status = SSLHandshake(context)
				} while (status == errSSLWouldBlock ||
					(tls.validate == TLS.Validate.none && status == errSSLPeerAuthCompleted))
				
				issuccess = (status == noErr || status == errSecSuccess)
				
				client.state = .didtls(context: context)
				client.createReadSource()
			}
			type(of: client).callBackQueue.async {
				complete?(issuccess, client)
			}
		}
	}
	
}

//
//  Address.swift
//  CocoaLumberjack
//
//  Created by hublot on 2018/2/1.
//

open class Address: NSObject {
	
	deinit {
		freeaddrinfo(info)
	}
	
	public let host: String
	
    public let port: UInt16
	
    public let type: Int32
	
    public let info: UnsafeMutablePointer<addrinfo>
	
	public init(_ host: String = "127.0.0.1", _ port: UInt16 = 9527) {
		self.host = host
		self.port = port
		var hint = addrinfo()
		var result: UnsafeMutablePointer<addrinfo>?
		getaddrinfo(host, String(port), &hint, &result)
		self.info = result ?? {
			let result = UnsafeMutablePointer<addrinfo>.allocate(capacity: 1)
			result.pointee = hint
			return result
		}()
		self.type = self.info.pointee.ai_family
	}
	
	public init(_ sockaddress: sockaddr, _ socklength: socklen_t) {
		let sockpoint: UnsafeMutablePointer<sockaddr> = {
			let sockpoint = UnsafeMutablePointer<sockaddr>.allocate(capacity: 1)
			sockpoint.pointee = sockaddress
			return sockpoint
		}()
		let hintpoint:UnsafeMutablePointer<addrinfo> = {
			var hint = addrinfo()
			hint.ai_addr = sockpoint
			let hintpoint = UnsafeMutablePointer<addrinfo>.allocate(capacity: 1)
			hintpoint.pointee = hint
			return hintpoint
		}()
		self.info = hintpoint
		self.type = Int32(hintpoint.pointee.ai_addr.pointee.sa_family)
		let hostcount = Int(NI_MAXHOST)
		let servicecount = Int(NI_MAXSERV)
		let hostname = UnsafeMutablePointer<Int8>.allocate(capacity: hostcount)
		let servicename = UnsafeMutablePointer<Int8>.allocate(capacity: servicecount)
		getnameinfo(sockpoint, socklength, hostname, socklen_t(MemoryLayout.size(ofValue: hostname.pointee) * hostcount), servicename, socklen_t(MemoryLayout.size(ofValue: servicename.pointee) * servicecount), 0)
		self.host = String.init(cString: hostname)
		var servicestring = String.init(cString: servicename)
		let servicestruct = getservbyname(servicename, nil)
		if let serviceport = servicestruct?.pointee.s_port {
			servicestring = String(NSSwapHostShortToBig(UInt16(serviceport)))
		}
		self.port = UInt16(servicestring) ?? 0
		hostname.deallocate()
		servicename.deallocate()
	}
	
	public static func systemHost() -> String? {
		var addresses = [String: [String]]()
		var ifaddr : UnsafeMutablePointer<ifaddrs>? = nil
		if getifaddrs(&ifaddr) == 0 {
			var lastifaddr = ifaddr
			while let lastaddr = lastifaddr {
				lastifaddr = lastaddr.pointee.ifa_next
				let flags = Int32(lastaddr.pointee.ifa_flags)
				guard (flags & (IFF_UP | IFF_RUNNING | IFF_LOOPBACK)) == (IFF_UP | IFF_RUNNING) else {
					continue
				}
				guard let addr = lastaddr.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) || addr.pointee.sa_family == UInt8(AF_INET6) else {
					continue
				}
				var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
				if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0, let address = String(validatingUTF8:hostname) {
					let interfacename = String(cString: lastaddr.pointee.ifa_name)
					guard address.contains("%") == false else {
						continue
					}
					if let _ = addresses[interfacename] {
						if addr.pointee.sa_family == UInt8(AF_INET6) {
							addresses[interfacename]?.insert(address, at: 0)
						} else {
							addresses[interfacename]?.append(address)
						}
					} else {
						addresses[interfacename] = [address]
					}
				}
			}
			freeifaddrs(ifaddr)
			if let wifi = addresses["en0"]?.first {
				return wifi
			} else if let _ = addresses["pdp_ip0"]?.first {
				if let _ = addresses["bridge100"]?.first {
					return "127.0.0.1"
				} else {
					return "127.0.0.1"
				}
			} else {
				return nil
			}
		}
		return nil
	}
	
}

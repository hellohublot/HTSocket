//
//  AppDelegate.swift
//  HTProxyExample
//
//  Created by hublot on 2018/2/3.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Cocoa
import HTSocket

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
//	let client = TCP.init(Address.init("hublot.wang", 443))
	
//	let server = TCP()
	
	let proxy = WebProxy()
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		
//		client.connect()
		
//		client.starttls()
		
//		client.write("GET / HTTP/1.0\r\n\r\n".data(using: .ascii)!)
		
		LogManager.shareLogManager?.logAblelist = []
		
		proxy.start()
		
	}

}


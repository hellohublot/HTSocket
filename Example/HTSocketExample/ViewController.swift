//
//  ViewController.swift
//  HTSocketExample
//
//  Created by hublot on 2018/1/25.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import HTSocket

class ViewController: UIViewController {
	
//	let client = TCP.init(Address.init("hublot.wang", 443))
//
//	override func viewDidLoad() {
//
//		super.viewDidLoad()
//
//		client.delegate = self
//
//		client.connect()
//
//		client.starttls()
//
//		client.write("GET / HTTP/1.0\r\n\r\n".data(using: .ascii)!)
//
//	}
	
	let proxy = WebProxy()
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		proxy.start()
		
		proxy.delegate = self
		
	}

}

extension ViewController: TCPDelegate {
	
	func didRead(socket: TCP, data: Data) {
		print(String.init(data: data, encoding: .ascii)!)
	}
	
}

extension ViewController: WebProxyDelegate {
	
}


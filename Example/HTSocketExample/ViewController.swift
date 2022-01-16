//
//  ViewController.swift
//  HTSocketExample
//
//  Created by hublot on 2022/1/16.
//

import UIKit
import HTSocket

enum HTSocketActionType: String {

    case tcpclient

    case tcpserver

    case udpclient

    case udpserver

    case webproxy

    static func packModelArray() -> [HTSocketActionType] {
        return [
            .tcpclient,
            .tcpserver,
            .udpclient,
            .udpserver,
            .webproxy
        ]
    }

}


class ViewController: UIViewController {

    lazy var modelArray: [HTSocketActionType] = {
        let modelArray = HTSocketActionType.packModelArray()
        return modelArray
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView.init(frame: CGRect.zero)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    var socket = Socket.init(SOCK_STREAM, Address.init("www.baidu.com", 443), 0)

    var webProxy = WebProxy.init(Address.init("127.0.0.1", 9527))

    override func viewDidLoad() {
        super.viewDidLoad()
        initDataSource()
        initUserInterface()
    }

    func initDataSource() {

    }

    func initUserInterface() {
        tableView.frame = view.bounds
        view.addSubview(tableView)
    }


}

extension ViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
        let model = modelArray[indexPath.row]
        cell.textLabel?.text = model.rawValue
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = modelArray[indexPath.row]
        self.modelActionDidTouch(model)
    }

    func modelActionDidTouch(_ model: HTSocketActionType) {
        socket.close()
        webProxy.stop()
        switch (model) {
        case .tcpclient:
            let socket = TCP.init(Address.init("www.baidu.com", 443))
            self.socket = socket
            socket.delegate = self
            socket.connect()
            socket.starttls()
            socket.write("GET / HTTP/1.0\r\n\r\n".data(using: .ascii)!)
        case .tcpserver:
            let socket = TCP.init(Address.init("localhost", 9527))
            self.socket = socket
            socket.delegate = self
            socket.bind()
            socket.listen(100)
            print("tcp 服务器已打开, 请用命令行执行 curl 'localhost:9527'")
        case .udpclient:
            let address = Address.init("127.0.0.1", 7777)
            let socket = UDP.init(address)
            self.socket = socket
            socket.delegate = self
            socket.write("hello world".data(using: .ascii)!, to: address)
            print("udp 客户端测试请先用命令行执行 tcpdump -i lo0 udp port 7777 -X, 然后会监听到这个请求发出去")
        case .udpserver:
            let address = Address.init("127.0.0.1", 9527)
            let socket = UDP.init(address)
            self.socket = socket
            socket.delegate = self
            socket.bind()
            socket.write("hello world".data(using: .ascii)!, to: Address.init("127.0.0.1", 7777))
            print("udp 服务器测试请先用命令行执行 tcpdump -i lo0 udp port 7777 -X, 然后会监听到这个请求发出去")
        case .webproxy:
            let webProxy = WebProxy.init(Address.init("127.0.0.1", 9527))
            self.webProxy = webProxy
            webProxy.manager = self
            webProxy.start()
            print("http 代理服务器已打开, 请把电脑的 wifi 代理设置为 127.0.0.1:9527")
        }
    }

}

extension ViewController: TCPDelegate {

    func didRead(socket: TCP, data: Data) {
        print("收到 tcp 消息如下\n\(String.init(data: data, encoding: .ascii) ?? "")")
    }

}

extension ViewController: UDPDelegate {

    func didRead(socket: UDP, data: Data, sendFrom address: Address) {
        print("收到 udp 消息如下\n\(String.init(data: data, encoding: .ascii) ?? "")")
    }

}

extension ViewController: WebProxyManager {

    func clientRead(data: Data, isheaderMessage: Bool, host: String, connectionIndex: Int) -> Data {
        print("收到来自客户端的消息如下\n\(String.init(data: data, encoding: .ascii) ?? "")")
        return data
    }

    func remoteRead(data: Data, isheaderMessage: Bool, host: String, requestData: Data, connectionIndex: Int) -> Data {
        print("收到来自服务器(\(host))的消息如下\n\(String.init(data: data, encoding: .ascii) ?? "")")
        return data
    }

}


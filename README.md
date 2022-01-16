- 支持 tcp + tls
- 支持 udp
- 支持 https webProxy, 可以修改请求和响应

## Usage

[点击查看完整示例 Example](./Example/HTSocketExample/ViewController.swift)

```ruby
pod 'HTSocket', :git => 'https://github.com/hellohublot/HTSocket.git'
```
```swift
// tcp client
let socket = TCP.init(Address.init("www.baidu.com", 443))
self.socket = socket
socket.delegate = self
socket.connect()
socket.starttls()
socket.write("GET / HTTP/1.0\r\n\r\n".data(using: .ascii)!)

func didRead(socket: TCP, data: Data) {
    print("收到 tcp 消息如下\n\(String.init(data: data, encoding: .ascii) ?? "")")
}
```

```swift
// webProxy
let webProxy = WebProxy.init(Address.init("127.0.0.1", 9527))
self.webProxy = webProxy
webProxy.manager = self
webProxy.start()

func clientRead(data: Data, isheaderMessage: Bool, host: String, connectionIndex: Int) -> Data {
    print("收到来自客户端的消息如下\n\(String.init(data: data, encoding: .ascii) ?? "")")
    return data
}

func remoteRead(data: Data, isheaderMessage: Bool, host: String, requestData: Data, connectionIndex: Int) -> Data {
    print("收到来自服务器(\(host))的消息如下\n\(String.init(data: data, encoding: .ascii) ?? "")")
    return data
}

// 如果需要支持 https, 返回一个 tlspair, 否则返回 nil
tlspair 的 remotetls = TLS.init(validate: .require)
tlspair 的 clienttls = 根据域名创建的欺骗客户端的子证书
func tlsHandShakeFromHost(_ host: String, connectionIndex: Int) -> TLSPair? {
	return nil
}
```

## Author

hellohublot, hublot@aliyun.com

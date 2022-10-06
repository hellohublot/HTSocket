## Features

- support tcp + tls
- support udp
- support https webProxy, it can modified request and response

## Usage

[Example](./Example/HTSocketExample/ViewController.swift)

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
    print("The message received from TCP\n\(String.init(data: data, encoding: .ascii) ?? "")")
}
```

```swift
// webProxy
let webProxy = WebProxy.init(Address.init("127.0.0.1", 9527))
self.webProxy = webProxy
webProxy.manager = self
webProxy.start()

func clientRead(data: Data, isheaderMessage: Bool, host: String, connectionIndex: Int) -> Data {
    print("The message received from client\n\(String.init(data: data, encoding: .ascii) ?? "")")
    return data
}

func remoteRead(data: Data, isheaderMessage: Bool, host: String, requestData: Data, connectionIndex: Int) -> Data {
    print("The message received from server (\(host))\n\(String.init(data: data, encoding: .ascii) ?? "")")
    return data
}

// Returns a tlspair if https is required, nil otherwise
tlspair.remotetls = TLS.init(validate: .require)
tlspair.clienttls = `A sub-certificate created based on the domain name to spoof the client`
func tlsHandShakeFromHost(_ host: String, connectionIndex: Int) -> TLSPair? {
	return nil
}
```

## Author

hellohublot, hublot@aliyun.com

## HTSocket
HTSocket is a asynchronous network proxy server library that supports rewriting https packages, You can import the certificate, and then you can read the https packages on the iOS device, and you can rewrite the https package

## Features

- [x] Support domain name resolution to ip address
- [x] Support simulated TCP TLS handshake
- [x] Support for UDP connections
- [x] Support HTTP packet automatic parsing
- [x] Support for reading and writing HTTPS request and response packets
- [x] Support logging to Console.app because it usually runs in Extension

## Install

```ruby
pod 'HTSocket', :git => 'https://github.com/hellohublot/HTSocket.git'
```

## Usage

[View Full Example](./Example/HTSocketExample/ViewController.swift)


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

## Contact

hellohublot, hublot@aliyun.com

<div style="display: flex; align-items: center; gap: 20px; margin-bottom: 15px;">
  <img src="https://authmatech.com/wp-content/uploads/2025/05/Authmatech-logo.png" alt="Authmatech Logo" width="180" align="center">
  <div>
    <h1 style="margin: 0; padding: 0;">Authmatech iOS SDK</h1>
    <p style="margin: 5px 0 0 0; font-size: 1.1em; color: #555;">
      Seamless Mobile Identity Verification via Mobile Network Operator (MNO)
    </p>
  </div>
</div>

> **Version**: `1.0.8`   |   **Platform**: iOS 12.0+  
> **License**: MIT   |   [Documentation](https://docs.authmatech.com)
---

## 🔧 Installation

### Swift Package Manager (Recommended)
```swift
dependencies: [
    .package(url: "https://github.com/authmatech/authmatech-sdk-ios.git", from: "1.0.0")
]
```

> Or use Xcode:  
> `File > Add Packages > Search: https://github.com/authmatech/authmatech-sdk-ios.git`

### CocoaPods
```ruby
pod 'AuthmatechSDK', :git => 'https://github.com/authmatech/authmatech-sdk-ios.git', :tag => '1.0.0'
```

---

## 📱 Supported iOS Versions

- iOS **12.0** and above
- Compatible with **Objective-C** and **Swift**
- Native support for **cellular-only connections** even when Wi-Fi is available

---

## ⚙️ Features

- ✅ Authmatech Code Retrieval via Mobile Network Operater (MNO)
- ✅ Fallback support for secure redirect chains
- ✅ Debug logging with full request trace
- ✅ Token-based authentication support
- ✅ Objective-C interoperability via `ObjcAuthmatechSDK`

---

## 🧑‍💻 Example Usage (Swift)

```swift
import AuthmatechSDK

let sdk = AuthmatechSDK()

let url = URL(string: "https://api.example.com/mno")!

sdk.openWithDataCellular(url: url, debug: true) { result in
    print("Authmatech response: \(result)")
}
```

### Using Access Token
```swift
sdk.openWithDataCellularAndAccessToken(
    url: url,
    accessToken: "Bearer your-token",
    debug: true
) { result in
    print(result["response_body"] ?? "No body found")
}
```

---

## 🧪 Sample Output

```json
{
  "http_status": 200,
  "response_body": {
    "errorCode": "0",
    "authmatechCode": "c%2BEx..etc",
    "MNOID": "0"
  },
  "debug": {
    "device_info": "iPhone/17.0",
    "url_trace": "Trace started at 2025-04-22T12:00:00Z\n..."
  }
}
```

---

## 💬 Objective-C Compatibility

```objc
#import <AuthmatechSDK/AuthmatechSDK-Swift.h>

ObjcAuthmatechSDK *sdk = [[ObjcAuthmatechSDK alloc] init];
NSURL *url = [NSURL URLWithString:@"https://api.example.com/mno"];

[sdk openWithDataCellular:url debug:YES completion:^(NSDictionary * _Nonnull result) {
    NSLog(@"%@", result);
}];
```

---

## 📄 License

MIT – See [LICENSE](./LICENSE) file for details.

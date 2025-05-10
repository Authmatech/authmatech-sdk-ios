# ![Authmatech Logo](https://authmatech.com/logo.svg) Authmatech iOS SDK

> Seamless Mobile Identity Verification via Telecom Header Enrichment  
> **Version**: `1.0.0` &nbsp;&nbsp;|&nbsp;&nbsp;**Platform**: iOS 12.0+

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

- ✅ MSISDN Retrieval via telecom header enrichment
- ✅ Fallback support for secure redirect chains
- ✅ Debug logging with full request trace
- ✅ Token-based authentication support
- ✅ Objective-C interoperability via `ObjcAuthmatechSDK`

---

## 🧑‍💻 Example Usage (Swift)

```swift
import AuthmatechSDK

let sdk = AuthmatechSDK()

let url = URL(string: "https://api.partner.com/msisdn")!

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
    "authmatechCode": "c%2BExNVz5AktLCHBz7sAjlAU7AmMW5bTKxqo%2F==",
    "MNOID": "1"
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
NSURL *url = [NSURL URLWithString:@"https://api.partner.com/msisdn"];

[sdk openWithDataCellular:url debug:YES completion:^(NSDictionary * _Nonnull result) {
    NSLog(@"%@", result);
}];
```

---

## 📄 License

MIT – See [LICENSE](./LICENSE) file for details.

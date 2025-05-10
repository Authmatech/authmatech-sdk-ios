# 📦 Authmatech iOS SDK – Changelog

All notable changes to the Authmatech iOS SDK will be documented in this file.

## [1.0.0] - 2025-04-22
### 🚀 Initial Release
- 📱 iOS SDK supports cellular-only mobile identity verification via telecom header enrichment.
- 🌐 Swift-native HTTP connection over TCP with redirect handling.
- 🔒 Secure MSISDN (mobile number) retrieval using telecom infrastructure.
- 🧪 Includes both Swift & Objective-C interfaces for compatibility:
  - `AuthmatechSDK` for Swift.
  - `ObjcAuthmatechSDK` for Objective-C / KMM.
- ✅ Verified MSISDN response with:
  - `authmatechCode` (encoded MSISDN)
  - `MNOID` (mobile network operator ID)
- 📊 Debug mode returns device info and URL trace.
- 🔧 Supports iOS 12.0+ and Swift 5+.

---

<img width="1070" alt="Authsignal" src="https://raw.githubusercontent.com/authsignal/authsignal-ios/main/.github/images/authsignal.png">

# Authsignal Flows iOS

Check out our [official documentation](https://docs.authsignal.com/sdks/client/ios).

## Installation

#### Cocoapods

Add AuthsignalFlows to your Podfile:

```rb
pod 'AuthsignalFlows', '~> 1.0.0-alpha1'
```

#### Swift Package Manager

Add authsignal-flows-ios to the dependencies value of your Package.swift.

```swift
dependencies: [
    .package(url: "https://github.com/authsignal/authsignal-flows-ios.git", from: "1.0.0-alpha1")
]
```

## Initialization

```swift
import AuthsignalFlows
...

let authsignal = AuthsignalFlows(tenantId: "YOUR_TENANT_ID", apiUrl: "YOUR_REGION_API_URL")
```

You can find your tenant ID in the [Authsignal Portal](https://portal.authsignal.com/organisations/tenants/api).

You must specify the correct base URL for your tenant's region.

| Region        | Base URL                      |
| ------------- | ----------------------------- |
| US (Oregon)   | https://api.authsignal.com    |
| CA (Montreal) | https://ca.api.authsignal.com |
| AU (Sydney)   | https://au.api.authsignal.com |
| EU (Dublin)   | https://eu.api.authsignal.com |
| UK (London)   | https://uk.api.authsignal.com |

## Usage

For more detail on how to use this SDK refer to the [official documentation](https://docs.authsignal.com/sdks/client/ios).

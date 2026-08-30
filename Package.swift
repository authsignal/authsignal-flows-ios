// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "AuthsignalFlows",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "AuthsignalFlows",
      targets: ["AuthsignalFlows"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "AuthsignalFlows",
      dependencies: [])
  ]
)

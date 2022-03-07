// swift-tools-version:5.5

import PackageDescription

let package = Package(
	name: "Cause-Logic-Effect",
	platforms: [
		.iOS(.v9),
	],
	products: [
		.library(
			name: "Cause-Logic-Effect",
			targets: ["Cause-Logic-Effect"]
		),
	],
	dependencies: [
		.package(
			url: "https://github.com/ReactiveX/RxSwift.git",
			.upToNextMajor(from: "6.0.0")
		)
	],
	targets: [
		.target(
			name: "Cause-Logic-Effect",
			dependencies: [
				"RxSwift",
				.product(name: "RxCocoa", package: "RxSwift"),
			],
			path: "Utilities"
		)
	]
)

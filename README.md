# CLE-Architecture-Tools

The File Templates can be use to create new Rx Scenes (use one of these instead of creating a View Controller directly.) Place the folder in `Library/Developer/Xcode/Templates/`.

The Utilities folder contains support code that should be included in the project. The most important files, from an architectural perspective, are "Stage.swift" and "Scene.swift". The others contain code that I used in 80% or more of my projects.

The Tools folder contains helpers that I have developed but aren't needed in most projects.

## Requirements
* RxSwift
* RxCocoa

## Installation
Two Ways to Install

1. Drag and drop the Utilities folder into your xcode workspace under the project name folder

2. Use Swift Package Manager.

3. Use [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html).
```
use_frameworks!

target 'YOUR_TARGET_NAME' do
   pod 'Cause-Logic-Effect'
end
 ```
 Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```bash
$ pod install
```

## Use

The idea behind this library is to provide an easy way to wrap a view controller as an Observable resource in order to make it a simple asynchronous event. In essence, your code will be able to work with its view controllers the same way it works with its server or database, through flatMap and bind.

### Scene
The core type is the `Scene` which consists of a view controller, along with an Observable that emits any needed user provided values along with a stop event when it's done. Alternativly, the calling code can `dispose()` the Scene's Observable if it wants to dismiss the view controller before completion.

A `Scene` can be created from a view controller by calling the `scene` method. There is an instance method for constructing a Scene from an already existing view controller or you can use the `scene` static method which will load a view controller from a storyboard and create a Scene using that.

### Displaying a Scene

Once a Scene is created, it can be displayed in any of a number of ways. You can `present` it, `push` it onto a navigation controller, or `show` it. All the same ways that you can work with a normal view controller. Whatever way you choose to display your Scene, you are assured that when it's disposed of, it will hide itself using the correct inverse of the display method. (So if presented it will dismiss, if pushed it will pop, etc.) The functions for displaying a Scene are in the "Stage.swift" file.

### An Example Scene

Virtually every program uses an Alert controller at some point. The library provides methods on UIAlertController for some of the most common actions a view controller is used for. They are `connectOK()` which returns an Observable that emits a Void when the user taps the OK button and a `connectChoice` which will add a button for each choice provided, along with a cancel button, and return an Observable that emits the choice taken by the user (or nil of the user cancels.)

### Working with a flow

A Scene can also represent a number of child Scenes that all work together as a "flow" or "process". Below is an example of such a construct. A flow is a function that returns a Scene and that Scene actually encapsulates a number of child Scenes that work together to get a job done. If any one child scene complets, the entire flow completes. Notice that unlike a typical Coordinator type, you don't need to manage any resources. At no point do you need to manually keep track of what view controllers are currently being displayed.

## Example of Use

When the user taps the "forgot password" link in one of my apps:
```swift
forgotPasswordButton.rx.tap
    .bind(onNext: presentScene(animated: true, scene: forgotPasswordFlow))
    .disposed(by: disposeBag)
```

The forgot password flow consists of presenting three screens in order:
```swift
func forgotPasswordFlow() -> Scene<Void> {
    // This scene asks the user to enter their phone number.
    let forgotPassword = ForgotPasswordViewController.scene { $0.phoneNumber() }

    // Once we get the phone number, send a one-time password to the user and ask them to enter it.
    let otpResult = forgotPassword.action
        .observe(on: MainScheduler.instance)
        .flatMapFirst(presentScene(animated: true) { phoneNumber in
            OTPViewController.scene { $0.passwordResetToken(forPhoneNumber: phoneNumber) }
        })

    // After they enter the OTP, allow them to reset their password.
    let resetPasswordResult = otpResult
        .observe(on: MainScheduler.instance)
        .flatMapFirst(presentScene(animated: true) { token in
            ResetPasswordViewController.scene { $0.resetPassword(withToken: token) }
        })

    // When `resetPasswordResult` completes, the entire flow will automatically unwind.
    return Scene(controller: forgotPassword.controller, action: resetPasswordResult)
}
```

### Imperative Use
On the chance that you are converting from imperative code to using this library. The following functions will come in handy:
```swift
func call<T>(_ fn: (()) -> Observable<T>) -> Observable<T> {
	fn(())
}

func final(_ fn: (()) -> Void) {
	fn(())
}
```
The `call` function is for when your view controller is returning information to its caller, otherwise use the `final` function. You can wrap these around the functions in the Stage.swift file. So for example:

```swift
final(presentScene(animated: true) {
    UIAlertController(title: "Greeting", message: "Hello World", preferredStyle: .alert)
        .scene { $0.connectOK() }
})

_ = call(presentScene(animated: true, over: button) {
    UIAlertController(title: nil, message: "Which One?", preferredStyle: .actionSheet)
        .scene { $0.connectChoice(choices: ["This One", "That One"]) }
})
.subscribe(onNext: {
    print("A choice was made:", $0 as Any)
})
```

## Other Types

The other types/methods/functions in the library are ancelary that I use in at least 80% of my apps.

The `ActivityIndicator` and `ErrorRouter` types are used to track network requests. The `cycle` function can be used when you have an Observable that feeds back on itself. The `Identifier` type is used to create ids for `Identifiable` types. RxHelpers contains some misc methods to make mapping and Observer success easier to deal with. The "UIColor+Extensions" file contains a convience init function to create a color from a hex value. The "UIViewController+Rx.swift" file wraps some basic functions for handling a view controller internally. It includes `dismissSelf` and `popSelf` on those rare occasions when you want to remove a view controller _before_ it completes.

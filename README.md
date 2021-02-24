# CLE-Architecture-Tools

The File Templates can be use to create new Rx Scenes (use one of these instead of creating a View Controller directly.) Place the folder in `Library/Developer/Xcode/Templates/`.

The Utilities folder contains support code that should be included in the project. The most important files, from an architectural perspective, are "Stage.swift" and "Scene.swift". The others contain code that I used in 80% or more of my projects.

The Tools folder contains helpers that I have developed but aren't needed in most projects.

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

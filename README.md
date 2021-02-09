# CLE-Architecture-Tools

The File Templates can be use to create new Rx Scenes (use one of these instead of creating a View Controller directly.) Place the folder in `Library/Developer/Xcode/Templates/`.

The Utilities folder contains support code that should be included in the project. The most important files, from an architectural perspective, are "Stage.swift" and "Scene.swift". The others contain code that I used in 80% or more of my projects.

The Tools foder contains helpers that I have developed but aren't needed in most projects.

## Example of Use

When the user taps the "forgot password" link in one of my apps:
```
forgotPasswordButton.rx.tap
    .bind {
        finalPresentScene(animated: true, scene: forgotPasswordFlow)
    }
    .disposed(by: disposeBag)
```

The forgot password flow consists of presenting three screens in order:
```
func forgotPasswordFlow() -> Scene<Void> {
    // This scene asks the user to enter their phone number.
    let forgotPassword = ForgotPasswordViewController.scene { $0.phoneNumber() }

    // Once we get the phone number, send a one-time password to the user and ask them to enter it.
    let otpResult = forgotPassword.action
        .observe(on: MainScheduler.instance)
        .flatMapFirst { phoneNumber in
            presentScene(animated: true) {
                OTPViewController.scene { $0.passwordResetToken(forPhoneNumber: phoneNumber) }
            }
        }

    // After they enter the OTP, allow them to reset their password.
    let resetPasswordResult = otpResult
        .observe(on: MainScheduler.instance)
        .flatMapFirst { token in
            presentScene(animated: true) {
                ResetPasswordViewController.scene { $0.resetPassword(withToken: token) }
            }
        }

    // When `resetPasswordResult` completes, the entire flow will automatically unwind.
    return Scene(controller: forgotPassword.controller, action: resetPasswordResult)
}
```

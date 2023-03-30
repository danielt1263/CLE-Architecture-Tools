//
//  WKWebView+Rx.swift
//
//  Created by Daniel Tartaglia on 27 Mar 2023.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxCocoa
import RxSwift
import WebKit

extension Reactive where Base: WKWebView {
    var navigationDelegate: WKNavigationDelegateProxy {
        return WKNavigationDelegateProxy.proxy(for: base)
    }

    var decidePolicyForNavigationAction: ControlEvent<NavigationActionEvent> {
        ControlEvent(events: navigationDelegate.navigationActionEvent)
    }

    var decidePolicyForNavigationActionPrefs: ControlEvent<NavigationActionPrefsEvent> {
        ControlEvent(events: navigationDelegate.navigationActionPrefsEvent)
    }

    var decidePolicyForNavigationResponse: ControlEvent<NavigationResponseEvent> {
        ControlEvent(events: navigationDelegate.navigationResponseEvent)
    }

    var didStartProvisionalNavigation: ControlEvent<WKNavigation> {
        controlEvent(from: #selector(WKNavigationDelegate.webView(_:didStartProvisionalNavigation:)))
    }

    var didReceiveServerRedirectForProvisionalNavigation: ControlEvent<WKNavigation> {
        controlEvent(from: #selector(WKNavigationDelegate.webView(_:didReceiveServerRedirectForProvisionalNavigation:)))
    }

    var didFailProvisionalNavigation: ControlEvent<NavigationErrorEvent> {
        ControlEvent(
            events: navigationDelegate.methodInvoked(
                #selector(WKNavigationDelegate.webView(_:didFailProvisionalNavigation:withError:))
            )
            .map { ($0[1] as! WKNavigation, $0[2] as! Error) }
        )
    }

    var didCommit: ControlEvent<WKNavigation> {
        controlEvent(from: #selector(WKNavigationDelegate.webView(_:didCommit:)))
    }

    var didFinish: ControlEvent<WKNavigation> {
        controlEvent(from: #selector(WKNavigationDelegate.webView(_:didFinish:)))
    }
    
    var didFail: ControlEvent<NavigationErrorEvent> {
        ControlEvent(
            events: navigationDelegate.methodInvoked(#selector(WKNavigationDelegate.webView(_:didFail:withError:)))
                .map { ($0[1] as! WKNavigation, $0[2] as! Error) }
        )
    }

    private func controlEvent(from selector: Selector) -> ControlEvent<WKNavigation> {
        ControlEvent(events: navigationDelegate.methodInvoked(selector).map { $0[1] as! WKNavigation })
    }
}

typealias NavigationActionEvent = (navigationAction: WKNavigationAction,
								   decisionHandler: (WKNavigationActionPolicy) -> Void)

typealias NavigationActionPrefsEvent = (navigationAction: WKNavigationAction,
										preferences: WKWebpagePreferences,
										decisionHandler: (WKNavigationActionPolicy, WKWebpagePreferences) -> Void)

typealias NavigationResponseEvent = (navigationResponse: WKNavigationResponse,
									 decisionHandler: (WKNavigationResponsePolicy) -> Void)

typealias NavigationErrorEvent = (navigation: WKNavigation, error: Error)

class WKNavigationDelegateProxy
: DelegateProxy<WKWebView, WKNavigationDelegate>
, DelegateProxyType
, WKNavigationDelegate {
    static func currentDelegate(for object: WKWebView) -> WKNavigationDelegate? {
        object.navigationDelegate
    }
    
    static func setCurrentDelegate(_ delegate: WKNavigationDelegate?, to object: WKWebView) {
        object.navigationDelegate = delegate
    }
    
    public static func registerKnownImplementations() {
        self.register { WKNavigationDelegateProxy(parentObject: $0) }
    }
    
    init(parentObject: WKWebView) {
        super.init(parentObject: parentObject, delegateProxy: WKNavigationDelegateProxy.self)
    }

    deinit {
        navigationActionEvent.onCompleted()
        navigationActionPrefsEvent.onCompleted()
        navigationResponseEvent.onCompleted()
    }

    func webView(_ webView: WKWebView,
				 decidePolicyFor navigationAction: WKNavigationAction,
				 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        navigationActionEvent.onNext((navigationAction, decisionHandler))
    }

    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView,
				 decidePolicyFor navigationAction: WKNavigationAction,
				 preferences: WKWebpagePreferences,
				 decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        navigationActionPrefsEvent.onNext((navigationAction, preferences, decisionHandler))
    }

    func webView(_ webView: WKWebView,
				 decidePolicyFor navigationResponse: WKNavigationResponse,
				 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        navigationResponseEvent.onNext((navigationResponse, decisionHandler))
    }

    fileprivate let navigationActionEvent = PublishSubject<NavigationActionEvent>()
    fileprivate let navigationActionPrefsEvent = PublishSubject<NavigationActionPrefsEvent>()
    fileprivate let navigationResponseEvent = PublishSubject<NavigationResponseEvent>()
}

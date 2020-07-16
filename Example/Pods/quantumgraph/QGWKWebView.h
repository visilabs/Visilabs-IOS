//
//  QGWKWebView.h
//  QGSdk
//
//  Created by Shiv.Raj on 18/2/19.
//  Copyright © 2019 APPIER INC. All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @abstract
 Delegate your custom injected javascript calls
 
 @discussion
 This protocol send back the injected javascript calls from your web page.
 Custom javascript can be injected using below method and register handlers.
 
 */
@protocol QGWKScriptMessageHandler <NSObject>

/*!
 @abstract
 Receives the call for your injected javascript
 */
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;

@end

/*!
 @abstract
 QGWKWebView is a subclass of WKWebView,
 helps to create communication bridge between webview and native ios.
 
 @discussion
 QGWKWebView can be used to load your website integrated with AIQUA web sdk.
 This helps track user events and attributes from your website to ios app.
 It has its own WKWebViewConfiguration and WKUserContentController with userScriptHandler.
 
 @note
 This class must be used after QGSdk is initialised using onStart.
 
 */
@interface QGWKWebView : WKWebView

/*!
 @abstract
 Inject your javascript to the webview
 
 @discussion
 This can be used to inject some javascript into the webview.
 */
- (void)injectUserScript:(WKUserScript *)userScript;

/*!
 @abstract
 Registers script message handler for your injected javascript
 
 @discussion
 This registers your message handlers for the injected javascript.
 The delegate will pass all the calls to these handler to the callee.
 
 */
- (void)addScriptMessageHandler:(NSString *)name;

@property (nonatomic, weak) id <QGWKScriptMessageHandler> delegate;

@end

NS_ASSUME_NONNULL_END

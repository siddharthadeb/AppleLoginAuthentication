//
//  AppleLoginAuthentication.swift
//  AppleLoginAuthentication
//
//  Created by Siddhartha S Deb on 27/08/20.
//  Copyright © 2020 Siddhartha S Deb. All rights reserved.
//

import UIKit
import AuthenticationServices
@objc public protocol AppleLoginDelegate {
    @objc optional func getAppleView() -> UIWindow
    @objc optional func getAppleUserInfo(_ userIdentifier: String, givenName: String, familyName: String, email: String) -> Void
    
}
class AppleLoginAuthentication: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
   public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        (self.delegate?.getAppleView?() ?? UIWindow())
    }
    
   public var delegate: AppleLoginDelegate?
   public func getAppleLoginAccess() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
    }
    /// - Tag: did_complete_authorization
   public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            // Create an account in your system.
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            self.showResultViewController(userIdentifier: userIdentifier, fullName: fullName, email: email)
        
        case let passwordCredential as ASPasswordCredential:
        
            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password
            
            // For the purpose of this demo app, show the password credential as an alert.
            DispatchQueue.main.async {
                self.showPasswordCredentialAlert(username: username, password: password)
            }
            
        default:
            break
        }
        
        
    }
 
    public func showResultViewController(userIdentifier: String, fullName: PersonNameComponents?, email: String?) {

        var giveNameValue = ""
        var familyNameValue = ""
        DispatchQueue.main.async {
       
            if let givenName = fullName?.givenName {
                giveNameValue = givenName
            }
            if let familyName = fullName?.familyName {
                familyNameValue = familyName
            }
        
            self.delegate?.getAppleUserInfo?(userIdentifier, givenName: giveNameValue, familyName: familyNameValue, email: email ?? "")
        }
    }
    
    public func showPasswordCredentialAlert(username: String, password: String) {
        let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
        let alertController = UIAlertController(title: "Keychain Credential Received",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
      //  self.present(alertController, animated: true, completion: nil)
    }
    
    /// - Tag: did_complete_error
   public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("authorization error")
        guard let error = error as? ASAuthorizationError else {
            return
        }

        switch error.code {
        case .canceled:
            // user press "cancel" during the login prompt
            print("Canceled")
        case .unknown:
            // user didn't login their Apple ID on the device
            print("Unknown")
        case .invalidResponse:
            // invalid response received from the login
            print("Invalid Respone")
        case .notHandled:
            // authorization request not handled, maybe internet failure during login
            print("Not handled")
        case .failed:
            // authorization failed
            print("Failed")
        @unknown default:
            print("Default")
        }
    }

}


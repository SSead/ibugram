//
//  LoginScreen.swift
//  ibugram
//
//  Created by Sead Smailagic on 27. 11. 2023..
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

struct LoginScreen: View {
    func login() -> Void {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { result, error in
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else {
                // ...
                return
                
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { result, error in
                if (error == nil) {
                    UserDefaults.standard.set(true, forKey:"signIn")
                }
            }
            
            // ...
        }
    }
    
    var body: some View {
        VStack(alignment:.center, spacing: 16) {
            Spacer()
            
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 16)
            
            Spacer()
            
            Button(action: login) {
                HStack(spacing: 8) {
                    Spacer()
                    
                    Image("google")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 24)
                    
                    
                    Text("Login with Google")
                        .font(.headline)
                        .padding(.vertical, 8)
                    
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .presentationCornerRadius(8)
        }
        .padding(16)
    }
}

#Preview {
    LoginScreen()
}

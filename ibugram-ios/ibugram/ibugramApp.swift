//
//  ibugramApp.swift
//  ibugram
//
//  Created by Sead Smailagic on 27. 11. 2023..
//

import SwiftUI

@main
struct ibugramApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("signIn") var isSignedIn = false
    
    var body: some Scene {
        WindowGroup {
            if (isSignedIn) {
                TabBar()
            } else {
                LoginScreen()
            }
        }
    }
}

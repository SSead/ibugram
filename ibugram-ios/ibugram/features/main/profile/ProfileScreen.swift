//
//  ProfileScreen.swift
//  ibugram
//
//  Created by Sead Smailagic on 27. 11. 2023..
//

import SwiftUI

struct ProfileScreen: View {
    func logout() -> Void {
        UserDefaults.standard.set(false, forKey: "signIn")
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Text("This is you!")
            Spacer()
            
            Button(action: logout) {
                HStack(spacing: 8) {
                    Spacer()
                    
                    Text("Logout")
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
    ProfileScreen()
}

//
//  TabBar.swift
//  ibugram
//
//  Created by Sead Smailagic on 27. 11. 2023..
//

import SwiftUI

enum TabName {
    case FEED
    case SEARCH
    case CHAT
    case PROFILE
}

struct TabBar: View {
    @State var selection = TabName.FEED
    
    var body: some View {
        TabView(selection: $selection) {
            FeedScreen().tabItem {
                Image(systemName: "menucard")
                Text("Feed")
            }.tag(TabName.FEED)
            
            SearchScreen()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }.tag(TabName.SEARCH)
            
            ChatScreen()
                .tabItem {
                    Image(systemName: "bubble")
                    Text("Chat")
                }.tag(TabName.CHAT)
            
            ProfileScreen()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }.tag(TabName.PROFILE)
            
            
        }
    }
}

#Preview {
    TabBar()
}


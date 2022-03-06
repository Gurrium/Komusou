//
//  KomusouApp.swift
//  Komusou
//
//  Created by gurrium on 2022/03/05.
//

import SwiftUI

@main
struct KomusouApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                PlayView()
                    .edgesIgnoringSafeArea(.top)
                    .tabItem {
                        Image(systemName: "bicycle")
                    }
                Text("Settings")
                    .tabItem {
                        Image(systemName: "gearshape")
                    }
            }
        }
    }
}

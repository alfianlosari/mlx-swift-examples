//
//  MLXChatApp.swift
//  MLXChat
//
//  Created by Alfian Losari on 21/02/24.
//

import SwiftUI

@main
struct MLXChatApp: App {
    
    @State var vm = ViewModel()
        
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {
                HeaderView(vm: $vm)
                Divider()
                ContentView(vm: $vm)
            }.frame(width: 500)
        }
        .windowResizability(.contentSize)
        
//        MenuBarExtra("XCA MLX Chat", systemImage: "bubbles.and.sparkles") {
//            VStack(spacing: 16) {
//                HeaderView(vm: $vm).padding([.horizontal, .top])
//                ContentView(vm: $vm)
//            }.frame(width: 480, height: 648)
//        }.menuBarExtraStyle(.window)
//        
        Settings {
            PreferencePane(vm: $vm)
        }
    }
}

//
//  MLXChatApp.swift
//  MLXChat
//
//  Created by Alfian Losari on 21/02/24.
//

import SwiftUI

struct HeaderView: View {
    
    @Binding var vm: ViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("XCA MLX Chat").font(.title)
                if let model = vm.model {
                    Text(model.lastPathComponent).font(.headline)
                } else {
                    Text("Select local LLM Folder in Settings Pane").font(.headline)
                }
            }
        
            Spacer()
            
            Button {
                guard !vm.isPrompting else { return }
                vm.clearMessages()
            } label: {
                Image(systemName: "trash")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 24))
            }.buttonStyle(.borderless)
            
            SettingsLink {
                Image(systemName: "gearshape")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 24))
            }
            
         
            
            Button {
                exit(0)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 24))
            }.buttonStyle(.borderless)
            
            

            
        }
        .padding()

    }
}

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

//
//  PreferencePane.swift
//  MLXChat
//
//  Created by Alfian Losari on 23/02/24.
//

import SwiftUI

struct PreferencePane: View {
    
    @Binding var vm: ViewModel
    @State var importing = false
    
    var body: some View {
        TabView {
            Group {
                VStack {
                    VStack {
                        Button("Select MLX LLM Folder") {
                            importing = true
                        }
                        .fileImporter(
                            isPresented: $importing,
                            allowedContentTypes: [.folder]
                        ) { result in
                            switch result {
                            case .success(let url):
                                vm.model = url
                                print(url.relativePath)
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
                        }
                        
                        if let model = vm.model {
                            Text(model.relativeString)
                        } else {
                            Text("No LLM Folder Selected")
                        }
                        
                        
                    }
                    .padding(.bottom, 24)
                
                    
                    VStack(alignment: .leading) {
                        Text("Max Tokens: \(Int(vm.maxTokens))")
                        Slider(value: $vm.maxTokens, in: 50...1000)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Temperature: \(String(format: "%.1f", vm.temperature))")
                        Slider(value: $vm.temperature, in: 0...1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Seed: \(Int(vm.seed))")
                        Slider(value: $vm.seed, in: 0...99999)
                    }
                }
                .padding()
            }
            .tabItem {
                Label("LLM Settings", systemImage: "gearshape")
            }
        }
        .frame(width: 340, height: 280)
    }
}

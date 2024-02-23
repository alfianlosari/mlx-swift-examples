//
//  HeaderView.swift
//  MLXChat
//
//  Created by Alfian Losari on 24/02/24.
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
            
        }
        .padding()

    }
}

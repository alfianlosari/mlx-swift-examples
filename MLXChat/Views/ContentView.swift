import SwiftUI

struct ContentView: View {
        
    @Environment(\.colorScheme) var colorScheme
    @Binding var vm: ViewModel
    @FocusState var isTextFieldFocused: Bool
    
    var body: some View {
        chatListView
    }
    
    var chatListView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.messages) { message in
                            MessageRowView(message: message) {
                                vm.retry(message: $0)
                            }
                        }
                    }
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
                Divider()
                bottomView(image: "profile", proxy: proxy)
                Spacer()
            }
            .onChange(of: vm.messages.last?.responseText) { _ in  scrollToBottom(proxy: proxy)
            }
        }
        .background(colorScheme == .light ? .white : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
    }
    
    func bottomView(image: String, proxy: ScrollViewProxy) -> some View {
        VStack {

            HStack(alignment: .top, spacing: 8) {
                if image.hasPrefix("http"), let url = URL(string: image) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .frame(width: 30, height: 30)
                    } placeholder: {
                        ProgressView()
                    }

                } else {
                    Image(image)
                        .resizable()
                        .frame(width: 30, height: 30)
                }
                
                TextField("Send message", text: $vm.inputMessage, axis: .vertical)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .disabled(vm.isPrompting)
                
                if vm.isPrompting {
                    Button {
                        vm.cancelStreamingResponse()
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 30))
                            .symbolRenderingMode(.multicolor)
                            .foregroundColor(.red)
                            
                    }.buttonStyle(.borderless)
    //                DotLoadingView().frame(width: 60, height: 30)
                } else {
                    Button {
                        Task { @MainActor in
                            isTextFieldFocused = false
                            scrollToBottom(proxy: proxy)
                            vm.sendTapped()
                        }
                    } label: {
                        Image(systemName: "paperplane.circle.fill")
                            .rotationEffect(.degrees(45))
                            .font(.system(size: 30))
                    }
                    .buttonStyle(.borderless)
                    .keyboardShortcut(.defaultAction)
                    .foregroundColor(.accentColor)
                    .disabled(vm.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let id = vm.messages.last?.id else { return }
        proxy.scrollTo(id, anchor: .bottomTrailing)
    }
}


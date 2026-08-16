import SwiftUI
import Security

private func keychainLoad(forKey key: String) -> String? {
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrAccount as String: key,
                                kSecReturnData as String: true,
                                kSecMatchLimit as String: kSecMatchLimitOne]
    var result: AnyObject?
    guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
          let data = result as? Data else { return nil }
    return String(data: data, encoding: .utf8)
}

struct ContentView: View {
    @State private var urlString = UserDefaults.standard.string(forKey: "serverURL") ?? ""
    @State private var username = UserDefaults.standard.string(forKey: "username") ?? "dsh"
    @State private var password = keychainLoad(forKey: "password") ?? ""
    @State private var showSettings = false
    @State private var loaded = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                if loaded {
                    WebView(urlString: urlString, username: username, password: password)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("连接中…")
                            .foregroundColor(.white)
                    }
                }
            }
            .navigationTitle("DSH Remote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("设置") { showSettings = true }
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                if !urlString.isEmpty {
                    loaded = true
                } else {
                    showSettings = true
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(
                    urlString: $urlString,
                    username: $username,
                    password: $password
                ) {
                    if !urlString.isEmpty {
                        loaded = true
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

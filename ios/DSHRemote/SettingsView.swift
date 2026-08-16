import SwiftUI
import Security

private func keychainSave(_ value: String, forKey key: String) {
    let data = Data(value.utf8)
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrAccount as String: key,
                                kSecValueData as String: data]
    SecItemDelete(query as CFDictionary)
    SecItemAdd(query as CFDictionary, nil)
}

struct SettingsView: View {
    @Binding var urlString: String
    @Binding var username: String
    @Binding var password: String
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("服务器") {
                    TextField("https://your-domain.de5.net/mobile", text: $urlString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                Section("账号") {
                    TextField("用户名（默认 dsh）", text: $username)
                        .autocapitalization(.none)
                    SecureField("密码（已保存，留空则不修改）", text: $password)
                }
            }
            .navigationTitle("DSH 服务器设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存并连接") {
                        UserDefaults.standard.set(urlString.trimmingCharacters(in: .whitespaces), forKey: "serverURL")
                        UserDefaults.standard.set(username.trimmingCharacters(in: .whitespaces), forKey: "username")
                        keychainSave(password, forKey: "password")
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

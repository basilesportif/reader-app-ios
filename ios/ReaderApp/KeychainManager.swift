import Foundation
import Security

enum KeychainManager {
    private static let service = "com.reader.ReaderApp"
    
    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        var newQuery = query
        newQuery[kSecValueData as String] = data
        
        SecItemAdd(newQuery as CFDictionary, nil)
    }
    
    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // Convenience methods for provider API keys
    static func getKey(for provider: ProviderType) -> String? {
        get(key: "apiKey_\(provider.rawValue)")
    }
    
    static func setKey(_ apiKey: String, for provider: ProviderType) {
        save(key: "apiKey_\(provider.rawValue)", value: apiKey)
    }
    
    static func deleteKey(for provider: ProviderType) {
        delete(key: "apiKey_\(provider.rawValue)")
    }
}

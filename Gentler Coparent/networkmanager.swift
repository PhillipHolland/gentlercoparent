import Foundation
import Network
import Combine

class NetworkManager: ObservableObject {
    // MARK: - Properties
    /// All model calls go through the Vercel backend. The Grok/xAI key lives ONLY in
    /// that project's env (`XAI_API_KEY` or `GROK_API_KEY`) — never in the iOS app.
    ///
    /// Override with Info.plist key `GCPChatAPIURL` if the deployment host changes.
    /// Dashboard project: vercel.com/gentler-coparent/… — host must match the project
    /// where you set the env var (today: gentler-coparent-simple-rag).
    private var enhancedChatURL: URL {
        if let custom = Bundle.main.object(forInfoDictionaryKey: "GCPChatAPIURL") as? String,
           !custom.isEmpty,
           let url = URL(string: custom) {
            return url
        }
        return URL(string: "https://gentler-coparent-simple-rag.vercel.app/api/enhanced-chat")!
    }
    
    private let session: URLSession
    
    // MARK: - Initialization
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60.0
        configuration.timeoutIntervalForResource = 120.0
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Methods
    /// Single entry: always use Vercel enhanced-chat (server holds Grok key).
    func performChatRequest(systemPrompt: String, messages: [[String: String]], onChunk: (@Sendable (String) -> Void)? = nil, userProfile: [String: Any]? = nil) async -> Result<String, Error> {
        print("☁️ Chat via Vercel backend: \(enhancedChatURL.absoluteString)")
        return await performEnhancedChatRequest(
            systemPrompt: systemPrompt,
            messages: messages,
            onChunk: onChunk,
            userProfile: userProfile
        )
    }
    
    func performEnhancedChatRequest(systemPrompt: String, messages: [[String: String]], onChunk: (@Sendable (String) -> Void)? = nil, userProfile: [String: Any]? = nil) async -> Result<String, Error> {
        // Configure the URL request for enhanced chat API
        var request = URLRequest(url: enhancedChatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get the user's message for knowledge matching
        let userMessage = messages.last?["content"] ?? ""
        
        // Construct the request body for enhanced chat
        var body: [String: Any] = [
            "message": userMessage,
            "systemPrompt": systemPrompt,
            "messages": messages.map { ["role": $0["role"] ?? "user", "content": $0["content"] ?? ""] }
        ]
        
        // Add user profile if provided — sanitize so Dates/URLs never hit JSONSerialization
        // (raw Date raises uncatchable NSInvalidArgumentException: Invalid type in JSON write)
        if let userProfile = userProfile {
            body["userProfile"] = Self.jsonSafeValue(userProfile)
        }
        
        // Serialize the body to JSON
        guard JSONSerialization.isValidJSONObject(body) else {
            print("❌ Enhanced chat body is not a valid JSON object (likely Date/URL in payload)")
            return .failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Request body contains non-JSON types"]))
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            // Log a short preview (full profile can be large)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let preview = jsonString.prefix(800)
                print("Sending request to Enhanced Chat API (\(jsonData.count) bytes): \(preview)…")
            }
        } catch {
            return .failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request body: \(error.localizedDescription)"]))
        }
        
        // Perform the request
        do {
            print("⏳ Starting enhanced chat request...")
            let startTime = Date()
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]))
            }
            
            print("📡 HTTP Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                let errorData = String(data: data, encoding: .utf8) ?? "No error data"
                print("❌ Enhanced chat error: \(errorData)")
                return .failure(NSError(domain: "NetworkManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(httpResponse.statusCode)"]))
            }
            
            // Parse the JSON response (knowledgeUsed optional for lean backends)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let response = json["response"] as? String {
                
                let knowledgeUsed = json["knowledgeUsed"] as? [String] ?? []
                let duration = Date().timeIntervalSince(startTime)
                let cleanResponse = ExpertSystem.sanitizeResponseIdentity(response)
                
                let confidenceScore = calculateRetrievalConfidence(
                    json: json,
                    knowledgeUsed: knowledgeUsed,
                    responseLength: cleanResponse.count
                )
                
                print("✅ Enhanced chat completed in \(String(format: "%.2f", duration))s")
                if !knowledgeUsed.isEmpty {
                    print("📚 Knowledge sections used: \(knowledgeUsed.joined(separator: ", "))")
                }
                print("🎯 Retrieval confidence: \(String(format: "%.1f", confidenceScore * 100))%")
                
                if let similarityScores = json["similarityScores"] as? [Double], !similarityScores.isEmpty {
                    let avgSimilarity = similarityScores.reduce(0, +) / Double(similarityScores.count)
                    print("📊 Average similarity score: \(String(format: "%.3f", avgSimilarity))")
                }
                
                // Simulate streaming for UI typewriter if callback provided
                if let onChunk = onChunk {
                    let chunkSize = 10
                    let responseChunks = stride(from: 0, to: cleanResponse.count, by: chunkSize).map {
                        String(cleanResponse[cleanResponse.index(cleanResponse.startIndex, offsetBy: $0)..<cleanResponse.index(cleanResponse.startIndex, offsetBy: min($0 + chunkSize, cleanResponse.count))])
                    }
                    
                    for chunk in responseChunks {
                        onChunk(chunk)
                        try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay between chunks
                    }
                }
                
                return .success(cleanResponse)
            } else {
                let preview = String(data: data, encoding: .utf8)?.prefix(300) ?? "n/a"
                print("❌ Enhanced chat invalid response format: \(preview)")
                return .failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format from chat backend"]))
            }
            
        } catch {
            let errorMessage = "Enhanced chat request failed: \(error.localizedDescription)"
            print("❌ \(errorMessage)")
            return .failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
        }
    }
    
    /// Direct api.x.ai calls are disabled — keys must not live in the app.
    /// Kept as a stub so any old call sites fail clearly.
    func performDirectChatRequest(systemPrompt: String, messages: [[String: String]], onChunk: (@Sendable (String) -> Void)? = nil) async -> Result<String, Error> {
        print("⛔ Direct Grok API is disabled. Chat goes through Vercel only (\(enhancedChatURL.absoluteString)).")
        return .failure(NSError(
            domain: "NetworkManager",
            code: 403,
            userInfo: [NSLocalizedDescriptionKey: "Direct Grok API disabled. Use Vercel backend (XAI_API_KEY on the server)."]
        ))
    }
    
    // MARK: - RAG Confidence Scoring
    private func calculateRetrievalConfidence(json: [String: Any], knowledgeUsed: [String], responseLength: Int) -> Double {
        var confidence: Double = 0.0
        
        // Factor 1: Number of knowledge sections used (more sections = higher confidence)
        let knowledgeCount = Double(knowledgeUsed.count)
        let knowledgeScore = min(knowledgeCount / 3.0, 1.0) // Max score at 3+ sections
        confidence += knowledgeScore * 0.3
        
        // Factor 2: Similarity scores if available
        if let similarityScores = json["similarityScores"] as? [Double], !similarityScores.isEmpty {
            let avgSimilarity = similarityScores.reduce(0, +) / Double(similarityScores.count)
            let maxSimilarity = similarityScores.max() ?? 0.0
            
            // Weight average and max similarity
            let similarityScore = (avgSimilarity * 0.7) + (maxSimilarity * 0.3)
            confidence += similarityScore * 0.4
        } else {
            // If no similarity scores, give moderate confidence if knowledge was used
            confidence += knowledgeCount > 0 ? 0.2 : 0.0
        }
        
        // Factor 3: Response quality indicators
        if responseLength > 50 {
            confidence += 0.1 // Substantial response
        }
        
        if let retrievalTime = json["retrievalTime"] as? Double, retrievalTime < 2.0 {
            confidence += 0.1 // Fast retrieval usually means good matches
        }
        
        // Factor 4: Topic match indicators
        if let topicMatch = json["topicMatch"] as? Bool, topicMatch {
            confidence += 0.1
        }
        
        return min(confidence, 1.0) // Cap at 100%
    }
    
    // MARK: - JSON safety
    /// Recursively convert Foundation values into JSONSerialization-safe types.
    /// `Date` / `URL` must never reach `JSONSerialization` (raises uncatchable NSException).
    private static func jsonSafeValue(_ value: Any) -> Any {
        switch value {
        case let date as Date:
            return ISO8601DateFormatter().string(from: date)
        case let url as URL:
            return url.absoluteString
        case let data as Data:
            return data.base64EncodedString()
        case let dict as [String: Any]:
            return dict.mapValues { jsonSafeValue($0) }
        case let array as [Any]:
            return array.map { jsonSafeValue($0) }
        case is String, is NSNumber, is Bool, is NSNull:
            return value
        case let n as Int:
            return n
        case let n as Double:
            return n
        case let n as Float:
            return n
        default:
            // Drop unknown objects rather than crash
            if let s = value as? CustomStringConvertible {
                return s.description
            }
            return NSNull()
        }
    }
}

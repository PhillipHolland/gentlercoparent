import Foundation
import Network
import Combine

class NetworkManager: ObservableObject {
    // MARK: - Properties
    /// Prefer Info.plist `XAIAPIKey` or env `XAI_API_KEY` — never hardcode secrets in source.
    private var apiKey: String {
        if let plist = Bundle.main.object(forInfoDictionaryKey: "XAIAPIKey") as? String,
           !plist.isEmpty, !plist.hasPrefix("$(") {
            return plist
        }
        if let env = ProcessInfo.processInfo.environment["XAI_API_KEY"], !env.isEmpty {
            return env
        }
        return ""
    }
    private let model = "grok-4.5"
    private let apiURL = URL(string: "https://api.x.ai/v1/chat/completions")!
    private let enhancedChatURL = URL(string: "https://gentler-coparent-simple-rag.vercel.app/api/enhanced-chat")!
    private let session: URLSession
    
    // MARK: - Initialization
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0  // Reasonable timeout for streaming responses
        configuration.timeoutIntervalForResource = 60.0  // Allow time for longer responses  
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Methods
    func performChatRequest(systemPrompt: String, messages: [[String: String]], onChunk: (@Sendable (String) -> Void)? = nil, userProfile: [String: Any]? = nil) async -> Result<String, Error> {
        // Check if this is a simple query that might not benefit from RAG
        let userMessage = messages.last?["content"] ?? ""
        let isSimpleQuery = userMessage.count < 50 && 
                           !userMessage.contains("screenshot") && 
                           !userMessage.contains("message") &&
                           !userMessage.contains("analyze") &&
                           !userMessage.contains("help with") &&
                           (userMessage.contains("How to") || userMessage.contains("What") || userMessage.contains("💡") || userMessage.contains("🌟"))
        
        // For very simple queries, try direct API first with shorter timeout
        if isSimpleQuery {
            print("🚀 Simple query detected, trying direct API first for speed")
            let directResult = await performDirectChatRequest(systemPrompt: systemPrompt, messages: messages, onChunk: onChunk)
            if case .success = directResult {
                return directResult
            }
        }
        
        // Try enhanced knowledge service first, fallback to direct API if it fails
        let enhancedResult = await performEnhancedChatRequest(systemPrompt: systemPrompt, messages: messages, onChunk: onChunk, userProfile: userProfile)
        
        switch enhancedResult {
        case .success(let response):
            return .success(response)
        case .failure(let error):
            print("🔄 Enhanced chat failed, falling back to direct API: \(error.localizedDescription)")
            // Fallback to direct cloud API (identity still forced via system prompt)
            return await performDirectChatRequest(systemPrompt: systemPrompt, messages: messages, onChunk: onChunk)
        }
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
            
            // Parse the JSON response with enhanced confidence scoring
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let response = json["response"] as? String,
               let knowledgeUsed = json["knowledgeUsed"] as? [String] {
                
                let duration = Date().timeIntervalSince(startTime)
                let cleanResponse = ExpertSystem.sanitizeResponseIdentity(response)
                
                // Calculate confidence score based on knowledge retrieval success
                let confidenceScore = calculateRetrievalConfidence(json: json, knowledgeUsed: knowledgeUsed, responseLength: cleanResponse.count)
                
                print("✅ Enhanced chat completed in \(String(format: "%.2f", duration))s")
                print("📚 Knowledge sections used: \(knowledgeUsed.joined(separator: ", "))")
                print("🎯 Retrieval confidence: \(String(format: "%.1f", confidenceScore * 100))%")
                
                // Log detailed retrieval metrics
                if let similarityScores = json["similarityScores"] as? [Double], !similarityScores.isEmpty {
                    let avgSimilarity = similarityScores.reduce(0, +) / Double(similarityScores.count)
                    print("📊 Average similarity score: \(String(format: "%.3f", avgSimilarity))")
                }
                
                // Check if confidence is too low and we should fallback to direct API
                if confidenceScore < 0.3 {
                    print("⚠️ Low confidence retrieval (\(String(format: "%.1f", confidenceScore * 100))%) - response may benefit from direct API fallback")
                }
                
                // Simulate streaming by sending the full response in chunks if callback provided
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
                return .failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]))
            }
            
        } catch {
            let errorMessage = "Enhanced chat request failed: \(error.localizedDescription)"
            print("❌ \(errorMessage)")
            return .failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
        }
    }
    
    func performDirectChatRequest(systemPrompt: String, messages: [[String: String]], onChunk: (@Sendable (String) -> Void)? = nil) async -> Result<String, Error> {
        let key = apiKey
        guard !key.isEmpty else {
            return .failure(NSError(
                domain: "NetworkManager",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Missing XAI API key. Set XAIAPIKey in Info.plist or XAI_API_KEY in the environment."]
            ))
        }
        // Configure the URL request
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Construct the messages array with systemPrompt as the first message
        var fullMessages = [[String: String]]()
        fullMessages.append(["role": "system", "content": systemPrompt]) // Add systemPrompt as system message
        fullMessages.append(contentsOf: messages) // Append the rest of the messages
        
        // Construct the request body
        let body: [String: Any] = [
            "messages": fullMessages,
            "model": model,
            "stream": true,
            "temperature": 0
        ]
        
        // Serialize the body to JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            print("Sending request to cloud AI API (\(model)), \(jsonData.count) bytes")
        } catch {
            return .failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request body: \(error.localizedDescription)"]))
        }
        
        // Perform the streaming request
        do {
            print("⏳ Starting streaming cloud AI request...")
            let startTime = Date()
            
            let (asyncBytes, response) = try await session.bytes(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]))
            }
            
            print("📡 HTTP Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                return .failure(NSError(domain: "NetworkManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(httpResponse.statusCode)"]))
            }
            
            var fullResponse = ""
            var currentChunk = ""
            
            // Process streaming chunks
            for try await line in asyncBytes.lines {
                if line.isEmpty || line == "data: [DONE]" {
                    continue
                }
                
                if line.hasPrefix("data: ") {
                    let jsonString = String(line.dropFirst(6))
                    
                    if let data = jsonString.data(using: .utf8) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let choices = json["choices"] as? [[String: Any]],
                               let firstChoice = choices.first,
                               let delta = firstChoice["delta"] as? [String: Any],
                               let content = delta["content"] as? String {
                                
                                currentChunk += content
                                fullResponse += content
                                
                                // Send chunk to UI callback
                                if let onChunk = onChunk {
                                    onChunk(content)
                                }
                                
                                // Log progress periodically
                                if fullResponse.count % 50 == 0 {
                                    let elapsed = Date().timeIntervalSince(startTime)
                                    print("📝 Received \(fullResponse.count) characters in \(String(format: "%.1f", elapsed))s")
                                }
                            }
                        } catch {
                            print("⚠️ Failed to parse JSON chunk: \(error)")
                            continue
                        }
                    }
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            print("✅ Streaming completed in \(String(format: "%.2f", duration))s with \(fullResponse.count) characters")
            
            guard !fullResponse.isEmpty else {
                return .failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty response received"]))
            }
            
            // Client-side identity lock: never surface provider model names to users.
            return .success(ExpertSystem.sanitizeResponseIdentity(fullResponse))
            
        } catch {
            let errorMessage = "Request failed: \(error.localizedDescription)"
            print("❌ \(errorMessage)")
            return .failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
        }
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

//
//  MCPTool.swift
//  FM CLI
//
//  MCP tool implementation for Foundation Models integration
//

import Foundation
import FoundationModels
import MCP
import Logging

/// Arguments wrapper for MCP tool calls
struct MCPToolArgument: ConvertibleFromGeneratedContent {
    let content: GeneratedContent
    
    init(_ content: GeneratedContent) throws {
        self.content = content
    }
    
    /// Converts GeneratedContent to MCP Value format
    func toMCPArguments() throws -> [String: Value] {
        var arguments: [String: Value] = [:]
        
        try content.properties().forEach { name, content in
            arguments[name] = try convertToMCPValue(content)
        }
        
        return arguments
    }
    
    // MARK: - Private Methods
    
    private func convertToMCPValue(_ content: GeneratedContent) throws -> Value {
        // Try different types in order of preference
        if let stringValue = try? content.value(String.self) {
            return .string(stringValue)
        } else if let intValue = try? content.value(Int.self) {
            return .int(intValue)
        } else if let doubleValue = try? content.value(Double.self) {
            return .double(doubleValue)
        } else if let boolValue = try? content.value(Bool.self) {
            return .bool(boolValue)
        } else {
            // Fallback to string representation
            return .string(String(describing: content))
        }
    }
}

/// Foundation Models tool implementation that wraps MCP tools
struct MCPTool: FoundationModels.Tool {
    typealias Arguments = MCPToolArgument
    
    // MARK: - Properties
    
    private let mcpTool: MCP.Tool
    private let mcpClient: MCP.Client
    
    var name: String {
        mcpTool.name
    }
    
    var description: String {
        mcpTool.description
    }
    
    var parameters: GenerationSchema {
        convertMCPSchemaToGenerationSchema()
    }
    
    var includesSchemaInInstructions: Bool = true
    
    // MARK: - Initialization
    
    init(_ mcpTool: MCP.Tool, mcpClient: MCP.Client) {
        self.mcpTool = mcpTool
        self.mcpClient = mcpClient
    }
    
    // MARK: - Tool Execution
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        let mcpArguments = try arguments.toMCPArguments()
        
        let (contents, isError) = try await mcpClient.callTool(
            name: name,
            arguments: mcpArguments
        )
        
        if isError == true {
            logger.error("MCP tool '\(name)' returned an error")
        }
        
        let outputText = convertContentsToText(contents)
        return ToolOutput(GeneratedContent(outputText))
    }
    
    // MARK: - Private Methods
    
    private func convertMCPSchemaToGenerationSchema() -> GenerationSchema {
        guard let schema = mcpTool.inputSchema else {
            return GenerationSchema(type: String.self, properties: [])
        }
        
        let values = schema.arrayValue ?? [schema]
        let properties = values.compactMap { value -> GenerationSchema.Property? in
            convertMCPValueToProperty(value)
        }
        
        return GenerationSchema(type: String.self, properties: properties)
    }
    
    private func convertMCPValueToProperty(_ value: Value) -> GenerationSchema.Property? {
        let propertyName = extractPropertyName(from: value)
        let description = String(describing: value)
        
        switch value {
        case .string:
            return GenerationSchema.Property(name: propertyName, description: description, type: String.self)
        case .int:
            return GenerationSchema.Property(name: propertyName, description: description, type: Int.self)
        case .double:
            return GenerationSchema.Property(name: propertyName, description: description, type: Double.self)
        case .bool:
            return GenerationSchema.Property(name: propertyName, description: description, type: Bool.self)
        case .null:
            return GenerationSchema.Property(name: propertyName, description: description, type: String.self)
        case .data, .array, .object:
            // TODO: Implement complex type conversion
            logger.debug("Complex MCP type not yet supported: \(value)")
            return GenerationSchema.Property(name: propertyName, description: description, type: String.self)
        }
    }
    
    private func extractPropertyName(from value: Value) -> String {
        // TODO: Extract actual property name from schema
        return "value"
    }
    
    private func convertContentsToText(_ contents: [MCP.Tool.Content]) -> String {
        var text = ""
        
        for content in contents {
            switch content {
            case .text(let str):
                text += str
            case .image(data: _, mimeType: let mimeType, metadata: _):
                text += "[Image: \(mimeType)]"
            case .audio(data: _, mimeType: let mimeType):
                text += "[Audio: \(mimeType)]"
            case .resource(uri: let uri, mimeType: let mimeType, text: let resourceText):
                if let resourceText = resourceText {
                    text += resourceText
                } else {
                    text += "[Resource: \(uri) (\(mimeType ?? "unknown"))]"
                }
            }
        }
        
        return text
    }
}

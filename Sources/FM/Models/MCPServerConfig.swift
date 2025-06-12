//
//  MCPServerConfig.swift
//  FM CLI
//
//  Configuration and implementation for MCP servers
//

import Foundation
import FoundationModels
import MCP
import Logging

/// Configuration for an MCP server
struct MCPServerConfig: Codable {
    let type: String?
    let command: String
    let args: [String]
    let env: [String: String]?
    
    /// Creates tools from this MCP server configuration
    /// - Parameter name: The name identifier for this server
    /// - Returns: Array of tools provided by the server
    func createTools(named name: String) async throws -> [any FoundationModels.Tool] {
        logger.debug("Starting MCP server: \(name)")
        
        let process = try createProcess()
        let transport = process.stdioTransport(logger: logger)
        
        try process.run()
        
        let client = Client(name: name, version: "1.0.0")
        try await client.connect(transport: transport)
        
        return try await loadToolsFromClient(client)
    }
    
    // MARK: - Private Methods
    
    private func createProcess() throws -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        
        // Construct arguments: command followed by its arguments
        var processArgs = [command]
        processArgs.append(contentsOf: args)
        process.arguments = processArgs
        
        // Set environment variables if specified
        if let serverEnv = env {
            var environment = ProcessInfo.processInfo.environment
            for (key, value) in serverEnv {
                environment[key] = value
            }
            process.environment = environment
        }
        
        return process
    }
    
    private func loadToolsFromClient(_ client: Client) async throws -> [any FoundationModels.Tool] {
        let (listedTools, nextCursor) = try await client.listTools()
        
        // TODO: Handle pagination with nextCursor
        if nextCursor != nil {
            logger.warning("MCP server returned paginated results - some tools may be missing")
        }
        
        return listedTools.map { MCPTool($0, mcpClient: client) }
    }
}

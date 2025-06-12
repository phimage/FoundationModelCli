//
//  ToolService.swift
//  FM CLI
//
//  Service for loading and managing tools from various sources
//

import Foundation
import FoundationModels
import Logging

/// Service responsible for loading tools from various sources
struct ToolService {
    
    /// Loads all available tools from configured sources
    /// - Returns: Array of Foundation Model tools
    func loadTools() async -> [any FoundationModels.Tool] {
        var tools: [any FoundationModels.Tool] = []
        
        // Load tools from Claude MCP servers
        tools.append(contentsOf: await loadMCPTools())
        
        // TODO: Add other tool sources here (local tools, APIs, etc.)
        
        logger.debug("Loaded \(tools.count) tools total")
        return tools
    }
    
    // MARK: - Private Methods
    
    private func loadMCPTools() async -> [any FoundationModels.Tool] {
        var tools: [any FoundationModels.Tool] = []
        
        do {
            let claudeConfig = try ClaudeConfigService.loadConfig()
            
            for (serverName, serverConfig) in claudeConfig.mcpServers {
                do {
                    let serverTools = try await serverConfig.createTools(named: serverName)
                    tools.append(contentsOf: serverTools)
                    logger.debug("Loaded \(serverTools.count) tools from MCP server: \(serverName)")
                } catch {
                    logger.error("Failed to load tools from MCP server '\(serverName)': \(error.localizedDescription)")
                }
            }
            
            if !claudeConfig.mcpServers.isEmpty {
                logger.debug("Loaded \(tools.count) MCP tools from \(claudeConfig.mcpServers.count) servers")
            }
            
        } catch {
            logger.error("Error loading Claude configuration: \(error.localizedDescription)")
        }
        
        return tools
    }
}

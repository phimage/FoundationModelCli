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
        tools.append(contentsOf: await loadClaudeMCPTools())
        
        // Load tools from VS Code MCP servers
        tools.append(contentsOf: await loadVSCodeMCPTools())
        
        // TODO: Add other tool sources here (local tools, APIs, etc.)
        
        logger.debug("Loaded \(tools.count) tools total")
        return tools
    }
                                                                                 
    // MARK: - Internal Methods (for testing and diagnostics)
    
    func loadClaudeMCPTools() async -> [any FoundationModels.Tool] {
        var tools: [any FoundationModels.Tool] = []
        
        do {
            let claudeConfig = try ClaudeConfigService.loadConfig()
            
            for (serverName, serverConfig) in claudeConfig.mcpServers {
                do {
                    let serverTools = try await serverConfig.createTools(named: serverName)
                    tools.append(contentsOf: serverTools)
                    logger.debug("Loaded \(serverTools.count) tools from Claude MCP server: \(serverName)")
                } catch {
                    logger.error("Failed to load tools from Claude MCP server '\(serverName)': \(error.localizedDescription)")
                }
            }
            
            if !claudeConfig.mcpServers.isEmpty {
                logger.debug("Loaded \(tools.count) Claude MCP tools from \(claudeConfig.mcpServers.count) servers")
            }
            
        } catch {
            logger.error("Error loading Claude configuration: \(error.localizedDescription)")
        }
        
        return tools
    }
    
    func loadVSCodeMCPTools() async -> [any FoundationModels.Tool] {
        var tools: [any FoundationModels.Tool] = []
        
        do {
            let vsCodeConfig = try VSCodeConfigService.loadConfig()
            
            guard let mcpServers = vsCodeConfig.mcp?.servers else {
                logger.debug("No MCP servers found in VS Code configuration")
                return tools
            }
            
            for (serverName, serverConfig) in mcpServers {
                do {
                    let serverTools = try await serverConfig.createTools(named: serverName)
                    tools.append(contentsOf: serverTools)
                    logger.debug("Loaded \(serverTools.count) tools from VS Code MCP server: \(serverName)")
                } catch {
                    logger.error("Failed to load tools from VS Code MCP server '\(serverName)': \(error.localizedDescription)")
                }
            }
            
            if !mcpServers.isEmpty {
                logger.debug("Loaded \(tools.count) VS Code MCP tools from \(mcpServers.count) servers")
            }
            
        } catch {
            logger.error("Error loading VS Code configuration: \(error.localizedDescription)")
        }
        
        return tools
    }
}

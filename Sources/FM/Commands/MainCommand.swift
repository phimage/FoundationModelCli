//
//  MainCommand.swift
//  FM CLI
//
//  A command-line interface for Foundation Models with MCP support
//

import Foundation
import FoundationModels
import ArgumentParser
import Logging

/// Main command-line interface for the Foundation Model CLI
@main
struct MainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fm",
        abstract: "A command-line interface for Foundation Models with MCP support",
        version: "1.0.0"
    )
    
    @Option(name: .long, help: "Specify system instructions for the model")
    var systemInstructions: String = "You are a helpful assistant."

    @Option(name: .long, help: "Set model temperature (0.0-1.0, default: 0.7)")
    var temperature: Double = 0.7
   
    @Option(name: .long, help: "Maximum response tokens")
    var maximumResponseTokens: Int?
    
    @Flag(name: .long, help: "Enable debug logging")
    var debug: Bool = false
    
    @Flag(name: [.short, .long], help: "Run in interactive mode")
    var interactive: Bool = false
    
    @Option(name: .long, help: "Comma-separated list of authorized MCP tool names. If not specified, all tools are authorized. Use empty string to disable all MCP tools.")
    var authorizedTools: String?
    
    @Argument(help: "The request to send to the model")
    var request: String?
    
    mutating func run() async throws {
        setupLogging()
        
        let tools = await loadTools()
        let session = createSession(with: tools)
        let options = createGenerationOptions()
        
        if interactive {
            try await InteractiveSession(session: session, options: options).run()
        } else {
            try await processSingleRequest(session: session, options: options)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupLogging() {
        logger.logLevel = debug ? .debug : .info
    }
    
    private func loadTools() async -> [any FoundationModels.Tool] {
        // Check if MCP tools should be disabled
        if let authorizedTools = authorizedTools, authorizedTools.isEmpty {
            logger.debug("MCP tools disabled via empty authorized-tools option")
            return []
        }
        
        let toolService = ToolService()
        let allTools = await toolService.loadTools()
        
        // Remove duplicates by name
        let uniqueTools = removeDuplicateTools(from: allTools)
        
        // Filter tools if specific names are provided
        if let authorizedTools = authorizedTools {
            let authorizedNames = Set(authorizedTools.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
            let filteredTools = uniqueTools.filter { authorizedNames.contains($0.name) }
            logger.debug("Filtered to \(filteredTools.count) authorized tools from \(uniqueTools.count) available tools")
            return filteredTools
        }
        
        logger.debug("Using all \(uniqueTools.count) available tools")
        return uniqueTools
    }
    
    private func removeDuplicateTools(from tools: [any FoundationModels.Tool]) -> [any FoundationModels.Tool] {
        var seenNames = Set<String>()
        var uniqueTools: [any FoundationModels.Tool] = []
        
        for tool in tools {
            if !seenNames.contains(tool.name) {
                seenNames.insert(tool.name)
                uniqueTools.append(tool)
            } else {
                logger.debug("Removing duplicate tool: \(tool.name)")
            }
        }
        
        return uniqueTools
    }
    
    private func createSession(with tools: [any FoundationModels.Tool]) -> LanguageModelSession {
        logger.debug("Loaded tools: \(tools.map(\.name))")
        let model = SystemLanguageModel.default
        return LanguageModelSession(
            model: model,
            guardrails: .default,
            tools: tools,
            instructions: systemInstructions
        )
    }
    
    private func createGenerationOptions() -> GenerationOptions {
        return GenerationOptions(
            sampling: nil,
            temperature: temperature,
            maximumResponseTokens: maximumResponseTokens
        )
    }
    
    private func processSingleRequest(session: LanguageModelSession, options: GenerationOptions) async throws {
        guard let request = request else {
            throw ValidationError("Request is required in non-interactive mode. Use --interactive flag for interactive mode.")
        }
        
        do {
            let response = try await session.respond(to: request, options: options)
            print(response.content)
        } catch {
            logger.error("Error processing request: \(error.localizedDescription)")
            throw error
        }
    }
}

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
        let toolService = ToolService()
        return await toolService.loadTools()
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

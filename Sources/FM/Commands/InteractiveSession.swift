//
//  InteractiveSession.swift
//  FM CLI
//
//  Handles interactive shell functionality
//

import Foundation
import FoundationModels
import Logging

/// Manages interactive shell sessions with the language model
struct InteractiveSession {
    private let session: LanguageModelSession
    private let options: GenerationOptions
    
    init(session: LanguageModelSession, options: GenerationOptions) {
        self.session = session
        self.options = options
    }
    
    func run() async throws {
        print("🤖 Interactive Foundation Model CLI")
        print("Type your messages and press Enter. Use 'quit' or 'exit' to stop.")
        print("---")
        
        // Initial greeting from the model
        do {
            let response = try await session.respond(to: "", options: options)
            if !response.content.isEmpty {
                print("Assistant: \(response.content)")
            }
        } catch {
            logger.warning("Failed to get initial response: \(error.localizedDescription)")
        }
        
        await startInteractiveLoop()
    }
    
    // MARK: - Private Methods
    
    private func startInteractiveLoop() async {
        while true {
            print("\n> ", terminator: "")
            fflush(stdout)
            
            guard let input = readLine() else {
                break
            }
            
            let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if shouldExit(input: trimmedInput) {
                print("👋 Goodbye!")
                break
            }
            
            if !trimmedInput.isEmpty {
                await processUserInput(trimmedInput)
            }
        }
    }
    
    private func shouldExit(input: String) -> Bool {
        let exitCommands = ["quit", "exit", "bye", "q"]
        return exitCommands.contains(input.lowercased())
    }
    
    private func processUserInput(_ input: String) async {
        do {
            let response = try await session.respond(to: input, options: options)
            print("Assistant: \(response.content)")
        } catch {
            logger.error("Error: \(error.localizedDescription)")
            print("❌ Sorry, I encountered an error processing your request.")
        }
    }
}

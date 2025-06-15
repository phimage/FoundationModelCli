# FM CLI - Foundation Model Command Line Interface

A command-line interface for interacting with Foundation Models, featuring support for Model Context Protocol (MCP) servers and Claude Desktop integration.

## Features

- 🤖 **Interactive Chat Mode**: Real-time conversations with Foundation Models
- 🔧 **MCP Integration**: Automatic loading of tools from Claude Desktop configuration
- ⚙️ **Configurable**: Customizable system instructions, temperature, and token limits

## Installation

### Prerequisites

- macOS 26.0 or later
- Swift 6.2 or later
- Xcode 26.0 or later (for development)

### Building from Source

```bash
git clone <repository-url>
cd FoundationModelCli
swift build -c release
```

The executable will be available at `.build/release/fm`.

## Usage

### Basic Usage

```bash
# Single request
fm "Tell me a joke"

# Interactive mode
fm --interactive

# With custom system instructions
fm --system-instructions "You are a coding assistant" --interactive

# With custom temperature
fm --temperature 0.9 "Be creative and write a story"
```

### Command Line Options

- `--interactive` / `-i`: Start interactive chat mode
- `--system-instructions`: Set custom system instructions
- `--temperature`: Control randomness (0.0-1.0, default: 0.7)
- `--maximum-response-tokens`: Limit response length
- `--debug`: Enable detailed logging
- `--help`: Show help information

### Interactive Mode Commands

- Type your messages and press Enter
- Use `quit`, `exit`, `bye`, or `q` to exit
- Empty messages are ignored

## Configuration

FM CLI automatically loads MCP servers from your Claude Desktop configuration file located at:
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

No additional configuration is required if you have Claude Desktop set up with MCP servers.

Sample for VSCode configuration file.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

See LICENSE file for details.

## Troubleshooting

### Enable Debug Logging

```bash
fm --debug --interactive
```

### Common Issues

- **No tools loaded**: Ensure Claude Desktop is configured with MCP servers
- **Permission errors**: Check that MCP server executables are accessible
- **Connection issues**: Verify MCP server configurations in Claude Desktop

For more help, run `fm --help` or enable debug logging to see detailed information about tool loading and execution.

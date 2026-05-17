# protonvpn-cli-wrapper

A bash wrapper CLI script to add/extend the ProtonVPN CLI commands with additional functionality like port-forwarding keep-alive support.

## Features

- **Port Forwarding Keep-Alive**: Automatically renews NAT-PMP port mappings to prevent disconnection timeouts
- **Extended Commands**: 
  - `protonvpn connect` - Start with port-forwarding keep-alive in background
  - `protonvpn disconnect` - Stop keep-alive before disconnecting
  - `protonvpn get-port` - Display the current mapped port
  - `protonvpn keepalive-logs` - Follow live keep-alive logs
  - `protonvpn keepalive-stop` - Stop the background keep-alive process

## Installation

### Quick Install (Recommended)

Copy and paste this command into your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/pjortiz/protonvpn-cli-wrapper/main/install.sh | bash
```

This will:
1. Download the wrapper script from the GitHub repository
2. Install it to `~/.protonvpn-wrapper/`
3. Add the necessary source line to your shell configuration files (`.bashrc`, `.bash_profile`, `.profile`, `.zshrc`, `.config/fish/config.fish`)

After installation, reload your shell:
```bash
source ~/.bashrc  # or your respective shell rc file
```

### Manual Installation

If you prefer to install manually:

1. **Clone or download the repository:**
   ```bash
   git clone https://github.com/pjortiz/protonvpn-cli-wrapper.git
   # or download protonvpn_wrapper.sh directly
   ```

2. **Create the installation directory and copy the wrapper:**
   ```bash
   mkdir -p ~/.protonvpn-wrapper
   cp protonvpn_wrapper.sh ~/.protonvpn-wrapper/
   chmod +x ~/.protonvpn-wrapper/protonvpn_wrapper.sh
   ```

3. **Add the source line to your shell configuration:**
   
   Choose one of the files below based on your shell:
   - **Bash**: `~/.bashrc` or `~/.bash_profile`
   - **Zsh**: `~/.zshrc`
   - **Fish**: `~/.config/fish/config.fish`
   
   Add this line to the end of your chosen file:
   ```bash
   [ -f ~/.protonvpn-wrapper/protonvpn_wrapper.sh ] && source ~/.protonvpn-wrapper/protonvpn_wrapper.sh
   ```

4. **Reload your shell configuration:**
   ```bash
   source ~/.bashrc  # or your respective shell rc file
   ```

## Usage

### Basic Commands

```bash
# Connect with port-forwarding keep-alive
protonvpn connect

# Disconnect (stops keep-alive first)
protonvpn disconnect

# Get current mapped port
protonvpn get-port

# Follow keep-alive logs in real-time
protonvpn keepalive-logs

# Stop the keep-alive background process
protonvpn keepalive-stop
```

## Uninstall

To remove the ProtonVPN CLI wrapper:

1. **Remove the installation directory:**
   ```bash
   rm -rf ~/.protonvpn-wrapper
   ```

2. **Remove the source line from your shell configuration files:**
   
   Open and edit:
   - `~/.bashrc`
   - `~/.bash_profile`
   - `~/.profile`
   - `~/.zshrc`
   - `~/.config/fish/config.fish`
   
   Remove or comment out the line:
   ```bash
   [ -f ~/.protonvpn-wrapper/protonvpn_wrapper.sh ] && source ~/.protonvpn-wrapper/protonvpn_wrapper.sh
   ```

3. **Reload your shell:**
   ```bash
   source ~/.bashrc  # or your respective shell rc file
   ```

## Requirements

- `protonvpn-cli`: The official ProtonVPN command-line client
- `natpmpc`: For NAT-PMP port mapping support
- Standard Unix tools: `curl`, `bash`, `grep`

## License

See LICENSE file for details.

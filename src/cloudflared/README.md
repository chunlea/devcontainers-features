# Cloudflared (cloudflared)

Installs cloudflared - the Cloudflare Tunnel client for exposing local services securely.

## Example Usage

```json
"features": {
    "ghcr.io/chunlea/devcontainers-features/cloudflared:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the version to install. Use 'latest' for the most recent release, or specify a version number (e.g., '2024.1.0'). | string | latest |

## What is cloudflared?

[cloudflared](https://github.com/cloudflare/cloudflared) is the command-line client for Cloudflare Tunnel, a tunneling daemon that proxies traffic from the Cloudflare network to your origins. This enables you to:

- Expose local web servers to the internet securely without opening ports
- Create secure tunnels to Cloudflare's network
- Access internal services through Cloudflare Access
- Run quick tunnels for development and testing

## Usage Examples

### Quick Tunnel (No Cloudflare account required)

```bash
# Expose a local web server on port 8080
cloudflared tunnel --url http://localhost:8080
```

### Named Tunnel (Requires Cloudflare account)

```bash
# Login to Cloudflare
cloudflared tunnel login

# Create a tunnel
cloudflared tunnel create my-tunnel

# Run the tunnel
cloudflared tunnel run my-tunnel
```

## Supported Architectures

- x86_64 (amd64)
- aarch64/arm64
- armv7l (arm)

---

_Note: This feature downloads cloudflared directly from the official GitHub releases._

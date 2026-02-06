# LSS Configuration Guide

This document covers all configuration options for the LSS plugin.

## Llama Stack Configuration

```yaml
lss:
  llamaStack:
    baseUrl: "http://localhost:8321"
    model: "meta-llama/Llama-3.2-3B-Instruct"
    vectorStoreName: "my-knowledge-base"
```

## Security Configuration

| Option | Description | Default |
|--------|-------------|---------|
| `mode` | Security mode: none, plugin-only, full | none |
| `requiredGroup` | Keycloak group for access control | - |

## RAG Configuration

Enable RAG by configuring document sources:

- **Directory**: Local filesystem paths
- **GitHub**: Fetch from GitHub repos
- **URL**: Fetch from web endpoints

## MCP Server Configuration

```yaml
lss:
  mcpServers:
    - id: openshift-server
      name: OpenShift MCP Server
      type: streamable-http
      url: "https://your-mcp-server.com/mcp"
```

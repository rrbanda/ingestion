# LSS Troubleshooting Guide

Common issues and solutions for the LSS plugin.

## Blank Response on Second Prompt

**Symptom**: First prompt works, second prompt returns blank.

**Cause**: Llama Stack not storing responses (previous_response_id fails).

**Solutions**:
1. Check `zdrMode` is not set to `true`
2. Verify Llama Stack server has storage configured
3. Check `store: true` is being sent in API requests

## RAG Not Finding Documents

**Symptom**: Knowledge base search returns no results.

**Checklist**:
1. Verify documents are ingested: `GET /api/lss/documents`
2. Check vector store exists in Llama Stack
3. Confirm embedding model is configured correctly

## MCP Tool Execution Fails

**Symptom**: Tool calls fail with connection errors.

**Checklist**:
1. MCP server URL is reachable
2. Authentication tokens are valid
3. Network policies allow connection

## Performance Issues

For slow responses:
- Enable streaming (`stream: true`)
- Reduce context window size
- Use smaller embedding models

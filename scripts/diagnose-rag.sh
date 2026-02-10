#!/bin/bash
# =============================================================================
# RAG Diagnostic Script for Llama Stack
# =============================================================================
# Tests each layer of the RAG pipeline to identify where the issue is.
# Run this on any environment to verify RAG is working end-to-end.
#
# Prerequisites: curl, jq
#
# Usage:
#   ./scripts/diagnose-rag.sh
# =============================================================================

set -e

for cmd in curl jq; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: '${cmd}' is required but not installed."
    exit 1
  fi
done

echo "=============================================="
echo "  Llama Stack RAG Diagnostics"
echo "=============================================="
echo ""

read -p "Llama Stack URL (e.g. https://my-llama-stack.example.com): " URL
if [ -z "$URL" ]; then
  echo "ERROR: URL is required."
  exit 1
fi
URL="${URL%/}"

PASS=0
FAIL=0
WARN=0

pass() { echo "  ✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠️  WARN: $1"; WARN=$((WARN + 1)); }

# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TEST 1: Connectivity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" --connect-timeout 10 "${URL}/v1/health" 2>/dev/null)
if [ "$HTTP_CODE" == "200" ]; then
  pass "Llama Stack is reachable"
else
  fail "Cannot reach Llama Stack (HTTP ${HTTP_CODE})"
  echo ""
  echo "  Cannot continue without connectivity. Check the URL."
  exit 1
fi

VERSION=$(curl -sk "${URL}/v1/version" 2>/dev/null | jq -r '.version // "unknown"')
echo "  Server version: ${VERSION}"

# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TEST 2: Embedding Models"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

EMBEDDING_MODELS=$(curl -sk "${URL}/v1/models" 2>/dev/null \
  | jq -r '.data[] | select(.model_type == "embedding") | .identifier' 2>/dev/null)

if [ -n "$EMBEDDING_MODELS" ]; then
  ECOUNT=$(echo "$EMBEDDING_MODELS" | wc -l | tr -d ' ')
  pass "Found ${ECOUNT} embedding model(s)"
  echo "$EMBEDDING_MODELS" | while read -r m; do echo "    - ${m}"; done
else
  fail "No embedding models found"
  echo "  RAG requires an embedding model. Check the Llama Stack config."
fi

# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TEST 3: LLM Models"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

LLM_MODELS=$(curl -sk "${URL}/v1/models" 2>/dev/null \
  | jq -r '.data[] | select(.model_type == "llm") | .identifier' 2>/dev/null)

if [ -n "$LLM_MODELS" ]; then
  LCOUNT=$(echo "$LLM_MODELS" | wc -l | tr -d ' ')
  pass "Found ${LCOUNT} LLM model(s)"
  echo "$LLM_MODELS" | while read -r m; do echo "    - ${m}"; done
else
  fail "No LLM models found"
fi

# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TEST 4: Vector Stores"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

VS_RESPONSE=$(curl -sk "${URL}/v1/openai/v1/vector_stores" 2>/dev/null)
VS_LIST=$(echo "$VS_RESPONSE" | jq -r '.data[]? | "\(.id) | \(.name) | files: \(.file_counts.total // 0)"' 2>/dev/null)

if [ -n "$VS_LIST" ]; then
  VS_COUNT=$(echo "$VS_LIST" | wc -l | tr -d ' ')
  pass "Found ${VS_COUNT} vector store(s)"
  echo "$VS_LIST" | while read -r vs; do echo "    ${vs}"; done

  # Find one with files
  VSID=$(echo "$VS_RESPONSE" | jq -r '.data[] | select(.file_counts.total > 0) | .id' 2>/dev/null | head -1)
  VSNAME=$(echo "$VS_RESPONSE" | jq -r ".data[] | select(.id == \"${VSID}\") | .name" 2>/dev/null)
  VSFILES=$(echo "$VS_RESPONSE" | jq -r ".data[] | select(.id == \"${VSID}\") | .file_counts.total" 2>/dev/null)

  if [ -n "$VSID" ]; then
    echo ""
    echo "  Using vector store with data: ${VSID} (${VSNAME}, ${VSFILES} files)"
  else
    warn "All vector stores are empty (0 files). Ingestion may have failed."
    VSID=$(echo "$VS_RESPONSE" | jq -r '.data[0].id' 2>/dev/null)
    echo "  Using first store for remaining tests: ${VSID}"
  fi
else
  fail "No vector stores found"
  echo "  Create a vector store and ingest documents first."
  echo ""
  echo "  Skipping remaining tests."
  echo ""
  echo "=============================================="
  echo "  Results: ${PASS} passed, ${FAIL} failed, ${WARN} warnings"
  echo "=============================================="
  exit 1
fi

# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TEST 5: Vector Store Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

FILES_RESPONSE=$(curl -sk "${URL}/v1/openai/v1/vector_stores/${VSID}/files" 2>/dev/null)
FILE_LIST=$(echo "$FILES_RESPONSE" | jq -r '.data[]? | "\(.id) | status: \(.status) | \(.bytes // "?") bytes"' 2>/dev/null)

if [ -n "$FILE_LIST" ]; then
  FCOUNT=$(echo "$FILE_LIST" | wc -l | tr -d ' ')
  pass "Found ${FCOUNT} file(s) in vector store"
  echo "$FILE_LIST" | while read -r f; do echo "    ${f}"; done

  # Check for failed files
  FAILED_FILES=$(echo "$FILES_RESPONSE" | jq -r '.data[]? | select(.status == "failed") | .id' 2>/dev/null)
  if [ -n "$FAILED_FILES" ]; then
    fail "Some files have status 'failed' — embedding may not be working"
    echo "$FILES_RESPONSE" | jq '.data[] | select(.status == "failed") | {id, status, last_error}' 2>/dev/null
  fi
else
  fail "No files in vector store — ingestion failed or never ran"
fi

# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TEST 6: Embedding Test (Canary)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Upload a tiny test file and try to embed it
CANARY_FILE=$(mktemp /tmp/canary-XXXXXX.md)
echo "# Test Document" > "$CANARY_FILE"
echo "This is a canary test to verify the embedding model works." >> "$CANARY_FILE"

CANARY_UPLOAD=$(curl -sk -X POST "${URL}/v1/openai/v1/files" \
  -F "file=@${CANARY_FILE}" \
  -F "purpose=assistants" 2>/dev/null)
CANARY_FID=$(echo "$CANARY_UPLOAD" | jq -r '.id' 2>/dev/null)
rm -f "$CANARY_FILE"

if [ "$CANARY_FID" == "null" ] || [ -z "$CANARY_FID" ]; then
  fail "Could not upload canary file"
else
  echo "  Uploaded canary file: ${CANARY_FID}"

  CANARY_ATTACH=$(curl -sk -X POST "${URL}/v1/openai/v1/vector_stores/${VSID}/files" \
    -H "Content-Type: application/json" \
    -d "{\"file_id\": \"${CANARY_FID}\", \"chunking_strategy\": {\"type\": \"auto\"}}" 2>/dev/null)

  CANARY_STATUS=$(echo "$CANARY_ATTACH" | jq -r '.status' 2>/dev/null)
  CANARY_ERROR=$(echo "$CANARY_ATTACH" | jq -r '.last_error // empty' 2>/dev/null)

  if [ "$CANARY_STATUS" == "completed" ]; then
    pass "Embedding model works — canary file ingested successfully"
    # Cleanup
    curl -sk -X DELETE "${URL}/v1/openai/v1/vector_stores/${VSID}/files/${CANARY_FID}" > /dev/null 2>&1
    curl -sk -X DELETE "${URL}/v1/openai/v1/files/${CANARY_FID}" > /dev/null 2>&1
  else
    fail "Embedding model FAILED to process canary file (status: ${CANARY_STATUS})"
    if echo "$CANARY_ERROR" | grep -qi "huggingface"; then
      echo "  Root cause: Cannot download embedding model from HuggingFace"
      echo "  Fix: Pre-cache the model in the Llama Stack container image"
    else
      echo "  Error: ${CANARY_ERROR}"
    fi
    # Cleanup
    curl -sk -X DELETE "${URL}/v1/openai/v1/files/${CANARY_FID}" > /dev/null 2>&1
  fi
fi

# =============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TEST 7: RAG Query (file_search via Responses API)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Pick a model - prefer gemini, then any
if [ -n "$LLM_MODELS" ]; then
  TEST_MODEL=$(echo "$LLM_MODELS" | grep -m1 'gemini-2.5-flash$' 2>/dev/null || \
               echo "$LLM_MODELS" | grep -m1 'gemini' 2>/dev/null || \
               echo "$LLM_MODELS" | head -1)
else
  TEST_MODEL=""
fi

if [ -z "$TEST_MODEL" ]; then
  warn "No LLM model available — skipping RAG query test"
else
  echo "  Using model: ${TEST_MODEL}"
  echo "  Using vector store: ${VSID}"
  echo "  Query: What is Type A migration?"
  echo ""

  set +e
  RAG_RESPONSE=$(curl -sk -X POST "${URL}/v1/openai/v1/responses" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"${TEST_MODEL}\",
      \"input\": \"What is Type A migration?\",
      \"tools\": [{\"type\": \"file_search\", \"vector_store_ids\": [\"${VSID}\"]}],
      \"include\": [\"file_search_call.results\"]
    }" 2>/dev/null)
  CURL_RC=$?
  set -e

  if [ $CURL_RC -ne 0 ]; then
    fail "RAG query request failed (curl error)"
  else
    # Check for API error
    API_ERROR=$(echo "$RAG_RESPONSE" | jq -r '.detail // .error // empty' 2>/dev/null)
    if [ -n "$API_ERROR" ] && [ "$API_ERROR" != "null" ]; then
      fail "RAG query returned error: ${API_ERROR}"
    else
      # Check for file_search_call in output (tool was actually executed)
      HAS_TOOL_CALL=$(echo "$RAG_RESPONSE" | jq -r '.output[]? | select(.type == "file_search_call") | .type' 2>/dev/null)
      HAS_MESSAGE=$(echo "$RAG_RESPONSE" | jq -r '.output[]? | select(.type == "message") | .content[]? | .text' 2>/dev/null)

      if [ -n "$HAS_TOOL_CALL" ]; then
        pass "file_search tool was EXECUTED (not just text output)"
      else
        warn "No file_search_call in output — model may be outputting tool calls as text"
        echo "  This usually means the model doesn't support OpenAI-format tool calling."
        echo "  Try using a Gemini model instead of Llama/vLLM models."
      fi

      if [ -n "$HAS_MESSAGE" ] && [ "$HAS_MESSAGE" != "null" ]; then
        pass "Got a response from the LLM"
        echo ""
        echo "  Response preview (first 300 chars):"
        echo "  ${HAS_MESSAGE:0:300}"

        # Check if response contains tool call as text (bad sign)
        if echo "$HAS_MESSAGE" | grep -qi "file_search\|knowledge_search"; then
          warn "Response contains tool call as TEXT — model is not executing tools properly"
          echo "  The model writes [file_search(...)] instead of calling the tool."
          echo "  Fix: Use a model with proper tool calling support (e.g. Gemini)."
        fi
      else
        fail "No message in response"
        echo "  Full response:"
        echo "$RAG_RESPONSE" | jq '.output' 2>/dev/null
      fi
    fi
  fi
fi

# =============================================================================
echo ""
echo "=============================================="
echo "  Diagnostic Summary"
echo "=============================================="
echo "  Passed:   ${PASS}"
echo "  Failed:   ${FAIL}"
echo "  Warnings: ${WARN}"
echo ""

if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
  echo "  All tests passed. RAG is working correctly."
elif [ $FAIL -eq 0 ]; then
  echo "  No failures but some warnings. RAG may partially work."
else
  echo "  There are failures. Common fixes:"
  echo ""
  echo "  - Embedding fails (HuggingFace): Pre-cache model in container image"
  echo "  - Empty vector store: Run the ingestion script to load documents"
  echo "  - Tool calls as text: Use a model that supports tool calling (Gemini)"
  echo "  - Vector store not found: Check vectorStoreIds in app-config.yaml"
fi
echo ""
echo "  Environment:"
echo "    URL:     ${URL}"
echo "    Version: ${VERSION}"
echo "    Vector Store: ${VSID:-none}"
echo "=============================================="

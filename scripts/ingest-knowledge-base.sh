#!/bin/bash
# =============================================================================
# Knowledge Base Ingestion Script for Llama Stack
# =============================================================================
# Uploads markdown documents into a Llama Stack vector store for RAG.
# Prompts for all configuration values. Optionally deletes an existing
# vector store and recreates from scratch.
#
# Prerequisites: curl, jq
#
# Usage:
#   ./scripts/ingest-knowledge-base.sh
#   ./scripts/ingest-knowledge-base.sh /path/to/custom/docs
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Allow overriding knowledge-base directory via argument
if [ -n "$1" ]; then
  KB_DIR="$1"
else
  KB_DIR="${WORKSPACE_DIR}/docs/knowledge-base"
fi

# --- Preflight checks ---

for cmd in curl jq; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: '${cmd}' is required but not installed."
    exit 1
  fi
done

if [ ! -d "$KB_DIR" ]; then
  echo "ERROR: Knowledge base directory not found: ${KB_DIR}"
  echo "Usage: $0 [/path/to/docs]"
  exit 1
fi

MD_COUNT=$(ls -1 "${KB_DIR}"/*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$MD_COUNT" -eq 0 ]; then
  echo "ERROR: No .md files found in ${KB_DIR}"
  exit 1
fi

echo "=============================================="
echo "  Llama Stack - Knowledge Base Ingestion"
echo "=============================================="
echo ""
echo "Found ${MD_COUNT} markdown file(s) in ${KB_DIR}"
echo ""

# =============================================================================
# Prompt for configuration
# =============================================================================

read -p "Llama Stack URL (e.g. https://my-llama-stack.example.com): " LLAMA_STACK_URL
if [ -z "$LLAMA_STACK_URL" ]; then
  echo "ERROR: Llama Stack URL is required."
  exit 1
fi
# Strip trailing slash
LLAMA_STACK_URL="${LLAMA_STACK_URL%/}"

read -p "Vector Store Name [techx-db]: " VS_NAME
VS_NAME="${VS_NAME:-techx-db}"

# --- Fetch and display available embedding models ---

echo ""
echo "Fetching available embedding models from Llama Stack..."
AVAILABLE_EMBEDDINGS=$(curl -sk "${LLAMA_STACK_URL}/v1/models" \
  | jq -r '.data[] | select(.model_type == "embedding") | .identifier' 2>/dev/null)

if [ -n "$AVAILABLE_EMBEDDINGS" ]; then
  echo "Available embedding models:"
  echo "$AVAILABLE_EMBEDDINGS" | while read -r model; do echo "  - ${model}"; done
  DEFAULT_EMBEDDING=$(echo "$AVAILABLE_EMBEDDINGS" | head -1)
else
  echo "  (Could not fetch models — enter the model name manually)"
  DEFAULT_EMBEDDING=""
fi
echo ""

if [ -n "$DEFAULT_EMBEDDING" ]; then
  read -p "Embedding Model [${DEFAULT_EMBEDDING}]: " EMBEDDING_MODEL
  EMBEDDING_MODEL="${EMBEDDING_MODEL:-${DEFAULT_EMBEDDING}}"
else
  read -p "Embedding Model: " EMBEDDING_MODEL
  if [ -z "$EMBEDDING_MODEL" ]; then
    echo "ERROR: Embedding model is required."
    exit 1
  fi
fi

read -p "Embedding Dimension [768]: " EMBEDDING_DIM
EMBEDDING_DIM="${EMBEDDING_DIM:-768}"

# --- Fetch and display available LLM models for RAG test ---

echo ""
echo "Fetching available LLM models for RAG test..."
AVAILABLE_LLMS=$(curl -sk "${LLAMA_STACK_URL}/v1/models" \
  | jq -r '.data[] | select(.model_type == "llm") | .identifier' 2>/dev/null)

if [ -n "$AVAILABLE_LLMS" ]; then
  echo "Available LLM models:"
  echo "$AVAILABLE_LLMS" | while read -r model; do echo "  - ${model}"; done
  DEFAULT_LLM=$(echo "$AVAILABLE_LLMS" | head -1)
else
  echo "  (Could not fetch models — enter the model name manually)"
  DEFAULT_LLM=""
fi
echo ""

if [ -n "$DEFAULT_LLM" ]; then
  read -p "LLM Model for RAG test [${DEFAULT_LLM}]: " LLM_MODEL
  LLM_MODEL="${LLM_MODEL:-${DEFAULT_LLM}}"
else
  read -p "LLM Model for RAG test: " LLM_MODEL
  if [ -z "$LLM_MODEL" ]; then
    echo "WARNING: No LLM model specified — skipping RAG test."
  fi
fi

echo ""
echo "----------------------------------------------"
echo "  Configuration Summary"
echo "----------------------------------------------"
echo "  Llama Stack URL:    ${LLAMA_STACK_URL}"
echo "  Vector Store Name:  ${VS_NAME}"
echo "  Embedding Model:    ${EMBEDDING_MODEL}"
echo "  Embedding Dimension: ${EMBEDDING_DIM}"
echo "  LLM Model (test):   ${LLM_MODEL:-<skipped>}"
echo "  Knowledge Base Dir: ${KB_DIR}"
echo "  Files to ingest:    ${MD_COUNT}"
echo "----------------------------------------------"
echo ""
read -p "Proceed? [Y/n]: " CONFIRM_PROCEED
CONFIRM_PROCEED="${CONFIRM_PROCEED:-Y}"
if [[ ! "$CONFIRM_PROCEED" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi
echo ""

# =============================================================================
# Check connectivity
# =============================================================================

echo "--- Checking Llama Stack connectivity ---"
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "${LLAMA_STACK_URL}/v1/openai/v1/vector_stores")
if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: Cannot reach Llama Stack at ${LLAMA_STACK_URL} (HTTP ${HTTP_CODE})"
  exit 1
fi
echo "OK — Llama Stack is reachable"
echo ""

# =============================================================================
# Find and delete existing vector store (if any)
# =============================================================================

echo "--- Checking for existing vector store '${VS_NAME}' ---"
EXISTING_VS=$(curl -sk "${LLAMA_STACK_URL}/v1/openai/v1/vector_stores" \
  | jq -r ".data[] | select(.name == \"${VS_NAME}\") | .id")

if [ -n "$EXISTING_VS" ]; then
  echo "Found existing vector store: ${EXISTING_VS}"
  read -p "Delete and recreate from scratch? [Y/n]: " CONFIRM_DELETE
  CONFIRM_DELETE="${CONFIRM_DELETE:-Y}"

  if [[ "$CONFIRM_DELETE" =~ ^[Yy]$ ]]; then
    echo "Deleting vector store ${EXISTING_VS}..."

    # List and delete all files in the vector store first
    FILE_IDS=$(curl -sk "${LLAMA_STACK_URL}/v1/openai/v1/vector_stores/${EXISTING_VS}/files" \
      | jq -r '.data[].id // empty' 2>/dev/null)

    if [ -n "$FILE_IDS" ]; then
      echo "Removing files from vector store..."
      for FID in $FILE_IDS; do
        curl -sk -X DELETE "${LLAMA_STACK_URL}/v1/openai/v1/vector_stores/${EXISTING_VS}/files/${FID}" > /dev/null 2>&1
        curl -sk -X DELETE "${LLAMA_STACK_URL}/v1/openai/v1/files/${FID}" > /dev/null 2>&1
        echo "  Deleted file: ${FID}"
      done
    fi

    # Delete the vector store
    curl -sk -X DELETE "${LLAMA_STACK_URL}/v1/openai/v1/vector_stores/${EXISTING_VS}" > /dev/null 2>&1
    echo "Deleted vector store: ${EXISTING_VS}"
    echo ""
  else
    echo "Keeping existing store. Will create a new one with a different name."
    VS_NAME="${VS_NAME}-$(date +%s)"
    echo "New store name: ${VS_NAME}"
    echo ""
  fi
else
  echo "No existing vector store found with name '${VS_NAME}'"
  echo ""
fi

# =============================================================================
# Create new vector store
# =============================================================================

echo "--- Creating vector store '${VS_NAME}' ---"
CREATE_RESPONSE=$(curl -sk -X POST "${LLAMA_STACK_URL}/v1/openai/v1/vector_stores" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"${VS_NAME}\",
    \"embedding_model\": \"${EMBEDDING_MODEL}\",
    \"embedding_dimension\": ${EMBEDDING_DIM}
  }")

VECTOR_STORE_ID=$(echo "$CREATE_RESPONSE" | jq -r '.id')
VS_STATUS=$(echo "$CREATE_RESPONSE" | jq -r '.status')

if [ "$VECTOR_STORE_ID" == "null" ] || [ -z "$VECTOR_STORE_ID" ]; then
  echo "ERROR: Failed to create vector store"
  echo "$CREATE_RESPONSE" | jq .
  exit 1
fi

echo "Created vector store: ${VECTOR_STORE_ID} (status: ${VS_STATUS})"
echo ""

# =============================================================================
# Upload and ingest all markdown files
# =============================================================================

echo "--- Ingesting documents ---"
echo ""

FILE_COUNT=0
SUCCESS_COUNT=0
FAIL_COUNT=0

for FILE_PATH in "${KB_DIR}"/*.md; do
  [ -f "$FILE_PATH" ] || continue

  FILENAME=$(basename "$FILE_PATH")
  FILE_COUNT=$((FILE_COUNT + 1))

  echo "[${FILE_COUNT}] Uploading: ${FILENAME}"

  # Step 1: Upload file
  UPLOAD_RESPONSE=$(curl -sk -X POST "${LLAMA_STACK_URL}/v1/openai/v1/files" \
    -F "file=@${FILE_PATH}" \
    -F "purpose=assistants")

  FILE_ID=$(echo "$UPLOAD_RESPONSE" | jq -r '.id')
  FILE_BYTES=$(echo "$UPLOAD_RESPONSE" | jq -r '.bytes')

  if [ "$FILE_ID" == "null" ] || [ -z "$FILE_ID" ]; then
    echo "    ERROR: Upload failed"
    echo "    $UPLOAD_RESPONSE"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    continue
  fi

  echo "    Uploaded: ${FILE_ID} (${FILE_BYTES} bytes)"

  # Step 2: Attach to vector store with chunking
  TITLE=$(head -1 "$FILE_PATH" | sed 's/^#[[:space:]]*//')

  ATTACH_RESPONSE=$(curl -sk -X POST "${LLAMA_STACK_URL}/v1/openai/v1/vector_stores/${VECTOR_STORE_ID}/files" \
    -H "Content-Type: application/json" \
    -d "{
      \"file_id\": \"${FILE_ID}\",
      \"chunking_strategy\": {\"type\": \"auto\"},
      \"attributes\": {
        \"title\": \"${TITLE}\",
        \"source_url\": \"internal://knowledge-base/${FILENAME}\",
        \"content_type\": \"markdown\"
      }
    }")

  ATTACH_STATUS=$(echo "$ATTACH_RESPONSE" | jq -r '.status')

  if [ "$ATTACH_STATUS" == "completed" ]; then
    echo "    Ingested: OK"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    echo "    ERROR: Ingestion failed (status: ${ATTACH_STATUS})"
    echo "    $(echo "$ATTACH_RESPONSE" | jq -r '.last_error // empty')"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi

  echo ""
done

# =============================================================================
# Verify
# =============================================================================

echo "--- Verification ---"
FINAL_STATUS=$(curl -sk "${LLAMA_STACK_URL}/v1/openai/v1/vector_stores/${VECTOR_STORE_ID}" \
  | jq '{name, id, status, file_counts}')
echo "$FINAL_STATUS"
echo ""

# =============================================================================
# Test RAG search (optional)
# =============================================================================

if [ -n "$LLM_MODEL" ]; then
  echo "--- Testing RAG search ---"
  read -p "Test query [What namespaces are in scope for CSI 12345?]: " TEST_QUERY
  TEST_QUERY="${TEST_QUERY:-What namespaces are in scope for CSI 12345?}"
  echo "Query: ${TEST_QUERY}"
  echo ""

  TEST_RESPONSE=$(curl -sk -X POST "${LLAMA_STACK_URL}/v1/openai/v1/responses" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"${LLM_MODEL}\",
      \"input\": \"${TEST_QUERY}\",
      \"tools\": [{\"type\": \"file_search\", \"vector_store_ids\": [\"${VECTOR_STORE_ID}\"]}],
      \"include\": [\"file_search_call.results\"]
    }")

  ANSWER=$(echo "$TEST_RESPONSE" | jq -r '.output[] | select(.type == "message") | .content[] | .text')

  if [ -n "$ANSWER" ] && [ "$ANSWER" != "null" ]; then
    echo "RAG Response:"
    echo "$ANSWER"
    echo ""
    echo "RAG search is working."
  else
    echo "WARNING: RAG search returned no answer."
    echo "$TEST_RESPONSE" | jq '.error // .output' 2>/dev/null
  fi
  echo ""
fi

# =============================================================================
# Summary
# =============================================================================

echo "=============================================="
echo "  Ingestion Complete"
echo "=============================================="
echo "  Vector Store ID:   ${VECTOR_STORE_ID}"
echo "  Vector Store Name: ${VS_NAME}"
echo "  Embedding Model:   ${EMBEDDING_MODEL}"
echo "  Embedding Dim:     ${EMBEDDING_DIM}"
echo "  Files uploaded:    ${FILE_COUNT}"
echo "  Succeeded:         ${SUCCESS_COUNT}"
echo "  Failed:            ${FAIL_COUNT}"
echo ""
echo "  Add to your app-config.yaml:"
echo ""
echo "    lss:"
echo "      llamaStack:"
echo "        vectorStoreIds:"
echo "          - '${VECTOR_STORE_ID}'"
echo "        vectorStoreName: '${VS_NAME}'"
echo "        embeddingModel: '${EMBEDDING_MODEL}'"
echo "        embeddingDimension: ${EMBEDDING_DIM}"
echo "=============================================="

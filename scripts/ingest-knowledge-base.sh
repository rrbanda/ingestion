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

# =============================================================================
# Preflight checks
# =============================================================================

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

MD_FILES=()
for f in "${KB_DIR}"/*.md; do
  [ -f "$f" ] && MD_FILES+=("$f")
done

if [ ${#MD_FILES[@]} -eq 0 ]; then
  echo "ERROR: No .md files found in ${KB_DIR}"
  exit 1
fi

echo "=============================================="
echo "  Llama Stack - Knowledge Base Ingestion"
echo "=============================================="
echo ""
echo "Available files in ${KB_DIR}:"
echo ""
for i in "${!MD_FILES[@]}"; do
  FNAME=$(basename "${MD_FILES[$i]}")
  FSIZE=$(wc -c < "${MD_FILES[$i]}" | tr -d ' ')
  echo "  $((i + 1))) ${FNAME}  (${FSIZE} bytes)"
done
echo ""
echo "Enter file numbers to ingest (comma-separated), or 'all' for everything."
echo "Example: 1,3 or all"
read -p "Files to ingest [all]: " FILE_SELECTION
FILE_SELECTION="${FILE_SELECTION:-all}"

SELECTED_FILES=()
if [ "$FILE_SELECTION" == "all" ]; then
  SELECTED_FILES=("${MD_FILES[@]}")
else
  IFS=',' read -ra INDICES <<< "$FILE_SELECTION"
  for idx in "${INDICES[@]}"; do
    idx=$(echo "$idx" | tr -d ' ')
    if ! [[ "$idx" =~ ^[0-9]+$ ]] || [ "$idx" -lt 1 ] || [ "$idx" -gt ${#MD_FILES[@]} ]; then
      echo "ERROR: Invalid selection '${idx}'. Must be 1-${#MD_FILES[@]}."
      exit 1
    fi
    SELECTED_FILES+=("${MD_FILES[$((idx - 1))]}")
  done
fi

if [ ${#SELECTED_FILES[@]} -eq 0 ]; then
  echo "ERROR: No files selected."
  exit 1
fi

MD_COUNT=${#SELECTED_FILES[@]}
echo ""
echo "Selected ${MD_COUNT} file(s) for ingestion."
echo ""

# =============================================================================
# Prompt: Llama Stack URL
# =============================================================================

read -p "Llama Stack URL (e.g. https://my-llama-stack.example.com): " LLAMA_STACK_URL
if [ -z "$LLAMA_STACK_URL" ]; then
  echo "ERROR: Llama Stack URL is required."
  exit 1
fi
# Strip trailing slash
LLAMA_STACK_URL="${LLAMA_STACK_URL%/}"

# Quick connectivity check before continuing
echo ""
echo "Checking connectivity..."
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" --connect-timeout 10 "${LLAMA_STACK_URL}/v1/openai/v1/vector_stores" 2>/dev/null)
if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: Cannot reach Llama Stack at ${LLAMA_STACK_URL} (HTTP ${HTTP_CODE})"
  echo "       Check the URL and ensure the server is running."
  exit 1
fi
echo "OK — Llama Stack is reachable"

# =============================================================================
# Fetch all models once (reuse for embedding + LLM sections)
# =============================================================================

echo ""
echo "Fetching available models from Llama Stack..."
ALL_MODELS=$(curl -sk "${LLAMA_STACK_URL}/v1/models" 2>/dev/null)

# =============================================================================
# Prompt: Vector Store Name
# =============================================================================

echo ""
read -p "Vector Store Name [techx-db]: " VS_NAME
VS_NAME="${VS_NAME:-techx-db}"

# =============================================================================
# Prompt: Embedding Model (auto-discovered)
# =============================================================================

echo ""
echo "--- Embedding Models ---"
AVAILABLE_EMBEDDINGS=$(echo "$ALL_MODELS" \
  | jq -r '.data[] | select(.model_type == "embedding") | .identifier' 2>/dev/null)

if [ -n "$AVAILABLE_EMBEDDINGS" ]; then
  EMBED_COUNT=$(echo "$AVAILABLE_EMBEDDINGS" | wc -l | tr -d ' ')
  echo "Found ${EMBED_COUNT} embedding model(s):"
  INDEX=0
  while IFS= read -r model; do
    INDEX=$((INDEX + 1))
    echo "  ${INDEX}) ${model}"
  done <<< "$AVAILABLE_EMBEDDINGS"
  DEFAULT_EMBEDDING=$(echo "$AVAILABLE_EMBEDDINGS" | head -1)
else
  echo "  (Could not fetch embedding models — enter the model name manually)"
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

# --- Auto-detect embedding dimension ---
# Try to get dimension from model metadata; fall back to common defaults
AUTO_DIM=$(echo "$ALL_MODELS" \
  | jq -r ".data[] | select(.identifier == \"${EMBEDDING_MODEL}\") | .metadata.embedding_dimension // empty" 2>/dev/null)

if [ -n "$AUTO_DIM" ] && [ "$AUTO_DIM" != "null" ]; then
  echo "  Auto-detected embedding dimension: ${AUTO_DIM}"
  DEFAULT_DIM="$AUTO_DIM"
else
  # Guess based on well-known model names
  case "$EMBEDDING_MODEL" in
    *all-MiniLM-L6*)       DEFAULT_DIM=384 ;;
    *nomic-embed*)          DEFAULT_DIM=768 ;;
    *bge-large*|*e5-large*) DEFAULT_DIM=1024 ;;
    *text-embedding-3-small*) DEFAULT_DIM=1536 ;;
    *text-embedding-3-large*) DEFAULT_DIM=3072 ;;
    *text-embedding-004*)   DEFAULT_DIM=768 ;;
    *gemini-embedding*)     DEFAULT_DIM=768 ;;
    *)                      DEFAULT_DIM=768 ;;
  esac
  echo "  Estimated embedding dimension for '${EMBEDDING_MODEL}': ${DEFAULT_DIM}"
  echo "  (Common values: 384, 768, 1024, 1536, 3072)"
fi

read -p "Embedding Dimension [${DEFAULT_DIM}]: " EMBEDDING_DIM
EMBEDDING_DIM="${EMBEDDING_DIM:-${DEFAULT_DIM}}"

# Validate dimension is a number
if ! [[ "$EMBEDDING_DIM" =~ ^[0-9]+$ ]]; then
  echo "ERROR: Embedding dimension must be a number, got: ${EMBEDDING_DIM}"
  exit 1
fi

# =============================================================================
# Prompt: LLM Model for RAG test (auto-discovered, filtered)
# =============================================================================

echo ""
echo "--- LLM Models (for optional RAG test) ---"

# Filter to only chat/completion-capable LLM models
# Exclude: embedding, imagen, veo, lyria, tts, aqa, robotics models
AVAILABLE_LLMS=$(echo "$ALL_MODELS" \
  | jq -r '.data[] | select(.model_type == "llm") | .identifier' 2>/dev/null \
  | grep -iv -e 'embedding' -e 'imagen' -e 'veo' -e 'lyria' -e 'tts' -e 'aqa' -e 'robotics' -e 'image-generation' -e 'nano-banana' -e 'deep-research')

if [ -n "$AVAILABLE_LLMS" ]; then
  LLM_COUNT=$(echo "$AVAILABLE_LLMS" | wc -l | tr -d ' ')
  echo "Found ${LLM_COUNT} chat-capable LLM(s):"
  INDEX=0
  while IFS= read -r model; do
    INDEX=$((INDEX + 1))
    echo "  ${INDEX}) ${model}"
  done <<< "$AVAILABLE_LLMS"

  # Pick a sensible default: prefer gemini-2.5-flash, then any gemini, then first
  DEFAULT_LLM=$(echo "$AVAILABLE_LLMS" | grep -m1 'gemini-2.5-flash$' 2>/dev/null || \
                echo "$AVAILABLE_LLMS" | grep -m1 'gemini' 2>/dev/null || \
                echo "$AVAILABLE_LLMS" | head -1)
else
  echo "  (Could not fetch LLM models — enter the model name manually, or press Enter to skip)"
  DEFAULT_LLM=""
fi
echo ""

if [ -n "$DEFAULT_LLM" ]; then
  read -p "LLM Model for RAG test [${DEFAULT_LLM}] (Enter to accept, 'skip' to skip): " LLM_MODEL
  if [ "$LLM_MODEL" == "skip" ]; then
    LLM_MODEL=""
    echo "  Skipping RAG test."
  else
    LLM_MODEL="${LLM_MODEL:-${DEFAULT_LLM}}"
  fi
else
  read -p "LLM Model for RAG test (press Enter to skip): " LLM_MODEL
  if [ -z "$LLM_MODEL" ]; then
    echo "  Skipping RAG test."
  fi
fi

# =============================================================================
# Configuration Summary + Confirmation
# =============================================================================

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
  echo "ERROR: Failed to create vector store."
  echo ""
  ERROR_DETAIL=$(echo "$CREATE_RESPONSE" | jq -r '.detail // empty' 2>/dev/null)
  if [ -n "$ERROR_DETAIL" ]; then
    echo "  Server said: ${ERROR_DETAIL}"
  else
    echo "  Response: $(echo "$CREATE_RESPONSE" | jq . 2>/dev/null)"
  fi
  echo ""
  echo "Troubleshooting:"
  echo "  - Is the embedding model '${EMBEDDING_MODEL}' registered on this server?"
  echo "  - Is dimension ${EMBEDDING_DIM} correct for this model?"
  echo "  - Run: curl -sk ${LLAMA_STACK_URL}/v1/models | jq '.data[] | select(.model_type==\"embedding\")'"
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

for FILE_PATH in "${SELECTED_FILES[@]}"; do

  FILENAME=$(basename "$FILE_PATH")
  FILE_COUNT=$((FILE_COUNT + 1))

  echo "[${FILE_COUNT}/${MD_COUNT}] Uploading: ${FILENAME}"

  # Step 1: Upload file
  UPLOAD_RESPONSE=$(curl -sk -X POST "${LLAMA_STACK_URL}/v1/openai/v1/files" \
    -F "file=@${FILE_PATH}" \
    -F "purpose=assistants")

  FILE_ID=$(echo "$UPLOAD_RESPONSE" | jq -r '.id')
  FILE_BYTES=$(echo "$UPLOAD_RESPONSE" | jq -r '.bytes')

  if [ "$FILE_ID" == "null" ] || [ -z "$FILE_ID" ]; then
    echo "    ERROR: Upload failed"
    echo "    $(echo "$UPLOAD_RESPONSE" | jq -r '.detail // .' 2>/dev/null)"
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
    echo "    WARNING: Ingestion status: ${ATTACH_STATUS}"
    echo "    $(echo "$ATTACH_RESPONSE" | jq -r '.last_error // empty' 2>/dev/null)"
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
# Test RAG search (optional, non-fatal)
# =============================================================================

if [ -n "$LLM_MODEL" ]; then
  echo "--- Testing RAG search ---"
  read -p "Test query [What namespaces are in scope for CSI 12345?]: " TEST_QUERY
  TEST_QUERY="${TEST_QUERY:-What namespaces are in scope for CSI 12345?}"
  echo "Query: ${TEST_QUERY}"
  echo ""

  # Disable set -e for the RAG test so a failure doesn't kill the script
  set +e
  TEST_RESPONSE=$(curl -sk -X POST "${LLAMA_STACK_URL}/v1/openai/v1/responses" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"${LLM_MODEL}\",
      \"input\": \"${TEST_QUERY}\",
      \"tools\": [{\"type\": \"file_search\", \"vector_store_ids\": [\"${VECTOR_STORE_ID}\"]}],
      \"include\": [\"file_search_call.results\"]
    }" 2>/dev/null)
  CURL_RC=$?
  set -e

  if [ $CURL_RC -ne 0 ]; then
    echo "WARNING: RAG test request failed (curl exit code: ${CURL_RC})."
    echo "         Ingestion was successful — test the RAG search manually."
  else
    # Check for API-level error
    API_ERROR=$(echo "$TEST_RESPONSE" | jq -r '.detail // .error // empty' 2>/dev/null)
    if [ -n "$API_ERROR" ] && [ "$API_ERROR" != "null" ]; then
      echo "WARNING: RAG test returned an error: ${API_ERROR}"
      echo "         The LLM model '${LLM_MODEL}' may not support tool use."
      echo "         Ingestion was successful — try a different model for RAG queries."
    else
      ANSWER=$(echo "$TEST_RESPONSE" | jq -r '.output[]? | select(.type == "message") | .content[]? | .text' 2>/dev/null)

      if [ -n "$ANSWER" ] && [ "$ANSWER" != "null" ]; then
        echo "RAG Response:"
        echo "$ANSWER"
        echo ""
        echo "RAG search is working."
      else
        echo "WARNING: RAG test returned no answer (model may still be loading)."
        echo "         Ingestion was successful — try querying manually."
      fi
    fi
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

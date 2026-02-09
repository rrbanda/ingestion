# Knowledge Base Ingestion for Llama Stack

Ingest markdown documents into a [Llama Stack](https://github.com/meta-llama/llama-stack) vector store for RAG (Retrieval-Augmented Generation).

## Repository Structure

```
├── scripts/
│   └── ingest-knowledge-base.sh   # Interactive ingestion script
├── docs/
│   └── knowledge-base/            # Markdown files to ingest
│       ├── migration-scope-data.md
│       └── type-a-migration-guide.md
├── LICENSE
└── README.md
```

## Prerequisites

- `curl`
- `jq`
- A running Llama Stack instance with vector store support

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/rrbanda/ingestion.git
cd ingestion

# 2. Run the ingestion script
./scripts/ingest-knowledge-base.sh
```

The script will walk you through everything interactively:

### Step-by-step prompts

| # | Prompt | Default | Description |
|---|--------|---------|-------------|
| 1 | **Files to ingest** | `all` | Lists available `.md` files with sizes. Pick by number (e.g. `1,3`) or `all` |
| 2 | **Llama Stack URL** | *(required)* | Base URL of your Llama Stack server |
| 3 | **Vector Store Name** | `techx-db` | Name for the vector store |
| 4 | **Embedding Model** | *(auto-detected)* | Fetches and lists available embedding models from the server |
| 5 | **Embedding Dimension** | *(auto-detected)* | Auto-detected from model metadata, with fallback for well-known models |
| 6 | **LLM Model** | *(auto-detected)* | For the optional RAG verification test. Type `skip` to skip |
| 7 | **Confirm** | `Y` | Review summary and proceed |
| 8 | **Delete existing store?** | `Y` | Only asked if a store with the same name already exists |
| 9 | **Test query** | pre-filled | Custom query to verify RAG search works |

### Example run

```
==============================================
  Llama Stack - Knowledge Base Ingestion
==============================================

Available files in ./docs/knowledge-base:

  1) migration-scope-data.md  (13594 bytes)
  2) type-a-migration-guide.md  (10930 bytes)

Enter file numbers to ingest (comma-separated), or 'all' for everything.
Example: 1,3 or all
Files to ingest [all]: all

Llama Stack URL: https://my-llama-stack.example.com
Vector Store Name [techx-db]:

--- Embedding Models ---
Found 1 embedding model(s):
  1) sentence-transformers/nomic-ai/nomic-embed-text-v1.5

  Auto-detected embedding dimension: 768
...
```

## What the Script Does

1. **Lists files** and lets you pick which ones to ingest
2. **Checks connectivity** to the Llama Stack server before proceeding
3. **Auto-discovers** available embedding and LLM models from the server
4. **Auto-detects** embedding dimension from model metadata
5. **Deletes** an existing vector store with the same name (with confirmation)
6. **Creates** a new vector store with the specified embedding model
7. **Uploads and ingests** selected `.md` files with auto-chunking
8. **Verifies** the vector store status and file counts
9. **Tests** RAG search with a sample query (non-fatal — ingestion succeeds even if test fails)
10. **Outputs** the `app-config.yaml` snippet for your Backstage/RHDH configuration

## Custom Documents Directory

You can point to a different directory of markdown files:

```bash
./scripts/ingest-knowledge-base.sh /path/to/my/docs
```

## Adding New Knowledge Base Documents

1. Add `.md` files to `docs/knowledge-base/`
2. Use self-contained sections — each section should have all context needed for a single RAG retrieval
3. Re-run the ingestion script (it will delete and recreate the vector store)

### RAG-Friendly Document Tips

- Use clear `#` headings for each topic
- Keep related information together in one section
- Avoid cross-references between sections when possible
- Include key identifiers (CSI, namespace, cluster name) in each section so they get indexed

## License

Apache-2.0

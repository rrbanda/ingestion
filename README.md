# Knowledge Base Ingestion for Llama Stack

Ingest markdown documents into a [Llama Stack](https://github.com/meta-llama/llama-stack) vector store for RAG (Retrieval-Augmented Generation).

## Repository Structure

```
├── scripts/
│   └── ingest-knowledge-base.sh   # Interactive ingestion script
├── docs/
│   └── knowledge-base/            # Markdown files to ingest
│       ├── migration-scope-data.md
│       ├── type-a-migration-guide.md
│       ├── configuration.md
│       ├── getting-started.md
│       └── troubleshooting.md
├── LICENSE
└── README.md
```

## Prerequisites

- `curl`
- `jq`
- A running Llama Stack instance with vector store support

## Quick Start

```bash
# Clone the repo
git clone https://github.com/rrbanda/ingestion.git
cd ingestion

# Run the ingestion script
./scripts/ingest-knowledge-base.sh
```

The script will interactively prompt for:

| Prompt | Default | Description |
|--------|---------|-------------|
| Llama Stack URL | *(required)* | Base URL of your Llama Stack server |
| Vector Store Name | `techx-db` | Name for the vector store |
| Embedding Model | *(auto-detected)* | Fetches available models from the server |
| Embedding Dimension | `768` | Dimension for the embedding model |
| LLM Model | *(auto-detected)* | Model used for the RAG verification test |

## What the Script Does

1. **Validates** prerequisites (`curl`, `jq`, `.md` files exist)
2. **Auto-discovers** available embedding and LLM models from the server
3. **Deletes** an existing vector store with the same name (with confirmation)
4. **Creates** a new vector store with the specified embedding model
5. **Uploads** all `.md` files from `docs/knowledge-base/`
6. **Ingests** each file into the vector store with auto-chunking
7. **Verifies** the vector store status and file counts
8. **Tests** RAG search with a sample query
9. **Outputs** the `app-config.yaml` snippet for your Backstage/RHDH configuration

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

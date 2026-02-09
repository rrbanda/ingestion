# Deploying Knowledge Base Documents Locally on RHDH (OpenShift)

This guide covers how to deploy knowledge base documents **locally** (no GitHub, no external URLs) on an RHDH instance running on OpenShift. The LSS plugin will automatically ingest these documents into the vector store on every startup.

## Overview

```
┌─────────────────────────────────────────────────────────┐
│  OpenShift Cluster                                      │
│                                                         │
│  ┌─────────────────┐     ┌──────────────────────────┐  │
│  │ ConfigMap        │────▶│ RHDH Pod                  │  │
│  │ lss-knowledge-   │     │                           │  │
│  │ base             │     │ /opt/app-root/src/        │  │
│  │                  │     │   knowledge-base/         │  │
│  │  migration-      │     │     migration-scope-      │  │
│  │   scope-data.md  │     │       data.md             │  │
│  │  type-a-         │     │     type-a-migration-     │  │
│  │   migration-     │     │       guide.md            │  │
│  │   guide.md       │     │                           │  │
│  └─────────────────┘     │ Plugin reads from here    │  │
│                           │ on startup & syncs to     │  │
│                           │ Llama Stack vector store  │  │
│                           └──────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

- RHDH deployed on OpenShift
- `oc` CLI logged in to the cluster
- Your knowledge base `.md` files ready

## Step 1: Create a ConfigMap from your documents

```bash
# Create ConfigMap containing all your knowledge base markdown files
oc create configmap lss-knowledge-base \
  --from-file=migration-scope-data.md \
  --from-file=type-a-migration-guide.md \
  -n <your-rhdh-namespace>
```

You can add as many `--from-file` entries as you have documents. Each file becomes a key in the ConfigMap.

> **Tip**: If your files are in a directory, you can use:
> ```bash
> oc create configmap lss-knowledge-base \
>   --from-file=docs/knowledge-base/ \
>   -n <your-rhdh-namespace>
> ```
> This adds every file in the directory to the ConfigMap.

## Step 2: Mount the ConfigMap into the RHDH pod

Add to your RHDH Helm chart values (or Deployment spec):

```yaml
upstream:
  backstage:
    extraVolumes:
      # Knowledge base documents
      - name: lss-knowledge-base
        configMap:
          name: lss-knowledge-base
    extraVolumeMounts:
      # Mount documents to a known path
      - name: lss-knowledge-base
        mountPath: /opt/app-root/src/knowledge-base
        readOnly: true
```

After this, your documents will appear inside the RHDH container at:
```
/opt/app-root/src/knowledge-base/migration-scope-data.md
/opt/app-root/src/knowledge-base/type-a-migration-guide.md
```

## Step 3: Configure the LSS plugin to read from that directory

In your RHDH `app-config` ConfigMap, add the `documents` section under `lss`:

```yaml
lss:
  # ... existing config (llamaStack, branding, systemPrompt, etc.) ...

  # Knowledge base ingestion - local directory
  documents:
    syncMode: full          # 'full' removes docs deleted from source
    # syncSchedule: '1h'   # optional: re-sync periodically
    sources:
      - type: directory
        path: /opt/app-root/src/knowledge-base
        patterns:
          - '**/*.md'
```

### What each field means

| Field | Value | Description |
|-------|-------|-------------|
| `syncMode` | `full` | On sync, removes documents that are no longer in the source directory |
| `syncMode` | `append` | Only adds new/changed documents, never removes |
| `syncSchedule` | `'1h'` | Optional. Re-syncs every hour. Omit to only sync on startup |
| `type` | `directory` | Reads files from a local filesystem path |
| `path` | `/opt/app-root/src/knowledge-base` | Must match the `mountPath` from Step 2 |
| `patterns` | `['**/*.md']` | Glob patterns for which files to ingest |

## Step 4: Apply changes and restart

```bash
# If using Helm
helm upgrade <release-name> <chart> -f values.yaml -n <your-rhdh-namespace>

# Or restart the deployment directly
oc rollout restart deployment/<rhdh-deployment-name> -n <your-rhdh-namespace>
```

## What happens on startup

1. Plugin connects to Llama Stack and finds/creates the vector store
2. Plugin reads all `.md` files from `/opt/app-root/src/knowledge-base/`
3. Hashes each file's content — only uploads new or changed files
4. Uploads to Llama Stack Files API and attaches to vector store with chunking
5. Logs the result:
   ```
   Initial document sync completed: added=2, updated=0, removed=0, failed=0, unchanged=0
   Vector store ready with 2 document(s) for RAG
   ```

On subsequent restarts, unchanged files are **skipped** (no re-upload).

## Updating documents (no plugin rebuild needed)

To add, edit, or remove documents:

```bash
# 1. Update the ConfigMap with your new/changed files
oc create configmap lss-knowledge-base \
  --from-file=migration-scope-data.md \
  --from-file=type-a-migration-guide.md \
  --from-file=new-document.md \
  -n <your-rhdh-namespace> \
  --dry-run=client -o yaml | oc apply -f -

# 2. Restart RHDH to pick up changes
oc rollout restart deployment/<rhdh-deployment-name> -n <your-rhdh-namespace>
```

The plugin will detect the changes (via content hashing) and sync accordingly.

## Validation

After restart, check the RHDH pod logs:

```bash
oc logs deployment/<rhdh-deployment-name> -n <your-rhdh-namespace> | grep -i "document\|sync\|vector"
```

You should see:
```
LSS loaded 1 document source(s)
Starting initial document sync (awaiting completion)...
Fetched 2 documents from directory source
Initial document sync completed: added=2, updated=0, removed=0, failed=0, unchanged=0
Vector store ready with 2 document(s) for RAG
```

## Triggering a manual sync (without restart)

The plugin exposes a sync API endpoint:

```bash
curl -X POST https://<rhdh-url>/api/lss/sync \
  -H "Authorization: Bearer <token>"
```

This is useful if you update the ConfigMap and want to sync without a full restart (note: the pod still needs to re-mount the ConfigMap, which OpenShift does automatically after ~1 minute for mounted ConfigMaps).

## Complete example: app-config snippet

```yaml
lss:
  debug: true

  systemPrompt:
    $file: /opt/app-root/src/prompts/system-prompt.md

  llamaStack:
    baseUrl: 'https://your-llama-stack-url'
    model: 'gemini-llm/models/gemini-2.5-flash'
    vectorStoreName: 'techx-db'
    embeddingModel: 'sentence-transformers/nomic-ai/nomic-embed-text-v1.5'
    embeddingDimension: 768
    skipTlsVerify: true
    toolChoice: 'auto'

  # Knowledge base - local directory (mounted via ConfigMap)
  documents:
    syncMode: full
    sources:
      - type: directory
        path: /opt/app-root/src/knowledge-base
        patterns:
          - '**/*.md'

  swimLanes:
    # ... your swim lanes config ...
```

## ConfigMap size limits

Kubernetes ConfigMaps have a **1 MB size limit**. If your knowledge base exceeds this:

- **Option A**: Split into multiple ConfigMaps and mount each to a subdirectory
- **Option B**: Use a PersistentVolumeClaim (PVC) instead
- **Option C**: Switch to `type: github` or `type: url` source (pulls docs over network)

For most use cases, a few dozen markdown files will fit comfortably within 1 MB.

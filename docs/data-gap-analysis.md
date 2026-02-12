# Data Gap Analysis — Real Data Headers vs. Journey Requirements

This document maps the actual data available in the migration system against what each user journey requires, and identifies gaps.

---

## Real Data: 5 Datasets

### Dataset A: Applications & Namespaces In Scope (main table)

The primary application/namespace table. Each row is a **namespace** (not an application — one application can have multiple namespace rows for dev/uat/prod).

| # | Column | Notes |
|---|--------|-------|
| 1 | Namespace | The namespace name |
| 2 | App_IC | Application identifier — likely the lookup key (CSI equivalent?) |
| 3 | Source ECS Cluster | Source ECS 1.0 cluster |
| 4 | Destination Cluster | Destination Cloud@Citi cluster |
| 5 | Cluster_Type | Type of cluster |
| 6 | Data_Center | Data center location |
| 7 | ENV | Environment (DEV, UAT, PROD) |
| 8 | Sector | Business sector |
| 9 | Region | Geographic region |
| 10 | App Manager | Application manager contact |
| 11 | Support Manager | Support manager contact |
| 12 | Org | Organization |
| 13 | L1Head | L1 leadership |
| 14 | L4Head | L4 leadership |
| 15 | L3Head | L3 leadership |
| 16 | LE Business | LE business unit |
| 17 | L5 Tech | L5 technology lead |
| 18 | App Creation | App creation date |
| 19 | Namespace Creation | Namespace creation date |
| 20 | query | (unclear — possibly internal/system field) |
| 21 | timestamp | (system field) |
| 22 | Run | (system field) |
| 23 | Da... | (truncated — possibly Date) |

---

### Dataset B: Cloud@Citi Cluster VIPs, Infra Nodes, & SiteMinder Shared Secrets

Cluster-level infrastructure data. Each row is a **cluster** (not an app/namespace).

| # | Column | Notes |
|---|--------|-------|
| 1 | Cloud @ Citi Cluster | Cluster name |
| 2 | Cluster Subnet | Subnet |
| 3 | Cluster VIP Name | VIP name |
| 4 | Cluster VIP IP Address | VIP IP |
| 5 | Infra node Ips | Infrastructure node IPs |
| 6 | SM_REGHOST_HOSTNAME | SiteMinder registration host |
| 7 | SSO_SHARED_SECRET | SiteMinder shared secret |

---

### Dataset C: Source & Destination Clusters

Simple cluster mapping table. Each row is a source → destination pair.

| # | Column | Notes |
|---|--------|-------|
| 1 | Source ECS 1.0 Cluster(s) | Source cluster name |
| 2 | Destination Cloud @ Citi OpenShift Cluster | Destination cluster name |

---

### Dataset D: Namespace Network/Egress Details

Namespace-level network data. Each row is a **namespace**.

| # | Column | Notes |
|---|--------|-------|
| 1 | NAMESPACE | Namespace name |
| 2 | Source ECS Cluster | Source cluster |
| 3 | Destination Cloud@Citi Cluster | Destination cluster |
| 4 | Source Egress IP | Egress IP on source cluster |
| 5 | Destination Egress Ip | Egress IP on destination cluster |
| 6 | ENV | Environment |
| 7 | NETWORK TYPE | Network type |

---

## Gap Analysis: Journey Requirements vs. Real Data

### Lookup Key Issue

The diagram uses **CSI** as the user's input to look up their application. The real data has **App_IC**. 

**Question:** Is CSI the same as App_IC? Or does CSI map to App_IC through a separate lookup? This needs to be confirmed — it determines whether the user provides App_IC directly or whether there's a translation layer.

For this analysis, I'll assume **CSI = App_IC** (or that there's a known mapping).

---

### Journey 1: Start My Migration

| Requirement from diagram | Needed data | Available in real data? | Which dataset/column? | Status |
|---|---|---|---|---|
| Look up application by CSI | App identifier | **App_IC** (Dataset A) | Dataset A, col 2 | AVAILABLE (if CSI = App_IC) |
| Pre-populate namespaces | Namespace list | **Namespace** + **ENV** | Dataset A, cols 1 + 7 | AVAILABLE |
| Pre-populate source cluster | Source cluster | **Source ECS Cluster** | Dataset A, col 3 | AVAILABLE |
| Pre-populate destination cluster | Destination cluster | **Destination Cluster** | Dataset A, col 4 | AVAILABLE |
| Pre-populate data center | Data center | **Data_Center** | Dataset A, col 6 | AVAILABLE |
| Pre-populate app contacts | Owner/manager | **App Manager**, **Support Manager** | Dataset A, cols 10-11 | AVAILABLE |
| Pre-populate org info | Org hierarchy | **Org**, **L1-L5 heads**, **Sector** | Dataset A, cols 8, 12-17 | AVAILABLE |
| User confirms: Vanity URL | Per-app vanity URL status | **NOT IN DATA** | — | GAP |
| User confirms: Ping or SSO | Per-app auth method | **NOT IN DATA** (SSO_SHARED_SECRET is cluster-level, not app-level) | — | GAP |
| Migration wave assignment | Wave (W1, W2, W3) | **NOT IN DATA** | — | GAP |
| Wave dates / schedule | Migration dates per wave | **NOT IN DATA** | — | GAP |
| CI/CD platform type | Enterprise DevOps Portal vs Legacy Release Manager | **NOT IN DATA** | — | GAP |
| Dependencies | Oracle, Redis, Kafka, etc. | **NOT IN DATA** | — | GAP |
| Resource requirements | CPU, memory, storage | **NOT IN DATA** | — | GAP |
| Operator requirements | Redis Operator, CouchBase, Service Mesh | **NOT IN DATA** | — | GAP |
| Certificate SAN | Certificate details | **NOT IN DATA** | — | GAP |
| Certificate changes required | Yes/no | **NOT IN DATA** | — | GAP |

**Journey 1 verdict:** The data can support identifying the application, its namespaces, clusters, and contacts. But the core value proposition of the journey — generating a **customized migration guide** based on Vanity URL, auth method, CI/CD type, dependencies, and operators — has **no backing data**. The diagram's manual selection step (Vanity URL, Ping/SSO) makes sense precisely because this data doesn't exist in the structured tables — the user must supply it. But even with that, the agent would still need CI/CD type, dependencies, and operator requirements to produce a meaningful customized guide.

---

### Journey 2: Is My Application In Scope?

| Requirement from diagram | Needed data | Available in real data? | Which dataset/column? | Status |
|---|---|---|---|---|
| Look up application by CSI | App identifier | **App_IC** | Dataset A, col 2 | AVAILABLE |
| List of namespaces in scope | Namespace + ENV | **Namespace**, **ENV** | Dataset A, cols 1 + 7 | AVAILABLE |
| Source cluster per namespace | Source cluster | **Source ECS Cluster** | Dataset A, col 3 | AVAILABLE |
| Destination cluster per namespace | Destination cluster | **Destination Cluster** | Dataset A, col 4 | AVAILABLE |
| Organized by wave | Wave assignment | **NOT IN DATA** | — | GAP |
| Wave dates | Dates per wave | **NOT IN DATA** | — | GAP |

**Journey 2 verdict:** The core ask — "is my app in scope?" — **is answerable**. If the App_IC exists in Dataset A, the app is in scope. The agent can return namespaces with their source/destination clusters and environments. However, the diagram says results should be "organized by wave" with "dates for the waves" — **wave data is not available**. The best the agent can do is organize by ENV (DEV/UAT/PROD), not by wave.

---

### Journey 3: Pull Cluster/Migration Details

| Requirement from diagram | Needed data | Available in real data? | Which dataset/column? | Status |
|---|---|---|---|---|
| Look up application by CSI | App identifier | **App_IC** | Dataset A, col 2 | AVAILABLE |
| Destination cluster name | Cluster name | **Destination Cluster** | Dataset A, col 4 | AVAILABLE |
| Cluster VIP name | VIP name | **Cluster VIP Name** | Dataset B, col 3 | AVAILABLE |
| Cluster VIP IP | VIP IP address | **Cluster VIP IP Address** | Dataset B, col 4 | AVAILABLE |
| Cluster subnet | Subnet | **Cluster Subnet** | Dataset B, col 2 | AVAILABLE |
| Infra node IPs | Node IPs | **Infra node Ips** | Dataset B, col 5 | AVAILABLE |
| SiteMinder host | SM host | **SM_REGHOST_HOSTNAME** | Dataset B, col 6 | AVAILABLE |
| SSO shared secret | Shared secret | **SSO_SHARED_SECRET** | Dataset B, col 7 | AVAILABLE |
| Source egress IP | Egress IP | **Source Egress IP** | Dataset D, col 4 | AVAILABLE |
| Destination egress IP | Egress IP | **Destination Egress Ip** | Dataset D, col 5 | AVAILABLE |
| Network type | Network type | **NETWORK TYPE** | Dataset D, col 7 | AVAILABLE |
| Source → destination cluster mapping | Cluster mapping | **Source / Destination** | Dataset C, cols 1-2 | AVAILABLE |

**Journey 3 verdict:** This is the **best supported journey**. Almost everything the diagram asks for is present across Datasets B, C, and D. The agent can:
1. Take the CSI/App_IC
2. Look up the destination cluster from Dataset A
3. Join to Dataset B for VIPs, infra nodes, SiteMinder details
4. Join to Dataset D for egress IPs and network type
5. Join to Dataset C for the cluster mapping

---

### Journey 4: Need Migration Support

| Requirement from diagram | Needed data | Available in real data? | Status |
|---|---|---|---|
| ServiceNow link | Static content | Not data-dependent | N/A — static |
| Office hours schedule | Static content | Not data-dependent | N/A — static |
| Email DL | Static content | Not data-dependent | N/A — static |

**Journey 4 verdict:** Fully possible. No data dependencies — this is static content baked into agent instructions.

---

## Summary: What's Possible vs. What's Not

### Fully Possible (data exists)

| Journey | What works |
|---------|-----------|
| Journey 2 | Look up App_IC, return namespaces with source/destination clusters, ENV — confirms "in scope" |
| Journey 3 | Full cluster infrastructure details: VIPs, infra nodes, subnets, egress IPs, SiteMinder, network type |
| Journey 4 | Static support channels — no data needed |

### Partially Possible (some data exists, some doesn't)

| Journey | What works | What's missing |
|---------|-----------|----------------|
| Journey 1 | App lookup, namespaces, clusters, contacts, org hierarchy | Vanity URL, auth method, CI/CD type, dependencies, operators, certificates, wave/schedule — all the data needed to build the "customized migration guide" |
| Journey 2 | Scope confirmation, namespaces, clusters | Wave assignments and wave dates (can only organize by ENV, not by wave) |

### Not Possible Without Additional Data

| Missing data | Affects | Notes |
|-------------|---------|-------|
| Wave assignment (W1, W2, W3) | Journey 1, Journey 2 | No column indicates which PROD wave an app belongs to |
| Wave dates/schedule | Journey 1, Journey 2 | No migration schedule data in the structured tables |
| Vanity URL (per app) | Journey 1 | Not in any dataset — diagram expects user to provide this manually, which is workable |
| Auth method per app (Ping/SSO) | Journey 1 | Not in any dataset — diagram expects user to provide this manually, which is workable |
| CI/CD platform type | Journey 1 | Not in any dataset — agent cannot determine DevOps Portal vs Legacy Release Manager |
| Dependencies | Journey 1 | No dependency data (Oracle, Redis, Kafka, etc.) |
| Resource requirements | Journey 1 | No CPU/memory/storage data |
| Operator requirements | Journey 1 | No Redis/CouchBase/Service Mesh flags |
| Certificate SAN / cert changes | Journey 1 | No certificate data |

---

## Real Data That Exists BUT Was Not In The Diagram

The real data has columns that the diagram doesn't account for. These could add value:

| Column | Dataset | Potential use |
|--------|---------|---------------|
| Cluster_Type | A | Could help differentiate cluster behavior |
| Data_Center | A | Useful for region-specific guidance |
| Sector | A | Business context |
| Region | A | Geographic context |
| Org / L1Head / L3Head / L4Head / L5 Tech / LE Business | A | Full org hierarchy — could be used for routing, escalation, or access control |
| Cluster Subnet | B | Network planning details |
| SM_REGHOST_HOSTNAME | B | SiteMinder configuration — useful in migration steps |
| NETWORK TYPE | D | Could affect migration procedure (e.g., different steps for different network types) |
| App Creation / Namespace Creation dates | A | Age of the app/namespace — could indicate complexity |

---

## Recommendations

### 1. CSI vs App_IC — Clarify the lookup key
The diagram says users will provide a "CSI." The real data has "App_IC." Need to confirm:
- Are these the same thing?
- If not, is there a mapping table?
- Can users realistically provide an App_IC when prompted?

### 2. Journey 3 is the strongest candidate to build first
It has the most complete data backing. The agent can provide a genuinely useful table of cluster/infrastructure details by joining Datasets A, B, C, and D on cluster name and namespace.

### 3. Journey 2 works but needs expectation adjustment
The agent can confirm scope and return namespaces with clusters, but cannot organize by wave or show wave dates. The output should be organized by ENV (DEV/UAT/PROD) instead.

### 4. Journey 1 needs a different approach
The "customized migration guide" cannot be fully generated from structured data alone. Two options:
- **Option A:** The guide is generated from the **unstructured knowledge base** (the markdown files already in this repo), using the structured data only for app-specific details (namespaces, clusters). The manual selections (Vanity URL, Ping/SSO) drive which sections of the knowledge base guide are relevant.
- **Option B:** Additional structured data columns are added (CI/CD type, dependencies, vanity URL flag, auth method, wave assignment) to make the guide fully data-driven.

### 5. The follow-up prompts from Journey 2 are realistic
- "What steps must my application follow to migrate?" → Journey 1 (works if Journey 1 uses Option A above)
- "Pull cluster/migration details for my application" → Journey 3 (fully supported)

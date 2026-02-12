# Migration Assistant — Agentic User Journey

**Type:** Type A Migration (Containerized apps — ECS 1.0 → Cloud@Citi BareMetal OpenShift)
**Status:** Draft for review
**Date:** February 12, 2026

---

## How to Read This Document

This document describes the **Migration Assistant** — an AI-powered conversational agent that guides application teams through their OpenShift migration. For each journey, you'll see:

- **What the user says or clicks** at each step
- **What the agent does** behind the scenes (data lookups, decisions, knowledge base queries)
- **What the agent responds with** (including realistic examples)
- **Review questions** for your feedback

Please review each journey and confirm whether the interactions, agent behavior, and expected outputs match your expectations.

---

## What Makes This an Agent (Not Just a Form)

The Migration Assistant is not a static portal or a simple form wizard. It is a **conversational AI agent** that:

| Capability | What it means |
|-----------|--------------|
| **Understands intent** | The user can type naturally ("I want to start my migration" or "Am I in scope?") and the agent routes them to the right journey. They can also click pre-built prompt cards. |
| **Looks up data** | When the user provides their CSI, the agent queries multiple data sources (namespace registry, cluster mapping, network details) and joins the results into a single view. |
| **Asks smart follow-up questions** | The agent knows which application attributes it cannot look up (CI/CD platform, Vanity URL, auth method) and asks the user to provide them. |
| **Applies decision logic** | Based on the user's answers, the agent selects the relevant sections of the migration guide from the knowledge base, skipping sections that don't apply. |
| **Personalizes the output** | The guide is not one-size-fits-all. The agent assembles a customized guide from 11 possible sections, each with conditional content. |
| **Remembers context** | If the user completes Journey 2 and then continues to Journey 1 or 3, the agent remembers their CSI and does not ask again. |
| **Handles follow-ups** | After delivering a guide or data, the user can ask clarifying questions ("What does EgressIP mean?" or "How do I create a Vanity URL?") and the agent answers from the knowledge base. |

---

## Migration Timeline (applies to all journeys)

All in-scope applications follow the same phased schedule:

| Phase | Quarter | Start | End |
|-------|---------|-------|-----|
| DEV | Q1 2026 | January 5, 2026 | February 28, 2026 |
| UAT | Q2 2026 | April 1, 2026 | May 31, 2026 |
| PROD Wave 1 | Q3 2026 | July 1, 2026 | August 31, 2026 |
| PROD Wave 2 | Q4 2026 | October 1, 2026 | November 30, 2026 |
| PROD Wave 3 | Q1 2027 | January 5, 2027 | February 28, 2027 |

DEV and UAT phases are the same for everyone. Individual applications are assigned to a PROD wave (W1, W2, or W3).

---

## How the Conversation Starts

When a user opens the Migration Assistant and selects **Type A** migration, the agent greets them and presents four prompt cards:

> **Welcome to the Migration Assistant.**
>
> I can help you with your Type A migration (ECS 1.0 → Cloud@Citi BareMetal OpenShift). What would you like to do?
>
> 1. **Start my migration** — Get a customized migration procedure for your application
> 2. **Is my application in scope?** — Check if your app is included in the current migration
> 3. **Pull cluster/migration details** — View infrastructure details for your migration
> 4. **Need migration support** — Get help with questions or issues

The user can **click a card** or **type naturally** (e.g., "I want to know if my app is in scope" or "Help me start migrating"). The agent interprets their intent and routes to the appropriate journey.

---

## Journey 1: Start My Migration

**Purpose:** Guide the user through a customized, step-by-step migration procedure tailored to their specific application.

---

**Step 1 — User selects intent**

The user clicks the card or types something like:

> "Start my migration"

---

**Step 2 — Agent asks for CSI**

The agent responds:

> Great — let's get started. Please provide your **CSI** and I'll pull up your application details.

**What the agent is doing:** Preparing to query the namespace registry and cluster mapping data sources using the CSI as the lookup key.

---

**Step 3 — User provides CSI**

> `12345`

---

**Step 4 — Agent shows application details and asks three questions**

**What the agent is doing:** The agent queries the structured data using the CSI, retrieves namespaces, source/destination clusters, environment mappings, and contacts. It then presents this data and asks three questions — these are the attributes the agent *cannot* look up from data and needs the user to provide, because they determine which migration steps apply.

The agent responds:

> I found your application. Here's what I have:
>
> | Namespace | Environment | Source Cluster | Destination Cluster |
> |-----------|-------------|---------------|-------------------|
> | trade-settle-dev | DEV | ecs-east-01 | acme-bm-east-01 |
> | trade-settle-uat | UAT | ecs-east-01 | acme-bm-east-01 |
> | trade-settle-prod | PROD | ecs-east-01 | acme-bm-east-01 |
>
> **App Manager:** J. Smith | **Support Manager:** K. Patel
>
> To build your customized migration guide, I need three things from you:
>
> **1. Which CI/CD platform does your application use?**
> - Lightspeed Enterprise (LSE)
> - Release Lifecycle Management (RLM)
> - Lightspeed Classic (LSC)
>
> **2. Does your application use a Vanity URL?**
> - Yes — we already have one
> - Yes — we need to create one
> - No — we use a cluster-based route
>
> **3. What authentication method does your application use?**
> - Ping Access (SecureSSO)
> - SiteMinder

---

**Step 5 — User makes selections**

The user responds naturally:

> "We use LSE, we already have a Vanity URL, and we use Ping Access"

Or clicks through the options. The agent understands either format.

---

**Step 6 — Agent delivers customized migration guide**

**What the agent is doing:** This is where the core intelligence lives. The agent takes the user's three selections and applies decision logic to assemble a personalized guide from the migration knowledge base. The guide has a preamble (what has already been done for them) plus 11 possible sections. Each section's content changes — or is omitted entirely — based on the user's selections.

**Example output** for a user who selected **LSE + existing Vanity URL + Ping Access:**

> Here is your customized migration guide based on your application's setup:
>
> ---
>
> **Before You Begin: What's Already Done**
>
> The following were handled by Platform Operations — no action needed from your team:
> - Project copy (namespaces, quotas, limits, service accounts, role bindings, secrets, network policies, storage volumes)
> - Netgroup configuration for destination cluster nodes
> - Firewall rules for your application's EgressIP
>
> You can view your destination cluster details on the Migration Information page.
>
> ---
>
> **Step 1. Application Deployment (Lightspeed Enterprise)**
>
> Your application uses LSE. Here's what to do:
> 1. Login to the LightSpeed Portal
> 2. Go to the Explore tab and enter your application CSI ID
> 3. Select the relevant project from the list
> 4. Add the Namespace that was copied from your source cluster
> 5. Vault Changes (if applicable)
> 6. Create an Environment referencing the new namespace on the Destination Cluster
> 7. Modify your Existing Manifest to include the new environment
> 8. Update your Helm chart to include the new environment
>
> ---
>
> **Step 2. Additional OpenShift Resources**
>
> If your application uses any of the following, specific setup instructions are available:
> - **Redis Operator** — request installation and configuration on the destination cluster
> - **Autosys** — follow the Autosys setup procedure for the new environment
> - **Service Mesh** — follow the Service Mesh configuration steps
>
> ---
>
> **Step 3. Certificate Changes**
>
> Your application uses a Vanity URL only in the SAN list.
> **No changes needed** — your existing certificates will work on the new cluster.
>
> ---
>
> **Step 4. Secrets**
>
> **No action required.** Managed and unmanaged secrets carry over automatically. Native secrets were copied from the source cluster.
> **Note:** Token-related secrets were not copied. Recreate them on the destination cluster if needed.
>
> ---
>
> **Step 5. Ping Access (SecureSSO)**
>
> Your application uses Ping Access with a Vanity URL.
> **No changes needed** — the same Vanity URL will be used on the Destination Cluster.
>
> ---
>
> **Step 6. Egress IP / Firewall / Proxy / Nodeport**
>
> **Important:** Your application will get a new Egress IP on the destination cluster.
> - If your Egress IP is in a firewall rule for **internet access** — no action needed, the Migration Team will coordinate
> - If your Egress IP is used for **internal systems** (EEMS, SFTP, Mainframes, MQ, etc.) — you must work with those teams to update whitelisting
>
> **Proxy:** If your application uses a proxy for internet access, update ports from 9999 (Dev) / 7777 (Prod) to **17777** on BareMetal clusters.
>
> **Nodeport:** You'll keep the same NodePort. If you get a Port Conflict error, contact Tenant Ops.
>
> ---
>
> **Step 7. Network Policies**
>
> **No action required.** All existing network policies will be created on the Destination Cluster automatically.
>
> ---
>
> **Step 8. Storage (PV/PVC)**
>
> - **Traditional storage (NAS/SONIC):** PV/PVCs are copied as part of project copy. Note: the Container UID will be different — ensure your Pod/Deployment yaml has the Supplemental group GID defined.
> - **Dynamic storage (sc-ontap-nas, thin, thin-csi):** Existing dynamic PVs cannot be reused on the destination. However, the same storage classes are already provisioned on Cloud@Citi clusters, so you can create new PVs.
>
> ---
>
> **Step 9. Vanity URL Configuration**
>
> Your application already has a Vanity URL. Since BareMetal clusters have **no wildcard DNS**, your Vanity URL must be explicitly mapped.
>
> *DEV / UAT:*
> - Map your Vanity URL to the **Cluster VIP** (recommended, no extra infra needed)
> - Alternative: Use an F5 APP VIP via the NSA portal
> - Update via the DNS UI tool → **Modify**
>
> *PROD / COB:*
> - Create a **WIP** (Weighted IP pool) with infra nodes as members using **LBAaS** (recommended)
> - Alternative: Provision through the NSA portal
> - Map your Vanity URL to the WIP or Cluster VIP
>
> *If your URL is branded* (e.g., yourapp.company.com):
> 1. Register DNS entry through CMP (3-day SLA, requires SNOW change)
> 2. Map to VIP/WIP via DNS UI tool → "Add Domain DNS Entries"
>
> *If your URL is non-branded* (e.g., yourapp.nam.nsroot.net):
> - DNS UI tool → Modify (3-day SLA from approval, no procurement needed)
>
> ---
>
> **Step 10. Application Validation**
>
> After deployment, perform checkouts and reach out to Tenant Operations for any issues using INC template **ITMP0000266058**.
> Contact: CTI GLOBAL Openshift-Migration
>
> ---
>
> **Step 11. Project Deletion on Old Cluster**
>
> This should be your **last step** — only after your application is running on the new cluster.
> - Remove all resources from the source project first
> - **DEV & UAT:** Raise INC with template **ITMP0000256715**
> - **PROD:** Use Change Task template **TTMP0000265950**
> - **Warning:** Once deleted, the project cannot be restored.
>
> ---
>
> Do you have any questions about your migration guide? Or would you like me to pull your cluster infrastructure details?

---

**How the agent's decision logic works:**

The three selections the user makes in Step 5 determine which version of each section the agent delivers:

| User selection | Sections affected | What changes |
|---------------|-------------------|-------------|
| **CI/CD platform** | Step 1 only | LSE = 8 steps via LightSpeed Portal. RLM = update the RLM OnBoarding Template. LSC = update CI/CD pipeline, must be a Delegate to the LightSpeed Project. |
| **Vanity URL status** | Steps 3, 5, and 9 | Existing Vanity URL = no cert changes, no auth changes, modify DNS mapping. Creating new = full DNS registration + VIP/WIP setup. Cluster-based route = order new certificate, modify Base URL in auth config. |
| **Auth method** | Step 5 only | Ping Access + Vanity URL = no changes. SiteMinder + Vanity URL = no changes. Ping Access + cluster route = modify Base URL via CMP. SiteMinder + cluster route = modify Base URL AND update SM_REGHOST_HOSTNAME. |

Sections that **always appear regardless of selections:** Before You Begin, Steps 2, 4, 6, 7, 8, 10, 11.

---

### Journey 1 — Step Summary

| Step | Who | What happens |
|------|-----|-------------|
| 1 | User | Clicks card or types "Start my migration" |
| 2 | Agent | Asks for CSI |
| 3 | User | Provides CSI |
| 4 | Agent | Queries data, shows application details, asks three selection questions (CI/CD, Vanity URL, auth) |
| 5 | User | Makes selections (click or natural language) |
| 6 | Agent | Applies decision logic, assembles personalized guide from knowledge base, delivers it |
| 7 | User | Can ask follow-up questions or navigate to another journey |

### Journey 1 — Review Questions

| # | Question |
|---|----------|
| 1a | The agent asks three questions: CI/CD platform (LSE/RLM/LSC), Vanity URL status, and auth method (Ping/SiteMinder). **Are these the right three questions?** Are there others that affect the migration steps? |
| 1b | The guide has a preamble + 11 steps. **Are there sections missing or ones that should be removed?** |
| 1c | The original diagram says the agent should "submit the pertinent requests and orders on your behalf." **What specific requests/orders?** (CMP orders for certificates? SNOW changes for DNS? INC templates?) Should the agent actually submit these, or just provide links and template numbers? |
| 1d | After delivering the guide, **should the agent offer follow-up actions?** (e.g., "Want me to pull your cluster details?" or "Want me to check your scope?") |

---

## Journey 2: Is My Application In Scope?

**Purpose:** Let the user check whether their application is included in the current migration and see which namespaces are in scope.

---

**Step 1 — User selects intent**

The user clicks the card or types:

> "Is my application in scope?"

---

**Step 2 — Agent asks for CSI**

> Sure — let me check for you. What's your **CSI**?

**What the agent is doing:** Preparing to query the namespace registry for all namespaces associated with this CSI.

---

**Step 3 — User provides CSI**

> `67890`

---

**Step 4 — Agent returns scope results**

**What the agent is doing:** The agent queries the data, finds all namespaces linked to this CSI, retrieves their source/destination clusters and environments, and overlays the migration timeline.

If the CSI is found:

> Your application is **in scope** for the current migration. Here are your namespaces:
>
> **DEV — Q1 2026 (Jan 5 – Feb 28, 2026)**
>
> | Namespace | Source Cluster | Destination Cluster |
> |-----------|---------------|-------------------|
> | risk-analytics-dev | ecs-west-01 | acme-bm-west-01 |
>
> **UAT — Q2 2026 (Apr 1 – May 31, 2026)**
>
> | Namespace | Source Cluster | Destination Cluster |
> |-----------|---------------|-------------------|
> | risk-analytics-uat | ecs-west-01 | acme-bm-west-01 |
>
> **PROD — Q3-Q4 2026 or Q1 2027**
>
> | Namespace | Source Cluster | Destination Cluster |
> |-----------|---------------|-------------------|
> | risk-analytics-prod | ecs-west-01 | acme-bm-west-01 |

> **Data note for reviewers:** DEV and UAT dates are the same for all applications and can always be shown. The specific **PROD wave assignment** (W1, W2, or W3) is not currently in the structured data — the agent can confirm the app is in scope for PROD but cannot confirm which specific wave or date.

If the CSI is not found:

> I wasn't able to find CSI **99999** in the current migration scope. This could mean your application isn't included in this wave, or the CSI may be different. Would you like to try a different CSI, or would you prefer to contact the migration support team?

---

**Step 5 — Agent offers next steps**

After showing scope results, the agent proactively offers two follow-up paths:

> **What would you like to do next?**
>
> → "What steps must my application follow to migrate?"
> → "Pull cluster/migration details for my application"

**What the agent is doing:** It holds the CSI in memory. If the user picks either option, the agent routes them into Journey 1 or Journey 3 **without asking for the CSI again**.

---

### Journey 2 — Step Summary

| Step | Who | What happens |
|------|-----|-------------|
| 1 | User | Clicks card or types "Is my app in scope?" |
| 2 | Agent | Asks for CSI |
| 3 | User | Provides CSI |
| 4 | Agent | Queries data, returns namespaces organized by migration phase with dates |
| 5 | Agent | Offers follow-up paths (Journey 1 or Journey 3), remembers CSI |

### Journey 2 — Review Questions

| # | Question |
|---|----------|
| 2a | **Should per-app PROD wave assignment (W1/W2/W3) be added to the data source?** The agent can currently show DEV/UAT dates (same for everyone) but cannot confirm which PROD wave. |
| 2b | **Should the agent show additional fields** in the scope results? (e.g., App Manager, region, org?) |
| 2c | When the CSI is not found, the agent offers to try another CSI or contact support. **Is this the right fallback?** |

---

## Journey 3: Pull Cluster/Migration Details

**Purpose:** Give the user the infrastructure details they need for their migration — cluster endpoints, network information, and authentication configuration.

---

**Step 1 — User selects intent**

The user clicks the card or types:

> "Pull cluster details for my application"

---

**Step 2 — Agent asks for CSI**

> I'll pull your cluster and migration details. What's your **CSI**?

**What the agent is doing:** Preparing to query multiple data sources — namespace registry, cluster infrastructure, and network details — and join them by destination cluster.

---

**Step 3 — User provides CSI**

> `11111`

---

**Step 4 — Agent returns infrastructure details**

**What the agent is doing:** The agent looks up the CSI, identifies the destination cluster, then joins across cluster infrastructure data (VIPs, subnets, infra nodes, SiteMinder config) and namespace network data (egress IPs, network type) to present one unified view.

> Here are the migration details for your application:
>
> ---
>
> **Cluster Mapping**
>
> | Source (ECS 1.0) | Destination (Cloud@Citi) |
> |---|---|
> | ecs-east-01 | acme-bm-east-01 |
>
> ---
>
> **Destination Cluster Infrastructure**
>
> | Field | Value |
> |---|---|
> | Cluster Subnet | 10.40.1.0/24 |
> | Cluster VIP Name | acme-bm-east-01-vip |
> | Cluster VIP IP Address | 10.40.1.100 |
> | Infra Node IPs | 10.40.1.10, 10.40.1.11, 10.40.1.12 |
> | SM_REGHOST_HOSTNAME | smreg-east-01.acme.com |
> | SSO_SHARED_SECRET | Contact Platform Operations |
>
> ---
>
> **Namespace Network Details**
>
> | Namespace | ENV | Source Egress IP | Destination Egress IP | Network Type |
> |---|---|---|---|---|
> | payments-dev | DEV | 10.20.100.1 | 10.40.100.1 | Standard |
> | payments-uat | UAT | 10.20.100.1 | 10.40.100.1 | Standard |
> | payments-prod | PROD | 10.20.100.1 | 10.40.100.1 | Standard |
>
> ---
>
> Would you like me to walk you through your migration steps, or do you have questions about any of these details?

---

### Journey 3 — Step Summary

| Step | Who | What happens |
|------|-----|-------------|
| 1 | User | Clicks card or types "Pull my cluster details" |
| 2 | Agent | Asks for CSI |
| 3 | User | Provides CSI |
| 4 | Agent | Queries and joins multiple data sources, returns unified infrastructure view |
| 5 | Agent | Offers to continue to migration steps or answer questions |

### Journey 3 — Review Questions

| # | Question |
|---|----------|
| 3a | **Is this the right set of infrastructure details?** Cluster VIP, infra nodes, subnets, egress IPs, SiteMinder hostname, SSO shared secret, network type. Anything missing? |
| 3b | **Should SSO_SHARED_SECRET be shown**, or should it always say "Contact Platform Operations"? |
| 3c | **Are there fields the user needs that aren't listed?** (e.g., firewall rules, specific port numbers, DNS entries?) |

---

## Journey 4: Need Migration Support

**Purpose:** Direct the user to the right support channel.

---

**Step 1 — User selects intent**

The user clicks the card or types:

> "I need help with my migration"

---

**Step 2 — Agent presents support options**

**What the agent is doing:** No data lookup needed. The agent pulls support channel information directly from the knowledge base and presents it.

> I'm happy to help! Here are your support options:
>
> ---
>
> **Submit a Migration Issue**
> Open a ServiceNow Incident using the linked INC template — response within 90 minutes.
>
> ---
>
> **Join Weekly Office Hours**
> Live Q&A with the migration team:
> - **APAC:** Wednesdays, 9–10 AM IST
> - **EMEA:** Wednesdays, 9–10 AM GMT
> - **NAM:** Thursdays, 9–10 AM CT
>
> Click your region to save to your calendar.
>
> ---
>
> **Email the Migration Team**
> Send to: *CTS Global OpenShift Migrations*
> Response guaranteed within 24 hours.
>
> ---
>
> Is there a specific question I can help with right now?

---

### Journey 4 — Step Summary

| Step | Who | What happens |
|------|-----|-------------|
| 1 | User | Clicks card or types "I need help" |
| 2 | Agent | Presents three support channels from the knowledge base |
| 3 | User | Picks a channel, or asks the agent a direct question |

### Journey 4 — Review Questions

| # | Question |
|---|----------|
| 4a | **Are these the correct three support channels?** Any missing or outdated? |
| 4b | **Should the ServiceNow option link directly to a pre-filled INC template?** |
| 4c | **Are the office hours times and regions correct?** |

---

## Cross-Journey Connections

The journeys are connected. The agent maintains context across them:

```
User opens Migration Assistant
    │
    ├── Journey 1: "Start my migration"
    │       └── After guide → agent offers: Journey 3 or follow-up questions
    │
    ├── Journey 2: "Is my app in scope?"
    │       └── After results → agent offers: Journey 1 or Journey 3 (CSI remembered)
    │
    ├── Journey 3: "Pull cluster details"
    │       └── After details → agent offers: Journey 1 or follow-up questions
    │
    └── Journey 4: "Need support"
            └── Agent presents channels or answers questions directly
```

**Key agent behavior:** When the user transitions between journeys, the agent **does not ask for the CSI again** if it already has it. The conversation is continuous, not a series of disconnected forms.

### Review Questions

| # | Question |
|---|----------|
| 5a | **Are there other cross-journey connections?** Should any journey link to any other that isn't shown above? |
| 5b | **Should the agent proactively suggest the next journey?** For example, after delivering the guide in Journey 1, should it say "Would you like me to pull your cluster details too?" |

---

## Summary of All Review Questions

| # | Journey | Question |
|---|---------|----------|
| 1a | Start My Migration | Are CI/CD platform (LSE/RLM/LSC), Vanity URL status, and auth method (Ping/SiteMinder) the right three questions? |
| 1b | Start My Migration | Are there guide sections missing or ones that should be removed from the 11 shown? |
| 1c | Start My Migration | What specific "requests and orders" should the agent submit? Or just provide links and template numbers? |
| 1d | Start My Migration | After the guide, should the agent offer follow-up actions? |
| 2a | Is App In Scope? | Should per-app PROD wave assignment (W1/W2/W3) be added to the data source? |
| 2b | Is App In Scope? | Should additional fields be shown in scope results? |
| 2c | Is App In Scope? | Is "try another CSI or contact support" the right fallback when not found? |
| 3a | Cluster Details | Is this the right set of infrastructure details? |
| 3b | Cluster Details | Should SSO_SHARED_SECRET be displayed or redacted? |
| 3c | Cluster Details | Are there missing fields the user needs? |
| 4a | Support | Are the three support channels correct and current? |
| 4b | Support | Should ServiceNow link to a pre-filled template? |
| 4c | Support | Are office hours times and regions correct? |
| 5a | Cross-Journey | Are there other journey connections not shown? |
| 5b | Cross-Journey | Should the agent proactively suggest the next journey? |

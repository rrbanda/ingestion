# Migration Assistant — User Journey Review

**Type:** Type A Migration (Containerized apps — ECS 1.0 → Cloud@Citi OpenShift)
**Status:** Draft for review
**Date:** February 12, 2026

---

## How to Read This Document

This document walks through each user journey in the Migration Assistant, step by step. For each journey, you'll see:

- **What the user sees** at each step
- **What the user does** (clicks, types)
- **What the system responds with** (including an example)
- **Review questions** for your feedback

Please review each journey and confirm whether the steps, prompts, and expected outputs match your expectations.

---

## Overview

When a user selects **Type A** migration, they are presented with four options:

| # | Option | Purpose |
|---|--------|---------|
| 1 | **Start my migration** | Get a customized migration procedure for your application |
| 2 | **Is my application in scope?** | Check if your application is included in the current migration wave |
| 3 | **Pull application-specific cluster/migration details** | View infrastructure details needed for your migration |
| 4 | **Need migration support** | Get help with migration-related questions or issues |

---

## Journey 1: Start My Migration

**Purpose:** Determine the migration procedure specific to the user's application and generate a customized migration guide.

---

**Step 1 — User selects the card**

The user sees:

> **Start my migration.**
>
> Select to determine the procedure specific to your application and have the Migration Assistant submit the pertinent requests and orders on your behalf.

The user clicks the card.

---

**Step 2 — System asks for CSI**

The system responds:

> Please provide your CSI to populate the migration and let the Migration Assistant get started on your migration.

---

**Step 3 — User provides CSI**

The user types their CSI (e.g., `12345`).

---

**Step 4 — System shows application details and asks for confirmation**

The system looks up the CSI and shows what it found:

> I found your application details:
>
> | Namespace | Environment | Source Cluster | Destination Cluster | Data Center |
> |-----------|-------------|---------------|-------------------|-------------|
> | trade-settle-dev | DEV | ecs-east-01 | acme-bm-east-01 | US East |
> | trade-settle-uat | UAT | ecs-east-01 | acme-bm-east-01 | US East |
> | trade-settle-prod | PROD | ecs-east-01 | acme-bm-east-01 | US East |
>
> **App Manager:** J. Smith
> **Support Manager:** K. Patel
>
> I need you to confirm the following:
> 1. Does your application/namespace leverage a **Vanity URL**?
> 2. Does your application use **Ping Access** or **SSO**?

---

**Step 5 — User makes selections**

The user responds (e.g., "Yes we use a Vanity URL, and we use Ping Access").

---

**Step 6 — System delivers customized migration guide**

The system generates a migration guide tailored to the user's application:

> Based on your application's attributes, here is your customized migration guide:
>
> **Your application uses a Vanity URL with Ping Access.**
>
> **Certificate Changes:** No changes required — your existing certificates work on the new cluster since your SAN only contains your Vanity URL.
>
> **Authentication Changes:** No changes required — Ping Access with a Vanity URL requires no reconfiguration.
>
> **Migration Steps:**
> 1. Ensure Platform Operations has completed the project copy (namespaces, quotas, secrets, network policies)
> 2. Update your CI/CD pipeline to target the destination cluster...
> 3. Deploy to the new cluster and validate...
> *(continued)*

---

### Journey 1 — Step Summary

| Step | Who | What happens |
|------|-----|-------------|
| 1 | User | Clicks "Start my migration" |
| 2 | System | Asks for CSI |
| 3 | User | Provides CSI |
| 4 | System | Shows application details, asks user to confirm Vanity URL and Ping/SSO |
| 5 | User | Confirms Vanity URL and authentication method |
| 6 | System | Delivers customized migration guide |

### Journey 1 — Review Questions

| # | Question |
|---|----------|
| 1a | The system can show namespaces, source/destination clusters, data center, and contacts from the lookup. **Is this the right set of information to pre-populate?** Are there other fields the user should see? |
| 1b | The user is asked to manually confirm Vanity URL and Ping/SSO. **Should the system also ask about CI/CD platform** (Enterprise DevOps Portal vs. Legacy Release Manager)? This is not available from the data lookup, but it changes the migration steps. |
| 1c | The customized guide is generated based on the user's selections. **What level of detail is expected?** A summary of key points, or a full step-by-step procedure? |
| 1d | The diagram says the Migration Assistant should "submit the pertinent requests and orders on your behalf." **What specific requests/orders does this refer to?** (e.g., ServiceNow tickets, DNS requests, certificate orders?) |

---

## Journey 2: Is My Application In Scope?

**Purpose:** Let the user check if their application is included in the current migration and see which namespaces are in scope.

---

**Step 1 — User selects the card**

The user sees:

> **Is my application in scope?**
>
> Select to pull all projects associated with your application.

The user clicks the card.

---

**Step 2 — System asks for CSI**

The system responds:

> Please provide your CSI below for a list of all namespaces in scope for the current migration wave.

---

**Step 3 — User provides CSI**

The user types their CSI (e.g., `67890`).

---

**Step 4 — System returns scope results**

The diagram specifies the system should return: *"a list of namespaces (organized by wave) that are in scope for their app. This should also include source + destination cluster and dates for the waves."*

If the CSI is found, the expected output per the diagram:

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
> **PROD Wave 1 — Q3 2026 (Jul 1 – Aug 31, 2026)**
>
> | Namespace | Source Cluster | Destination Cluster |
> |-----------|---------------|-------------------|
> | risk-analytics-prod | ecs-west-01 | acme-bm-west-01 |

> **Data note:** The current structured data has namespace, source cluster, destination cluster, and environment (DEV/UAT/PROD) — but does **not** have wave assignments (W1/W2/W3) or wave dates. To produce the output above, wave and schedule data would need to be added to the data source. Without it, results can only be organized by environment without dates.

If the CSI is not found:

> Your application (CSI: 99999) was **not found** in the current migration scope. Please contact the migration support team for assistance.

---

**Step 5 — System offers follow-up options**

After showing the results, the system presents two follow-up prompts the user can click:

> **What would you like to do next?**
>
> → "What steps must my application follow to migrate?"
>
> → "Pull cluster/migration details for my application"

- The first option takes the user into **Journey 1** (Start My Migration)
- The second option takes the user into **Journey 3** (Pull Cluster Details)
- In both cases, the **CSI is already known** — the system does not ask for it again.

---

### Journey 2 — Step Summary

| Step | Who | What happens |
|------|-----|-------------|
| 1 | User | Clicks "Is my application in scope?" |
| 2 | System | Asks for CSI |
| 3 | User | Provides CSI |
| 4 | System | Shows namespaces with source/destination clusters, organized by wave with dates (per diagram) |
| 5 | System | Offers two follow-up options |

### Journey 2 — Review Questions

| # | Question |
|---|----------|
| 2a | The diagram requires results organized by wave with wave dates. **Wave assignments (W1/W2/W3) and wave dates are not currently in the data.** Should this data be added to the source? Or is organizing by environment (DEV/UAT/PROD) without dates acceptable? |
| 2b | **Should the system show any additional fields** in the scope results? (e.g., App Manager, region, org?) |
| 2c | When the CSI is not found, **what should the system recommend?** Contact support? Check a different CSI? |

---

## Journey 3: Pull Application-Specific Cluster/Migration Details

**Purpose:** Show the user the infrastructure details they need for their migration — cluster endpoints, network information, and SiteMinder configuration.

---

**Step 1 — User selects the card**

The user sees:

> **Pull application-specific cluster/migration details**
>
> View the procedure and infrastructure details required for your application to migrate.

The user clicks the card.

---

**Step 2 — System asks for CSI**

The system responds:

> Please provide your CSI below for a list of all namespaces in scope for the current migration wave.

---

**Step 3 — User provides CSI**

The user types their CSI (e.g., `11111`).

---

**Step 4 — System returns migration details**

The system looks up the CSI, finds the destination cluster, and joins across multiple data sources to present a complete infrastructure view:

> Here are the migration details for your application:
>
> ---
>
> **Cluster Mapping**
>
> | Source ECS 1.0 Cluster | Destination Cloud@Citi Cluster |
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

---

### Journey 3 — Step Summary

| Step | Who | What happens |
|------|-----|-------------|
| 1 | User | Clicks "Pull application-specific cluster/migration details" |
| 2 | System | Asks for CSI |
| 3 | User | Provides CSI |
| 4 | System | Returns cluster infrastructure and namespace network details |

### Journey 3 — Review Questions

| # | Question |
|---|----------|
| 3a | **Is this the right set of infrastructure details?** Cluster VIP, infra nodes, subnets, egress IPs, SiteMinder hostname, SSO shared secret, network type. Anything missing? |
| 3b | **Should the SSO_SHARED_SECRET be shown directly**, or should it always say "Contact Platform Operations"? |
| 3c | **Are there any fields the user needs that aren't listed here?** (e.g., wildcard DNS, firewall rules, specific port numbers?) |

---

## Journey 4: Need Migration Support

**Purpose:** Direct the user to the right support channel based on their needs.

---

**Step 1 — User selects the card**

The user sees:

> **Need migration support.**
>
> Select for help with migration-related questions or issues.

The user clicks the card.

---

**Step 2 — System presents support options**

The system responds (no CSI or data lookup needed):

> Need support? Choose one of the following options to get the assistance you need!
>
> ---
>
> **Submit a Migration Issue**
> ServiceNow Incident — Complete the linked INC template for response within 90 minutes.
>
> ---
>
> **Join our Weekly Office Hours**
> Join live office hours for Q&A and support.
> - **APAC:** Wednesdays, 9–10 AM IST
> - **EMEA:** Wednesdays, 9–10 AM GMT
> - **NAM:** Thursdays, 9–10 AM CT
>
> Click your region to download and save to your calendar.
>
> ---
>
> **Have an Additional Migration Question?**
> Send to the following DL: *CTS Global OpenShift Migrations*
> Response guaranteed within 24 hours.

---

### Journey 4 — Step Summary

| Step | Who | What happens |
|------|-----|-------------|
| 1 | User | Clicks "Need migration support" |
| 2 | System | Presents three support channels |
| 3 | User | Chooses a channel and follows through |

### Journey 4 — Review Questions

| # | Question |
|---|----------|
| 4a | **Are these the correct three support channels?** Are any missing or outdated? |
| 4b | **Should the ServiceNow option link directly to a pre-filled INC template**, or just to the general ServiceNow portal? |
| 4c | **Are the office hours times and regions correct?** |

---

## Cross-Journey Connections

The journeys are not isolated. After completing Journey 2, the user is offered two follow-up options that connect to the other journeys:

```
Journey 2 (Is my app in scope?)
    │
    ├── "What steps must my application follow to migrate?"
    │       └── → Journey 1 (Start my migration) — CSI already known
    │
    └── "Pull cluster/migration details for my application"
            └── → Journey 3 (Pull cluster details) — CSI already known
```

When the user follows these links, **the system remembers the CSI** from Journey 2 and does not ask for it again.

### Review Question

| # | Question |
|---|----------|
| 5a | **Are there any other cross-journey connections?** For example, should Journey 1 offer a link to Journey 3 after delivering the migration guide? Should Journey 3 offer a link to Journey 1? |

---

## Summary of All Review Questions

| # | Journey | Question |
|---|---------|----------|
| 1a | Start My Migration | Is the right set of information being pre-populated? |
| 1b | Start My Migration | Should the system also ask about CI/CD platform (DevOps Portal vs. Legacy Release Manager)? |
| 1c | Start My Migration | What level of detail is expected in the customized migration guide? |
| 1d | Start My Migration | What specific "requests and orders" should the system submit on behalf of the user? |
| 2a | Is App In Scope? | The diagram requires results organized by wave with dates. This data (wave assignment, wave dates) is **not currently available**. Should it be added to the data source? Or is organizing by environment (DEV/UAT/PROD) without dates acceptable? |
| 2b | Is App In Scope? | Should additional fields be shown in scope results? |
| 2c | Is App In Scope? | What should happen when a CSI is not found? |
| 3a | Cluster Details | Is this the right set of infrastructure details? |
| 3b | Cluster Details | Should SSO_SHARED_SECRET be displayed or redacted? |
| 3c | Cluster Details | Are there missing fields the user needs? |
| 4a | Support | Are the three support channels correct and current? |
| 4b | Support | Should ServiceNow link to a pre-filled template? |
| 4c | Support | Are office hours times and regions correct? |
| 5a | Cross-Journey | Are there other connections between journeys beyond the two shown? |

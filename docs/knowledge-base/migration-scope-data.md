# ACME Corp Type A Migration — Scope and Schedule

## Migration Schedule

All in-scope applications follow the same environment-based migration phases:

- **DEV** — Q1 2026 (January 5, 2026 – February 28, 2026). DEV migration deadline: February 28, 2026.
- **UAT** — Q2 2026 (April 1, 2026 – May 31, 2026)
- **PROD Wave 1** — Q3 2026 (July 1, 2026 – August 31, 2026)
- **PROD Wave 2** — Q4 2026 (October 1, 2026 – November 30, 2026)
- **PROD Wave 3** — Q1 2027 (January 5, 2027 – February 28, 2027)

Current phase: DEV (Q1 2026). All DEV migrations must complete by February 28, 2026.

Applications are assigned to a PROD wave (W1, W2, or W3) based on complexity and dependencies. DEV and UAT phases are the same for all applications.

---

## Applications & Namespaces In Scope

All applications and namespaces in scope for the DEV migration and their destination ACME Cloud clusters.

### CSI 12345 — Trade Settlement Service

- **Owner:** Team Alpha
- **Contact:** trade-settle-team@acme-demo.com
- **Description:** Real-time trade settlement processing for equities and fixed income
- **In Scope:** Yes
- **PROD Wave:** Wave 1 (Q3 2026)
- **Source Cluster (ECS 1.0):** ecs-east-01
- **Destination Cluster (ACME Cloud):** acme-bm-east-01
- **Namespaces:** trade-settle-dev, trade-settle-uat, trade-settle-prod
- **CI/CD Platform:** Enterprise DevOps Portal
- **Vanity URL:** Yes — settle.acme-demo.com
- **Authentication:** Ping Access
- **Certificate SAN:** settle.acme-demo.com (Vanity URL only — no cluster routes in SAN)
- **Certificate Changes Required:** No — existing certificates work on new cluster
- **Auth Changes Required:** No — Vanity URL with Ping Access requires no changes
- **Dependencies:** Oracle DB (external), Redis (in-cluster), MQ Series (external)
- **Resource Requirements:** CPU: 8 cores, Memory: 32GB, Storage: 50GB
- **Requires Redis Operator:** Yes — 3-node cluster
- **Requires Service Mesh:** No
- **DEV Migration Status:** Scheduled
- **Notes:** Low-risk migration. All dependencies use Vanity URLs.

---

### CSI 67890 — Risk Analytics Engine

- **Owner:** Team Bravo
- **Contact:** risk-analytics-team@acme-demo.com
- **Description:** Real-time risk calculations and reporting for trading desks
- **In Scope:** Yes
- **PROD Wave:** Wave 1 (Q3 2026)
- **Source Cluster (ECS 1.0):** ecs-west-01
- **Destination Cluster (ACME Cloud):** acme-bm-west-01
- **Namespaces:** risk-analytics-dev, risk-analytics-uat, risk-analytics-prod
- **CI/CD Platform:** Legacy Release Manager
- **Vanity URL:** Yes — risk.acme-demo.com
- **Authentication:** SSO (SiteMinder)
- **Certificate SAN:** risk.acme-demo.com (Vanity URL only)
- **Certificate Changes Required:** No — existing certificates work on new cluster
- **Auth Changes Required:** No change required for migration, but recommend migrating from SiteMinder to Ping Access post-migration
- **Dependencies:** PostgreSQL (external), Kafka (external), SFTP (external)
- **Resource Requirements:** CPU: 16 cores, Memory: 64GB, Storage: 100GB
- **Requires Redis Operator:** No
- **Requires Service Mesh:** Yes — inter-service communication
- **DEV Migration Status:** Scheduled
- **Notes:** Medium complexity due to Service Mesh and SiteMinder.

---

### CSI 11111 — Payment Gateway

- **Owner:** Team Charlie
- **Contact:** payments-team@acme-demo.com
- **Description:** Payment processing gateway for domestic and international wire transfers
- **In Scope:** Yes
- **PROD Wave:** Wave 1 (Q3 2026)
- **Source Cluster (ECS 1.0):** ecs-east-01
- **Destination Cluster (ACME Cloud):** acme-bm-east-01
- **Namespaces:** payments-dev, payments-uat, payments-prod
- **CI/CD Platform:** Enterprise DevOps Portal
- **Vanity URL:** Yes — pay.acme-demo.com
- **Authentication:** Ping Access
- **Certificate SAN:** pay.acme-demo.com (Vanity URL only)
- **Certificate Changes Required:** No
- **Auth Changes Required:** No
- **Dependencies:** Oracle DB (external), HSM (external), MQ Series (external)
- **Resource Requirements:** CPU: 12 cores, Memory: 48GB, Storage: 75GB
- **Requires Redis Operator:** Yes — 3-node cluster for session caching
- **Requires Service Mesh:** No
- **DEV Migration Status:** In Progress
- **Notes:** Dev migration currently in progress. Validated successfully in lower environments.

---

### CSI 22222 — Customer Portal

- **Owner:** Team Delta
- **Contact:** cust-portal-team@acme-demo.com
- **Description:** External-facing customer portal for account management
- **In Scope:** Yes
- **PROD Wave:** Wave 2 (Q4 2026)
- **Source Cluster (ECS 1.0):** ecs-east-02
- **Destination Cluster (ACME Cloud):** acme-bm-east-01
- **Namespaces:** cust-portal-dev, cust-portal-uat, cust-portal-prod
- **CI/CD Platform:** Enterprise DevOps Portal
- **Vanity URL:** Yes — portal.acme-demo.com
- **Authentication:** Ping Access
- **Certificate SAN:** portal.acme-demo.com (Vanity URL only)
- **Certificate Changes Required:** No
- **Auth Changes Required:** No
- **Dependencies:** MongoDB (in-cluster), Redis (in-cluster), S3 (external)
- **Resource Requirements:** CPU: 8 cores, Memory: 32GB, Storage: 40GB
- **Requires Redis Operator:** Yes — 3-node cluster
- **Requires Service Mesh:** No
- **DEV Migration Status:** Scheduled
- **Notes:** Straightforward migration. All in-cluster dependencies handled by Platform Ops project copy.

---

### CSI 33333 — Compliance Reporting

- **Owner:** Team Echo
- **Contact:** team-echo@acme-demo.com
- **Description:** Regulatory compliance reporting and audit generation
- **In Scope:** Yes
- **PROD Wave:** Wave 2 (Q4 2026)
- **Source Cluster (ECS 1.0):** ecs-west-01
- **Destination Cluster (ACME Cloud):** acme-bm-west-01
- **Namespaces:** compliance-dev, compliance-uat, compliance-prod
- **CI/CD Platform:** Legacy Release Manager
- **Vanity URL:** No — uses cluster-specific route
- **Authentication:** Ping Access
- **Certificate SAN:** compliance-reporting.apps.ecs-west-01.acme-demo.com (cluster route — NOT a Vanity URL)
- **Certificate Changes Required:** YES — current SAN includes cluster-specific route. Must order new certificate with updated SAN for destination cluster, or migrate to a Vanity URL (recommended).
- **Auth Changes Required:** No — Ping Access with cluster route still works, but Base URL update may be needed if route changes
- **Dependencies:** Oracle DB (external), SFTP (external)
- **Resource Requirements:** CPU: 4 cores, Memory: 16GB, Storage: 200GB
- **Requires Redis Operator:** No
- **Requires Service Mesh:** No
- **DEV Migration Status:** Scheduled
- **Notes:** IMPORTANT — Requires new certificate due to cluster-specific route in SAN. Strongly recommend migrating to a Vanity URL before migration.

---

### CSI 44444 — FX Trading Platform

- **Owner:** Team Foxtrot
- **Contact:** fx-platform-team@acme-demo.com
- **Description:** Foreign exchange trading and execution platform
- **In Scope:** Yes
- **PROD Wave:** Wave 2 (Q4 2026)
- **Source Cluster (ECS 1.0):** ecs-east-01
- **Destination Cluster (ACME Cloud):** acme-bm-east-01
- **Namespaces:** fx-trading-dev, fx-trading-prod (no UAT environment)
- **CI/CD Platform:** Enterprise DevOps Portal
- **Vanity URL:** Yes — fx.acme-demo.com
- **Authentication:** Ping Access
- **Certificate SAN:** fx.acme-demo.com (Vanity URL only)
- **Certificate Changes Required:** No
- **Auth Changes Required:** No
- **Dependencies:** Oracle DB (external), Kafka (external), Bloomberg feed (external)
- **Resource Requirements:** CPU: 16 cores, Memory: 64GB, Storage: 50GB
- **Requires Redis Operator:** No
- **Requires Service Mesh:** No
- **DEV Migration Status:** Scheduled
- **Notes:** No UAT environment. Deploys directly to prod after dev validation.

---

### CSI 55555 — Document Management

- **Owner:** Team Golf
- **Contact:** docmgmt-team@acme-demo.com
- **Description:** Enterprise document storage and retrieval system
- **In Scope:** Yes
- **PROD Wave:** Wave 3 (Q1 2027)
- **Source Cluster (ECS 1.0):** ecs-west-02
- **Destination Cluster (ACME Cloud):** acme-bm-west-01
- **Namespaces:** docmgmt-dev, docmgmt-prod
- **CI/CD Platform:** Enterprise DevOps Portal
- **Vanity URL:** Yes — docs.acme-demo.com
- **Authentication:** SSO (SiteMinder)
- **Certificate SAN:** docs.acme-demo.com (Vanity URL only)
- **Certificate Changes Required:** No
- **Auth Changes Required:** No change for migration, but recommend migrating to Ping Access
- **Dependencies:** CouchBase (in-cluster), S3 (external)
- **Resource Requirements:** CPU: 4 cores per pod, Memory: 16GB per pod, Storage: 500GB
- **Requires CouchBase Operator:** Yes — 3-node cluster
- **Requires Service Mesh:** No
- **DEV Migration Status:** Scheduled
- **Notes:** Requires CouchBase Operator installation on destination cluster before migration. Coordinate with Database Engineering.

---

### CSI 66666 — Audit Trail Service

- **Owner:** Team Echo
- **Contact:** audit-team@acme-demo.com
- **Description:** System-wide audit logging and trail generation
- **In Scope:** Yes
- **PROD Wave:** Wave 3 (Q1 2027)
- **Source Cluster (ECS 1.0):** ecs-east-02
- **Destination Cluster (ACME Cloud):** acme-bm-east-01
- **Namespaces:** audit-dev, audit-prod
- **CI/CD Platform:** Legacy Release Manager
- **Vanity URL:** No — uses cluster-specific route
- **Authentication:** SSO (SiteMinder)
- **Certificate SAN:** audit-service.apps.ecs-east-02.acme-demo.com (cluster route — NOT a Vanity URL)
- **Certificate Changes Required:** YES — current SAN includes cluster-specific route. Must order new certificate.
- **Auth Changes Required:** YES — SiteMinder config must be updated with new Base URL for destination cluster route. Strongly recommend migrating to Vanity URL and Ping Access.
- **Dependencies:** Elasticsearch (in-cluster), Kafka (external)
- **Resource Requirements:** CPU: 8 cores, Memory: 32GB, Storage: 1TB
- **DEV Migration Status:** Scheduled
- **Notes:** IMPORTANT — Requires new certificate AND SiteMinder Base URL update. Highest complexity among in-scope apps. Recommend migrating to Vanity URL and Ping Access before migration.

---

## Source & Destination Clusters

All ECS 1.0 clusters in scope for the DEV migration and their corresponding destination ACME Cloud clusters.

### ecs-east-01 → acme-bm-east-01
- **Source:** ecs-east-01 (ECS 1.0, US East, New Jersey)
- **Destination:** acme-bm-east-01 (ACME Cloud BareMetal, US East, New Jersey)
- **Applications:** CSI 12345 (Trade Settlement), CSI 11111 (Payment Gateway), CSI 44444 (FX Trading)

### ecs-east-02 → acme-bm-east-01
- **Source:** ecs-east-02 (ECS 1.0, US East, New Jersey)
- **Destination:** acme-bm-east-01 (ACME Cloud BareMetal, US East, New Jersey)
- **Applications:** CSI 22222 (Customer Portal), CSI 66666 (Audit Trail)

### ecs-west-01 → acme-bm-west-01
- **Source:** ecs-west-01 (ECS 1.0, US West, Texas)
- **Destination:** acme-bm-west-01 (ACME Cloud BareMetal, US West, Texas)
- **Applications:** CSI 67890 (Risk Analytics), CSI 33333 (Compliance Reporting)

### ecs-west-02 → acme-bm-west-01
- **Source:** ecs-west-02 (ECS 1.0, US West, Texas)
- **Destination:** acme-bm-west-01 (ACME Cloud BareMetal, US West, Texas)
- **Applications:** CSI 55555 (Document Management)

---

## ACME Cloud Cluster VIPs, Infra Nodes & SiteMinder Shared Secrets

### acme-bm-east-01 (US East, New Jersey)
- **Cluster VIP:** 10.40.1.100
- **Infra Node 1:** 10.40.1.10 (infra-east-01a)
- **Infra Node 2:** 10.40.1.11 (infra-east-01b)
- **Infra Node 3:** 10.40.1.12 (infra-east-01c)
- **SiteMinder Shared Secret:** Contact Platform Operations — shared secrets are provided during onboarding
- **Wildcard DNS:** *.apps.acme-bm-east-01.acme-demo.com

### acme-bm-west-01 (US West, Texas)
- **Cluster VIP:** 10.50.1.100
- **Infra Node 1:** 10.50.1.10 (infra-west-01a)
- **Infra Node 2:** 10.50.1.11 (infra-west-01b)
- **Infra Node 3:** 10.50.1.12 (infra-west-01c)
- **SiteMinder Shared Secret:** Contact Platform Operations — shared secrets are provided during onboarding
- **Wildcard DNS:** *.apps.acme-bm-west-01.acme-demo.com

---

## Egress IPs

Source and destination Egress IPs for applications that require external connectivity (databases, SFTP, message queues, etc.). These must be whitelisted in firewall rules before migration.

### acme-bm-east-01 Egress IPs
- **Egress IP Range:** 10.40.100.0/28
- **Primary Egress IP:** 10.40.100.1
- **Secondary Egress IP:** 10.40.100.2
- **Firewall Rule:** Whitelist destination Egress IPs with external services BEFORE migration cutover

### acme-bm-west-01 Egress IPs
- **Egress IP Range:** 10.50.100.0/28
- **Primary Egress IP:** 10.50.100.1
- **Secondary Egress IP:** 10.50.100.2
- **Firewall Rule:** Whitelist destination Egress IPs with external services BEFORE migration cutover

### Source ECS 1.0 Egress IPs (for reference during cutover)
- **ecs-east-01:** 10.20.100.1, 10.20.100.2
- **ecs-east-02:** 10.20.200.1, 10.20.200.2
- **ecs-west-01:** 10.30.100.1, 10.30.100.2
- **ecs-west-02:** 10.30.200.1, 10.30.200.2

**Important:** Do NOT remove source Egress IPs from firewall rules until migration is fully validated and source namespaces are decommissioned.

---

## Migration Support Contacts

### Report an Issue
Create a ServiceNow incident ticket under assignment group "ACME Cloud Platform Operations".

### Ask a Migration Question
Email the migration support team: acme-migrations-support@acme-demo.com

### Browse Documentation
- SharePoint: https://docs.acme-demo.com/migrations
- Confluence: https://wiki.acme-demo.com/migrations/type-a
- Slack: #acme-cloud-migrations

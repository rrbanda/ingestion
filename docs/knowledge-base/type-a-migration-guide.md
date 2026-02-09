# Type A Migration Guide

## Overview

Type A Migration refers to migrating containerized applications from **VM-based OpenShift clusters** to **BareMetal OpenShift clusters**. This is the simplest migration type because applications are already containerized and require minimal code changes.

### Migration Types Summary

| Type       | Description                                 | Complexity                              |
| ---------- | ------------------------------------------- | --------------------------------------- |
| **Type A** | Container-ready apps (already on OpenShift) | Low - Infrastructure changes only       |
| **Type B** | Apps requiring containerization             | Medium - Need Dockerfile, build configs |
| **Type C** | Complex apps requiring refactoring          | High - Architecture changes needed      |

---

## Pre-requisites

### Application Team Responsibilities

Before starting migration, complete the following:

1. **Network Whitelisting**

   - Identify egress IP requirements for internal systems (SFTP, message queues, databases, mainframes)
   - Document all external service dependencies

2. **Vanity URL Strategy**

   - Determine if you will use an existing vanity URL or create a new one
   - Vanity URLs are strongly recommended to avoid future migration issues

3. **Migration Companion Table**
   - Complete the migration checklist documenting:
     - Source cluster and namespace
     - Destination cluster and namespace
     - Required firewall rules
     - Certificate requirements
     - CI/CD pipeline type

### Platform Operations Responsibilities

Platform Ops will handle:

- **Project Copy**: Namespaces, quotas, limits, service accounts, role bindings
- **Secrets Migration**: Managed and native secrets
- **Network Policies**: EgressIP, persistent volumes, persistent volume claims
- **Netgroup Configuration**: Add destination cluster nodes to appropriate netgroups

> **Note**: Application deployments, services, routes, and HPAs are NOT copied. These should be deployed via your CI/CD pipeline.

---

## Migration Steps by CI/CD Platform Type

### Option 1: Enterprise DevOps Portal (Recommended)

For teams using the Enterprise DevOps Portal for CI/CD:

#### Step 1: Login to DevOps Portal

Navigate to your organization's DevOps Portal and select the Explore tab.

#### Step 2: Add Namespace

1. Go to **Infrastructure** → **OpenShift Namespaces**
2. Click **Add Namespace**
3. Configure:
   - **Cluster Type**: Select based on environment (Dev/UAT/Prod)
   - **Cluster Name**: Enter destination cluster name (may need manual entry)
   - **Naming Policy**: Select Legacy or Enhanced based on project
   - **Provisioning**: Select "Partially Managed"
4. Save and validate the namespace appears in the list

#### Step 3: Create Environment

1. Go to **Environments** tab
2. Click **Create Environment**
3. Configure:
   - **Environment Type**: OpenShift
   - **Environment Name**: Descriptive name for destination
   - **Environment Class**: Select appropriate class
   - **Cluster/Namespace**: Select destination from dropdown
4. Save changes

#### Step 4: Update Manifest

Modify your existing deployment manifest to include the new environment:

```yaml
# Example manifest update
environments:
  - name: prod-legacy
    cluster: source-cluster
    namespace: my-app-prod
  - name: prod-baremetal # Add new environment
    cluster: destination-cluster
    namespace: my-app-prod
```

Create corresponding `values-prod-baremetal.yaml` (copy from existing values file).

#### Step 5: Deploy and Validate

1. Trigger deployment to new environment
2. Validate application starts correctly
3. Check logs and health endpoints

---

### Option 2: Legacy Release Manager

For teams using a legacy release management system:

#### Step 1: Submit Modification Request

Raise a request to modify your existing release manager configuration for the destination cluster.

#### Step 2: Update Configuration Template

Download and update the onboarding template:

```
OPENSHIFT_HOST = api.<destination-cluster>.example.com:6443
OPENSHIFT_URL = https://api.<destination-cluster>.example.com:6443
OPENSHIFT_HOME = /opt/oseclient/v3.7/bin
```

#### Step 3: Submit and Deploy

Submit the updated template and trigger deployment to the new cluster.

---

## Additional OpenShift Resources

### Redis Operator Installation

If your application requires Redis:

1. **Request Operator Installation**

   - Raise a ticket with Platform Operations
   - Specify namespace and resource requirements

2. **Resource Requirements**

   ```yaml
   quota:
     cpu: 12 cores
     memory: 80GB
     pods: 10
   limits:
     cpu: 4 cores
     memory: 16GB
   storage: 100GB
   ```

3. **Create Redis Cluster**

   ```yaml
   spec:
     serviceAccountName: rec
     nodes: 3
     persistentSpec:
       enabled: true
       storageClassName: sc-ontap-nas
       volumeSize: 20Gi
   ```

4. **Create Route**
   - Create passthrough secure route to `rec-ui` service

### CouchBase Operator Installation

If your application requires CouchBase:

1. **Request Operator Installation**

   - Raise a ticket with Platform Operations
   - Consult with database engineering for sizing

2. **Resource Requirements**

   ```yaml
   quota:
     cpu: 4 cores per pod
     memory: 16GB per pod
     pods: 3
   limits:
     defaultCpu: 1 core
     defaultMemory: 4GB
   ```

3. **Create CouchBase Cluster**

   - Use provided YAML templates
   - Wait for 3 pods to be running

4. **Create Route**
   - Passthrough secure route on port 18091

### Service Mesh Configuration

For applications requiring service mesh:

1. **Create Service Mesh Control Plane**

   ```yaml
   # Adjust quota first
   maxPods: 15
   maxCpuPerContainer: 2
   ```

2. **Create Service Mesh Member**

   ```yaml
   apiVersion: maistra.io/v1
   kind: ServiceMeshMember
   metadata:
     name: default
   spec:
     controlPlaneRef:
       namespace: istio-system
       name: basic
   ```

3. **Enable Sidecar Injection**
   ```yaml
   annotations:
     sidecar.istio.io/inject: 'true'
     sidecar.istio.io/proxyCPU: '100m'
     sidecar.istio.io/proxyMemory: '100Mi'
   ```

---

## Certificate Management

### Scenario 1: Vanity URL Only

If your certificate SAN list contains only vanity URLs:

- **No changes required** - existing certificates work on new cluster

### Scenario 2: Cluster-Based Routes in SAN

If your certificate includes cluster-specific routes:

1. Order new certificate with updated SAN list
2. Update deployment files with new certificate policy nickname
3. Deploy updated certificate to destination cluster

---

## Vanity URL and Load Balancer Configuration

### Creating a New Vanity URL

1. **Register DNS Entry**

   - Submit request to DNS team for FQDN registration
   - SLA: 5 business days

2. **Create Virtual IP (VIP)**

   - Navigate to Network Service Automation portal
   - Configure:
     - VIP Port: 443
     - Idle Timeout: 300 seconds (adjustable)
     - Data Center: Match destination cluster location
   - Add infrastructure node IPs as members

3. **Create Wide IP (WIP)**

   - For production/failover configuration
   - Add both production and DR cluster infra nodes
   - Configure round-robin algorithm

4. **Map Vanity URL to VIP/WIP**
   - Submit DNS mapping request
   - Validate resolution before cutover

### Updating Existing Vanity URL

For cutover from old to new cluster:

1. **Submit DNS Change Request**

   - Specify old VIP/cluster wildcard DNS
   - Specify new destination cluster VIP
   - Schedule change window (15-20 minutes for propagation)

2. **Validate**
   - Test application access via vanity URL
   - Verify traffic routing to new cluster

---

## Authentication Configuration

### Ping Access / SSO

**Scenario 1: Using Vanity URL**

- No changes required if same vanity URL is used

**Scenario 2: Using Cluster-Based Route**

- Raise modification request to update Base URL
- Strongly recommended: Migrate to vanity URL

### SiteMinder (Legacy)

- Inform Platform Operations for shared secret configuration
- Recommendation: Migrate to Ping Access when possible

---

## Validation and Cutover

### Pre-Cutover Checklist

- [ ] Application deployed to destination cluster
- [ ] All pods running and healthy
- [ ] Logs show no errors
- [ ] Health endpoints responding
- [ ] Database connectivity verified
- [ ] External service connectivity verified
- [ ] Certificates valid and working
- [ ] Authentication working

### Cutover Steps

1. **Schedule maintenance window**
2. **Update DNS/Vanity URL mapping**
3. **Validate traffic routing to new cluster**
4. **Monitor for errors**
5. **Rollback plan ready if issues occur**

### Post-Migration Cleanup

After successful migration and validation period:

1. **Delete resources from source namespace**
2. **Raise request to delete source namespace**
   - Dev: Submit incident ticket
   - UAT/Prod: Submit change ticket

> **Warning**: Deleted namespaces cannot be restored. Ensure all resources are migrated before deletion.

---

## Troubleshooting

### Common Issues

| Issue              | Cause                   | Resolution               |
| ------------------ | ----------------------- | ------------------------ |
| Pods not starting  | Resource quota exceeded | Request quota increase   |
| Connection refused | Firewall/egress rules   | Update network policies  |
| Certificate errors | SAN mismatch            | Order new certificate    |
| SSO failing        | Base URL not updated    | Update SSO configuration |
| DNS not resolving  | Propagation delay       | Wait 15-20 minutes       |

### Getting Help

- **Platform Operations**: For infrastructure issues
- **Database Engineering**: For Redis/CouchBase issues
- **Security Team**: For certificate and SSO issues
- **Network Team**: For DNS and load balancer issues

---

## Quick Reference Commands

```bash
# Check pod status
oc get pods -n <namespace>

# Check deployment status
oc get deployments -n <namespace>

# View pod logs
oc logs <pod-name> -n <namespace>

# Describe pod (for troubleshooting)
oc describe pod <pod-name> -n <namespace>

# Check routes
oc get routes -n <namespace>

# Check services
oc get services -n <namespace>

# Check resource quotas
oc describe quota -n <namespace>

# Check limit ranges
oc describe limitrange -n <namespace>
```

---

## Summary

Type A Migration is a straightforward infrastructure migration for applications already running on OpenShift. The key steps are:

1. **Prepare**: Complete prerequisites and companion table
2. **Configure**: Update CI/CD pipeline for new cluster
3. **Deploy**: Deploy application to destination cluster
4. **Validate**: Verify application functionality
5. **Cutover**: Update DNS/vanity URL to point to new cluster
6. **Cleanup**: Delete resources from source cluster

For assistance, contact your Platform Operations team or use LSS to get step-by-step guidance.

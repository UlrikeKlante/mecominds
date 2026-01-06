# Kafka and Strimzi Upgrade for QA Cluster

## Overview

This directory contains the Kubernetes manifests for deploying and upgrading Kafka and Strimzi in the QA environment.

## Versions

- **Strimzi Operator**: v0.49.0
- **Kafka**: v4.1.1

## Files

- `strimzi-operator.yaml` - Strimzi Cluster Operator deployment (v0.49.0)
- `kafka-cluster.yaml` - Kafka cluster configuration (v4.1.1)
- `UPGRADE_GUIDE.md` - Detailed upgrade guide in German

## Quick Start

### Deploy Strimzi Operator

```bash
kubectl apply -f strimzi-operator.yaml
```

### Deploy Kafka Cluster

```bash
kubectl apply -f kafka-cluster.yaml
```

### Verify Deployment

```bash
# Check operator
kubectl get deployment strimzi-cluster-operator -n kafka-qa

# Check Kafka cluster
kubectl get kafka mecominds-kafka-qa -n kafka-qa

# Check all pods
kubectl get pods -n kafka-qa
```

## Upgrade Path

This configuration supports upgrading from:
- Strimzi v0.47.0 → v0.49.0 (skipping v0.48.0)
- Kafka v4.0.0 → v4.1.1

According to Strimzi documentation, multi-version upgrades are supported even when the supported Kafka versions differ between old and new versions.

## Architecture

### Kafka Cluster

- **Brokers**: 3 replicas
- **Zookeeper**: 3 replicas
- **Storage**: Persistent volumes (100Gi per Kafka broker, 10Gi per Zookeeper)
- **Listeners**:
  - Plain (port 9092) - internal, no TLS
  - TLS (port 9093) - internal, with TLS
- **Monitoring**: JMX Prometheus Exporter enabled

### Resources

**Kafka Brokers**:
- Memory: 2Gi (request/limit)
- CPU: 1000m (request), 2000m (limit)
- JVM: 1024m heap

**Zookeeper**:
- Memory: 1Gi (request/limit)
- CPU: 500m (request), 1000m (limit)
- JVM: 512m heap

## Monitoring

Kafka metrics are exposed via JMX Prometheus Exporter and can be scraped by Prometheus.

Metrics ConfigMap includes:
- Kafka server metrics
- Zookeeper metrics

## Notes

- The cluster uses persistent storage - data will survive pod restarts
- Entity Operator is enabled for managing Kafka topics and users
- Kafka Exporter is included for additional metrics
- Delete claim is set to `false` to prevent data loss

## References

- [Strimzi Documentation](https://strimzi.io/docs/operators/latest/)
- [Strimzi v0.49.0 Release](https://github.com/strimzi/strimzi-kafka-operator/releases/tag/0.49.0)
- [Apache Kafka 4.1.1](https://kafka.apache.org/documentation/)

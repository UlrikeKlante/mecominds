# Kafka und Strimzi Upgrade Dokumentation für QA Cluster

## Übersicht

Dieses Dokument beschreibt das Upgrade von Strimzi und Kafka in den QA-Clustern.

### Upgrade-Plan

1. **Strimzi Operator**: v0.47.0 → v0.49.0 (eine Version überspringen)
2. **Kafka**: v4.0.0 → v4.1.1

## Kann man eine Strimzi-Version überspringen?

**Ja, das ist möglich und wird unterstützt.**

Laut der offiziellen Strimzi-Dokumentation (https://strimzi.io/docs/operators/latest/deploying#con-api-conversion-v1-str):

> "Multi-version upgrades are possible even if the supported Kafka versions differ between the old and new versions."

### Was bedeutet das?

- **Multi-Version-Upgrades werden unterstützt**: Man kann mehrere Strimzi-Versionen auf einmal überspringen
- **Kafka-Versionskompatibilität**: Auch wenn die unterstützten Kafka-Versionen zwischen alten und neuen Strimzi-Versionen unterschiedlich sind, funktioniert das Upgrade
- **Keine Zwischenschritte erforderlich**: Es ist nicht notwendig, erst auf v0.48.0 zu upgraden, bevor man auf v0.49.0 geht

### Wichtige Hinweise

1. **API-Kompatibilität**: Strimzi v0.49.0 unterstützt die gleichen Custom Resource Definitions (CRDs) wie v0.47.0
2. **Kafka-Version**: Die Kafka-Version kann nach dem Strimzi-Upgrade separat aktualisiert werden
3. **Rolling Update**: Strimzi führt ein Rolling Update durch, sodass die Kafka-Cluster während des Upgrades verfügbar bleiben

## Upgrade-Prozess

### Schritt 1: Strimzi Operator Upgrade (v0.47.0 → v0.49.0)

```bash
# Operator-Deployment aktualisieren
kubectl apply -f k8s/kafka/qa/strimzi-operator.yaml
```

Der Strimzi Operator v0.49.0:
- Verwendet das Image: `quay.io/strimzi/operator:0.49.0`
- Unterstützt Kafka-Versionen: 4.0.0, 4.1.0, 4.1.1
- Behält alle bestehenden Kafka-Cluster bei

### Schritt 2: Kafka-Version Upgrade (4.0.0 → 4.1.1)

Nach dem erfolgreichen Strimzi-Upgrade:

```bash
# Kafka-Cluster mit neuer Version deployen
kubectl apply -f k8s/kafka/qa/kafka-cluster.yaml
```

Die Kafka-Cluster-Konfiguration:
- Version: `4.1.1`
- Inter-Broker-Protocol: `4.1`
- Log-Message-Format: `4.1`

### Schritt 3: Verifizierung

```bash
# Strimzi Operator Status prüfen
kubectl get deployment strimzi-cluster-operator -n kafka-qa

# Kafka-Cluster Status prüfen
kubectl get kafka mecominds-kafka-qa -n kafka-qa

# Kafka-Pods prüfen
kubectl get pods -n kafka-qa
```

## Konfigurationsdetails

### Strimzi Operator v0.49.0

- **Image**: `quay.io/strimzi/operator:0.49.0`
- **Namespace**: `kafka-qa`
- **Unterstützte Kafka-Versionen**: 4.0.0, 4.1.0, 4.1.1
- **Reconciliation-Intervall**: 120 Sekunden
- **Timeout**: 300 Sekunden

### Kafka Cluster

- **Name**: `mecominds-kafka-qa`
- **Kafka-Version**: `4.1.1`
- **Replikas**: 3 Broker, 3 Zookeeper
- **Storage**: Persistent Claims (100Gi für Kafka, 10Gi für Zookeeper)
- **Listeners**: 
  - Plain (9092) - unverschlüsselt für interne Kommunikation
  - TLS (9093) - verschlüsselt für interne Kommunikation
- **Monitoring**: JMX Prometheus Exporter konfiguriert

## Rollback-Plan

Falls Probleme auftreten:

1. **Strimzi Rollback**:
   ```bash
   # Zurück zur vorherigen Operator-Version
   kubectl set image deployment/strimzi-cluster-operator \
     strimzi-cluster-operator=quay.io/strimzi/operator:0.47.0 \
     -n kafka-qa
   ```

2. **Kafka-Version Rollback**:
   ```bash
   # Kafka-Cluster-Manifest auf vorherige Version ändern
   # und erneut anwenden
   kubectl apply -f kafka-cluster-v4.0.0.yaml
   ```

## Referenzen

- [Strimzi Upgrade-Dokumentation](https://strimzi.io/docs/operators/latest/deploying#con-api-conversion-v1-str)
- [Strimzi v0.49.0 Release Notes](https://github.com/strimzi/strimzi-kafka-operator/releases/tag/0.49.0)
- [Apache Kafka 4.1.1 Documentation](https://kafka.apache.org/documentation/)

## Support und Troubleshooting

Bei Problemen:
1. Logs des Strimzi Operators prüfen: `kubectl logs -n kafka-qa deployment/strimzi-cluster-operator`
2. Kafka-Cluster-Status prüfen: `kubectl describe kafka mecominds-kafka-qa -n kafka-qa`
3. Events prüfen: `kubectl get events -n kafka-qa --sort-by='.lastTimestamp'`

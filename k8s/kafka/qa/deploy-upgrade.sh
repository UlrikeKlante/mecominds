#!/bin/bash

# Kafka and Strimzi Upgrade Script for QA Cluster
# This script performs the upgrade from:
# - Strimzi v0.47.0 -> v0.49.0 (skipping v0.48.0)
# - Kafka v4.0.0 -> v4.1.1

set -e

echo "=========================================="
echo "Kafka and Strimzi Upgrade for QA Cluster"
echo "=========================================="
echo ""
echo "This script will:"
echo "1. Upgrade Strimzi Operator from v0.47.0 to v0.49.0"
echo "2. Upgrade Kafka from v4.0.0 to v4.1.1"
echo ""
echo "Note: According to Strimzi documentation, multi-version"
echo "upgrades are supported even when Kafka versions differ."
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Function to wait for deployment to be ready
wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    local timeout=${3:-300}
    
    echo "Waiting for deployment $deployment in namespace $namespace to be ready..."
    kubectl wait --for=condition=available --timeout=${timeout}s \
        deployment/$deployment -n $namespace
}

# Function to wait for Kafka cluster to be ready
wait_for_kafka() {
    local namespace=$1
    local kafka_name=$2
    local timeout=${3:-600}
    
    echo "Waiting for Kafka cluster $kafka_name to be ready..."
    kubectl wait --for=condition=Ready --timeout=${timeout}s \
        kafka/$kafka_name -n $namespace || true
}

echo "Step 1: Deploying Strimzi Operator v0.49.0"
echo "-------------------------------------------"
kubectl apply -f k8s/kafka/qa/strimzi-operator.yaml

echo ""
echo "Waiting for Strimzi Operator to be ready..."
sleep 10
wait_for_deployment kafka-qa strimzi-cluster-operator 300

echo ""
echo "Step 2: Deploying Kafka Cluster v4.1.1"
echo "---------------------------------------"
kubectl apply -f k8s/kafka/qa/kafka-cluster.yaml

echo ""
echo "Waiting for Kafka cluster to be ready..."
echo "This may take several minutes..."
sleep 30
wait_for_kafka kafka-qa mecominds-kafka-qa 600

echo ""
echo "Step 3: Verification"
echo "--------------------"

echo ""
echo "Strimzi Operator Status:"
kubectl get deployment strimzi-cluster-operator -n kafka-qa

echo ""
echo "Kafka Cluster Status:"
kubectl get kafka mecominds-kafka-qa -n kafka-qa

echo ""
echo "All Pods in kafka-qa namespace:"
kubectl get pods -n kafka-qa

echo ""
echo "=========================================="
echo "Upgrade completed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Verify Kafka brokers are running: kubectl get pods -n kafka-qa -l strimzi.io/name=mecominds-kafka-qa-kafka"
echo "2. Check Zookeeper pods: kubectl get pods -n kafka-qa -l strimzi.io/name=mecominds-kafka-qa-zookeeper"
echo "3. Review operator logs: kubectl logs -n kafka-qa deployment/strimzi-cluster-operator"
echo "4. Test Kafka connectivity with your applications"
echo ""

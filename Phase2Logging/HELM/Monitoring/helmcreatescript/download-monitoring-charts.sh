#!/bin/bash

set -e

retry() {
  local retries=5
  local count=0

  until "$@"; do
    exit_code=$?
    count=$((count + 1))

    if [ $count -lt $retries ]; then
      echo ""
      echo "Retrying command ($count/$retries)..."
      sleep 5
    else
      echo ""
      echo "Command failed after $retries attempts."
      return $exit_code
    fi
  done
}

BASE_DIR="/Users/arpitchouksey/Documents/PersonalProjects/Project5-MonitoringSRE/HELM/Monitoring"

echo "===================================================="
echo " Downloading Local Monitoring Helm Charts "
echo "===================================================="

echo ""
echo "STEP 1 - Adding Helm repositories..."

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo add zabbix-chart https://zabbix-chart.github.io/zabbix-helm-charts || true

echo ""
echo "STEP 2 - Updating Helm repositories..."
helm repo update

echo ""
echo "STEP 3 - Downloading kube-prometheus-stack..."

mkdir -p ${BASE_DIR}/kube-prometheus-stack

retry helm pull prometheus-community/kube-prometheus-stack \
  --untar \
  --untardir ${BASE_DIR}/kube-prometheus-stack

echo ""
echo "STEP 4 - Downloading Loki..."

mkdir -p ${BASE_DIR}/loki

retry helm pull grafana/loki \
  --untar \
  --untardir ${BASE_DIR}/loki

echo ""
echo "STEP 5 - Downloading Fluent Bit..."

mkdir -p ${BASE_DIR}/fluent-bit

retry helm pull grafana/fluent-bit \
  --untar \
  --untardir ${BASE_DIR}/fluent-bit

echo ""
echo "STEP 6 - Downloading Blackbox Exporter..."

mkdir -p ${BASE_DIR}/blackbox-exporter

retry helm pull prometheus-community/prometheus-blackbox-exporter \
  --untar \
  --untardir ${BASE_DIR}/blackbox-exporter

echo ""
echo "STEP 7 - Downloading Grafana OnCall..."

mkdir -p ${BASE_DIR}/grafana-oncall

retry helm pull grafana/oncall \
  --untar \
  --untardir ${BASE_DIR}/grafana-oncall

echo ""
echo "STEP 8 - Downloading Zabbix..."

mkdir -p ${BASE_DIR}/zabbix

retry helm pull zabbix-chart/zabbix \
  --untar \
  --untardir ${BASE_DIR}/zabbix

echo ""
echo "===================================================="
echo " All Monitoring Helm Charts Downloaded "
echo "===================================================="

echo ""
echo "FINAL DIRECTORY STRUCTURE:"
echo ""

tree ${BASE_DIR}

echo ""
echo "===================================================="
echo " READY FOR LOCAL HELM INSTALLATION "
echo "===================================================="

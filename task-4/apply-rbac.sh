#!/bin/bash
set -e

echo "🚀 Начало настройки RBAC для кластера PropDevelopment"
echo ""

# Проверяем подключение к кластеру
echo "📡 Проверка подключения к кластеру..."
kubectl cluster-info

# Создаём namespace для доменов
echo ""
echo "📦 Создание namespace для доменов..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: sales-domain
  labels:
    domain: sales
---
apiVersion: v1
kind: Namespace
metadata:
  name: utilities-domain
  labels:
    domain: utilities
---
apiVersion: v1
kind: Namespace
metadata:
  name: finance-domain
  labels:
    domain: finance
---
apiVersion: v1
kind: Namespace
metadata:
  name: data-domain
  labels:
    domain: data
EOF

# Применяем роли
echo ""
echo "🔑 Создание ролей..."
kubectl apply -f roles.yaml

# Применяем привязки
echo ""
echo "🔗 Создание привязок ролей..."
kubectl apply -f role-bindings.yaml

# Создаём kubeconfig для пользователей
echo ""
echo "⚙️  Создание kubeconfig файлов для пользователей..."

CERT_DIR="./certs"
CLUSTER_NAME="propdevelopment-cluster"
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA_CERT="ca.crt"

create_kubeconfig() {
    local USERNAME=$1
    local CONTEXT_NAME="${USERNAME}-context"
    
    kubectl config set-cluster ${CLUSTER_NAME} \
        --server=${CLUSTER_SERVER} \
        --certificate-authority=${CERT_DIR}/${CA_CERT} \
        --embed-certs=true \
        --kubeconfig=${CERT_DIR}/${USERNAME}.kubeconfig
    
    kubectl config set-credentials ${USERNAME} \
        --client-certificate=${CERT_DIR}/${USERNAME}.crt \
        --client-key=${CERT_DIR}/${USERNAME}.key \
        --embed-certs=true \
        --kubeconfig=${CERT_DIR}/${USERNAME}.kubeconfig
    
    kubectl config set-context ${CONTEXT_NAME} \
        --cluster=${CLUSTER_NAME} \
        --user=${USERNAME} \
        --kubeconfig=${CERT_DIR}/${USERNAME}.kubeconfig
    
    kubectl config use-context ${CONTEXT_NAME} \
        --kubeconfig=${CERT_DIR}/${USERNAME}.kubeconfig
    
    echo "✅ Kubeconfig создан: ${CERT_DIR}/${USERNAME}.kubeconfig"
}

# Создаём kubeconfig для ключевых пользователей
create_kubeconfig "security-admin"
create_kubeconfig "developer-1"
create_kubeconfig "sales-lead"

echo ""
echo "🎉 Настройка RBAC завершена!"
echo ""
echo "📋 Проверка созданных ресурсов:"
echo "   kubectl get clusterroles | grep propdevelopment"
echo "   kubectl get clusterrolebindings | grep propdevelopment"
echo "   kubectl get roles --all-namespaces | grep propdevelopment"
echo "   kubectl get rolebindings --all-namespaces | grep propdevelopment"
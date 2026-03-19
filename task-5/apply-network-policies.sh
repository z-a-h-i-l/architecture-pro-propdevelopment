#!/bin/bash
# Применение сетевых политик для изоляции трафика

set -e

NAMESPACE="propdevelopment"

echo "🔐 Применение сетевых политик в namespace: ${NAMESPACE}"

echo ""
echo "✅ Применение политик."
kubectl apply -f network-policies.yaml

# Проверка созданных политик
echo ""
echo "📋 Список сетевых политик:"
kubectl get networkpolicies --namespace=${NAMESPACE}

echo ""
echo "🔍 Детали политик:"
kubectl describe networkpolicies --namespace=${NAMESPACE} | grep -A 20 "Name:\|PodSelector:\|Ingress:\|Egress:"

echo ""
echo "🎉 Сетевые политики применены!"
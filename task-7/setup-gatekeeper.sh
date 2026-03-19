#!/bin/bash
# setup-gatekeeper.sh
# Установка и настройка OPA Gatekeeper

set -e

echo "🚀 Установка OPA Gatekeeper для PropDevelopment"
echo "================================================"
echo ""

# Проверка kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ Требуется установленный kubectl"
    exit 1
fi

# Проверка подключения к кластеру
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Не удалось подключиться к кластеру"
    exit 1
fi

echo "📦 Шаг 1: Установка Gatekeeper через Helm..."
if ! command -v helm &> /dev/null; then
    echo "⚠️  Helm не найден. Установка через kubectl apply..."
    
    # Альтернатива: установка через YAML
    GATEKEEPER_VERSION="v3.14.0"
    kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/${GATEKEEPER_VERSION}/deploy/gatekeeper.yaml
    
else
    # Установка через Helm (предпочтительный способ)
    helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
    helm repo update
    
    helm upgrade --install gatekeeper gatekeeper/gatekeeper \
        --namespace gatekeeper-system \
        --create-namespace \
        --set auditInterval=60 \
        --set constraintViolationsLimit=20 \
        --set enableExternalData=true \
        --set enableMutation=false \
        --set webhook.timeoutSeconds=3 \
        --set webhook.failurePolicy=Fail \
        --set controllerManager.args=["--log-level=INFO", "--enable-opa-runtime-experimental"]
fi

echo ""
echo "⏳ Шаг 2: Ожидание запуска контроллеров..."
kubectl wait --for=condition=available deployment/gatekeeper-controller-manager -n gatekeeper-system --timeout=120s
kubectl wait --for=condition=ready pod -l control-plane=audit-controller -n gatekeeper-system --timeout=120s

echo ""
echo "📋 Шаг 3: Применение Constraint Templates..."
kubectl apply -f gatekeeper/constraint-templates/

echo ""
echo "🔗 Шаг 4: Применение Constraints..."
kubectl apply -f gatekeeper/constraints/

echo ""
echo "✅ Шаг 5: Проверка установки..."
echo ""
echo "📊 Статус подов Gatekeeper:"
kubectl get pods -n gatekeeper-system

echo ""
echo "🔗 Статус Constraint Templates:"
kubectl get constrainttemplates

echo ""
echo "📋 Статус Constraints:"
kubectl get constraints --all-namespaces

echo ""
echo "🎉 Gatekeeper успешно установлен и настроен!"
echo ""
echo "📚 Документация:"
echo "   • https://open-policy-agent.github.io/gatekeeper/website/docs/"
echo "   • kubectl describe constrainttemplate/<name>"
echo ""
echo "🔍 Мониторинг нарушений:"
echo "   kubectl get constraints -o json | jq '.items[] | {name: .metadata.name, violations: .status.totalViolations}'"
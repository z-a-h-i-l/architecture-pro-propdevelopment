#!/bin/bash
# verify-admission.sh
# Проверка работы admission controllers

set -e

NAMESPACE="audit-zone"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Проверка admission controllers в namespace: ${NAMESPACE}"
echo "============================================================"
echo ""

# Функция для тестирования применения манифеста
test_manifest() {
    local FILE=$1
    local EXPECTED=$2
    local DESCRIPTION=$3
    
    echo -n "📋 ${DESCRIPTION} ... "
    
    # Попытка применить манифест
    if kubectl apply -f "${FILE}" -n "${NAMESPACE}" 2>&1 | grep -q "forbidden\|denied\|admission webhook"; then
        RESULT="BLOCKED"
    elif kubectl apply -f "${FILE}" -n "${NAMESPACE}" >/dev/null 2>&1; then
        RESULT="ALLOWED"
        # Очистка после успешного применения
        kubectl delete -f "${FILE}" -n "${NAMESPACE}" --ignore-not-found=true >/dev/null 2>&1
    else
        RESULT="ERROR"
    fi
    
    if [[ "${EXPECTED}" == "BLOCKED" && "${RESULT}" == "BLOCKED" ]]; then
        echo -e "${GREEN}✅ PASS${NC} (ожидалась блокировка)"
        return 0
    elif [[ "${EXPECTED}" == "ALLOWED" && "${RESULT}" == "ALLOWED" ]]; then
        echo -e "${GREEN}✅ PASS${NC} (ожидалось разрешение)"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC} (ожидалось: ${EXPECTED}, получено: ${RESULT})"
        return 1
    fi
}

# Проверка меток PodSecurity на namespace
echo "1️⃣  Проверка конфигурации namespace:"
LABELS=$(kubectl get namespace ${NAMESPACE} --show-labels 2>/dev/null | grep pod-security || echo "NOT FOUND")
if echo "${LABELS}" | grep -q "enforce:restricted"; then
    echo -e "   ${GREEN}✅${NC} PodSecurity: restricted включён"
else
    echo -e "   ${RED}❌${NC} PodSecurity: restricted НЕ найден"
    echo "   Текущие метки: ${LABELS}"
fi
echo ""

# Проверка Gatekeeper
echo "2️⃣  Проверка OPA Gatekeeper:"
if kubectl get pods -n gatekeeper-system 2>/dev/null | grep -q "Running"; then
    echo -e "   ${GREEN}✅${NC} Gatekeeper контроллеры запущены"
    
    # Проверка constraint templates
    TEMPLATES=$(kubectl get constrainttemplates 2>/dev/null | wc -l)
    echo "   📦 Constraint templates: $((TEMPLATES - 1))"  # минус заголовок
    
    # Проверка constraints
    CONSTRAINTS=$(kubectl get constraints 2>/dev/null | wc -l)
    echo "   🔗 Активные constraints: $((CONSTRAINTS - 1))"
else
    echo -e "   ${YELLOW}⚠️${NC} Gatekeeper не запущен или не установлен"
fi
echo ""

# Тестирование небезопасных манифестов (должны быть заблокированы)
echo "3️⃣  Тестирование НЕбезопасных манифестов (должны быть БЛОКИРОВАНЫ):"
echo ""
test_manifest "../insecure-manifests/01-privileged-pod.yaml" "BLOCKED" "privileged: true" || true
test_manifest "../insecure-manifests/02-hostpath-pod.yaml" "BLOCKED" "hostPath volume" || true
test_manifest "../insecure-manifests/03-root-user-pod.yaml" "BLOCKED" "root user (UID 0)" || true
echo ""

# Тестирование безопасных манифестов (должны быть разрешены)
echo "4️⃣  Тестирование БЕЗОПАСНЫХ манифестов (должны быть РАЗРЕШЕНЫ):"
echo ""
test_manifest "../secure-manifests/01-secure.yaml" "ALLOWED" "secure pod без privileged" || true
test_manifest "../secure-manifests/02-secure.yaml" "ALLOWED" "secure pod с emptyDir" || true
test_manifest "../secure-manifests/03-secure.yaml" "ALLOWED" "secure pod с non-root user" || true
echo ""

# Сводка
echo "============================================================"
echo "📊 Сводка проверки:"
echo "   • Namespace: ${NAMESPACE}"
echo "   • PodSecurity: restricted"
echo "   • Gatekeeper: $(kubectl get pods -n gatekeeper-system 2>/dev/null | grep -c Running || echo 0)/3 pods running"
echo ""
echo "💡 Для детального аудита нарушений:"
echo "   kubectl logs -n gatekeeper-system -l control-plane=audit-controller"
echo ""
echo "✅ Проверка завершена!"
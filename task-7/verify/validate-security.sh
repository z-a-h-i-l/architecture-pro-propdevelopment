#!/bin/bash
# validate-security.sh
# Комплексная валидация безопасности подов

set -e

echo "🛡️  Комплексная валидация безопасности подов в PropDevelopment"
echo "================================================================"
echo ""

# 1. Проверка состояния кластера
echo "📡 Статус кластера:"
kubectl cluster-info | head -2
echo ""

# 2. Проверка namespace audit-zone
echo "📦 Namespace audit-zone:"
kubectl get namespace audit-zone -o jsonpath='{.metadata.labels}' | jq -r 'to_entries[] | "   \(.key): \(.value)"' 2>/dev/null || \
kubectl describe namespace audit-zone | grep "pod-security" | sed 's/^/   /'
echo ""

# 3. Проверка PodSecurity Admission
echo "🔐 PodSecurity Admission:"
if kubectl api-versions | grep -q "admissionregistration.k8s.io/v1"; then
    echo "   ✅ AdmissionRegistration API доступен"
    
    # Проверка конфигурации через audit logs (если включён)
    echo "   📋 Проверка логов аудита (последние 5 записей):"
    kubectl logs -n kube-system -l component=kube-apiserver --tail=5 2>/dev/null | grep -i "podsecurity\|admission" | sed 's/^/   /' || echo "   ⚠️  Логи недоступны или аудит не настроен"
else
    echo "   ❌ AdmissionRegistration API не доступен"
fi
echo ""

# 4. Проверка OPA Gatekeeper
echo "🚪 OPA Gatekeeper:"
if kubectl get ns gatekeeper-system &>/dev/null; then
    echo "   ✅ Namespace gatekeeper-system существует"
    
    # Статус подов
    echo "   📊 Статус подов:"
    kubectl get pods -n gatekeeper-system -o jsonpath='{range .items[*]}{.metadata.name}{": "}{.status.phase}{"\n"}{end}' | sed 's/^/      /'
    
    # Статус constraints
    echo "   🔗 Статус constraints:"
    kubectl get constraints --all-namespaces -o json 2>/dev/null | jq -r '.items[] | "      \(.kind)/\(.metadata.name): \(.status.totalViolations // 0) violations"' 2>/dev/null || echo "      ⚠️  Не удалось получить статус constraints"
else
    echo "   ⚠️  Gatekeeper не установлен. Установка:"
    echo "      ./setup-gatekeeper.sh"
fi
echo ""

# 5. Анализ текущих подов в audit-zone
echo "🔍 Анализ подов в namespace audit-zone:"
PODS=$(kubectl get pods -n audit-zone -o json 2>/dev/null)
if [ -n "${PODS}" ] && [ "${PODS}" != "null" ]; then
    echo "   📦 Найдено подов: $(echo "${PODS}" | jq '.items | length')"
    
    # Проверка securityContext для каждого пода
    echo "   🛡️  Проверка securityContext:"
    echo "${PODS}" | jq -r '.items[] | 
        "      \(.metadata.name): " +
        (if .spec.securityContext?.runAsNonRoot == true then "✅ runAsNonRoot " else "❌ runAsNonRoot " end) +
        (if .spec.containers[0]?.securityContext?.readOnlyRootFilesystem == true then "✅ readOnlyRootFS " else "❌ readOnlyRootFS " end) +
        (if .spec.containers[0]?.securityContext?.privileged == true then "🔴 PRIVILEGED!" else "✅ not-privileged" end)
    ' 2>/dev/null || echo "      ⚠️  Не удалось проанализировать securityContext"
else
    echo "   ℹ️  Поды в audit-zone не найдены (это нормально для чистого namespace)"
fi
echo ""

# 6. Рекомендации
echo "💡 Рекомендации по безопасности:"
echo "   1. Всегда используйте securityContext с runAsNonRoot: true"
echo "   2. Избегайте privileged: true — это даёт полный доступ к хосту"
echo "   3. Используйте readOnlyRootFilesystem: true + emptyDir для временных данных"
echo "   4. Ограничивайте capabilities через drop: [ALL] + add: [только необходимое]"
echo "   5. Регулярно обновляйте Constraint Templates в Gatekeeper"
echo "   6. Включите audit logging для отслеживания нарушений"
echo ""

# 7. Экспорт отчёта
REPORT_FILE="security-audit-$(date +%Y%m%d-%H%M%S).json"
echo "📄 Экспорт отчёта: ${REPORT_FILE}"

kubectl get pods -n audit-zone -o json 2>/dev/null | jq '{
  audit_timestamp: now,
  namespace: "audit-zone",
  pods_count: (.items | length),
  pod_security_labels: (kubectl get namespace audit-zone -o json 2>/dev/null | jq -r ".metadata.labels // {}" | fromjson?),
  gatekeeper_status: (if (kubectl get ns gatekeeper-system &>/dev/null) then "installed" else "not-installed" end),
  recommendations: [
    "use runAsNonRoot: true",
    "avoid privileged: true", 
    "use readOnlyRootFilesystem: true",
    "drop all capabilities",
    "regular policy updates"
  ]
}' > "${REPORT_FILE}" 2>/dev/null || echo '{"error": "Failed to generate report"}' > "${REPORT_FILE}"

echo ""
echo "✅ Валидация завершена!"
echo "📁 Отчёт сохранён: ${REPORT_FILE}"
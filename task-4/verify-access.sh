#!/bin/bash
set -e

CERT_DIR="./certs"

echo "🔍 Проверка прав доступа пользователей PropDevelopment"
echo ""

# Функция проверки доступа
check_access() {
    local USERNAME=$1
    local RESOURCE=$2
    local VERB=$3
    local NAMESPACE=${4:-""}
    
    local KUBECONFIG="${CERT_DIR}/${USERNAME}.kubeconfig"
    
    if [ -z "${NAMESPACE}" ]; then
        RESULT=$(kubectl auth can-i ${VERB} ${RESOURCE} --kubeconfig=${KUBECONFIG} 2>/dev/null || echo "no")
    else
        RESULT=$(kubectl auth can-i ${VERB} ${RESOURCE} -n ${NAMESPACE} --kubeconfig=${KUBECONFIG} 2>/dev/null || echo "no")
    fi
    
    printf "%-20s | %-25s | %-10s | %-10s\n" "${USERNAME}" "${RESOURCE}" "${VERB}" "${RESULT}"
}

# Заголовок таблицы
printf "%-20s | %-25s | %-10s | %-10s\n" "ПОЛЬЗОВАТЕЛЬ" "РЕСУРС" "ДЕЙСТВИЕ" "ДОСТУП"
echo "--------------------------------------------------------------------------------"

# Проверка для security-admin (должен иметь полный доступ)
echo ""
echo "🔴 Привилегированная группа (security-admin):"
check_access "security-admin" "secrets" "get"
check_access "security-admin" "pods" "delete"
check_access "security-admin" "namespaces" "create"

# Проверка для developer-1 (только просмотр)
echo ""
echo "🟡 Группа просмотра (developer-1):"
check_access "developer-1" "pods" "get"
check_access "developer-1" "pods" "list"
check_access "developer-1" "secrets" "get"
check_access "developer-1" "deployments" "create"

# Проверка для sales-lead (доступ только к своему namespace)
echo ""
echo "🟢 Группа настройки (sales-lead):"
check_access "sales-lead" "pods" "get" "" "sales-domain"
check_access "sales-lead" "pods" "create" "" "sales-domain"
check_access "sales-lead" "pods" "get" "" "finance-domain"
check_access "sales-lead" "secrets" "get" "" "sales-domain"

echo ""
echo "✅ Проверка завершена!"
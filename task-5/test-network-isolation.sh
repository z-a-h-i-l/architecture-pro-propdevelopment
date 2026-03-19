#!/bin/bash
# test-network-isolation.sh
# Корректная проверка сетевых политик с временными подами, имеющими нужные роли.

set -e  # скрипт остановится только при критических ошибках (не из-за wget)

NAMESPACE="propdevelopment"
TEST_IMAGE="busybox:latest"  # содержит wget

echo "🧪 Тестирование изоляции трафика в namespace: ${NAMESPACE}"
echo ""

# Функция тестирования соединения
# Параметры:
#   $1 - роль источника (front-end, back-end-api, admin-front-end, admin-back-end-api)
#   $2 - имя целевого сервиса (без namespace)
#   $3 - ожидаемый результат: "ALLOW" или "DENY"
#   $4 - описание теста
test_connection() {
    local FROM_ROLE=$1
    local TO_SERVICE=$2
    local EXPECTED=$3
    local DESCRIPTION=$4

    local TEST_POD="test-${FROM_ROLE}-${RANDOM}"

    echo -n "🔌 ${DESCRIPTION} ... "

    # Запускаем временный под с метками и выполняем wget
    # --rm удалит под после завершения, -i позволяет захватить вывод
    # || true гарантирует, что ошибка wget не прервёт скрипт
    OUTPUT=$(kubectl run ${TEST_POD} --rm -i \
        --image=${TEST_IMAGE} \
        --namespace=${NAMESPACE} \
        --labels="role=${FROM_ROLE},app=propdevelopment" \
        --restart=Never \
        --command -- wget -qO- -T 3 --tries=1 http://${TO_SERVICE}.${NAMESPACE}.svc.cluster.local 2>&1) || true

    # Анализ результата
    if [[ "$EXPECTED" == "ALLOW" ]]; then
        # Разрешённый запрос должен вернуть HTML (от nginx)
        if [[ "$OUTPUT" == *"<!DOCTYPE"* ]] || [[ "$OUTPUT" == *"<html>"* ]]; then
            echo "✅ РАЗРЕШЕНО (ожидалось)"
            return 0
        else
            echo "❌ ЗАБЛОКИРОВАНО (ожидалось РАЗРЕШИТЬ)"
            echo "   Вывод: $OUTPUT"
            return 1
        fi
    else
        # Заблокированный запрос должен содержать ошибку соединения
        if [[ "$OUTPUT" == *"timed out"* ]] || \
           [[ "$OUTPUT" == *"Connection refused"* ]] || \
           [[ "$OUTPUT" == *"CONNECTION_FAILED"* ]] || \
           [[ "$OUTPUT" == "" ]]; then
            echo "✅ ЗАБЛОКИРОВАНО (ожидалось)"
            return 0
        else
            echo "❌ РАЗРЕШЕНО (ожидалось ЗАБЛОКИРОВАТЬ)"
            echo "   Вывод: $OUTPUT"
            return 1
        fi
    fi
}

echo "=== Тесты для РАЗРЕШЁННЫХ соединений ==="
echo ""

test_connection "front-end" "back-end-api-app" "ALLOW" "front-end → back-end-api"
test_connection "admin-front-end" "admin-back-end-api-app" "ALLOW" "admin-front-end → admin-back-end-api"

echo ""
echo "=== Тесты для ЗАБЛОКИРОВАННЫХ соединений ==="
echo ""

test_connection "front-end" "admin-back-end-api-app" "DENY" "front-end → admin-back-end-api [межгрупповой]"
test_connection "admin-front-end" "back-end-api-app" "DENY" "admin-front-end → back-end-api [межгрупповой]"
test_connection "back-end-api" "front-end-app" "DENY" "back-end-api → front-end [инициировано back-end]"
test_connection "admin-back-end-api" "admin-front-end-app" "DENY" "admin-back-end-api → admin-front-end [инициировано admin-back-end]"
test_connection "back-end-api" "admin-back-end-api-app" "DENY" "back-end-api → admin-back-end-api [API-к-API]"
test_connection "front-end" "admin-front-end-app" "DENY" "front-end → admin-front-end [UI-к-UI]"

echo ""
echo "📊 Сводка:"
echo "   - Разрешены: внутрипарные соединения (front→backend, admin-front→admin-backend)"
echo "   - Заблокированы: все межгрупповые соединения и инициированные из backend в frontend"
echo ""
echo "🎉 Тестирование завершено!"
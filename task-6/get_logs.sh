#!/bin/bash

# Проверка наличия jq
if ! command -v jq &> /dev/null; then
    echo "Ошибка: jq не установлен. Установите jq (например, apt install jq или brew install jq)."
    exit 1
fi

# Проверка аргументов
if [ $# -ne 1 ]; then
    echo "Использование: $0 <файл_audit.log>"
    exit 1
fi

AUDIT_LOG="$1"
OUTPUT_FILE="audit-extract.json"

echo "Анализ файла: $AUDIT_LOG"
echo "Поиск подозрительных событий..."

# Инициализация пустого массива для результатов
echo "[]" > "$OUTPUT_FILE"

# Функция для добавления события в JSON-массив
add_event() {
    local event="$1"
    # Используем jq для добавления элемента в массив
    jq --argjson new "$event" '. += [$new]' "$OUTPUT_FILE" > tmp.json && mv tmp.json "$OUTPUT_FILE"
}

# Обработка файла построчно
while IFS= read -r line; do
    # Пропускаем пустые строки
    [ -z "$line" ] && continue

    # Проверка на доступ к secrets (get)
    if echo "$line" | jq -e 'select(.objectRef.resource == "secrets" and .verb == "get")' > /dev/null 2>&1; then
        add_event "$(echo "$line" | jq '. + {"reason": "access_to_secrets"}')"
        continue
    fi

    # Проверка на kubectl exec
    if echo "$line" | jq -e 'select(.verb == "create" and .objectRef.subresource == "exec")' > /dev/null 2>&1; then
        add_event "$(echo "$line" | jq '. + {"reason": "kubectl_exec"}')"
        continue
    fi

    # Проверка на создание привилегированного пода
    if echo "$line" | jq -e 'select(.objectRef.resource == "pods" and .verb == "create")' > /dev/null 2>&1; then
        # Дополнительная проверка наличия privileged: true
        if echo "$line" | jq -e '.requestObject.spec.containers[]?.securityContext.privileged == true' > /dev/null 2>&1; then
            add_event "$(echo "$line" | jq '. + {"reason": "privileged_pod_created"}')"
            continue
        fi
    fi

    # Проверка на действия с audit-policy (удаление/изменение)
    if echo "$line" | jq -e 'select(.objectRef.name? | contains("audit-policy"))' > /dev/null 2>&1; then
        add_event "$(echo "$line" | jq '. + {"reason": "audit_policy_modified"}')"
        continue
    fi

    # Дополнительно: проверка на создание RoleBinding с cluster-admin
    if echo "$line" | jq -e 'select(.objectRef.resource == "rolebindings" and .verb == "create")' > /dev/null 2>&1; then
        if echo "$line" | jq -e '.requestObject.roleRef.name == "cluster-admin"' > /dev/null 2>&1; then
            add_event "$(echo "$line" | jq '. + {"reason": "cluster_admin_binding"}')"
            continue
        fi
    fi

done < "$AUDIT_LOG"

# Подсчёт количества найденных событий
COUNT=$(jq 'length' "$OUTPUT_FILE")
echo "Найдено подозрительных событий: $COUNT"
echo "Результат сохранён в $OUTPUT_FILE"
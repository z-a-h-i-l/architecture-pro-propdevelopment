#!/bin/bash

set -e

CLUSTER_NAME="propdevelopment-cluster"
CA_KEY="ca.key"
CA_CERT="ca.crt"
CERT_DIR="./certs"

# Создаём директорию для сертификатов
mkdir -p ${CERT_DIR}

# Функция создания пользователя
create_user() {
    local USERNAME=$1
    local USER_GROUPS=$2
    
    echo " Создание пользователя: ${USERNAME}"
    
    # Создаём приватный ключ
    openssl genrsa -out ${CERT_DIR}/${USERNAME}.key 2048
    
    # Создаём CSR (Certificate Signing Request)
    openssl req -new -key ${CERT_DIR}/${USERNAME}.key \
        -out ${CERT_DIR}/${USERNAME}.csr \
        -subj "/CN=${USERNAME}/O=${GUSER_GROUPSS}"
    
    # Подписываем сертификат (срок действия 365 дней)
    openssl x509 -req -in ${CERT_DIR}/${USERNAME}.csr \
        -CA ${CERT_DIR}/${CA_CERT} -CAkey ${CERT_DIR}/${CA_KEY} \
        -CAcreateserial -out ${CERT_DIR}/${USERNAME}.crt \
        -days 365
    
    echo "✅ Пользователь ${USERNAME} создан в группах: ${USER_GROUPS}"
}

# Создаём пользователей для разных групп
# Привилегированная группа (security-team)
create_user "security-admin" "security-team:platform-admins"
create_user "ib-specialist" "security-team"

# Группа просмотра (developers, devops)
create_user "developer-1" "developers"
create_user "developer-2" "developers"
create_user "devops-engineer" "devops"
create_user "bi-analyst" "bi-analysts"

# Группа настройки по доменам (namespace-scoped)
create_user "sales-lead" "sales-team"
create_user "utilities-lead" "utilities-team"
create_user "finance-lead" "finance-team"

echo ""
echo "📁 Все сертификаты сохранены в директорию: ${CERT_DIR}/"
echo "📋 Список созданных пользователей:"
ls -la ${CERT_DIR}/*.crt
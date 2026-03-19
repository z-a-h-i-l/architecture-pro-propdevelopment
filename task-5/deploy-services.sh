#!/bin/bash

set -e

NAMESPACE="propdevelopment"

# Создаём namespace, если не существует
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

echo "🚀 Развёртывание сервисов в namespace: ${NAMESPACE}"

# 1. Front-end сервис
echo "📦 Создание front-end-app..."
kubectl run front-end-app --image=nginx:latest \
    --labels="role=front-end,app=propdevelopment" \
    --namespace=${NAMESPACE} \
    --expose --port=80 --restart=Always

# 2. Back-end API сервис
echo "📦 Создание back-end-api-app..."
kubectl run back-end-api-app --image=nginx:latest \
    --labels="role=back-end-api,app=propdevelopment" \
    --namespace=${NAMESPACE} \
    --expose --port=80 --restart=Always

# 3. Admin front-end сервис
echo "📦 Создание admin-front-end-app..."
kubectl run admin-front-end-app --image=nginx:latest \
    --labels="role=admin-front-end,app=propdevelopment" \
    --namespace=${NAMESPACE} \
    --expose --port=80 --restart=Always

# 4. Admin back-end API сервис
echo "📦 Создание admin-back-end-api-app..."
kubectl run admin-back-end-api-app --image=nginx:latest \
    --labels="role=admin-back-end-api,app=propdevelopment" \
    --namespace=${NAMESPACE} \
    --expose --port=80 --restart=Always

# Ждём готовности подов
echo ""
echo "⏳ Ожидание готовности подов..."
kubectl wait --for=condition=ready pod -l app=propdevelopment --namespace=${NAMESPACE} --timeout=120s

# Проверка созданных ресурсов
echo ""
echo "✅ Проверка созданных ресурсов:"
echo ""
echo "📋 Поды:"
kubectl get pods -l app=propdevelopment --namespace=${NAMESPACE} -o wide
echo ""
echo "🔗 Сервисы:"
kubectl get services -l app=propdevelopment --namespace=${NAMESPACE}
echo ""
echo "🏷️  Метки подов:"
kubectl get pods -l app=propdevelopment --namespace=${NAMESPACE} --show-labels

echo ""
echo "🎉 Развёртывание завершено!"
#!/bin/bash
# quick-test-fixed.sh
NAMESPACE="propdevelopment"

echo "🚀 Проверка сетевых политик из подов с правильными ролями"
echo ""

# Тест 1: из front-end к back-end-api (должно работать)
echo "📦 Тест 1: front-end -> back-end-api"
kubectl run test-front-${RANDOM} --rm -i \
  --image=alpine:latest \
  --namespace=${NAMESPACE} \
  --labels="role=front-end,app=propdevelopment" \
  --restart=Never \
  --command -- \
  sh -c "wget -qO- --timeout=3 http://back-end-api-app.${NAMESPACE}.svc.cluster.local | head -3 || echo '[FAILED]'"
echo ""

# Тест 2: из admin-front-end к admin-back-end-api (должно работать)
echo "📦 Тест 2: admin-front-end -> admin-back-end-api"
kubectl run test-admin-${RANDOM} --rm -i \
  --image=alpine:latest \
  --namespace=${NAMESPACE} \
  --labels="role=admin-front-end,app=propdevelopment" \
  --restart=Never \
  --command -- \
  sh -c "wget -qO- --timeout=3 http://admin-back-end-api-app.${NAMESPACE}.svc.cluster.local | head -3 || echo '[FAILED]'"
echo ""

# Тест 3: из front-end к admin-back-end-api (должно блокироваться)
echo "📦 Тест 3: front-end -> admin-back-end-api (ожидается блокировка)"
kubectl run test-front-block-${RANDOM} --rm -i \
  --image=alpine:latest \
  --namespace=${NAMESPACE} \
  --labels="role=front-end,app=propdevelopment" \
  --restart=Never \
  --command -- \
  sh -c "timeout 5 wget -qO- http://admin-back-end-api-app.${NAMESPACE}.svc.cluster.local && echo '[UNEXPECTED - ALLOWED]' || echo '[BLOCKED - OK]'"
echo ""

# Тест 4: из admin-front-end к back-end-api (должно блокироваться)
echo "📦 Тест 4: admin-front-end -> back-end-api (ожидается блокировка)"
kubectl run test-admin-block-${RANDOM} --rm -i \
  --image=alpine:latest \
  --namespace=${NAMESPACE} \
  --labels="role=admin-front-end,app=propdevelopment" \
  --restart=Never \
  --command -- \
  sh -c "timeout 5 wget -qO- http://back-end-api-app.${NAMESPACE}.svc.cluster.local && echo '[UNEXPECTED - ALLOWED]' || echo '[BLOCKED - OK]'"
echo ""

echo "✅ Все проверки выполнены"
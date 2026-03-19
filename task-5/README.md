# Для Minikube с Calico (поддерживает NetworkPolicy)
```bash
minikube start --cni=calico --cpus=4 --memory=4096
```
# Проверка установки Calico
```bash
kubectl get pods -n kube-system | grep calico
```

# Делаем скрипты исполняемыми
```bash
chmod +x deploy-services.sh
chmod +x apply-network-policies.sh
chmod +x test-network-isolation.sh
```
# Запускаем развёртывание
```bash
bash deploy-services.sh
```

# Применяем политики
```bash
bash apply-network-policies.sh
```

# Быстрый тест
```bash
bash quick-test.sh
```

# Или полный тест
```bash
bash test-network-isolation.sh
```


# Удалить кластер
```bash
minikube delete
```
# Запуск кластера

```bash
bash setup-minikube-audit.sh
```

# Запуск симуляции инцидентов
```bash
bash simulate-incident.sh 
```

# получаем файл логов
```bash
kubectl logs kube-apiserver-minikube -n kube-system | grep audit.k8s.io/v1 > ./audit.log
```
# получаем файл логов
```bash
bash get_logs.sh ./audit.log
```

# Отчет в файле
`audit-extract.json`
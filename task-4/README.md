## 1. Таблица ролей и полномочий

На основе организационной структуры PropDevelopment и требований безопасности, определены следующие роли:

| № | Роль (Role/ClusterRole) | Тип | Полномочия (Verbs) | Ресурсы | Группы пользователей | Обоснование |
|---|------------------------|-----|-------------------|---------|---------------------|-------------|
| 1 | **cluster-admin-role** | ClusterRole | `*` (все действия) | `*` (все ресурсы) | `security-team`, `platform-admins` | Привилегированная группа: специалисты по ИБ и администраторы платформы. Требуется для управления секретами, политиками безопасности, аудита |
| 2 | **cluster-view-role** | ClusterRole | `get`, `list`, `watch` | `pods`, `services`, `deployments`, `configmaps`, `namespaces` | `developers`, `devops`, `bi-analysts` | Группа только для просмотра: разработчики, DevOps, аналитики. Не могут изменять конфигурацию или получать доступ к секретам |
| 3 | **namespace-edit-role** | Role | `get`, `list`, `watch`, `create`, `update`, `patch`, `delete` | `pods`, `services`, `deployments`, `configmaps` | `sales-team`, `utilities-team`, `finance-team` | Группа настройки: команды доменов могут управлять ресурсами только в своих namespace. Изоляция по организационной структуре |
| 4 | **secret-reader-role** | ClusterRole | `get`, `list` | `secrets` | `security-team` | Ограниченный доступ к секретам: только команда ИБ может просматривать секреты для аудита |
| 5 | **audit-reader-role** | ClusterRole | `get`, `list`, `watch` | `events`, `pods/log` | `security-team`, `compliance-team` | Доступ к логам и событиям для расследования инцидентов |


# Запуск пустого кластера Minikube
```bash
minikube start --cpus=4 --memory=4096 --disk-size=20g
```
# Проверка статуса
```bash
minikube status
```
# Получение CA сертификатов для подписи пользовательских сертификатов
```bash
mkdir -p ./certs
cp ~/.minikube/ca.crt ./certs/
cp ~/.minikube/ca.key ./certs/
```
# Делаем скрипты исполняемыми
```bash
chmod +x create-users.sh
chmod +x apply-rbac.sh
chmod +x verify-access.sh
```
# Создаём пользователей и сертификаты
```bash
bash create-users.sh
```

# Применяем RBAC-конфигурацию к кластеру
```bash
bash apply-rbac.sh
```
# Аудит прав
```bash
bash verify-access.sh 
```

# Удалить кластер
```bash
minikube delete
```
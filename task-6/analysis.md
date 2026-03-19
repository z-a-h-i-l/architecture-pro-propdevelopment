| Событие | Уровень риска | Статус |
|---------|--------------|--------|
| Доступ к bootstrap-token | 🟡 Средний | ✅ Легитимно (kubeadm) |
| Создание kube-proxy с privileged | 🟡 Средний | ✅ Легитимно (системный компонент) |
| Создание `privileged-pod` в `secure-ops` | 🔴 **КРИТИЧЕСКИЙ** | ❌ **ПОДОЗРИТЕЛЬНО** |

---

## 🔴 КРИТИЧЕСКИ ПОДОЗРИТЕЛЬНОЕ СОБЫТИЕ

### Событие: Создание пода `privileged-pod` в namespace `secure-ops`

```json
{
  "verb": "create",
  "objectRef": {
    "resource": "pods",
    "namespace": "secure-ops",  // ⚠️ НЕ системный namespace
    "name": "privileged-pod"     // ⚠️ Подозрительное имя
  },
  "user": {
    "username": "minikube-user",  // ⚠️ Пользователь с system:masters
    "groups": ["system:masters"]
  },
  "requestObject": {
    "spec": {
      "containers": [{
        "name": "pwn",              // ⚠️ Контейнер назван "pwn" (slang: "owned")
        "image": "alpine",          // ⚠️ Минимальный образ для атак
        "command": ["sleep", "3600"], // ⚠️ Держит под запущенным для доступа
        "securityContext": {
          "privileged": true        // 🔴 ПОЛНЫЙ ДОСТУП К ХОСТУ
        }
      }]
    }
  }
}
```
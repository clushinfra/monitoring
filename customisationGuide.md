## 쿠버네티스 아키텍쳐

<img width="972" height="541" alt="image" src="https://github.com/user-attachments/assets/fcefe845-d6ac-423e-a616-e0a330b288a5" />



## 네임스페이스 상태

```
(
  min by (namespace) (
    kube_pod_status_ready{condition="true", namespace=~"gpu|service|db"}
    and on (namespace,pod)
    (kube_pod_status_phase{phase="Running", namespace=~"gpu|service|db"} == 1)
  ) == bool 1
)
* on (namespace)
(
  count by (namespace) (kube_pod_status_phase{phase="Running", namespace=~"gpu|service|db"} == 1) > bool 0
)
```

Visualization : Gauge
Value Mappings: (1:UP, 0:Down)

## 총 CPU 사용량 

```
100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

Visualization : Gauge
Unit: Percent (0-100)
Color scheme: From thresholds(by value)
Thresholds: 빨강: 80% 주황: 60%

## 총 메모리 사용량

```
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

Visualization : Gauge
Unit: Percent (0-100)
Color scheme: From thresholds(by value)
Thresholds: 빨강: 80% 주황: 60%

## CPU 사용량

### Query A: 
```
sum by (namespace) (
  rate(container_cpu_usage_seconds_total{
    image!="", container!="POD",
    namespace=~"gpu"
  }[1m])
)
```

### Query B:
```
sum by (namespace) (
  rate(container_cpu_usage_seconds_total{
    image!="", container!="POD",
    namespace=~"service"
  }[1m])
)
```

### Query C: 

```
sum by (namespace) (
  rate(container_cpu_usage_seconds_total{
    image!="", container!="POD",
    namespace=~"db"
  }[1m])
)
```

Visualization: Time series
Unit: bytes(IEC)

## 메모리 사용량 

### Query A: 
```
sum by (namespace) (
  container_memory_working_set_bytes{
    image!="", container!="POD",
    namespace=~"gpu"
  }
)
```

### Query B:
```
sum by (namespace) (
  container_memory_working_set_bytes{
    image!="", container!="POD",
    namespace=~"service"
  }
)
```

### Query C: 

```
sum by (namespace) (
  container_memory_working_set_bytes{
    image!="", container!="POD",
    namespace=~"db"
  }
)
```

Visualization: Time series
Unit: bytes(IEC)

## 네임 스페이스 별 파드 개수
### Query A: 
```
count(kube_pod_info{namespace="gpu"})
```

### Query B:
```
count(kube_pod_info{namespace="db"})
```

### Query C: 

```
count(kube_pod_info{namespace="service"})
```

Visualization: Stat

## 노드 가동 시간 
```
node_time_seconds - node_boot_time_seconds
```
Visualization: Stat

## 유휴 CPU 
```
avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m]))
```
Visualization: Stat

## CPU 총 코어 수 
```
count(node_cpu_seconds_total{mode="system"})
```
Visualization: Stat


## 유휴 메모리
```
node_memory_MemAvailable_bytes / 1024 / 1024 / 1024
```
Visualization: Stat
Unit: gibibytes

## 총 메모리

```
node_memory_MemTotal_bytes / 1024 / 1024 / 1024
```

Visualization: Stat
Unit: gibibytes

## 네트워크 트래픽

### 서버 트래픽
### Query A: 
```
sum(
  rate(container_network_receive_bytes_total{namespace="service", pod=~"net-srv.*"}[1m])
)
+
sum(
  rate(container_network_transmit_bytes_total{namespace="service", pod=~"net-srv.*"}[1m])
) 
```

### 클라이언트 트래픽
### Query B:
```
sum(
  rate(container_network_receive_bytes_total{namespace="service", pod=~"net-gen.*"}[1m])
)
+
sum(
  rate(container_network_transmit_bytes_total{namespace="service", pod=~"net-gen.*"}[1m])
)
```

Visualization: Time series
Unit: bytes/sec(IEC)

## 디스크 사용량

```
sum by (instance) (
  rate(node_disk_written_bytes_total[5m])
) / 1024 / 1024
```
Visualization: Time series
Unit: bytes/sec(IEC)

## 완성된 대시보드
<img width="1899" height="986" alt="워크숍대시보드" src="https://github.com/user-attachments/assets/94c3bda7-da0a-4c10-adaf-7dfc5e51bae4" />

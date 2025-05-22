# Создание облачной инфраструктуры

## 1. Сервисный аккаунт и bucket

В Яндекс Облаке при помощи Terraform создал сервис-аккаунт и назначил необходимые права

![alt text](pics/sa.png)

а так-же создал bucket на 1ГБ

![alt text](pics/bucket.png)

В дальнейшем сгенерил terraform-key.json сервисного аккаунта, который буду использовать для аутентификации при подготовке инфраструктуры.

[Terraform код](terraform/service_account)

## 2. Инфраструктура

В Яндекс Облаке при помощи Terraform было поднято 

VPC c подсетями public и private

![alt text](pics/vps.png)

5 виртуальных машин

Одна виртуальная машина (master) в зоне public

Три виртуальных машины (worker) в зоне private

Одна виртуальная машина (nat-instance) в зоне public

Начальная конфигурация операционной системы на разных виртуальных машинах проходила через индивидуальный cloud-init

![alt text](pics/vm.png)

Так-же была создана таблица маршрутов из private на nat-instance для получения трафика виртуальным машинам в зоне private

![alt text](pics/routes.png)

Был создан Network Load Balancer и listener с targetport:30080

![alt text](pics/balancer.png)

В target-group добавил worker-nodes

![alt text](pics/nodes_healthy.png)

После применения кода, файл ```terraform.tfstate улетает``` в созданный ранее bucket

![alt text](pics/tfstate.png)

[Terraform код](terraform/main_infrastructure)

# Создание Kubernetes кластера

## Кластер

Kubernetes кластер подготавливал при помощи Kubespray, который запускал с master-node

```git clone https://github.com/kubernetes-sigs/kubespray.git```

Поставил зависимости

```pip install -r ~/kubespray/requirements.txt```

В файле с переменными ```~/kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml``` в параметре ```supplementary_addresses_in_ssl_keys``` подкинул nat-ip master-node

Заполняем inventory.ini

Одна мастер-нода, три воркер-ноды

![alt text](pics/inventory.png)

Ожидание составило почти 15 минут

![alt text](pics/kubespray.png)

После раскатки роли обновил ```~/.kube/config``` на master-node и на локальной машине

А так-же для ingress поставил ingress-nginx через helm

```# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx```

```# helm repo update```

При конфигурации ingress-nginx указал порт 30080, такой-же как и на listener у балансировщика в ЯО

```# helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --set controller.service.type=NodePort --set controller.service.nodePorts.http=30080 --set controller.progressDeadlineSeconds=30```

Команда kubectl get pods --all-namespaces отрабатывает без ошибок

![alt text](pics/kubectl.png)

# Создание тестового приложения

Собрал docker образ тестового приложения и поместил его в DockerHub

![alt text](pics/dockerhub.png)

[Ссылка на DockerHub](https://hub.docker.com/repository/docker/vyacheslavgaidar/diploma_app/general)

Docker файл с тестовой страницей html и nginx.conf лежат в репозитории.

[Ссылка на репозиторий](https://github.com/gaidarvu/test_app_k8s)

# Подготовка cистемы мониторинга и деплой приложения

Клонирую репозиторий с заранее подготовленными конфигами для мониторинга и моего тестового приложения

[Мой репозиторий с конфигами](https://github.com/gaidarvu/k8s_cfgs)

```git clone https://github.com/gaidarvu/k8s_cfgs.git```

## Grafana, prometheus, alertmanager, экспортер основных метрик Kubernetes

Систему мониторинга поднимал через helm

```# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts```

```# helm repo update```

Запускаем установку с конфигом из склонированного ранее репозитория

```# helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace -f ~/k8s_cfgs/kube-prom-values.yaml```

Gragana доступна по адресу http://158.160.172.134/grafana

![alt text](pics/grafana.png)

![alt text](pics/grafana2.png)

![alt text](pics/grafana3.png)

## Тестовое приложение

Запускаем манифест из склонированного ранее репозитория

```kubectl apply -f app_all_in_one.yml```

Тестовое приложение доступно по адресу http://158.160.172.134/app

![alt text](pics/testapp.png)

## CI/CD-terraform

Создал workflow в GitHub Actions, который при любом пуше в main запускает пайплайн

[Сам Workflow](https://github.com/gaidarvu/diploma/blob/main/.github/workflows/terraform.yml) 

Как видно пайплайн прошел успешно

![alt text](pics/workflow-tf.png)

Workflow прошел за две с половиной минуты

![alt text](pics/workflow-tf2.png)

Workflow, который протекает уже на поднятой инфраструктуре ничего не поменял и прошел успешно

![alt text](pics/workflow-tf3.png)

А тут решил добавить оперативки nat-инстансу

Workflow прошел успешно

![alt text](pics/workflow-tf4.png)

Как видим vm остановилась
![alt text](pics/vm_state.png)

И поднялась уже с 2ГБ оперативки

![alt text](pics/vm_state2.png)

# Установка и настройка CI/CD

В репозитории с тестовым приложением создал workflow в GitHub Actions, который при любом пуше в main запускает пайплайн где собирает образ приложения и отправляет его в DockerHub

А так-же если пуш происходит с тегом, приложение деплоится в кубернетес кластер

[Workflow](https://github.com/gaidarvu/test_app_k8s/blob/main/.github/workflows/deploy.yaml)

[Репозиторий с тестовым приложением](https://github.com/gaidarvu/test_app_k8s)

# Демонстрация работы

Внес изменения в репозитории и сделал пуш без тага

![alt text](pics/push_latest.png)

Как видим запустился пайплайн

![alt text](pics/test_commit.png)

Который завершился успешно, но не попал в деплой

![alt text](pics/test_commit2.png)

![alt text](pics/test_commit3.png)

Теперь внес изменения в репозитории и сделал пуш с тагом

Для наглядности внес изменение в страничку со статичными данными. Записал туда версию приложения, которую укажу в таге: 1.0.17

![alt text](pics/app_version.png)

![alt text](pics/push_tag.png)

Как видим пайплайн прошел успешно и приложение задеплоилось в кластер

![alt text](pics/deploy_commit.png)

![alt text](pics/deploy_commit2.png)

Смотрим какой образ использовался для деплоя

![alt text](pics/app_describe.png)

Web-интерфейс. Версия поменялась

![alt text](pics/deployed_app.png)

В DockerHub залетел образ с тагом

![alt text](pics/dockerhub2.png)

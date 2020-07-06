# Apiary Init Container

This container was introduced as apart of resolving [[Issue 165](https://github.com/ExpediaGroup/apiary-data-lake/issues/165)]. 
The general idea of why this container exists was to remove external dependencies and networking requirements between a deployment server and the deployment target when deploying Apiary. 

Previously, Apiary had a hard requirement that the location of where the terraform apply job was running, had to have direct network access to the MySQL database in order to properly configure account access for the read-only and read-write roles. This presented some challenges when deploying into air-gapped environments as there would be no direct network access without punching a hole or proxying a connection between the deployer and the deployment environment.

This solution relies on either [Kubernetes Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) or [ECS Container dependencies](https://aws.amazon.com/about-aws/whats-new/2019/03/amazon-ecs-introduces-enhanced-container-dependency-management/), depending on your deployment target.


The init docker container contains the same shell scripts which were previously ran as apart of the apiary terraform process.


## Terraform Usages

- Kubernetes
  - [Read-Only](https://github.com/ExpediaGroup/apiary-data-lake/blob/9881ef5b6fdb37bd22ca132542104f7eb026ce0c/k8s-readonly.tf#L40)
  - [Read-Write](https://github.com/ExpediaGroup/apiary-data-lake/blob/9881ef5b6fdb37bd22ca132542104f7eb026ce0c/k8s-readwrite.tf#L40)
- ECS
  - [Read-Only](https://github.com/ExpediaGroup/apiary-data-lake/blob/9881ef5b6fdb37bd22ca132542104f7eb026ce0c/templates/apiary-hms-readonly.json#L2)
  - [Read-Write](https://github.com/ExpediaGroup/apiary-data-lake/blob/9881ef5b6fdb37bd22ca132542104f7eb026ce0c/templates/apiary-hms-readwrite.json#L2)

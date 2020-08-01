---
title: Kubernetes Operator with RedHat Operator SDK
date: 2020-08-01 16:12:41
tags:
    - Kubernetes
    - Operator
---

This tutorial is to develop Kubernetes Operators with RedHat Operator SDK. <!-- more -->

# What is Operator?

- [kubernetes API 与 Operator：不为人知的开发者战争（完整篇）](https://www.lijiaocn.com/%E9%A1%B9%E7%9B%AE/2019/01/08/kubernetes-api-and-operator-history.html)
- [Operator Hub - How do I start writing an Operator?](https://operatorhub.io/getting-started#How-do-I-start-writing-an-Operator?)

# RedHat Operator Framework

Please refer to [GitHub - Operator Framework](https://github.com/operator-framework)

# Operator SDK

1. Create a new project

    ```bash
    $ export GO111MODULE=on
    $ operator-sdk new sample-operator --repo=github.com/stevenchiu30801/sample-operator
    $ cd sample-operator
    ```

2. Add a new Custom Resource Definition

    ```bash
    $ operator-sdk add api --api-version=sample.io/v1alpha1 --kind=SampleCr
    ```

3. Define the spec and status

    ```go
    // pkg/apis/sample/v1alpha1/samplecr_types.go
    type SampleCrSpec struct {
        TestList []int `json:"testList"`
        Count int `json:"count"`
    }
    ```

    ```bash
    # update the generated code for that resource type
    $ operator-sdk generate k8s
    # automatically generate the CRDs
    $ operator-sdk generate crds
    # changes would be applied in deploy/crds/sample.io_samplecr_crd.yaml
    ```

4. Add a new Controller

    ```bash
    $ operator-sdk add controller --api-version=sample.io/v1alpha1 --kind=SampleCr
    ```

5. Design the controller `pkg/controller/samplecr/samplecr_controller.go`

    List of API reference

    - [Sample `memcached_controller.go`](https://github.com/operator-framework/operator-sdk/blob/master/example/memcached-operator/memcached_controller.go.tmpl)
    - [kubernetes-sigs/controller-runtime](https://github.com/kubernetes-sigs/controller-runtime)
        - [Using the Controller Runtime Client API with Operator SDK](https://github.com/operator-framework/operator-sdk/blob/master/doc/user/client.md)
    - [kubernetes/cli-runtime](https://github.com/kubernetes/cli-runtime)
        - For Helm client to get Kubernetes client config
        - [genericclioptions.AddFlags()](https://github.com/kubernetes/cli-runtime/blob/master/pkg/genericclioptions/config_flags.go#L255)
            - Field explanation for genericclioptions.ConfigFlags
    - [kubernetes/client-go#rest/config.go-rest.InClusterConfig()](https://github.com/kubernetes/client-go/blob/master/rest/config.go#L471)
        - Config intended for clients that expect to be running inside a pod running on kubernetes
    - [helm/helm#pkg](https://github.com/helm/helm/tree/master/pkg)
        - [Samples on kubernetes helm golang client](https://stackoverflow.com/questions/45692719/samples-on-kubernetes-helm-golang-client)
    - [Cluster-scoped operator usage](https://github.com/operator-framework/operator-sdk/blob/master/doc/operator-scope.md#cluster-scoped-operator-usage)
6. Register CRD

    ```bash
    $ kubectl create -f deploy/crds/sample.io_samplecr_crd.yaml
    ```

7. Run the operator

    Two ways

    1. Run as a Deployment inside the cluster

    ```bash
    # build image and push it to your registry first!
    $ sed -i 's|REPLACE_IMAGE|<docker/repo:tag>|g'deploy/operator.yaml
    $ kubectl create -f deploy/service_account.yaml
    $ kubectl create -f deploy/role.yaml
    $ kubectl create -f deploy/role_binding.yaml
    $ kubectl create -f deploy/operator.yaml
    ```

    2. Run locally outside the cluster

    ```bash
    # during development cycle to deploy and test faster
    $ operator-sdk run --local --namespace=default
    ```

8. Create CR

    ```bash
    # modify CR spec first
    $ kubectl create -f deploy/crds/sample.io_v1alpha1_samplecr_cr.yaml
    ```

Some design logic of controller

- Design control logic in view of single unit of reconciled object
    - Don't think in the way of orchestrator or manager
    - Since reconciled object would be requeue due to changes
- Try to not maintain soft state in operator
    - Store data in database or volume
    - Use Status to keep object states
- Use finalizer to handle cleanup of external resources

# Reference

## Operator

- [operator-framework/getting-started](https://github.com/operator-framework/getting-started/blob/master/README.md)
    - [operator-sdk#user-guide.md](https://github.com/operator-framework/operator-sdk/blob/master/doc/user-guide.md) - for Go operator
- [operator-framework/operator-sdk-samples](https://github.com/operator-framework/operator-sdk-samples)

### Finalizer

- [Extend the Kubernetes API with CustomResourceDefinitions#Finalizers](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/#finalizers)
- [kubernetes-sigs/kuberbuilder#using_finalizers.md](https://github.com/kubernetes-sigs/kubebuilder/blob/master/docs/book/src/reference/using-finalizers.md)
- [kubernetes-sigs/kubebuilder#finalizer_example.go](https://github.com/kubernetes-sigs/kubebuilder/blob/master/docs/book/src/cronjob-tutorial/testdata/finalizer_example.go)
- [Kubernetes 实战-Operator Finalizers 实现](https://zdyxry.github.io/2019/09/13/Kubernetes-%E5%AE%9E%E6%88%98-Operator-Finalizers/)

## Others

- [Samples on kubernetes helm golang client](https://stackoverflow.com/questions/45692719/samples-on-kubernetes-helm-golang-client)
    - [For Helm 3](https://stackoverflow.com/a/60077666)

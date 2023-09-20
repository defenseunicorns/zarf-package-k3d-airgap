#! /bin/bash

###################### SCRIPT TO REMOVE BIG BANG/DUBBD ########################
############ USED IF ZARF PACKAGE REMOVE FAILS TO REMOVE BIG BANG #############

flux suspend hr -n bigbang kyverno
kubectl delete hr -n bigbang bigbang &
sleep 30
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io \
  kyverno-policy-validating-webhook-cfg kyverno-resource-validating-webhook-cfg
kubectl patch kialis.kiali.io -n kiali kiali \
  -p  '{"metadata":{"finalizers":null}}' --type=merge
kubectl patch istiooperators.install.istio.io \
  -n istio-system istiocontrolplane -p '{"metadata":{"finalizers":null}}' \
  --type=merge
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io \
  istio-validator-istio-system istiod-default-validator
kubectl delete gitrepositories.source.toolkit.fluxcd.io -n bigbang bigbang
kubectl delete ns bigbang
yes| flux uninstall








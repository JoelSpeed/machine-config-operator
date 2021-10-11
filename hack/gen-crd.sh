#!/usr/bin/env bash

set -eu

function annotate_crd() {
  script1='/^  annotations:/a\
\ \ \ \ include.release.openshift.io/ibm-cloud-managed: "true"\
\ \ \ \ include.release.openshift.io/self-managed-high-availability: "true"\
\ \ \ \ include.release.openshift.io/single-node-developer: "true"\
\ \ \ labels:\
\ \ \ \ "openshift.io/operator-managed": ""'
  script2='/^    controller-gen.kubebuilder.io\/version: (devel)/d'
  input="${1}"
  output="${2}"
  sed -e "${script1}" -e "${script2}" "${input}" > "${output}"
}

echo "Building controller-gen tool..."
go build -o bin/controller-gen github.com/openshift/machine-config-operator/vendor/sigs.k8s.io/controller-tools/cmd/controller-gen

dir=$(mktemp -d -t XXXXXXXX)
echo $dir
mkdir -p $dir/src/github.com/openshift/machine-config-operator/pkg/apis

cp -r pkg/apis/* $dir/src/github.com/openshift/machine-config-operator/pkg/apis
# Some dependencies need to be copied as well. Othwerwise, controller-gen will complain about non-existing kind Unsupported
cp -r vendor $dir/src/github.com/openshift/machine-config-operator/
cp go.mod go.sum $dir/src/github.com/openshift/machine-config-operator/

cwd=$(pwd)
pushd $dir/src/github.com/openshift/machine-config-operator
GOPATH=$dir ${cwd}/bin/controller-gen crd \
    crd:crdVersions=v1 \
    paths=$dir/src/github.com/openshift/machine-config-operator/pkg/apis/machineconfiguration.openshift.io/... \
    output:crd:dir=$dir/src/github.com/openshift/machine-config-operator/config/crds/

popd

echo "Copying and patching generated CRDs"
annotate_crd $dir/src/github.com/openshift/machine-config-operator/config/crds/machineconfiguration.openshift.io_containerruntimeconfigs.yaml install/0000_80_machine-config-operator_01_containerruntimeconfig.crd.yaml
annotate_crd $dir/src/github.com/openshift/machine-config-operator/config/crds/machineconfiguration.openshift.io_kubeletconfigs.yaml install/0000_80_machine-config-operator_01_kubeletconfig.crd.yaml
annotate_crd $dir/src/github.com/openshift/machine-config-operator/config/crds/machineconfiguration.openshift.io_machineconfigs.yaml install/0000_80_machine-config-operator_01_machineconfig.crd.yaml
annotate_crd $dir/src/github.com/openshift/machine-config-operator/config/crds/machineconfiguration.openshift.io_machineconfigpools.yaml install/0000_80_machine-config-operator_01_machineconfigpool.crd.yaml
annotate_crd $dir/src/github.com/openshift/machine-config-operator/config/crds/machineconfiguration.openshift.io_controllerconfigs.yaml manifests/controllerconfig.crd.yaml

rm -rf $dir

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

function ignitionSchema() {
  cat << EOF
              required:
              \- ignition
              properties:
                ignition:
                  description: Ignition section contains metadata about the configuration
                    itself. We only permit a subsection of ignition fields for MachineConfigs.
                  type: object
                  x-kubernetes-preserve-unknown-fields: true
                  properties:
                    config:
                      type: object
                      properties:
                        append:
                          type: array
                          items:
                            type: object
                            properties:
                              source:
                                type: string
                              verification:
                                type: object
                                properties:
                                  hash:
                                    type: string
                        replace:
                          type: object
                          properties:
                            source:
                              type: string
                            verification:
                              type: object
                              properties:
                                hash:
                                  type: string
                    security:
                      type: object
                      properties:
                        tls:
                          type: object
                          properties:
                            certificateAuthorities:
                              type: array
                              items:
                                type: object
                                properties:
                                  source:
                                    type: string
                                  verification:
                                    type: object
                                    properties:
                                      hash:
                                        type: string
EOF
}

function ignitionSchemaOriginal() {
  cat << EOF
  required:
  \- ignition
  properties:
    ignition:
      description: Ignition section contains metadata about the configuration
        itself. We only permit a subsection of ignition fields for MachineConfigs.
      type: object
      x-kubernetes-preserve-unknown-fields: true
      properties:
        config:
          type: object
          properties:
            append:
              type: array
              items:
                type: object
                properties:
                  source:
                    type: string
                  verification:
                    type: object
                    properties:
                      hash:
                        type: string
            replace:
              type: object
              properties:
                source:
                  type: string
                verification:
                  type: object
                  properties:
                    hash:
                      type: string
        security:
          type: object
          properties:
            tls:
              type: object
              properties:
                certificateAuthorities:
                  type: array
                  items:
                    type: object
                    properties:
                      source:
                        type: string
                      verification:
                        type: object
                        properties:
                          hash:
                            type: string
        timeouts:
          type: object
          properties:
            httpResponseHeaders:
              type: integer
            httpTotal:
              type: integer
        version:
          description: Version string is the semantic version number of
            the spec
          type: string
    passwd:
      type: object
      properties:
        users:
          type: array
          items:
            type: object
            properties:
              name:
                description: Name of user. Must be \"core\" user.
                type: string
              sshAuthorizedKeys:
                description: Public keys to be assigned to user core.
                type: array
                items:
                  type: string
    storage:
      description: Storage describes the desired state of the system's
        storage devices.
      type: object
      x-kubernetes-preserve-unknown-fields: true
      properties:
        directories:
          description: Directories is the list of directories to be created
          type: array
          items:
            description: Items is list of directories to be written
            type: object
            properties:
              filesystem:
                description: Filesystem is the internal identifier of
                  the filesystem in which to write the file. This matches
                  the last filesystem with the given identifier.
                type: string
              group:
                description: Group object specifies group of the owner
                type: object
                properties:
                  id:
                    description: ID is the user ID of the owner
                    type: integer
                  name:
                    description: Name is the user name of the owner
                    type: string
              mode:
                description: Mode is the file's permission mode. Note
                  that the mode must be properly specified as a decimal
                  value (i.e. 0644 -> 420)
                type: integer
              overwrite:
                description: Overwrite specifies whether to delete preexisting
                  nodes at the path
                type: boolean
              path:
                description: Path is the absolute path to the file
                type: string
              user:
                description: User object specifies the file's owner
                type: object
                properties:
                  id:
                    description: ID is the user ID of the owner
                    type: integer
                  name:
                    description: Name is the user name of the owner
                    type: string
        files:
          description: Files is the list of files to be created\/modified
          type: array
          items:
            description: Items is list of files to be written
            type: object
            x-kubernetes-preserve-unknown-fields: true
            properties:
              contents:
                description: Contents specifies options related to the
                  contents of the file
                type: object
                properties:
                  compression:
                    description: The type of compression used on the contents
                      (null or gzip). Compression cannot be used with
                      S3.
                    type: string
                  source:
                    description: Source is the URL of the file contents.
                      Supported schemes are http, https, tftp, s3, and
                      data. When using http, it is advisable to use the
                      verification option to ensure the contents haven't
                      been modified.
                    type: string
                  verification:
                    description: Verification specifies options related
                      to the verification of the file contents
                    type: object
                    properties:
                      hash:
                        description: Hash is the hash of the config, in
                          the form <type>-<value> where type is sha512
                        type: string
              filesystem:
                description: Filesystem is the internal identifier of
                  the filesystem in which to write the file. This matches
                  the last filesystem with the given identifier
                type: string
              group:
                description: Group object specifies group of the owner
                type: object
                properties:
                  id:
                    description: ID specifies group ID of the owner
                    type: integer
                  name:
                    description: Name is the group name of the owner
                    type: string
              mode:
                description: Mode specifies the file's permission mode.
                  Note that the mode must be properly specified as a decimal
                  value (i.e. 0644 -> 420)
                type: integer
              overwrite:
                description: Overwrite specifies whether to delete preexisting
                  nodes at the path
                type: boolean
              path:
                description: Path is the absolute path to the file
                type: string
              user:
                description: User object specifies the file's owner
                type: object
                properties:
                  id:
                    description: ID is the user ID of the owner
                    type: integer
                  name:
                    description: Name is the user name of the owner
                    type: string
    systemd:
      description: systemd describes the desired state of the systemd
        units
      type: object
      properties:
        units:
          description: Units is a list of units to be configured
          type: array
          items:
            description: Items describes unit configuration
            type: object
            properties:
              contents:
                description: Contents is the contents of the unit
                type: string
              dropins:
                description: Dropins is the list of drop-ins for the unit
                type: array
                items:
                  description: Items describes unit dropin
                  type: object
                  properties:
                    contents:
                      description: Contents is the contents of the drop-in
                      type: string
                    name:
                      description: Name is the name of the drop-in. This
                        must be suffixed with '.conf'
                      type: string
              enabled:
                description: Enabled describes whether or not the service
                  shall be enabled. When true, the service is enabled.
                  When false, the service is disabled. When omitted, the
                  service is unmodified. In order for this to have any
                  effect, the unit must have an install section
                type: boolean
              mask:
                description: Mask describes whether or not the service
                  shall be masked. When true, the service is masked by
                  symlinking it to \/dev\/null"
                type: boolean
              name:
                description: Name is the name of the unit. This must be
                  suffixed with a valid unit type (e.g. 'thing.service')
                type: string
EOF
}

function injectIgnitionSchema() {
  ignition=$(echo -n "$(ignitionSchema)" | tr "\n" "\r")
  script1="/x-kubernetes-preserve-unknown-fields: true/a\\
  $ignition"
  file=${1}
  sed -i ".tmp" -e "${script1}" "${file}"
  sed -i ".tmp" "s/\r/\n  /g" "${file}"
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

injectIgnitionSchema install/0000_80_machine-config-operator_01_machineconfig.crd.yaml

rm -rf $dir

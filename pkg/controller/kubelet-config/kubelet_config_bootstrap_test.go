package kubeletconfig

import (
	"fmt"
	"testing"

	configv1 "github.com/openshift/api/config/v1"
	mcfgv1 "github.com/openshift/machine-config-operator/pkg/apis/machineconfiguration.openshift.io/v1"
	ctrlcommon "github.com/openshift/machine-config-operator/pkg/controller/common"
	"github.com/openshift/machine-config-operator/test/helpers"
	"github.com/stretchr/testify/require"
	"github.com/vincent-petithory/dataurl"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	kubeletconfigv1beta1 "k8s.io/kubelet/config/v1beta1"
)

func TestRunKubeletBootstrap(t *testing.T) {
	for _, platform := range []configv1.PlatformType{configv1.AWSPlatformType, configv1.NonePlatformType, "unrecognized"} {
		t.Run(string(platform), func(t *testing.T) {
			cc := newControllerConfig(ctrlcommon.ControllerConfigName, platform)
			pools := []*mcfgv1.MachineConfigPool{
				helpers.NewMachineConfigPool("master", nil, helpers.MasterSelector, "v0"),
				helpers.NewMachineConfigPool("worker", nil, helpers.WorkerSelector, "v0"),
			}

			kcRaw, err := EncodeKubeletConfig(&kubeletconfigv1beta1.KubeletConfiguration{MaxPods: 100}, kubeletconfigv1beta1.SchemeGroupVersion)
			if err != nil {
				panic(err)
			}
			cfgs := []*mcfgv1.KubeletConfig{
				{
					Spec: mcfgv1.KubeletConfigSpec{
						KubeletConfig: &runtime.RawExtension{
							Raw: kcRaw,
						},
					},
				},
			}
			mcs, err := RunKubeletBootstrap("../../../templates", cfgs, cc, nil, pools)
			require.NoError(t, err)
			require.Len(t, mcs, len(pools))

			managedKeys := make(map[string]string)
			for i := range pools {
				for _, cfg := range cfgs {
					keyReg, _ := generateSuffixManagedKeyKubelet(pools[i], cfg, managedKeys)
					verifyKubeletConfigJSONContents(t, mcs[i], keyReg, cc.Spec.ReleaseImage)
				}
			}
		})
	}
}

func verifyKubeletConfigJSONContents(t *testing.T, mc *mcfgv1.MachineConfig, mcName string, releaseImageReg string) {
	ignCfg, err := ctrlcommon.ParseAndConvertConfig(mc.Spec.Config.Raw)
	require.NoError(t, err)
	regfile := ignCfg.Storage.Files[0]
	conf, err := dataurl.DecodeString(*regfile.Contents.Source)
	require.NoError(t, err)
	require.Contains(t, string(conf.Data), `"maxPods": 100`)
}

func TestGenerateSuffixManagedKeyKubelet(t *testing.T) {
	managedKeys := make(map[string]string)
	pool := helpers.NewMachineConfigPool("worker", nil, helpers.WorkerSelector, "v0")
	kcRaw, err := EncodeKubeletConfig(&kubeletconfigv1beta1.KubeletConfiguration{MaxPods: 100}, kubeletconfigv1beta1.SchemeGroupVersion)
	if err != nil {
		panic(err)
	}
	cfgs := []*mcfgv1.KubeletConfig{
		{
			Spec: mcfgv1.KubeletConfigSpec{
				KubeletConfig: &runtime.RawExtension{
					Raw: kcRaw,
				},
			},
		},
	}
	for _, cfg := range cfgs {
		generateSuffixManagedKeyKubelet(pool, cfg, managedKeys)
	}
	require.Equal(t, 1, len(managedKeys))

	managedKeys = make(map[string]string)
	cfgs = []*mcfgv1.KubeletConfig{
		{
			Spec: mcfgv1.KubeletConfigSpec{
				KubeletConfig: &runtime.RawExtension{
					Raw: kcRaw,
				},
			},
		},
		{
			ObjectMeta: metav1.ObjectMeta{Name: "kcfg-1"},
			Spec: mcfgv1.KubeletConfigSpec{
				KubeletConfig: &runtime.RawExtension{
					Raw: kcRaw,
				},
			},
		},
		{
			Spec: mcfgv1.KubeletConfigSpec{
				KubeletConfig: &runtime.RawExtension{
					Raw: kcRaw,
				},
			},
		},
		{
			ObjectMeta: metav1.ObjectMeta{Name: "kcfg-1"},
			Spec: mcfgv1.KubeletConfigSpec{
				KubeletConfig: &runtime.RawExtension{
					Raw: kcRaw,
				},
			},
		},
		{
			ObjectMeta: metav1.ObjectMeta{Name: "kcfg-2"},
			Spec: mcfgv1.KubeletConfigSpec{
				KubeletConfig: &runtime.RawExtension{
					Raw: kcRaw,
				},
			},
		},
	}
	for _, cfg := range cfgs {
		generateSuffixManagedKeyKubelet(pool, cfg, managedKeys)
	}
	require.Equal(t, 4, len(managedKeys))
	for _, k := range []string{"99-worker-generated-kubelet", "kcfg-1", "99-worker-generated-kubelet-2", "kcfg-2"} {
		_, ok := managedKeys[k]
		require.True(t, ok, fmt.Sprintf("%v should exist", k))
	}
}

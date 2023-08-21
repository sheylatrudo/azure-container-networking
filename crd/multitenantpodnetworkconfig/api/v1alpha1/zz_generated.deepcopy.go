//go:build !ignore_autogenerated
// +build !ignore_autogenerated

// Code generated by controller-gen. DO NOT EDIT.

package v1alpha1

import (
	runtime "k8s.io/apimachinery/pkg/runtime"
)

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *MultitenantPodNetworkConfig) DeepCopyInto(out *MultitenantPodNetworkConfig) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ObjectMeta.DeepCopyInto(&out.ObjectMeta)
	out.Spec = in.Spec
	out.Status = in.Status
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new MultitenantPodNetworkConfig.
func (in *MultitenantPodNetworkConfig) DeepCopy() *MultitenantPodNetworkConfig {
	if in == nil {
		return nil
	}
	out := new(MultitenantPodNetworkConfig)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *MultitenantPodNetworkConfig) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *MultitenantPodNetworkConfigList) DeepCopyInto(out *MultitenantPodNetworkConfigList) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ListMeta.DeepCopyInto(&out.ListMeta)
	if in.Items != nil {
		in, out := &in.Items, &out.Items
		*out = make([]MultitenantPodNetworkConfig, len(*in))
		for i := range *in {
			(*in)[i].DeepCopyInto(&(*out)[i])
		}
	}
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new MultitenantPodNetworkConfigList.
func (in *MultitenantPodNetworkConfigList) DeepCopy() *MultitenantPodNetworkConfigList {
	if in == nil {
		return nil
	}
	out := new(MultitenantPodNetworkConfigList)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyObject is an autogenerated deepcopy function, copying the receiver, creating a new runtime.Object.
func (in *MultitenantPodNetworkConfigList) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *MultitenantPodNetworkConfigSpec) DeepCopyInto(out *MultitenantPodNetworkConfigSpec) {
	*out = *in
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new MultitenantPodNetworkConfigSpec.
func (in *MultitenantPodNetworkConfigSpec) DeepCopy() *MultitenantPodNetworkConfigSpec {
	if in == nil {
		return nil
	}
	out := new(MultitenantPodNetworkConfigSpec)
	in.DeepCopyInto(out)
	return out
}

// DeepCopyInto is an autogenerated deepcopy function, copying the receiver, writing into out. in must be non-nil.
func (in *MultitenantPodNetworkConfigStatus) DeepCopyInto(out *MultitenantPodNetworkConfigStatus) {
	*out = *in
}

// DeepCopy is an autogenerated deepcopy function, copying the receiver, creating a new MultitenantPodNetworkConfigStatus.
func (in *MultitenantPodNetworkConfigStatus) DeepCopy() *MultitenantPodNetworkConfigStatus {
	if in == nil {
		return nil
	}
	out := new(MultitenantPodNetworkConfigStatus)
	in.DeepCopyInto(out)
	return out
}
################################################################################
# AWS VPC CNI ENIConfig Resources
#
# Each ENIConfig name matches an Availability Zone because:
# ENI_CONFIG_LABEL_DEF = topology.kubernetes.io/zone
#
# ENIConfig creation is disabled during the initial EKS bootstrap because
# kubernetes_manifest requires an existing, reachable Kubernetes API.
################################################################################

resource "kubernetes_manifest" "eni_config" {
  for_each = var.enable_eni_config ? var.pod_subnet_ids : {}

  manifest = {
    apiVersion = "crd.k8s.amazonaws.com/v1alpha1"
    kind       = "ENIConfig"

    metadata = {
      name = each.key
    }

    spec = {
      subnet = each.value

      securityGroups = [
        module.eks.node_security_group_id
      ]
    }
  }

  depends_on = [
    module.eks
  ]
}
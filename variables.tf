################################################################################
# Authentication
################################################################################

variable "ACCOUNT_ID" {
  description = "AWS Account ID to deploy the cluster into"
  type        = string
}

variable "ROLE_NAME" {
  description = "IAM role name to assume for cluster operations, for example Jenkins"
  type        = string
}

################################################################################
# Cluster
################################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_region" {
  description = "AWS region for the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster, for example 1.36"
  type        = string
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API server endpoint is publicly accessible"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS control plane and managed node groups"
  type        = list(string)
  default     = []
}

variable "cluster_addons" {
  description = "Additional EKS managed addon overrides merged with defaults in main.tf"
  type        = map(any)
  default     = {}
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node-group definitions"
  type        = map(any)
  default     = {}
}

variable "eks_managed_node_group_defaults" {
  description = "Default configuration applied to all EKS managed node groups"
  type        = map(any)
  default     = {}
}

################################################################################
# Existing Phase 1 IAM Roles
################################################################################

variable "eks_cluster_role_arn" {
  description = "ARN of the existing IAM role used by the EKS control plane"
  type        = string

  validation {
    condition     = can(regex("^arn:(aws|aws-us-gov|aws-cn):iam::[0-9]{12}:role/.+$", var.eks_cluster_role_arn))
    error_message = "eks_cluster_role_arn must be a valid IAM role ARN."
  }
}

variable "eks_managed_node_role_arn" {
  description = "ARN of the existing IAM role used by EKS managed node groups"
  type        = string

  validation {
    condition     = can(regex("^arn:(aws|aws-us-gov|aws-cn):iam::[0-9]{12}:role/.+$", var.eks_managed_node_role_arn))
    error_message = "eks_managed_node_role_arn must be a valid IAM role ARN."
  }
}

variable "karpenter_node_role_arn" {
  description = "ARN of the existing IAM role used by EC2 nodes provisioned by Karpenter"
  type        = string

  validation {
    condition     = can(regex("^arn:(aws|aws-us-gov|aws-cn):iam::[0-9]{12}:role/.+$", var.karpenter_node_role_arn))
    error_message = "karpenter_node_role_arn must be a valid IAM role ARN."
  }
}

variable "karpenter_node_role_name" {
  description = "Name of the existing IAM role used by EC2 nodes provisioned by Karpenter"
  type        = string
  default     = "ag-devops-ap-karpenter-node"

  validation {
    condition     = length(trimspace(var.karpenter_node_role_name)) > 0
    error_message = "karpenter_node_role_name must not be empty."
  }
}

variable "karpenter_node_instance_profile_name" {
  description = "Name of the existing IAM instance profile used by Karpenter nodes"
  type        = string
  default     = "ag-devops-ap-karpenter-node"

  validation {
    condition     = length(trimspace(var.karpenter_node_instance_profile_name)) > 0
    error_message = "karpenter_node_instance_profile_name must not be empty."
  }
}

################################################################################
# KMS
################################################################################

variable "cluster_kms_key_arn" {
  description = "ARN of the KMS key used for EKS secrets envelope encryption"
  type        = string
  default     = null
}

variable "velero_kms_key_arn" {
  description = "ARN of the KMS CMK used to encrypt the Velero S3 backup bucket"
  type        = string
  default     = null
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Common tags applied to all resources, including FinOps, owner, and environment tags"
  type        = map(string)
  default     = {}
}

################################################################################
# Addon Feature Flags
################################################################################

variable "enable_argo_rollouts" {
  type    = bool
  default = false
}

variable "enable_argo_workflows" {
  type    = bool
  default = false
}

variable "enable_argocd" {
  type    = bool
  default = false
}

variable "enable_aws_cloudwatch_metrics" {
  description = "Enable CloudWatch Container Insights through the amazon-cloudwatch-observability EKS addon"
  type        = bool
  default     = true
}

variable "enable_aws_efs_csi_driver" {
  type    = bool
  default = false
}

variable "enable_aws_fsx_csi_driver" {
  type    = bool
  default = false
}

variable "enable_aws_privateca_issuer" {
  type    = bool
  default = false
}

variable "enable_cluster_autoscaler" {
  type    = bool
  default = false
}

variable "enable_secrets_store_csi_driver" {
  type    = bool
  default = false
}

variable "enable_secrets_store_csi_driver_provider_aws" {
  type    = bool
  default = false
}

variable "enable_kube_prometheus_stack" {
  type    = bool
  default = false
}

variable "enable_external_dns" {
  type    = bool
  default = false
}

variable "external_dns_values" {
  type    = list(string)
  default = []
}

variable "enable_external_secrets" {
  description = "Enable External Secrets operator"
  type        = bool
  default     = false
}

variable "enable_gatekeeper" {
  type    = bool
  default = false
}

variable "enable_ingress_nginx" {
  type    = bool
  default = false
}

variable "enable_cert_manager" {
  type    = bool
  default = false
}

variable "cert_manager_values" {
  type    = map(any)
  default = {}
}

variable "enable_aws_load_balancer_controller" {
  type    = bool
  default = false
}

variable "aws_load_balancer_controller_values" {
  type    = map(any)
  default = {}
}

variable "enable_metrics_server" {
  type    = bool
  default = true
}

variable "enable_vpa" {
  description = "Enable Vertical Pod Autoscaler required for Goldilocks recommendations"
  type        = bool
  default     = true
}

variable "enable_fargate_fluentbit" {
  type    = bool
  default = false
}

variable "enable_aws_for_fluentbit" {
  description = "Enable AWS for Fluent Bit DaemonSet"
  type        = bool
  default     = false
}

variable "enable_aws_node_termination_handler" {
  type    = bool
  default = false
}

variable "enable_karpenter" {
  type    = bool
  default = true
}

variable "enable_velero" {
  type    = bool
  default = true
}

variable "velero_backup_namespaces" {
  description = "List of namespaces Velero should back up; an empty list means all namespaces"
  type        = list(string)
  default     = []
}

variable "enable_aws_gateway_api_controller" {
  type    = bool
  default = false
}

variable "enable_keda" {
  description = "Enable Kubernetes Event-driven Autoscaling"
  type        = bool
  default     = true
}

variable "vpc_cni_custom_networking" {
  description = "Enable AWS VPC CNI custom networking for dedicated Pod subnets"
  type        = bool
  default     = false
}

variable "pod_subnet_ids" {
  description = "Dedicated Pod subnet IDs mapped by Availability Zone"
  type        = map(string)
  default     = {}
}

variable "enable_eni_config" {
  description = "Create ENIConfig Kubernetes resources after the EKS cluster is reachable"
  type        = bool
  default     = false
}
################################################################################
# Helm Releases
#
# Defaults cover addons common to all clusters.
# Override per cluster in tfvars by providing a complete helm_releases map.
################################################################################

variable "helm_releases" {
  description = "Map of generic Helm chart releases to deploy on the cluster"
  type        = map(any)

  default = {
    cilium = {
      description      = "Cilium service mesh with Hubble UI"
      namespace        = "cilium"
      create_namespace = true
      chart            = "cilium"
      chart_version    = "1.16.5"
      repository       = "https://helm.cilium.io/"

      values = [
        <<-EOT
          hubble:
            enabled: true
            relay:
              enabled: true
            ui:
              enabled: true

          cni:
            chainingMode: generic-veth
            customConf: true
            configMap: cni-configuration

          enableIPv4Masquerade: false
          enableIPv6Masquerade: false
          routingMode: native
        EOT
      ]
    }

    prometheus-adapter = {
      description      = "Prometheus adapter for custom metrics API"
      namespace        = "prometheus-adapter"
      create_namespace = true
      chart            = "prometheus-adapter"
      chart_version    = "4.11.0"
      repository       = "https://prometheus-community.github.io/helm-charts"

      values = [
        <<-EOT
          replicas: 2

          podDisruptionBudget:
            enabled: true
        EOT
      ]
    }

    goldilocks = {
      description      = "VPA-based right-sizing recommendations"
      namespace        = "goldilocks"
      create_namespace = true
      chart            = "goldilocks"
      chart_version    = "9.0.1"
      repository       = "https://charts.fairwinds.com/stable"

      # VPA is installed separately through enable_vpa.
      values = [
        <<-EOT
          vpa:
            enabled: false
        EOT
      ]
    }

    kubetail = {
      description      = "Cluster-wide log tailing UI"
      namespace        = "kubetail"
      create_namespace = true
      chart            = "kubetail"
      chart_version    = "0.6.0"
      repository       = "https://kubetail-org.github.io/helm-charts/"

      values = [
        <<-EOT
          clusterRole: true
        EOT
      ]
    }

    kyverno = {
      description      = "Kubernetes policy engine"
      namespace        = "kyverno"
      create_namespace = true
      chart            = "kyverno"
      chart_version    = "3.3.4"
      repository       = "https://kyverno.github.io/kyverno/"

      values = [
        <<-EOT
          admissionController:
            replicas: 3
            nodeSelector:
              capacity-type: on-demand
            tolerations:
              - key: "CriticalAddonsOnly"
                operator: "Exists"

          backgroundController:
            nodeSelector:
              capacity-type: on-demand

          cleanupController:
            nodeSelector:
              capacity-type: on-demand

          reportsController:
            nodeSelector:
              capacity-type: on-demand
        EOT
      ]
    }

    keda = {
      description      = "Kubernetes Event-driven Autoscaling"
      namespace        = "keda"
      create_namespace = true
      chart            = "keda"
      chart_version    = "2.16.1"
      repository       = "https://kedacore.github.io/charts"

      values = [
        <<-EOT
          operator:
            replicaCount: 2

          metricsServer:
            replicaCount: 2

          webhooks:
            replicaCount: 1

          podDisruptionBudget:
            operator:
              minAvailable: 1
            metricServer:
              minAvailable: 1
        EOT
      ]
    }
  }
}
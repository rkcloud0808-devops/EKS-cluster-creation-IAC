# ============================================================
# EKS cluster
#
# ACCOUNT_ID and ROLE_NAME may alternatively be injected by
# CI/CD through TF_VAR_ACCOUNT_ID and TF_VAR_ROLE_NAME.
# ============================================================

ACCOUNT_ID = "xxxx"
ROLE_NAME  = "xxxx"

################################################################################
# Cluster
################################################################################

vpc_id = "xxxx"

# EKS control-plane and worker-node primary ENI subnets.
subnet_ids = [
  "xxxx",
  "xxxx",
  "xxxx"
]

cluster_name    = "xxxx"
cluster_region  = "ap-southeast-1"
cluster_version = "1.36"

cluster_endpoint_public_access = false

################################################################################
# AWS VPC CNI Custom Networking
#
# Nodes use subnet_ids above for their primary ENIs.
# Pods use the dedicated AZ-specific subnets below through secondary ENIs.
#
# ENIConfig resources must be named after the corresponding AZ because:
# ENI_CONFIG_LABEL_DEF = "topology.kubernetes.io/zone"
################################################################################

vpc_cni_custom_networking = true

# Keep false unless the centralized TGW/NAT team approves external SNAT.
# With false, VPC CNI performs its standard Pod-to-node-primary-ENI SNAT.
pod_subnet_ids = {
  "ap-southeast-1a" = "xxxx"
  "ap-southeast-1b" = "xxxx"
  "ap-southeast-1c" = "xxxx"
}

################################################################################
# Existing Phase 1 IAM Roles
#
# These IAM roles and the Karpenter instance profile are managed by the
# dedicated IAM Terraform stack.
################################################################################

eks_cluster_role_arn = "xxxx"

eks_managed_node_role_arn = "xxxx"

karpenter_node_role_arn = "xxxx"

karpenter_node_role_name = "xxxx"

karpenter_node_instance_profile_name = "xxxx"

################################################################################
# Addon Feature Flags
################################################################################

enable_cluster_autoscaler           = false
enable_karpenter                    = true
enable_velero                       = true
enable_gatekeeper                   = false
enable_aws_load_balancer_controller = true
enable_aws_for_fluentbit            = false
enable_aws_node_termination_handler = false
enable_aws_cloudwatch_metrics       = true
enable_vpa                          = true
enable_metrics_server               = true

################################################################################
# Common Tags
#
# Validate these values against the approved enterprise tagging standard.
################################################################################

tags = {
  appcode                      = "xxxx"
  AppEnv                       = "PRD"
  AwsEnv                       = "PRD"
  Application                  = "xxxx"
  Name                         = "xxxx"
  Project                      = "xxxx"
  AwsId                        = "xxxx"
  archiving                    = "no"
  backup                       = "yes"
  "data-confidentiality"       = "C2"
  "finops.automation.schedule" = "running"
  "finops.id"                  = "xxxx"
  "info.eol"                   = "Null"
  "info.owner"                 = "xxxx"
  msp                          = "xxxx"
}

################################################################################
# EKS Managed Node Groups
#
# Worker-node primary ENIs use the cluster subnet_ids.
# Pod secondary ENIs use the pod_subnet_ids through ENIConfig.
################################################################################

eks_managed_node_groups = {
  ondemand-arm = {
    instance_types = [
      "m7g.large",
      "m7g.xlarge",
      "m7g.2xlarge",
      "m6g.large",
      "m6g.xlarge",
      "m6g.2xlarge",
      "c7g.large",
      "c7g.xlarge",
      "c7g.2xlarge",
      "c6g.large",
      "c6g.xlarge",
      "c6g.2xlarge"
    ]

    ami_type                   = "AL2023_ARM_64_STANDARD"
    create_launch_template     = false
    use_custom_launch_template = false

    min_size     = 2
    max_size     = 4
    desired_size = 2

    capacity_type              = "ON_DEMAND"
    enable_bootstrap_user_data = true
    ebs_optimized              = true
    disable_api_termination    = false
    encrypted_volume           = true
    enable_monitoring          = true

    labels = {
      "capacity-type" = "on-demand"
      "workload-arch" = "arm64"
    }

    taints = []

    launch_template_tags = {
      "karpenter.sh/ekscluster" = "xxxx"
    }
  }
}

################################################################################
# Generic Helm Releases
#
# timeout is present in every map element to maintain a consistent object type.
################################################################################

helm_releases = {
  cilium = {
    description      = "Cilium networking and policy with Hubble UI"
    namespace        = "cilium"
    create_namespace = true
    chart            = "cilium"
    chart_version    = "1.16.5"
    repository       = "https://helm.cilium.io/"
    timeout          = 900

    values = [
      <<-EOT
        hubble:
          enabled: true
          relay:
            enabled: true
          ui:
            enabled: true

        cni:
          chainingMode: aws-cni
          exclusive: false

        enableIPv4Masquerade: false
        enableIPv6Masquerade: false
        routingMode: native
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
    timeout          = 900

    values = [
      <<-EOT
        clusterRole: true

        nodeSelector:
          capacity-type: on-demand
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
    timeout          = 900

    values = [
      <<-EOT
        image:
          repository: xxxx
          tag: v4.13.0
          pullPolicy: IfNotPresent

        # VPA is installed separately by the EKS addons module.
        vpa:
          enabled: false
      EOT
    ]
  }

  kyverno = {
    description      = "Kubernetes policy engine"
    namespace        = "kyverno"
    create_namespace = true
    chart            = "kyverno"
    chart_version    = "3.4.5"
    repository       = "https://kyverno.github.io/kyverno/"
    timeout          = 900

    values = [
      <<-EOT
        crds:
          migration:
            image:
              registry: xxxx
              repository: xxxx
              tag: v1.14.5
              pullPolicy: IfNotPresent

        webhooksCleanup:
          image:
            registry: xxxx
            repository: xxxx
            tag: "1.33.4"
            pullPolicy: IfNotPresent

        policyReportsCleanup:
          image:
            registry: xxxx
            repository: xxxx
            tag: "1.33.4"
            pullPolicy: IfNotPresent

        admissionController:
          replicas: 3

          initContainer:
            image:
              registry: xxxx
              repository: xxxx
              tag: v1.14.5
              pullPolicy: IfNotPresent

          container:
            image:
              registry: xxxx
              repository: xxxx
              tag: v1.14.5
              pullPolicy: IfNotPresent

          nodeSelector:
            capacity-type: on-demand

        backgroundController:
          image:
            registry: xxxx
            repository: xxxx
            tag: v1.14.5
            pullPolicy: IfNotPresent

          nodeSelector:
            capacity-type: on-demand

        cleanupController:
          image:
            registry: xxxx
            repository: xxxx
            tag: v1.14.5
            pullPolicy: IfNotPresent

          nodeSelector:
            capacity-type: on-demand

        reportsController:
          image:
            registry: xxxx
            repository: xxxx
            tag: v1.14.5
            pullPolicy: IfNotPresent

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
    timeout          = 900

    values = [
      <<-EOT
        operator:
          replicaCount: 2

        metricsServer:
          replicaCount: 2
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
    timeout          = 900

    values = [
      <<-EOT
        image:
          repository: xxxx
          tag: v0.12.0
          pullPolicy: IfNotPresent

        replicas: 2

        podDisruptionBudget:
          enabled: true
      EOT
    ]
  }
}

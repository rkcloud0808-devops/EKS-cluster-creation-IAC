provider "aws" {
  region = local.region

  assume_role {
    role_arn = "arn:aws:iam::${var.ACCOUNT_ID}:role/${var.ROLE_NAME}"
  }
}

# Required for public ECR where Karpenter artifacts are hosted
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"

  assume_role {
    role_arn = "arn:aws:iam::${var.ACCOUNT_ID}:role/${var.ROLE_NAME}"
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"

    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--role-arn",
      "arn:aws:iam::${var.ACCOUNT_ID}:role/${var.ROLE_NAME}"
    ]
  }
}

# Updated for latest stable Helm provider v3.x syntax
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"

      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--role-arn",
        "arn:aws:iam::${var.ACCOUNT_ID}:role/${var.ROLE_NAME}"
      ]
    }
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"

    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--role-arn",
      "arn:aws:iam::${var.ACCOUNT_ID}:role/${var.ROLE_NAME}"
    ]
  }
}

locals {
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # EKS managed node group
  default_update_config = {
    max_unavailable_percentage = 33
  }

  # Self-managed node group
  default_instance_refresh = {
    strategy = "Rolling"

    preferences = {
      min_healthy_percentage = 66
    }
  }
}

data "aws_availability_zones" "available" {}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

locals {
  name   = var.cluster_name
  region = var.cluster_region

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint                     = local.name
    "karpenter.sh/ekscluster"     = local.name
    "finops.id"                   = "hnyjvmy57dfgenfzhrvp"
    "info.owner"                  = "apac-cloud"
    "data-confidentiality"        = "C2"
    AwsEnv                        = "PRD"
    Support_Contact_Email         = "serviceassurance@1cloudhub.com"
    backup                        = "yes"
    AppEnv                        = "PRD"
    "finops.automation.schedule"  = "running"
    "info.eol"                    = "Null"
    msp                           = "1CLOUDHUB"
    "map-migrated"                = "mig44268"
    AwsId                         = "hnyjvmy57dfgenfzhrvp"
  }
}

################################################################################
# Blueprints Addons
################################################################################

locals {
  addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true

      configuration_values = jsonencode({
        env = {
          AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "false"
          ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
          ENABLE_PREFIX_DELEGATION           = "false"
          WARM_PREFIX_TARGET                 = "1"
        }
      })
    }

    kube-proxy = {
      most_recent = true
    }

    coredns = {
      most_recent = true

      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }

    eks-pod-identity-agent = {
      most_recent = true
    }

    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }

    # adot = {
    #   most_recent              = true
    #   service_account_role_arn = module.adot_irsa.iam_role_arn
    # }
  }
}

module "eks_blueprints_addons" {
  source = "./eks_addons"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Current design: EKS managed addons are handled in eks_blueprints_addons.
  # Avoid creating the same addons inside module.eks at the same time.
  eks_addons = merge(local.addons, var.cluster_addons)

  enable_aws_efs_csi_driver                    = var.enable_aws_efs_csi_driver
  enable_aws_fsx_csi_driver                    = var.enable_aws_fsx_csi_driver
  enable_argocd                                = var.enable_argocd
  enable_argo_rollouts                         = var.enable_argo_rollouts
  enable_argo_workflows                        = var.enable_argo_workflows
  enable_aws_cloudwatch_metrics                = false
  enable_aws_privateca_issuer                  = var.enable_aws_privateca_issuer
  enable_cluster_autoscaler                    = var.enable_cluster_autoscaler
  enable_secrets_store_csi_driver              = var.enable_secrets_store_csi_driver
  enable_secrets_store_csi_driver_provider_aws = var.enable_secrets_store_csi_driver_provider_aws
  enable_kube_prometheus_stack                 = var.enable_kube_prometheus_stack

  enable_external_dns = var.enable_external_dns

  external_dns_route53_zone_arns = [
    "arn:aws:route53:::hostedzone/*",
  ]

  enable_external_secrets = var.enable_external_secrets
  enable_gatekeeper       = var.enable_gatekeeper
  enable_ingress_nginx    = var.enable_ingress_nginx

  # Wait for all Cert Manager related resources to be ready
  enable_cert_manager = var.enable_cert_manager

  cert_manager = {
    wait = true
  }

  # AWS Load Balancer Controller
  # Region and VPC ID are parameterized for the EKS 1.36 cluster.
  enable_aws_load_balancer_controller = var.enable_aws_load_balancer_controller

  aws_load_balancer_controller = {
    values = [
      <<-EOT
        region: ${var.cluster_region}
        vpcId: ${var.vpc_id}
        enableServiceMutatorWebhook: false
      EOT
    ]
  }

  enable_metrics_server    = var.enable_metrics_server
  
  metrics_server = {
    values = [
      <<-EOT
        image:
          repository: 044063822467.dkr.ecr.ap-southeast-1.amazonaws.com/eks/metrics-server
          tag: v0.8.1
      EOT
    ]
  }
  enable_vpa = var.enable_vpa

  vpa = {
    values = [
      <<-EOT
        admissionController:
          image:
            repository: 044063822467.dkr.ecr.ap-southeast-1.amazonaws.com/eks/vpa-admission-controller
            tag: "1.6.0"
            pullPolicy: IfNotPresent

          certGen:
            image:
              repository: 044063822467.dkr.ecr.ap-southeast-1.amazonaws.com/eks/kube-webhook-certgen
              tag: v20230312-helm-chart-4.5.2-28-g66a760794
              pullPolicy: IfNotPresent

        recommender:
          image:
            repository: 044063822467.dkr.ecr.ap-southeast-1.amazonaws.com/eks/vpa-recommender
            tag: "1.6.0"
            pullPolicy: IfNotPresent

        updater:
          image:
            repository: 044063822467.dkr.ecr.ap-southeast-1.amazonaws.com/eks/vpa-updater
            tag: "1.6.0"
            pullPolicy: IfNotPresent
      EOT
    ]
  }
  enable_fargate_fluentbit = var.enable_fargate_fluentbit
  enable_aws_for_fluentbit = var.enable_aws_for_fluentbit

  aws_for_fluentbit_cw_log_group = {
    create          = false
    use_name_prefix = true
    name_prefix     = "eks-cluster-logs-"
    retention       = 7
  }

  aws_for_fluentbit = {
    enable_containerinsights = false
    kubelet_monitoring       = false
    chart_version            = "0.1.28"

    set = [
      {
        name  = "cloudWatchLogs.autoCreateGroup"
        value = true
      },
      {
        name  = "hostNetwork"
        value = true
      },
      {
        name  = "dnsPolicy"
        value = "ClusterFirstWithHostNet"
      }
    ]

    s3_bucket_arns = var.enable_velero ? [
      module.velero_backup_s3_bucket[0].s3_bucket_arn,
      "${module.velero_backup_s3_bucket[0].s3_bucket_arn}/logs/*"
    ] : []
  }

  # NTH: pass ASG ARNs (not names). The module constructs ARNs from the ASG names
  # returned by the EKS module using the data source below.
  aws_node_termination_handler_asg_arns = []

  enable_karpenter = var.enable_karpenter

# The Karpenter node instance profile is created by the dedicated IAM IaC.
karpenter_enable_instance_profile_creation = false

karpenter_node = {
  create_iam_role       = false
  iam_role_arn          = var.karpenter_node_role_arn
  iam_role_name         = var.karpenter_node_role_name

  create_instance_profile = false
  instance_profile_name   = var.karpenter_node_instance_profile_name
}

karpenter = {
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
}

  enable_velero = var.enable_velero

  velero = var.enable_velero ? {
    s3_backup_location = "${module.velero_backup_s3_bucket[0].s3_bucket_arn}/backups"

    # Removed old kubectl image override:
    # kubectl.image.tag: 1.29.2-debian-11-r5
    #
    # If image pinning is required, add an approved 1.36-compatible tag here.
  } : {}

  enable_aws_gateway_api_controller = var.enable_aws_gateway_api_controller

  # ECR login required
  aws_gateway_api_controller = {
    repository_username = data.aws_ecrpublic_authorization_token.token.user_name
    repository_password = data.aws_ecrpublic_authorization_token.token.password

    set = [
      {
        name  = "clusterVpcId"
        value = var.vpc_id
      }
    ]
  }

  # Pass in any number of Helm charts to be created for those that are not natively supported
  helm_releases = var.helm_releases

  tags = local.tags
}

################################################################################
# Cluster
################################################################################

module "eks" {
  source = "./eks"

  cluster_name                   = local.name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = var.cluster_endpoint_public_access

  # Use the EKS control-plane role created by the dedicated IAM IaC.
  create_iam_role = false
  iam_role_arn    = var.eks_cluster_role_arn

  # Current configuration disables cluster secrets encryption.
  cluster_encryption_config = []

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_security_group_additional_rules = {
  ingress_jenkins_private_api = {
    description = "Allow Jenkins VPC to access the private EKS API"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    type        = "ingress"
    cidr_blocks = ["10.30.112.0/23"]
  }
}

  # Give the Terraform identity admin access to the cluster.
  enable_cluster_creator_admin_permissions = true

  # Use the managed-node role created by the dedicated IAM IaC.
  eks_managed_node_group_defaults = merge(
    var.eks_managed_node_group_defaults,
    {
      create_iam_role           = false
      iam_role_arn              = var.eks_managed_node_role_arn
      iam_role_attach_cni_policy = false
    }
  )

  eks_managed_node_groups = var.eks_managed_node_groups

  tags = local.tags
}

output "eks_managed_node_groups_autoscaling_group_names" {
  value = module.eks.eks_managed_node_groups_autoscaling_group_names
}

################################################################################
# Karpenter NodePool / EC2NodeClass
################################################################################

locals {
  # Render the variables used inside nodepool.yaml.
  karpenter_rendered_yaml = templatefile(
    "${path.module}/nodepool.yaml",
    {
      cluster_name                         = var.cluster_name
      karpenter_node_instance_profile_name = var.karpenter_node_instance_profile_name
    }
  )

  # Normalize Windows line endings and split the multi-document YAML.
  karpenter_yaml_documents = [
    for document in split(
      "\n---\n",
      replace(local.karpenter_rendered_yaml, "\r\n", "\n")
    ) :
    yamldecode(trimspace(document))
    if trimspace(document) != ""
  ]

  # Extract the two EC2NodeClass documents.
  karpenter_ec2_nodeclasses = {
    for document in local.karpenter_yaml_documents :
    document.metadata.name => document
    if document.kind == "EC2NodeClass"
  }

  # Extract the two NodePool documents.
  karpenter_nodepools = {
    for document in local.karpenter_yaml_documents :
    document.metadata.name => document
    if document.kind == "NodePool"
  }
}

################################################################################
# Karpenter Node EKS Access Entry
#
# Required so EC2 instances launched by Karpenter can authenticate to and
# register with the EKS cluster.
################################################################################

resource "aws_eks_access_entry" "karpenter_node" {
  count = var.enable_karpenter ? 1 : 0

  cluster_name  = module.eks.cluster_name
  principal_arn = var.karpenter_node_role_arn
  type          = "EC2_LINUX"

  tags = local.tags

  depends_on = [
    module.eks
  ]
}

################################################################################
# EC2NodeClasses
#
# EC2NodeClasses are created before NodePools because each NodePool references
# an EC2NodeClass through spec.template.spec.nodeClassRef.
################################################################################

resource "kubectl_manifest" "karpenter_ec2_nodeclass" {
  for_each = var.enable_karpenter ? local.karpenter_ec2_nodeclasses : {}

  yaml_body = yamlencode(each.value)

  server_side_apply = true
  force_conflicts   = true

  depends_on = [
    module.eks,
    module.eks_blueprints_addons,
    aws_eks_access_entry.karpenter_node
  ]
}

################################################################################
# NodePools
################################################################################

resource "kubectl_manifest" "karpenter_nodepool" {
  for_each = var.enable_karpenter ? local.karpenter_nodepools : {}

  yaml_body = yamlencode(each.value)

  server_side_apply = true
  force_conflicts   = true

  depends_on = [
    aws_eks_access_entry.karpenter_node,
    kubectl_manifest.karpenter_ec2_nodeclass
  ]
}

################################################################################
# Validation
################################################################################

check "karpenter_yaml_documents" {
  assert {
    condition = (
      length(local.karpenter_yaml_documents) == 4 &&
      length(local.karpenter_ec2_nodeclasses) == 2 &&
      length(local.karpenter_nodepools) == 2
    )

    error_message = "nodepool.yaml must contain exactly two EC2NodeClasses and two NodePools."
  }
}

################################################################################
# Supporting Resources
################################################################################

/*
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}
*/

module "velero_backup_s3_bucket" {
  count = var.enable_velero ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket_prefix = "${local.name}-"

  # NOTE:
  # force_destroy is enabled in the existing code.
  # For production, confirm whether this should remain true.
  force_destroy = true

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  acl = "private"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  versioning = {
    status     = true
    mfa_delete = false
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags
}

module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${local.name}-ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

module "adot_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${local.name}-adot-"

  role_policy_arns = {
    prometheus = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
    xray       = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
    cloudwatch = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["opentelemetry-operator-system:opentelemetry-operator"]
    }
  }

  tags = local.tags
}

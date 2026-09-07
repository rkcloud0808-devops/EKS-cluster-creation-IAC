################################################################################
# Generic Helm Releases
################################################################################

resource "helm_release" "this" {
  for_each = var.helm_releases

  name             = try(each.value.name, each.key)
  description      = try(each.value.description, null)
  namespace        = try(each.value.namespace, null)
  create_namespace = try(each.value.create_namespace, null)

  chart      = each.value.chart
  version    = try(each.value.chart_version, null)
  repository = try(each.value.repository, null)
  values     = try(each.value.values, [])

  timeout                    = try(each.value.timeout, 600)
  repository_key_file        = try(each.value.repository_key_file, null)
  repository_cert_file       = try(each.value.repository_cert_file, null)
  repository_ca_file         = try(each.value.repository_ca_file, null)
  repository_username        = try(each.value.repository_username, null)
  repository_password        = try(each.value.repository_password, null)
  devel                      = try(each.value.devel, null)
  verify                     = try(each.value.verify, null)
  keyring                    = try(each.value.keyring, null)
  disable_webhooks           = try(each.value.disable_webhooks, null)
  reuse_values               = try(each.value.reuse_values, null)
  reset_values               = try(each.value.reset_values, null)
  force_update               = try(each.value.force_update, null)
  recreate_pods              = try(each.value.recreate_pods, null)
  cleanup_on_fail            = try(each.value.cleanup_on_fail, true)
  max_history                = try(each.value.max_history, 10)
  atomic                     = try(each.value.atomic, true)
  skip_crds                  = try(each.value.skip_crds, null)
  render_subchart_notes      = try(each.value.render_subchart_notes, null)
  disable_openapi_validation = try(each.value.disable_openapi_validation, null)
  wait                       = try(each.value.wait, true)
  wait_for_jobs              = try(each.value.wait_for_jobs, null)
  dependency_update          = try(each.value.dependency_update, null)
  replace                    = try(each.value.replace, null)
  lint                       = try(each.value.lint, null)

  # Helm provider v3 requires set as a list of objects rather than
  # repeated nested blocks.
  set = [
    for item in try(each.value.set, []) : {
      name  = item.name
      value = tostring(item.value)
      type  = try(item.type, null)
    }
  ]

  # Helm provider v3 requires set_sensitive as a list of objects rather
  # than repeated nested blocks.
  set_sensitive = [
    for item in try(each.value.set_sensitive, []) : {
      name  = item.name
      value = tostring(item.value)
      type  = try(item.type, null)
    }
  ]

  depends_on = [
    # Wait for EKS managed addons such as EBS CSI to be installed first.
    aws_eks_addon.this
  ]
}

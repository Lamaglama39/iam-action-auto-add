# タグ
locals {
  pj     = "iam-action-auto-add"
}

module "main" {
  source = "./module"
  project = local.pj
}

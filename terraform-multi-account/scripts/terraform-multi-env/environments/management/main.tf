module "admin_user" {
  source      = "../../modules/iam-user"
  user_name   = "admin-user"
  environment = "management"
}

module "organization" {
  source = "../../modules/organization"

  accounts = {
    dev = {
      name  = "dev-account"
      email = "choukseyarpit18@gmail.com"
    }

    prod = {
      name  = "prod-account"
      email = "shrivastavasuruchi11@gmail.com"
    }

    devtest = {
      name  = "devtest"
      email = "yourmail+terraformdev@gmail.com"
    }

    connectivity = {
      name  = "connectivity-account"
      email = "bharatchouksey2021@gmail.com"
    }

    logging = {
      name  = "logging-account"
      email = "choukseyaastha18@gmail.com"
    }

    audit = {
      name  = "audit-account"
      email = "arushikhare98@gmail.com"
    }
  }
}

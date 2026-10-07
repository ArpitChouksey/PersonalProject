aws_region = "us-east-1"

identity_store_id = "d-90666107c9"

permission_sets = {
  administrator = {
    name             = "AdministratorAccess"
    description      = "Administrator access permission set for AWS accounts"
    session_duration = "PT4H"

    tags = {}
  }
}

users = {
  arpit = {
    user_name    = "arpit"
    display_name = "Arpit Chouksey"
    given_name   = "Arpit"
    family_name  = "Chouksey"
    email        = "arpitchouksey18@gmail.com"
  }
}

account_assignments = {
  arpit_management = {
    account_id         = "211811255273"
    permission_set_key = "administrator"
    user_key           = "arpit"
  }

  arpit_security = {
    account_id         = "152500409784"
    permission_set_key = "administrator"
    user_key           = "arpit"
  }

  arpit_log_archive = {
    account_id         = "038269111064"
    permission_set_key = "administrator"
    user_key           = "arpit"
  }

  arpit_network = {
    account_id         = "360734036001"
    permission_set_key = "administrator"
    user_key           = "arpit"
  }

  arpit_shared_services = {
    account_id         = "070977799818"
    permission_set_key = "administrator"
    user_key           = "arpit"
  }

  arpit_production = {
    account_id         = "025775692925"
    permission_set_key = "administrator"
    user_key           = "arpit"
  }

  arpit_non_production = {
    account_id         = "325909447008"
    permission_set_key = "administrator"
    user_key           = "arpit"
  }
}

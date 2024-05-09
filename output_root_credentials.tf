output "root_credentials" {
  value = ({
      host = local.host
      database = local.database
      user = local.root_user
      password = local.root_password
  })
  sensitive = true
}


output "credentials" {
  value = ({
      host = local.host
      database = local.database
      user = local.user
      password = local.password
  })
  sensitive = true
}


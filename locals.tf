locals {
  network_id = var.network_params.network_id
  project = var.network_params.project
  postfix = var.network_params.postfix

  volume_exchange = var.volume_exchange
  host = "mongodb-${var.network_params.postfix}"
  user = "${var.network_params.project}${var.network_params.postfix}"
  password = random_string.password.result
  root_user = "r${var.network_params.project}${var.network_params.postfix}"
  root_password = random_string.root_password.result
  database = "${var.network_params.project}${var.network_params.postfix}"

  connection = "mongodb://${local.root_user}:${local.root_password}@${local.host}:27017/${local.database}?authSource=admin&compressors=disabled&gssapiServiceName=mongodb"
  repair = false
}

locals {
  env = [
    "MONGO_INITDB_ROOT_USERNAME=${local.root_user}",
    "MONGO_INITDB_ROOT_PASSWORD=${local.root_password}",
    "MONGO_INITDB_DATABASE=${local.database}",
  ]

  init_js = join("\n", [for d in concat([local.database], var.databases) : 
    "db = db.getSiblingDB('${d}');\ndb.createUser({ user: '${local.user}', pwd: '${local.password}', roles: [{ role: 'readWrite', db: '${d}' }]});\ndb.createCollection('_nothing');\n"
  ])
  upload = [{
    content = local.init_js
    file = "/docker-entrypoint-initdb.d/mongo-init.js"
  }]

  mounted_exchange = {
    source = local.volume_exchange
    target = "/exchange"
  }

  mounts = var.disabled > 0 || var.mounted == "" ? [] : [
    {
      source = var.mounted
      target = "/data/db"
    }
  ]

  volumes = var.disabled > 0 || local.mounts != [] ? [] : [{
    container_path = "/data/db"
    volume_name    = docker_volume.storage[0].name
  }]

  ports = var.open_ports ? [{
    internal = 27017
    external = 27017
  }] : []


  labels = [
    { "label": "host", "value": local.host },
    { "label": "role", "value": "mongodb" }    
  ]
}

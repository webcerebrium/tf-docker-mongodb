resource "docker_container" "mongodb_exporter" {
  count = var.enable_metrics ? 1 : 0
  image = docker_image.mongodb_exporter[0].image_id
  name = local.hostname
  restart = "always"

  command = local.metrics_cmd
  env = local.metrics_env
  log_opts = var.network_params.log_opts
  
  networks_advanced {
    name  = local.network_id
  }
  networks_advanced {
      name  = local.zone.network_public_id
  }
      
  dynamic labels {
      for_each = local.metrics_labels
      content {
          label = labels.value.label
          value = labels.value.value
      }
  }

  network_mode = "bridge"
}


resource "docker_image" "mongodb_exporter" {
  name = "percona/mongodb_exporter:0.20"
  count = var.enable_metrics ? 1 : 0
  keep_locally = true
}

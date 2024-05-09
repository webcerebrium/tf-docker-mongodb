resource "docker_image" "mongodb" {
  name = "mongo:7"
  count = var.disabled > 0 ? 0 : 1
  keep_locally = true
}

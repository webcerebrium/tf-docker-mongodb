resource "local_file" "shell" {
   content = <<EOF
#!/usr/bin/env bash
set -ex
docker exec -it ${local.host} bash -c 'mongosh --username=$MONGO_INITDB_ROOT_USERNAME --password=$MONGO_INITDB_ROOT_PASSWORD --authenticationDatabase=admin $MONGO_INITDB_DATABASE'
EOF
   filename = "./bin/mongodb-shell.sh"
   file_permission = "0777"
}


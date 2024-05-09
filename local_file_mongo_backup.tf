resource "local_file" "backup" {
   content = <<EOF
#!/usr/bin/env bash
set -ex

now() {
    date +"%Y%m%dT%H%M%S"
}

command -v aws >/dev/null 2>&1 || { echo "ERROR: AWS CLIv2 executable was not found"; exit 1; }

export DIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TAR_FOLDER=rentals
export DIR_EXCHANGE=$(docker inspect mongodb-${local.postfix} | jq -r '.[].Mounts[] | select(.Destination == "/exchange")'.Source)
export PID=$(docker ps --filter "label=host=${local.host}" --format "{{.ID}}")
if [[ "$PID" != "" ]]; then
    rm -rf $DIR_EXCHANGE/$TAR_FOLDER || true

    export LAST_TAR=${local.project}-${local.database}-`now`.tar
    echo "Starting MongoDB backup $LAST_TAR"
    docker exec -i $PID bash -c 'mongodump --gzip --username=$MONGO_INITDB_ROOT_USERNAME --password=$MONGO_INITDB_ROOT_PASSWORD --authenticationDatabase=admin --db=$MONGO_INITDB_DATABASE -o /exchange/'
    echo "Creating tarball"
    docker exec -i $PID bash -c 'cd /exchange && mv ${local.database} rentals && ls -All && tar cvf '$LAST_TAR' rentals && chmod -R 0666 '$LAST_TAR' && rm -rf rentals'
  
    ${var.network_params.env != "dev" ? "" : "rsync -arvc -e \"ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null\" $DIR_EXCHANGE/$LAST_TAR backup-dev@storage.karta.com:/home/backup-dev/" } 
    ${var.network_params.env != "prod" ? "" : "rsync -arvc -e \"ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null\" $DIR_EXCHANGE/$LAST_TAR backup-prod@storage.karta.com:/home/backup-prod/" } 
    
    ${var.network_params.env != "dev" && var.network_params.env != "prod" ? "" : "rm -f $DIR_EXCHANGE/$LAST_TAR" }
else 
   echo "ERROR: mongodb docker process was not found"
   exit 1
fi
EOF
   filename = "./bin/mongodb-backup.sh"
   file_permission = "0777"
}

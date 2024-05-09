resource "local_file" "download" {
   content = <<EOF
#!/usr/bin/env bash
set -ex

export DIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# source $DIR/mongo-wait.sh

export TAR_FOLDER=rentals
export DIR_EXCHANGE=${local.volume_exchange}

export PID=$(docker ps --filter "label=host=${local.host}" --format "{{.ID}}")
if [[ "$PID" != "" ]]; then
    cd $DIR_EXCHANGE

    sudo rm -rf rentals || true

    if [[ "$LAST_TAR" == "" ]]; then
       export SSH_HOST=$(curl -s https://stat.karta.com/hosts/ | grep dev.internal.karta.com | cut -f1 -d' ')
       export REMOTE_PATH=$(ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null karta@$SSH_HOST 'find /data/exchange/ -type f -name *.tar | sort | tail -n1')
       export LAST_TAR=$(echo $REMOTE_PATH | rev | cut -d'/' -f1 | rev)
       if [[ -z "$DIR_EXCHANGE/LAST_TAR" ]]; then
           echo "ERROR: Last tar file was not found"
           exit 1
       fi
    fi

    if [[ -f "$DIR_EXCHANGE/$LAST_TAR" ]]; then
        echo "Already downloaded to $DIR_EXCHANGE/$LAST_TAR"
        cd $DIR_EXCHANGE
        tar xvf $DIR_EXCHANGE/$LAST_TAR
    else
        echo "Downloading to $DIR_EXCHANGE/$LAST_TAR"
        scp -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null karta@$SSH_HOST:$REMOTE_PATH $DIR_EXCHANGE/$LAST_TAR
        cd $DIR_EXCHANGE
        tar xvf $DIR_EXCHANGE/$LAST_TAR
    fi

    docker exec -it $PID bash -c 'mongorestore --gzip --drop --username=$MONGO_INITDB_ROOT_USERNAME --password=$MONGO_INITDB_ROOT_PASSWORD --authenticationDatabase=admin --db=$MONGO_INITDB_DATABASE --dir=/exchange/rentals'
    # rm -f $LAST_TAR
    echo "Mongo dump installed successfully"
else 
   echo "ERROR: mongodb docker process was not found"
   exit 1
fi
EOF
   filename = "./bin/mongodb-download.sh"
   file_permission = "0777"
}


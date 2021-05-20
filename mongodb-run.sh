#!/bin/bash

readonly INSTALL_DIR="/data"
readonly MONGODB_CONF_FILES=("mongodbPrimary.conf" "mongodbSecondary1.conf" "mongodbSecondary2.conf")
readonly MONGODB_NODES=("mongodbPrimary" "mongodbSecondary1" "mongodbSecondary2")
readonly MONGODB_PORTS=(27017 27018 27019)
readonly MONGODB_ROOT_USER="db_root"
readonly MONGODB_ROOT_PASSWORD="password"

## Süreçleri öldürür
for i in "${MONGODB_PORTS[@]}"
do
mongo --port $i admin --eval 'db.auth("'"$MONGODB_ROOT_USER"'", "'"$MONGODB_ROOT_PASSWORD"'"); db.shutdownServer()'
done

# ReplicaSeti Başlatır
for i in "${MONGODB_CONF_FILES[@]}"
do
  mongod --config "$INSTALL_DIR/mongo/conf/$i" --fork
done

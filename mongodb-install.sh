INSTALL_DIR="/data"
MONGODB_CONF_FILES=("mongodbPrimary.conf" "mongodbSecondary1.conf" "mongodbSecondary2.conf")
MONGODB_NODES=("mongodbPrimary" "mongodbSecondary1" "mongodbSecondary2")
MONGODB_PORTS=(27017 27018 27019)
MONGODB_ROOT_USER="db_root"
MONGODB_ROOT_PASSWORD="password"
ID=$(egrep '^(ID)=' /etc/os-release)
OS=${ID:3}
REPO_FEDORA=/etc/yum.repos.d/mongodb-org-4.4.repo

create_dir(){
  mkdir -p "$INSTALL_DIR/mongo/db"
  chmod  777 "$INSTALL_DIR/mongo/db"
  mkdir -p "$INSTALL_DIR/mongo/logs"
  mkdir -p "$INSTALL_DIR/mongo/conf"
  mkdir -p "$INSTALL_DIR/db"
  for i in "${MONGODB_NODES[@]}"
  do
  mkdir "$INSTALL_DIR/mongo/db/$i"
  done
}

setup_mongodb(){

  if [[ $1 = fedora ]]
  then
   echo "install mongodb"
   cat <<EOF > $REPO_FEDORA
      name=MongoDB Repository
      baseurl=https://repo.mongodb.org/yum/redhat/8Server/mongodb-org/4.4/x86_64/
      gpgcheck=0
      enabled=1
      gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOF
   yum update && yum install -y mongodb-org mongodb-org-tools mongodb-org-shell

   

  elif [[ $1 = ubuntu ]]
  then
  echo "install mongodb"
  curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc |  apt-key add - &&
  echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" |  tee /etc/apt/sources.list.d/mongodb-org-4.4.list
  apt update && apt install -y mongodb-org
  else
  echo "Not Found Operation System"
  exit 1
  fi
}


configuration_data(){
   chown -R mongodb:mongodb  "$INSTALL_DIR"

    for i in "${MONGODB_CONF_FILES[@]}"
    do	
    	touch "$INSTALL_DIR/mongo/conf/$i"	
    done

    ITER=1
    for i in "${MONGODB_NODES[@]}"
    do
    echo "$INSTALL_DIR/mongo/conf/$i.conf"
    echo "
    systemLog:
      destination: file
      path: $INSTALL_DIR/mongo/logs/$i.log
      logAppend: true

    storage:
      dbPath: $INSTALL_DIR/mongo/db/$i
      journal:
        enabled: true

    net:
      port: ${MONGODB_PORTS[$ITER -1 ]}
      bindIp: 0.0.0.0
    " > "$INSTALL_DIR/mongo/conf/$i.conf"
    ITER=$(expr $ITER + 1)
    done
    chown -R mongodb:mongodb  "$INSTALL_DIR"

    
}


start_server(){
        for i in "${MONGODB_CONF_FILES[@]}"
        do
          mongod --config "$INSTALL_DIR/mongo/conf/$i" --fork
        done
}


create_mongo_user(){
    for i in "${MONGODB_PORTS[@]}"
    do
    mongo --port $i admin --eval 'db.createUser({user: "'"$MONGODB_ROOT_USER"'", pwd: "'"$MONGODB_ROOT_PASSWORD"'", roles: [ { role: "root", db: "admin" } ]})'
    done
}

openssl_create_key(){
  openssl rand -base64 756 > "$INSTALL_DIR/mongo/.mdbia"
  chmod 400 "$INSTALL_DIR/mongo/.mdbia"
}

mongo_reconfigure(){
    cd "$INSTALL_DIR/mongo/conf"
    for i in *.conf
    do 
    echo "
    security:
      authorization: enabled
      keyFile: $INSTALL_DIR/mongo/.mdbia

    replication:
      replSetName: rs1
    " >> $i
    done
}

reboot_mongodb(){
for i in "${MONGODB_PORTS[@]}"
do
mongo --port $i admin --eval 'db.auth("'"$MONGODB_ROOT_USER"'", "'"$MONGODB_ROOT_PASSWORD"'"); db.shutdownServer()'
done

for i in "${MONGODB_CONF_FILES[@]}"
do
  mongod --config "$INSTALL_DIR/mongo/conf/$i" --fork
done
}


replica_Set_mongo(){
mongo --port 27017 admin --eval 'db.auth("'"$MONGODB_ROOT_USER"'", "'"$MONGODB_ROOT_PASSWORD"'"); rs.initiate({"_id":"rs1","members":[{"_id":1,"host":"127.0.0.1:27017"}]})'
mongo --port 27017 admin --eval 'db.auth("'"$MONGODB_ROOT_USER"'", "'"$MONGODB_ROOT_PASSWORD"'"); rs.add("127.0.0.1:27018")'
mongo --port 27017 admin --eval 'db.auth("'"$MONGODB_ROOT_USER"'", "'"$MONGODB_ROOT_PASSWORD"'"); rs.add("127.0.0.1:27019")'
mongo --port 27017 admin --eval 'db.auth("'"$MONGODB_ROOT_USER"'", "'"$MONGODB_ROOT_PASSWORD"'"); cfg = rs.conf(); cfg.members[0].priority = 10; cfg.members[1].priority = 1; cfg.members[2].priority = 1; rs.reconfig(cfg)'
}

create_dir
setup_mongodb $OS
configuration_data
start_server
create_mongo_user
openssl_create_key
mongo_reconfigure
reboot_mongodb
replica_Set_mongo

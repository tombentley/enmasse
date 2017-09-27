#!/bin/sh

. $ARTEMIS_HOME/bin/partitionPV.sh
. $ARTEMIS_HOME/bin/dynamic_resources.sh

export BROKER_IP=`hostname -I | cut -f 1 -d ' '`
CONFIG_TEMPLATES=/config_templates
JAVA_OPTS="-Djava.net.preferIPv4Stack=true"

if [ -n "$ADMIN_SERVICE_HOST" ]
then
    export QUEUE_SCHEDULER_SERVICE_HOST=$ADMIN_SERVICE_HOST
    export QUEUE_SCHEDULER_SERVICE_PORT=$ADMIN_SERVICE_PORT_QUEUE_SCHEDULER
fi

MAX_HEAP=`get_heap_size`
if [ -n "$MAX_HEAP" ]; then
  JAVA_OPTS="-Xms${MAX_HEAP}m -Xmx${MAX_HEAP}m $JAVA_OPTS"
fi

# Make sure that we use /dev/urandom
JAVA_OPTS="${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom"

# Parameters are
# - instance directory
# - instance id
function configure() {
    local instanceDir=$1
    local instanceId=$2
    export CONTAINER_ID=$HOSTNAME
    if [ ! -d "$INSTANCE" ]; then
        $ARTEMIS_HOME/bin/artemis create $instanceDir --user admin --password admin --role admin --allow-anonymous --java-options "$JAVA_OPTS"
        cp $CONFIG_TEMPLATES/broker_header.xml /tmp/broker.xml
        if [ -n "$TOPIC_NAME" ]; then
            cat $CONFIG_TEMPLATES/broker_topic.xml >> /tmp/broker.xml
        elif [ -n $QUEUE_NAME ] && [ "$QUEUE_NAME" != "" ]; then
            cat $CONFIG_TEMPLATES/broker_queue.xml >> /tmp/broker.xml
        else
            cat $CONFIG_TEMPLATES/broker_queue_colocated.xml >> /tmp/broker.xml
        fi
        cat $CONFIG_TEMPLATES/broker_footer.xml >> /tmp/broker.xml

        export KEYSTORE_PATH=$instanceDir/etc/enmasse-keystore.jks
        export TRUSTSTORE_PATH=$instanceDir/etc/enmasse-truststore.jks
    
        envsubst < /tmp/broker.xml > $instanceDir/etc/broker.xml
        cp $CONFIG_TEMPLATES/bootstrap.xml $instanceDir/etc/bootstrap.xml

        # Convert certs
        openssl pkcs12 -export -passout pass:enmasse -in /etc/enmasse-certs/tls.crt -inkey /etc/enmasse-certs/tls.key -chain -CAfile /etc/enmasse-certs/ca.crt -name "io.enmasse" -out /tmp/enmasse-keystore.p12

        keytool -importkeystore -srcstorepass enmasse -deststorepass enmasse -destkeystore $KEYSTORE_PATH -srckeystore /tmp/enmasse-keystore.p12 -srcstoretype PKCS12
        keytool -import -noprompt -file /etc/enmasse-certs/ca.crt -alias firstCA -deststorepass enmasse -keystore $TRUSTSTORE_PATH

        cp $CONFIG_TEMPLATES/logging.properties $instanceDir/etc/logging.properties

    fi

}

# Parameters are
# - instance directory
# - instance id
function runServer() {
  local instanceDir=$1
  local instanceId=$2
  echo "Configuring instance $instanceId in directory $instanceDir"
  configure $instanceDir $instanceId
  echo "Running instance $instanceId"
  exec $instanceDir/bin/artemis run
}

DATA_DIR="/var/run/artemis/"
partitionPV "${DATA_DIR}" "${ARTEMIS_LOCK_TIMEOUT:-30}"

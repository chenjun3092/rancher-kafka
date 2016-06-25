#!/usr/bin/env sh

SERVICE_TMPL=${SERVICE_TMPL:-"/opt/tools/confd/etc/templates/server.properties.tmpl"}

KAFKA_HEAP_OPTS=${JVMFLAGS:-"-Xmx1G -Xms1G"}
KAFKA_ADVERTISE_PORT=${KAFKA_ADVERTISE_PORT:-"9092"}
KAFKA_LISTENER=${KAFKA_LISTENER:-"PLAINTEXT://0.0.0.0:"${KAFKA_ADVERTISE_PORT}}
KAFKA_LOG_DIRS=${KAFKA_LOG_DIRS:-${SERVICE_HOME}"/logs"}
KAFKA_LOG_FILE=${KAFKA_LOG_FILE:-${KAFKA_LOG_DIRS}"/kafkaServer.out"}
KAFKA_LOG_RETENTION_HOURS=${KAFKA_LOG_RETENTION_HOURS:-"168"}
KAFKA_NUM_PARTITIONS=${KAFKA_NUM_PARTITIONS:-"1"}

if [ "$ADVERTISE_PUB_IP" == "false" ]; then 
	KAFKA_ADVERTISE_LISTENER=${KAFKA_ADVERTISE_LISTENER:-${KAFKA_LISTENER}}
else
	KAFKA_ADVERTISE_LISTENER=${KAFKA_ADVERTISE_LISTENER:-'PLAINTEXT://{{getv "/self/host/agent_ip"}}:'${KAFKA_ADVERTISE_PORT}}
fi

cat << EOF > ${SERVICE_TMPL}
############################# Server Basics #############################
broker.id={{getv "/self/container/service_index"}}
############################# Socket Server Settings #############################
listeners=${KAFKA_LISTENER}
advertised.listeners=${KAFKA_ADVERTISE_LISTENER}
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
############################# Log Basics #############################
log.dirs=${KAFKA_LOG_DIRS}
num.partitions=${KAFKA_NUM_PARTITIONS}
num.recovery.threads.per.data.dir=1
############################# Log Flush Policy #############################
#log.flush.interval.messages=10000
#log.flush.interval.ms=1000
############################# Log Retention Policy #############################
log.retention.hours=${KAFKA_LOG_RETENTION_HOURS}
#log.retention.bytes=1073741824
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
log.cleaner.enable=true
############################# Connect Policy #############################{{ \$zk_link := split (getenv "ZK_SERVICE") "/" }}{{\$zk_stack := index \$zk_link 0}}{{ \$zk_service := index \$zk_link 1}} 
zookeeper.connect={{range \$i, \$e := ls (printf "/stacks/%s/services/%s/containers" \$zk_stack \$zk_service)}}{{if \$i}},{{end}}{{getv (printf "/stacks/%s/services/%s/containers/%s/primary_ip" \$zk_stack \$zk_service \$e)}}:2181{{end}}
zookeeper.connection.timeout.ms=6000
EOF
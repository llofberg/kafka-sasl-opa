Kafka in Docker with SSL/SASL and OPA authorization
===

Create certificates for SSL/SASL/Kerberos

    (cd secrets ; ./create-certs.sh)

Build Java clients

    mvn clean package

Start OPA, Kerberos, Zookeeper, Kafka broker, a producer and a consumer.

    docker-compose up -d
    docker logs producer

OPA policy stops producer and consumer from creating the topic "X" so they keep failing.

Create the topic from the broker box (as user kafka).

    docker exec -it broker bash -c "kafka-topics --zookeeper zookeeper --create --topic X --partitions 1 --replication-factor 1"

Soon after the topic is created the producer and the consumer can access it.

Note that consumer also queries OPA for policy decision on the received message.

    docker logs consumer

    docker-compose down

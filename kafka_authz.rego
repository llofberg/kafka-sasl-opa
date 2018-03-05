package kafka.authz

# Kafka authorize request
import input as kafka_request

default allow = false

topics = {
  "X" : {
    "Read"     : ["saslconsumer"],
    "Write"    : ["saslproducer"],
    "Describe" : ["saslconsumer", "saslproducer"],
  }
}

groups = {
  "ssl-sasl-host" : {
    "Read"     : ["saslconsumer"] ,
    "Write"    : ["saslconsumer"] ,
    "Describe" : ["saslconsumer", "saslproducer"],
  }
}

super_users = [
  "kafka"
]

allow {
  super_users[_] = kafka_request.session.principal.name
}

allow {
  kafka_request.resource.resourceType.name = "Topic"
  kafka_request.session.principal.principalType = "User"
  topics[kafka_request.resource.name][kafka_request.operation.name][_] =
    kafka_request.session.principal.name
}

allow {
  kafka_request.resource.resourceType.name = "Group"
  kafka_request.session.principal.principalType = "User"
  groups[kafka_request.resource.name][kafka_request.operation.name][_] =
    kafka_request.session.principal.name
}

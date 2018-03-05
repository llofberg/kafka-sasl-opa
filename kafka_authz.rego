package kafka.authz

# Kafka authorize request

clusters = {"Cluster:kafka-cluster": ["t1"]}

import input as kafka_request

# {"input":
#   {
#      "principal" : {"principalType":"User","name":"ANONYMOUS"},
#      "operation" : {"name":"ClusterAction"},
#      "resource"  : {"resourceType":{"name":"Cluster","errorCode":31},"name":"kafka-cluster"},
#      "session"   : {"clientAddress":"172.20.0.4","sanitizedUser":"ANONYMOUS",
#                      {"principal":{"principalType":"User","name":"ANONYMOUS"}}
#                    }
#    }
# }
#
# Resource types: Cluster, Group, Topic
#
# Operations
# - Cluster: ClusterAction, Create, Describe
# - Group: Describe, Read
# - Topic: Alter, Delete, Describe, Read, Write
#

default allow = false

# Allow user kafka everything
allow {
  kafka_request.session.principal.name = "kafka"
}

# Allow saslproducer to write to topic X
allow {
  kafka_request.session.principal.principalType = "User"
  kafka_request.session.principal.name = "saslproducer"
  kafka_request.resource.resourceType.name = "Topic"
  kafka_request.resource.name = "X"
  kafka_request.operation.name = "Write"
}

# Allow saslproducer to describe topic X
allow {
  kafka_request.resource.resourceType.name = "Topic"
  kafka_request.resource.name = "X"
  kafka_request.session.principal.principalType = "User"
  kafka_request.session.principal.name = "saslproducer"
  kafka_request.operation.name = "Describe"
}

# Allow saslconsumer to read from topic X
allow {
  kafka_request.resource.resourceType.name = "Topic"
  kafka_request.resource.name = "X"
  kafka_request.session.principal.principalType = "User"
  kafka_request.session.principal.name = "saslconsumer"
  kafka_request.operation.name = "Read"
}

# Allow saslconsumer to describe topic X
allow {
  kafka_request.resource.resourceType.name = "Topic"
  kafka_request.resource.name = "X"
  kafka_request.session.principal.principalType = "User"
  kafka_request.session.principal.name = "saslconsumer"
  kafka_request.operation.name = "Describe"
}

# Allow saslconsumer to describe consumer group ssl-sasl-host
allow {
  kafka_request.resource.resourceType.name = "Group"
  kafka_request.resource.name = "ssl-sasl-host"
  kafka_request.session.principal.principalType = "User"
  kafka_request.session.principal.name = "saslconsumer"
  kafka_request.operation.name = "Describe"
}

# Allow saslconsumer to read consumer group ssl-sasl-host
allow {
  kafka_request.resource.resourceType.name = "Group"
  kafka_request.resource.name = "ssl-sasl-host"
  kafka_request.session.principal.principalType = "User"
  kafka_request.session.principal.name = "saslconsumer"
  kafka_request.operation.name = "Read"
}

# Allow saslconsumer to write consumer group ssl-sasl-host
allow {
  kafka_request.resource.resourceType.name = "Group"
  kafka_request.resource.name = "ssl-sasl-host"
  kafka_request.session.principal.principalType = "User"
  kafka_request.session.principal.name = "saslconsumer"
  kafka_request.operation.name = "Write"
}

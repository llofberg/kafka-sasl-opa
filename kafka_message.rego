package kafka.message

# Kafka authorize request
import input as kafka_message

default allow = false

allow {
  is_string(kafka_message["k"])
}

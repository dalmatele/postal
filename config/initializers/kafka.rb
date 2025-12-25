require "rdkafka"

kafka_config = {
  "bootstrap.servers": "42.112.28.219:9092",
  "client.id": "rails-app-producer",
  # "security.protocol": "sasl_plaintext",#"sasl_ssl",
  # "sasl.mechanism": "PLAIN",#"SCRAM-SHA-256",
  # "sasl.username": "username",
  # "sasl.password": "password"
}

KAFKA_PRODUCER = Rdkafka::Config.new(kafka_config).producer
at_exit {KAFKA_PRODUCER.close}

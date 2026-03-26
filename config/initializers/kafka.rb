require "rdkafka"
require_relative "../../lib/postal/config"

kafka_config = {
  # "bootstrap.servers" => ENV.fetch("KAFKA_BROKERS"),
  # "client.id" => ENV.fetch("KAFKA_CLIENT_ID"),
  # "security.protocol" => ENV.fetch("KAFKA_PROTOCOL),
  # "sasl.mechanisms": "PLAIN",#"SCRAM-SHA-256",
  # "sasl.username" =>  ENV.fetch("KAFKA_USERNAME"),
  # "sasl.password" => ENV.fetch("KAFKA_PASSWORD"),
  "bootstrap.servers" => Postal::Config.kafka.bootstrap,
  "client.id" => Postal::Config.kafka.enabled,
  "acks" => "all",
  "enable.idempotence" => "true"
  }
if Postal::Config.kafka.enabled
  begin
    KAFKA_PRODUCER = Rdkafka::Config.new(kafka_config).producer
    puts "Kafka connected!!!"
  rescue StandardError => e
    puts "Kafka connects error: #{e.message}"
  end
end
at_exit {KAFKA_PRODUCER.close if defined? (KAFKA_PRODUCER)}

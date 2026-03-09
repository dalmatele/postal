class KafkaPublisherService

  #Send async data to Kafka
  def self.publish_async(topic, message)
    KAFKA_PRODUCER.produce(
      topic: topic,
      payload: message.to_json
    )
  rescue StandardError => e
    Rails.logger.error("Can not connect to Kafka: #{e.message}")

  end

  def self.publish(topic, message)
    begin
      payload = message.is_a?(String) ? message : message.to_json
      delivery_handle = KAFKA_PRODUCER.produce(
        topic: topic,
        payload: payload,
        key: nil
      )
      delivery_handle.wait
      puts "Sent successfully '#{topic} : #{payload}'"
      true
    rescue Rdkafka::RdkafkaError => e
      Rails.logger.error "Kafka Error: #{e.message} (Code: #{e.code})"
      false
    rescue StandardError => e
      Rails.logger.error "Error: #{e.message}"
      false
    ensure

    end

  end
end
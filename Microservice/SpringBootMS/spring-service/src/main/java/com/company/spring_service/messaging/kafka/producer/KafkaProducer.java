package com.company.spring_service.messaging.kafka.producer;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(
        name = "messaging.provider",
        havingValue = "kafka"
)
public class KafkaProducer {

    private final KafkaTemplate<String, Object> kafkaTemplate;

    /**
     * Publish a message to Kafka topic.
     *
     * @param topic   Kafka topic name
     * @param key     Message key
     * @param message Event payload
     */
    public void publish(
            String topic,
            String key,
            Object message) {

        log.info(
                "Publishing message to Kafka | Topic={} | Key={} | Payload={}",
                topic,
                key,
                message
        );

        kafkaTemplate.send(
                topic,
                key,
                message
        );

        log.info(
                "Successfully published message to Kafka | Topic={} | Key={}",
                topic,
                key
        );
    }
}

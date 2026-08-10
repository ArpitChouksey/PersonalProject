package com.company.spring_service.messaging.kafka.consumer;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@ConditionalOnProperty(
        name = "messaging.provider",
        havingValue = "kafka"
)
public class KafkaConsumer {

    @KafkaListener(
            topics = "${messaging.destination}",
            groupId = "${KAFKA_CONSUMER_GROUP_ID:user-service-group}"
    )
    public void consume(String message) {

        log.info(
                "Received Kafka Message: {}",
                message
        );
    }
}

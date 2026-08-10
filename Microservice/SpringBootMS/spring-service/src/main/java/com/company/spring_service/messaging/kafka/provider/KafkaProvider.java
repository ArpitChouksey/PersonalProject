package com.company.spring_service.messaging.kafka.provider;

import com.company.spring_service.messaging.broker.MessagingProvider;
import com.company.spring_service.messaging.kafka.producer.KafkaProducer;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(
        name = "messaging.provider",
        havingValue = "kafka"
)
public class KafkaProvider implements MessagingProvider {

    private final KafkaProducer kafkaProducer;

    public KafkaProvider(
            KafkaProducer kafkaProducer) {

        this.kafkaProducer = kafkaProducer;
    }

    @Override
    public String getProviderName() {
        return "kafka";
    }

    @Override
    public void publish(
            String destination,
            String key,
            Object payload) {

        kafkaProducer.publish(
                destination,
                key,
                payload
        );
    }
}

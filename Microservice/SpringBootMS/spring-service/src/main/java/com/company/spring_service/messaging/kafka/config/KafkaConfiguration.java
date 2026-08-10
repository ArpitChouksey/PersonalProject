package com.company.spring_service.messaging.kafka.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;

@Configuration
@EnableKafka
@ConditionalOnProperty(
        name = "messaging.provider",
        havingValue = "kafka"
)
public class KafkaConfiguration {
}

package com.company.spring_service.messaging.amazonmq.producer;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@ConditionalOnProperty(
        name = "messaging.provider",
        havingValue = "amazonmq"
)
public class AmazonMQProducer {

    private final JmsTemplate jmsTemplate;

    private final ObjectMapper objectMapper;

    public AmazonMQProducer(
            JmsTemplate jmsTemplate,
            ObjectMapper objectMapper) {

        this.jmsTemplate = jmsTemplate;
        this.objectMapper = objectMapper;
    }

    public void publish(
            String queueName,
            Object payload) {

        try {

            String json =
                    objectMapper.writeValueAsString(payload);

            log.info(
                    "Publishing message to Amazon MQ | Queue={} | Payload={}",
                    queueName,
                    json
            );

            jmsTemplate.convertAndSend(
                    queueName,
                    json
            );

            log.info(
                    "Message published successfully to Amazon MQ"
            );

        } catch (JsonProcessingException e) {

            throw new RuntimeException(
                    "Failed to serialize message",
                    e
            );
        }
    }
}

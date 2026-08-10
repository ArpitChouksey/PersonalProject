package com.company.spring_service.messaging.amazonmq.consumer;

import com.company.spring_service.event.UserCreatedEvent;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@ConditionalOnProperty(
        name = "messaging.provider",
        havingValue = "amazonmq"
)
public class AmazonMQConsumer {

    private final ObjectMapper objectMapper;

    public AmazonMQConsumer(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @JmsListener(destination = "${amazonmq.queue}")
    public void receive(String json) {

        try {

            UserCreatedEvent event =
                    objectMapper.readValue(
                            json,
                            UserCreatedEvent.class
                    );

            log.info(
                    "Amazon MQ Message Received : {}",
                    event.getUserId()
            );

            /*
             * Later:
             *
             * auditService.save(event);
             */

        } catch (Exception e) {

            log.error(
                    "Failed to process Amazon MQ message",
                    e
            );
        }
    }
}

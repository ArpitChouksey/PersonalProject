package com.company.spring_service.messaging.kafka.consumer;

import com.company.spring_service.event.UserCreatedEvent;
import com.company.spring_service.service.AuditService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(
        name = "messaging.provider",
        havingValue = "kafka"
)
public class AuditConsumer {

    private final AuditService auditService;

    @KafkaListener(
            topics = "${messaging.destination}",
            groupId = "${KAFKA_AUDIT_CONSUMER_GROUP_ID:audit-group}"
    )
    public void consume(UserCreatedEvent event) {

        log.info(
                "Audit Consumer received UserCreatedEvent : {}",
                event.getUserId()
        );

        auditService.saveUserCreatedAudit(event);

        log.info(
                "Audit record saved successfully for User : {}",
                event.getUserId()
        );
    }
}

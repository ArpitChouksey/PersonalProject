package com.company.spring_service.event;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public abstract class BaseEvent {

    private String eventId;

    private EventType eventType;

    private Instant eventTime;

    private String correlationId;

    private String version;

    private String source;

    protected BaseEvent(EventType eventType, String source) {

        this.eventId = UUID.randomUUID().toString();
        this.eventType = eventType;
        this.eventTime = Instant.now();
        this.correlationId = UUID.randomUUID().toString();
        this.version = "1.0";
        this.source = source;
    }
}

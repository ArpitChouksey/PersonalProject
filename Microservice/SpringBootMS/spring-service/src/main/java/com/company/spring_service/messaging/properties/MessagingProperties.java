package com.company.spring_service.messaging.properties;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "messaging")
public class MessagingProperties {

    private String provider;

    private String destination;

    private String source;
}

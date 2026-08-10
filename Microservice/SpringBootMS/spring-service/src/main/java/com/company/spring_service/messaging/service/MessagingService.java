package com.company.spring_service.messaging.service;

import com.company.spring_service.messaging.factory.MessagingProviderFactory;
import com.company.spring_service.messaging.properties.MessagingProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class MessagingService {

    private final MessagingProviderFactory messagingProviderFactory;

    private final MessagingProperties messagingProperties;

    /**
     * Publish a message using the configured messaging provider.
     *
     * Destination is read from application.properties.
     */
    public void publish(
            String key,
            Object message) {

        messagingProviderFactory
                .getProvider()
                .publish(
                        messagingProperties.getDestination(),
                        key,
                        message
                );
    }
}

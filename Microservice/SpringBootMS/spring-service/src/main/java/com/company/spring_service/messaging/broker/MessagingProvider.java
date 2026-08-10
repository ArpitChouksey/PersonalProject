package com.company.spring_service.messaging.broker;

public interface MessagingProvider {

    String getProviderName();

    void publish(
            String destination,
            String key,
            Object payload
    );

}

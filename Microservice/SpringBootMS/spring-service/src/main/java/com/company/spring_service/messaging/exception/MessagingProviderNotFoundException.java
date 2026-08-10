package com.company.spring_service.messaging.exception;

public class MessagingProviderNotFoundException extends RuntimeException {

    public MessagingProviderNotFoundException(String provider) {

        super("Unsupported messaging provider : " + provider);

    }

}

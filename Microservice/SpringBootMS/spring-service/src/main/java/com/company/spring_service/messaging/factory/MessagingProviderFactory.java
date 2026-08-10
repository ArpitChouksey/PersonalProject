package com.company.spring_service.messaging.factory;

import com.company.spring_service.messaging.broker.MessagingProvider;
import com.company.spring_service.messaging.properties.MessagingProperties;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Component
public class MessagingProviderFactory {

    private final Map<String, MessagingProvider> providers;

    private final MessagingProperties properties;

    public MessagingProviderFactory(
            List<MessagingProvider> providerList,
            MessagingProperties properties) {

        this.properties = properties;

        this.providers = providerList
                .stream()
                .collect(Collectors.toMap(
                        MessagingProvider::getProviderName,
                        provider -> provider
                ));
    }

    public MessagingProvider getProvider() {

        MessagingProvider provider =
                providers.get(properties.getProvider());

        if (provider == null) {

            throw new IllegalArgumentException(
                    "Unsupported messaging provider : "
                            + properties.getProvider()
            );
        }

        return provider;
    }
}

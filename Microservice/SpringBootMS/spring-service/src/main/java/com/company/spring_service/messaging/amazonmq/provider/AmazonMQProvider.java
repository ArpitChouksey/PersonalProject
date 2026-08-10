package com.company.spring_service.messaging.amazonmq.provider;

import com.company.spring_service.messaging.amazonmq.producer.AmazonMQProducer;
import com.company.spring_service.messaging.broker.MessagingProvider;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(
        name = "messaging.provider",
        havingValue = "amazonmq"
)
public class AmazonMQProvider implements MessagingProvider {

    private final AmazonMQProducer producer;

    public AmazonMQProvider(
            AmazonMQProducer producer) {

        this.producer = producer;
    }

    @Override
    public String getProviderName() {
        return "amazonmq";
    }

    @Override
    public void publish(
            String destination,
            String key,
            Object payload) {

        producer.publish(
                destination,
                payload
        );
    }
}

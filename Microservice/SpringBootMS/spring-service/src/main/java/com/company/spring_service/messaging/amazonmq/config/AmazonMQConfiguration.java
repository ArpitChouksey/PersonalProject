package com.company.spring_service.messaging.amazonmq.config;

import jakarta.jms.ConnectionFactory;
import org.apache.activemq.ActiveMQConnectionFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jms.core.JmsTemplate;

@Configuration
@ConditionalOnProperty(
        name = "messaging.provider",
        havingValue = "amazonmq"
)
public class AmazonMQConfiguration {

    @Value("${amazonmq.broker-url}")
    private String brokerUrl;

    @Value("${amazonmq.username}")
    private String username;

    @Value("${amazonmq.password}")
    private String password;

    @Bean
    public ConnectionFactory amazonMQConnectionFactory() {

        ActiveMQConnectionFactory factory =
                new ActiveMQConnectionFactory();

        factory.setBrokerURL(brokerUrl);
        factory.setUserName(username);
        factory.setPassword(password);

        return factory;
    }

    @Bean
    public JmsTemplate jmsTemplate(
            ConnectionFactory amazonMQConnectionFactory) {

        return new JmsTemplate(amazonMQConnectionFactory);
    }
}

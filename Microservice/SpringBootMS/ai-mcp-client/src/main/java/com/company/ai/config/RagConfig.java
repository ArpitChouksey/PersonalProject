package com.company.ai.config;

import org.springframework.ai.chat.client.advisor.vectorstore.QuestionAnswerAdvisor;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RagConfig {

    @Bean
    public QuestionAnswerAdvisor questionAnswerAdvisor(
            VectorStore vectorStore) {

        return QuestionAnswerAdvisor
                .builder(vectorStore)
                .build();
    }
}

package com.company.ai.service;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.vectorstore.QuestionAnswerAdvisor;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class AIChatService {

    private final ChatClient chatClient;
    private final ToolCallbackProvider mcpTools;
    private final QuestionAnswerAdvisor questionAnswerAdvisor;
    private final String systemPrompt;

    public AIChatService(
            ChatClient.Builder chatClientBuilder,
            ToolCallbackProvider mcpTools,
            QuestionAnswerAdvisor questionAnswerAdvisor,
            @Value("${ai.system-prompt}") String systemPrompt) {

        this.chatClient = chatClientBuilder.build();
        this.mcpTools = mcpTools;
        this.questionAnswerAdvisor = questionAnswerAdvisor;
        this.systemPrompt = systemPrompt;
    }

    public String chat(String message) {

        return chatClient
                .prompt()
                .system(systemPrompt)
                .user(message)
                .advisors(questionAnswerAdvisor)
                .toolCallbacks(mcpTools)
                .call()
                .content();
    }
}

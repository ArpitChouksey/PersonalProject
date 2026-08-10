package com.company.spring_service.mcp.config;

import com.company.spring_service.mcp.service.UserMcpService;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.ai.tool.method.MethodToolCallbackProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class McpToolConfig {

    @Bean
    public ToolCallbackProvider userMcpTools(
            UserMcpService userMcpService) {

        return MethodToolCallbackProvider.builder()
                .toolObjects(userMcpService)
                .build();
    }
}

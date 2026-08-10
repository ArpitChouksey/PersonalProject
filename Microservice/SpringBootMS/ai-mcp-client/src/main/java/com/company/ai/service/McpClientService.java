package com.company.ai.service;

import org.springframework.ai.tool.ToolCallback;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;

@Service
public class McpClientService {

    private final ToolCallbackProvider toolCallbackProvider;

    public McpClientService(
            ToolCallbackProvider toolCallbackProvider) {

        this.toolCallbackProvider = toolCallbackProvider;
    }

    public List<String> getAvailableTools() {

        ToolCallback[] callbacks =
                toolCallbackProvider.getToolCallbacks();

        return Arrays.stream(callbacks)
                .map(ToolCallback::getToolDefinition)
                .map(toolDefinition ->
                        toolDefinition.name())
                .toList();
    }
}

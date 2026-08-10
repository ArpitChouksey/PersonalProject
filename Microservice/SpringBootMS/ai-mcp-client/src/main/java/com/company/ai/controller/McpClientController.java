package com.company.ai.controller;

import com.company.ai.service.McpClientService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class McpClientController {

    private final McpClientService mcpClientService;

    public McpClientController(
            McpClientService mcpClientService) {

        this.mcpClientService = mcpClientService;
    }

    @GetMapping("/mcp/tools")
    public List<String> getTools() {

        return mcpClientService.getAvailableTools();
    }
}

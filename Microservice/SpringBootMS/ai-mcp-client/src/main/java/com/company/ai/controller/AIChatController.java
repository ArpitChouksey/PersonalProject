package com.company.ai.controller;

import com.company.ai.service.AIChatService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AIChatController {

    private final AIChatService aiChatService;

    public AIChatController(AIChatService aiChatService) {
        this.aiChatService = aiChatService;
    }

    @GetMapping("/ai/chat")
    public String chat(
            @RequestParam String message) {

        return aiChatService.chat(message);
    }
}

package com.company.ai.controller;

import com.company.ai.service.ProjectKnowledgeService;
import org.springframework.ai.document.Document;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.util.List;

@RestController
public class RagController {

    private final ProjectKnowledgeService projectKnowledgeService;

    public RagController(ProjectKnowledgeService projectKnowledgeService) {
        this.projectKnowledgeService = projectKnowledgeService;
    }

    /**
     * Load project knowledge from the configured knowledge location
     * into the configured VectorStore.
     */
    @PostMapping("/rag/load")
    public String loadKnowledge() throws IOException {

        int chunks = projectKnowledgeService.loadKnowledge();

        return "Project knowledge loaded successfully. "
                + "Chunks created: " + chunks;
    }

    /**
     * Directly search the VectorStore.
     *
     * This endpoint is mainly useful for verifying RAG retrieval
     * independently from the LLM.
     */
    @GetMapping("/rag/search")
    public List<Document> searchKnowledge(
            @RequestParam String query) {

        return projectKnowledgeService.search(query);
    }
}

package com.company.ai.service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

import org.springframework.ai.document.Document;
import org.springframework.ai.transformer.splitter.TokenTextSplitter;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.ResourcePatternResolver;
import org.springframework.stereotype.Service;

@Service
public class ProjectKnowledgeService {

    private final VectorStore vectorStore;
    private final ResourcePatternResolver resourcePatternResolver;

    private final String knowledgeLocation;
    private final String projectName;

    private final int chunkSize;
    private final int minChunkSizeChars;
    private final int minChunkLengthToEmbed;
    private final int maxNumChunks;
    private final boolean keepSeparator;

    public ProjectKnowledgeService(
            VectorStore vectorStore,
            ResourcePatternResolver resourcePatternResolver,

            @Value("${rag.knowledge-location}")
            String knowledgeLocation,

            @Value("${rag.project-name}")
            String projectName,

            @Value("${rag.chunk-size}")
            int chunkSize,

            @Value("${rag.min-chunk-size-chars}")
            int minChunkSizeChars,

            @Value("${rag.min-chunk-length-to-embed}")
            int minChunkLengthToEmbed,

            @Value("${rag.max-num-chunks}")
            int maxNumChunks,

            @Value("${rag.keep-separator}")
            boolean keepSeparator) {

        this.vectorStore = vectorStore;
        this.resourcePatternResolver = resourcePatternResolver;

        this.knowledgeLocation = knowledgeLocation;
        this.projectName = projectName;

        this.chunkSize = chunkSize;
        this.minChunkSizeChars = minChunkSizeChars;
        this.minChunkLengthToEmbed = minChunkLengthToEmbed;
        this.maxNumChunks = maxNumChunks;
        this.keepSeparator = keepSeparator;
    }

    /**
     * Loads all configured Markdown knowledge files,
     * splits them into chunks and stores the embeddings
     * in the configured VectorStore.
     */
    public int loadKnowledge() throws IOException {

        Resource[] resources =
                resourcePatternResolver.getResources(knowledgeLocation);

        List<Document> documents = new ArrayList<>();

        for (Resource resource : resources) {

            String content;

            try (InputStream inputStream = resource.getInputStream()) {

                content = new String(
                        inputStream.readAllBytes(),
                        StandardCharsets.UTF_8
                );
            }

            Document document = new Document(content);

            document.getMetadata()
                    .put("project", projectName);

            document.getMetadata()
                    .put("source", resource.getFilename());

            documents.add(document);
        }

        TokenTextSplitter textSplitter =
                new TokenTextSplitter(
                        chunkSize,
                        minChunkSizeChars,
                        minChunkLengthToEmbed,
                        maxNumChunks,
                        keepSeparator
                );

        List<Document> chunks =
                textSplitter.apply(documents);

        vectorStore.add(chunks);

        return chunks.size();
    }

    /**
     * Performs a direct similarity search against the VectorStore.
     *
     * This is useful for validating the RAG retrieval layer
     * independently from the LLM and QuestionAnswerAdvisor.
     */
    public List<Document> search(String query) {

        SearchRequest searchRequest =
                SearchRequest.builder()
                        .query(query)
                        .topK(5)
                        .build();

        return vectorStore.similaritySearch(searchRequest);
    }
}

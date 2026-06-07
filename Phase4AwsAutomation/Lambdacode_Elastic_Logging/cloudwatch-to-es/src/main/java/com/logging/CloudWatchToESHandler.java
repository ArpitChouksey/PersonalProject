package com.logging;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.CloudWatchLogsEvent;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.zip.GZIPInputStream;

public class CloudWatchToESHandler implements RequestHandler<CloudWatchLogsEvent, String> {

    private static final ObjectMapper mapper = new ObjectMapper();
    private static final String ES_HOST_IP = "172.20.136.186"; // Your EKS Private Service ClusterIP
    private static final int ES_PORT = 9200;
    private static final DateTimeFormatter indexDateFormatter = DateTimeFormatter.ofPattern("yyyy.MM.dd").withZone(ZoneId.of("UTC"));

    @Override
    public String handleRequest(CloudWatchLogsEvent event, Context context) {
        try {
            // 1. Decode and Decompress CloudWatch Log Payload
            byte[] compressedData = Base64.getDecoder().decode(event.getAwsLogs().getData());
            String jsonPayload = decompressGzip(compressedData);

            // 2. Parse the decompressed structural JSON
            JsonNode rootNode = mapper.readTree(jsonPayload);
            String logGroup = rootNode.path("logGroup").asText();
            String logStream = rootNode.path("logStream").asText();
            JsonNode logEvents = rootNode.path("logEvents");

            if (!logEvents.isArray() || logEvents.isEmpty()) {
                return "No log events found in payload.";
            }

            // 3. Build the Elasticsearch NDJSON bulk request body
            StringBuilder bulkRequestBody = new StringBuilder();
            String currentIndexSuffix = indexDateFormatter.format(Instant.now());
            String indexName = "cloudtrail-" + currentIndexSuffix;

            for (JsonNode logEvent : logEvents) {
                // Bulk action metadata metadata block
                bulkRequestBody.append("{\"index\":{\"_index\":\"").append(indexName).append("\"}}\n");

                // Construct data body payload
                long timestamp = logEvent.path("timestamp").asLong();
                String message = logEvent.path("message").asText();

                String logRecordJson = mapper.createObjectNode()
                        .put("@timestamp", Instant.ofEpochMilli(timestamp).toString())
                        .put("message", message)
                        .put("log_group", logGroup)
                        .put("log_stream", logStream)
                        .toString();

                bulkRequestBody.append(logRecordJson).append("\n");
            }

            // 4. Ship payload directly to private target endpoint via internal VPC route
            String response = postToElasticsearchBulk(bulkRequestBody.toString(), context);
            return "Execution complete. ES Status: " + response;

        } catch (Exception e) {
            context.getLogger().log("Error processing pipeline: " + e.getMessage());
            throw new RuntimeException(e);
        }
    }

    private String decompressGzip(byte[] compressed) throws Exception {
        try (GZIPInputStream gis = new GZIPInputStream(new ByteArrayInputStream(compressed));
             BufferedReader br = new BufferedReader(new InputStreamReader(gis, StandardCharsets.UTF_8))) {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) {
                sb.append(line);
            }
            return sb.toString();
        }
    }

    private String postToElasticsearchBulk(String bulkBody, Context context) throws Exception {
        String url = "http://" + ES_HOST_IP + ":" + ES_PORT + "/_bulk";
        try (CloseableHttpClient httpClient = HttpClients.createDefault()) {
            HttpPost httpPost = new HttpPost(url);
            httpPost.setHeader("Content-Type", "application/x-ndjson");
            httpPost.setEntity(new StringEntity(bulkBody, StandardCharsets.UTF_8));

            try (CloseableHttpResponse response = httpClient.execute(httpPost)) {
                int statusCode = response.getStatusLine().getStatusCode();
                String responseString = EntityUtils.toString(response.getEntity());
                context.getLogger().log("ES Bulk Post response code: " + statusCode);
                return String.valueOf(statusCode);
            }
        }
    }
}

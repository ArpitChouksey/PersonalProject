package com.company.spring_service.service;

import com.company.spring_service.exception.ServiceException;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class PythonClientService {

    private static final Logger logger =
            LogManager.getLogger(PythonClientService.class);

    private final RestTemplate restTemplate;
    private final String pythonServiceUrl;
    private final MeterRegistry meterRegistry;

    public PythonClientService(
            RestTemplate restTemplate,
            MeterRegistry meterRegistry,
            @Value("${python.service.url}") String pythonServiceUrl
    ) {
        this.restTemplate = restTemplate;
        this.meterRegistry = meterRegistry;
        this.pythonServiceUrl = pythonServiceUrl;
    }

    public String callPythonService(String name) {

        logger.info("Calling Python microservice for name={}", name);

        Timer.Sample sample = Timer.start(meterRegistry);

        try {

            String url = pythonServiceUrl + "/hello/" + name;

            logger.info("Python service URL={}", url);

            String response =
                    restTemplate.getForObject(url, String.class);

            logger.info("Python service call completed successfully");

            return response;

        } catch (Exception ex) {

            logger.error("Python service call failed", ex);

            throw new ServiceException(
                    "Failed to call Python service: " + ex.getMessage()
            );

        } finally {

            sample.stop(
                    Timer.builder("python_service_latency")
                            .description("Python service response latency")
                            .register(meterRegistry)
            );

            logger.info("Python service latency metric recorded");
        }
    }
}

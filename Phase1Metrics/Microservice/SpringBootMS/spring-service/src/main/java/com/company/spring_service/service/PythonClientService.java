package com.company.spring_service.service;

import com.company.spring_service.exception.ServiceException;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class PythonClientService {

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

        Timer.Sample sample = Timer.start(meterRegistry);

        try {

            String url = pythonServiceUrl + "/hello/" + name;

            return restTemplate.getForObject(url, String.class);

        } catch (Exception ex) {

            throw new ServiceException(
                    "Failed to call Python service: " + ex.getMessage()
            );

        } finally {

            sample.stop(
                    Timer.builder("python_service_latency")
                            .description("Python service response latency")
                            .register(meterRegistry)
            );
        }
    }
}

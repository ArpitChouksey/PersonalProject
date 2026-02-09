package com.company.spring_service.service;

import com.company.spring_service.exception.ServiceException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class PythonClientService {

    private final RestTemplate restTemplate;
    private final String pythonServiceUrl;

    public PythonClientService(
            RestTemplate restTemplate,
            @Value("${python.service.url}") String pythonServiceUrl
    ) {
        this.restTemplate = restTemplate;
        this.pythonServiceUrl = pythonServiceUrl;
    }

    public String callPythonService(String name) {
        try {
            String url = pythonServiceUrl + "/hello/" + name;
            return restTemplate.getForObject(url, String.class);
        } catch (Exception ex) {
            // ✅ SINGLE constructor argument (this matches ServiceException)
            throw new ServiceException("Failed to call Python service: " + ex.getMessage());
        }
    }
}

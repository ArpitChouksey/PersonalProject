package com.company.spring_service.dto;

public class ApiResponse {

    private String message;

    public ApiResponse() {
    }

    public ApiResponse(String message) {
        this.message = message;
    }

    public String getMessage() {
        return message;
    }
}

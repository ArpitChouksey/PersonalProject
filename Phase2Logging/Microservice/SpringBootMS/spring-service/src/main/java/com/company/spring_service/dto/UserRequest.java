package com.company.spring_service.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public class UserRequest {

    @NotBlank
    private String name;

    @Email
    private String email;

    public UserRequest() {
    }

    public String getName() {
        return name;
    }

    public String getEmail() {
        return email;
    }
}

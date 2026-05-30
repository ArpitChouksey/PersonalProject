package com.company.spring_service.controller;

import com.company.spring_service.dto.ApiResponse;
import com.company.spring_service.dto.UserRequest;
import com.company.spring_service.service.PythonClientService;
import com.company.spring_service.service.UserService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class UserController {

    private final UserService userService;
    private final PythonClientService pythonClientService;

    public UserController(UserService userService,
                          PythonClientService pythonClientService) {
        this.userService = userService;
        this.pythonClientService = pythonClientService;
    }

    @GetMapping("/hello/{name}")
    public ApiResponse hello(@PathVariable String name) {
        return new ApiResponse("Hello " + name);
    }

    @PostMapping("/users")
    public ApiResponse createUser(@Valid @RequestBody UserRequest request) {
        userService.createUser(request);
        return new ApiResponse("User created successfully");
    }

    @GetMapping("/call-python/{name}")
    public ApiResponse callPython(@PathVariable String name) {
        String response = pythonClientService.callPythonService(name);
        return new ApiResponse(response);
    }
}


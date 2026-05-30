package com.company.spring_service.controller;

import com.company.spring_service.dto.ApiResponse;
import com.company.spring_service.dto.UserRequest;
import com.company.spring_service.service.PythonClientService;
import com.company.spring_service.service.UserService;
import jakarta.validation.Valid;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class UserController {

    private static final Logger logger =
            LogManager.getLogger(UserController.class);

    private final UserService userService;
    private final PythonClientService pythonClientService;

    public UserController(UserService userService,
                          PythonClientService pythonClientService) {
        this.userService = userService;
        this.pythonClientService = pythonClientService;
    }

    @GetMapping("/hello/{name}")
    public ApiResponse hello(@PathVariable String name) {

        logger.info("Hello API called with name={}", name);

        return new ApiResponse("Hello " + name);
    }

    @PostMapping("/users")
    public ApiResponse createUser(@Valid @RequestBody UserRequest request) {

        logger.info("Create user API called for email={}",
                request.getEmail());

        userService.createUser(request);

        logger.info("User created successfully for email={}",
                request.getEmail());

        return new ApiResponse("User created successfully");
    }

    @GetMapping("/call-python/{name}")
    public ApiResponse callPython(@PathVariable String name) {

        logger.info("Calling Python service for name={}", name);

        String response = pythonClientService.callPythonService(name);

        logger.info("Python service response received successfully");

        return new ApiResponse(response);
    }
}

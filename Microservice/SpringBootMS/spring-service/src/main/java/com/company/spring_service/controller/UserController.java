package com.company.spring_service.controller;

import com.company.spring_service.dto.ApiResponse;
import com.company.spring_service.dto.UserRequest;
import com.company.spring_service.event.UserCreatedEvent;
import com.company.spring_service.messaging.service.MessagingService;
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
    private final MessagingService messagingService;

    public UserController(UserService userService,
                          PythonClientService pythonClientService,
                          MessagingService messagingService) {

        this.userService = userService;
        this.pythonClientService = pythonClientService;
        this.messagingService = messagingService;
    }

    @GetMapping("/hello/{name}")
    public ApiResponse hello(@PathVariable String name) {

        logger.info("Hello API called with name={}", name);

        return new ApiResponse("Hello " + name);
    }

    @PostMapping("/users")
    public ApiResponse createUser(
            @Valid @RequestBody UserRequest request) {

        logger.info(
                "Create user API called for email={}",
                request.getEmail());

        userService.createUser(request);

        logger.info(
                "User created successfully for email={}",
                request.getEmail());

        return new ApiResponse("User created successfully");
    }

    @GetMapping("/call-python/{name}")
    public ApiResponse callPython(
            @PathVariable String name) {

        logger.info(
                "Calling Python service for name={}",
                name);

        String response =
                pythonClientService.callPythonService(name);

        logger.info(
                "Python service response received successfully");

        return new ApiResponse(response);
    }

    /**
     * Temporary endpoint for Kafka testing.
     */
    @PostMapping("/kafka/test")
    public ApiResponse testKafka() {

        logger.info("Publishing Kafka Test Event");

        UserCreatedEvent event = new UserCreatedEvent(
                1L,
                "Arpit",
                "Chouksey",
                "arpit@test.com",
                "spring-service"
        );

        messagingService.publish(
                event.getUserId().toString(),
                event
        );

        logger.info("Kafka Test Event Published");

        return new ApiResponse(
                "Kafka Message Published Successfully"
        );
    }

    /**
     * Temporary endpoint for Amazon MQ testing.
     */
    @PostMapping("/amazonmq/test")
    public ApiResponse testAmazonMQ() {

        logger.info("Publishing Amazon MQ Test Event");

        UserCreatedEvent event = new UserCreatedEvent(
                1L,
                "Arpit",
                "Chouksey",
                "arpit@test.com",
                "spring-service"
        );

        messagingService.publish(
                event.getUserId().toString(),
                event
        );

        logger.info("Amazon MQ Test Event Published");

        return new ApiResponse(
                "Amazon MQ Message Published Successfully"
        );
    }

}

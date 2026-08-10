package com.company.spring_service.mcp.service;

import com.company.spring_service.dto.UserRequest;
import com.company.spring_service.mcp.dto.CreateUserRequest;
import com.company.spring_service.service.UserService;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.stereotype.Service;

@Service
public class UserMcpService {

    private final UserService userService;

    public UserMcpService(UserService userService) {
        this.userService = userService;
    }

    @Tool(
        name = "hello",
        description = "Checks whether the MCP Custom Curd application server is working"
    )
    public String hello() {

        return "hello. MCP Custom Curd application server is working";
    }

    @Tool(
        name = "createUser",
        description = "Creates a new user with name and email"
    )
    public String createUser(String name, String email) {

        CreateUserRequest mcpRequest =
                new CreateUserRequest();

        mcpRequest.setName(name);
        mcpRequest.setEmail(email);

        UserRequest userRequest =
                new UserRequest(
                        mcpRequest.getName(),
                        mcpRequest.getEmail()
                );

        userService.createUser(userRequest);

        return "User created successfully";
    }
}

package com.company.spring_service.service;

import com.company.spring_service.dto.UserRequest;
import com.company.spring_service.model.User;
import com.company.spring_service.repository.UserRepository;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final Counter usersCreatedCounter;

    public UserService(UserRepository userRepository,
                       MeterRegistry meterRegistry) {

        this.userRepository = userRepository;

        this.usersCreatedCounter = Counter.builder("app_users_created_total")
                .description("Total number of users created")
                .register(meterRegistry);
    }

    public void createUser(UserRequest request) {

        User user = new User();
        user.setName(request.getName());
        user.setEmail(request.getEmail());

        userRepository.save(user);

        usersCreatedCounter.increment();
    }
}

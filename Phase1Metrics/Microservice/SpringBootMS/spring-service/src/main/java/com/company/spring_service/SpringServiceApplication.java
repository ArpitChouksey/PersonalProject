package com.company.spring_service;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import jakarta.annotation.PostConstruct;

@SpringBootApplication
public class SpringServiceApplication {

    @PostConstruct
    public void debugEnv() {
        System.out.println("DB_URL = " + System.getenv("DB_URL"));
        System.out.println("DB_USERNAME = " + System.getenv("DB_USERNAME"));
    }

    public static void main(String[] args) {
        SpringApplication.run(SpringServiceApplication.class, args);
    }
}

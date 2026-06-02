package com.company.spring_service;

import jakarta.annotation.PostConstruct;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SpringServiceApplication {

    private static final Logger logger =
            LogManager.getLogger(SpringServiceApplication.class);

    @PostConstruct
    public void debugEnv() {

        logger.info("DB_URL={}", System.getenv("DB_URL"));
        logger.info("DB_USERNAME={}", System.getenv("DB_USERNAME"));
    }

    public static void main(String[] args) {

        logger.info("Starting Spring Service Application");

        SpringApplication.run(SpringServiceApplication.class, args);

        logger.info("Spring Service Application Started Successfully");
    }
}

package com.example.demo;

import org.slf4j.Logger;
import org.springframework.boot.SpringApplication;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class Helloworld {
    private final Logger logger = org.slf4j.LoggerFactory.getLogger(this.getClass());

    @RequestMapping("/")
    String home() {
        logger.info("home() was called. ");
        return "Hello World!";
    }

    public static void main(String[] args) throws Exception {
        SpringApplication.run(Helloworld.class, args);
    }
}

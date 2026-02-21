package com.viet.backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import java.io.FileInputStream;
import java.io.InputStream;
import java.io.IOException;

@Configuration
public class FirebaseConfig {

    @Value("${firebase.config.path}")
    private String configPath;

    @PostConstruct
    public void initialize() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                InputStream serviceAccount;

                if (configPath.startsWith("classpath:")) {
                    String path = configPath.replace("classpath:", "");
                    serviceAccount = new ClassPathResource(path).getInputStream();
                } else {
                    serviceAccount = new FileInputStream(configPath);
                }

                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                FirebaseApp.initializeApp(options);
                System.out.println("Firebase initialized successfully from: " + configPath);
            }
        } catch (IOException e) {
            System.err.println("CRITICAL: Error initializing Firebase with path: " + configPath);
            System.err.println("Resolved path: " + new java.io.File(configPath).getAbsolutePath());
            System.err.println("Error message: " + e.getMessage());
        }
    }
}

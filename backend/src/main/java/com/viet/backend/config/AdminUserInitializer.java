package com.viet.backend.config;

import com.viet.backend.model.Admin;
import com.viet.backend.model.Role;
import com.viet.backend.model.User;
import com.viet.backend.repository.AdminRepository;
import com.viet.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
public class AdminUserInitializer {

    private final UserRepository userRepository;
    private final AdminRepository adminRepository;
    private final PasswordEncoder passwordEncoder;

    @Bean
    CommandLineRunner initAdminUser() {
        return args -> {
            String adminEmail = "admin@example.com";
            if (!userRepository.existsByEmail(adminEmail)) {
                User adminUser = User.builder()
                        .firstname("Admin")
                        .lastname("System")
                        .email(adminEmail)
                        .password(passwordEncoder.encode("admin123"))
                        .role(Role.ADMIN)
                        .build();

                User savedUser = userRepository.save(adminUser);

                Admin adminProfile = Admin.builder()
                        .user(savedUser)
                        .permissions("SUPER_ADMIN")
                        .build();
                adminRepository.save(adminProfile);

                System.out.println("Successfully created default admin user and profile:");
                System.out.println("Email: " + adminEmail);
                System.out.println("Password: admin123");
            }
        };
    }
}

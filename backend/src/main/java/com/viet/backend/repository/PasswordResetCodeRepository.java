package com.viet.backend.repository;

import com.viet.backend.model.PasswordResetCode;
import com.viet.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PasswordResetCodeRepository extends JpaRepository<PasswordResetCode, Long> {
    Optional<PasswordResetCode> findByCodeAndUser_EmailAndIsActiveTrue(String code, String email);

    // To deactivate old codes for the same user when a new one is generated
    void deleteByUser(User user);
}

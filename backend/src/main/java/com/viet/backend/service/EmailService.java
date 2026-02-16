package com.viet.backend.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;
    private final TemplateEngine templateEngine;

    public void sendAccessCodeEmail(String to, String code) {
        Map<String, Object> variables = Map.of(
                "title", "Apartment Access Code",
                "message",
                "A new access code has been generated for your apartment registration. Please use the code below to verify your access:",
                "code", code,
                "expiryMinutes", 5);
        sendEmail(to, "Your Apartment Access Code", variables, "email-code");
    }

    public void sendPasswordResetEmail(String to, String code) {
        Map<String, Object> variables = Map.of(
                "title", "Password Reset Verification",
                "message",
                "You have requested to reset your password. Please use the verification code below to proceed:",
                "code", code,
                "expiryMinutes", 15);
        sendEmail(to, "Password Reset Verification Code", variables, "email-code");
    }

    private void sendEmail(String to, String subject, Map<String, Object> variables, String templateName) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, "utf-8");

            Context context = new Context();
            context.setVariables(variables);

            String htmlContent = templateEngine.process(templateName, context);

            helper.setText(htmlContent, true);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setFrom("no-reply@apartmentsystem.com");

            mailSender.send(mimeMessage);
        } catch (MessagingException e) {
            throw new RuntimeException("Failed to send email", e);
        }
    }
}

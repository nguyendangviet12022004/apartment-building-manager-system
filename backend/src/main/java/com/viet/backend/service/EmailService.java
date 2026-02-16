package com.viet.backend.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;
    private final TemplateEngine templateEngine;

    public void sendAccessCodeEmail(String to, String code) {
        sendEmail(to, "Your Apartment Access Code", code, "email-code");
    }

    public void sendPasswordResetEmail(String to, String code) {
        sendEmail(to, "Password Reset Verification Code", code, "email-code");
    }

    private void sendEmail(String to, String subject, String code, String templateName) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, "utf-8");

            Context context = new Context();
            context.setVariable("code", code);

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

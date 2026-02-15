package com.viet.backend.exception;

public class ExpiredCodeException extends RuntimeException {
    public ExpiredCodeException(String message) {
        super(message);
    }
}

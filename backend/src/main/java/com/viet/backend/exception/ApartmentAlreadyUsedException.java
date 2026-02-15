package com.viet.backend.exception;

public class ApartmentAlreadyUsedException extends RuntimeException {
    public ApartmentAlreadyUsedException(String message) {
        super(message);
    }
}

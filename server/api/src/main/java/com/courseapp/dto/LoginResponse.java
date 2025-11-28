package com.courseapp.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {
    private String token;
    private String username;
    private Long userId;
    private String message;
    
    public LoginResponse(String token, String username, Long userId) {
        this.token = token;
        this.username = username;
        this.userId = userId;
        this.message = "Login successful";
    }
}
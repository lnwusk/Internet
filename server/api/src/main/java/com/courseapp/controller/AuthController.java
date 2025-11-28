package com.courseapp.controller;

import com.courseapp.dto.LoginRequest;
import com.courseapp.dto.LoginResponse;
import com.courseapp.dto.RegisterRequest;
import com.courseapp.service.AuthService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
@Api(tags = "Authentication")
public class AuthController {
    private final AuthService authService;
    
    @PostMapping("/login")
    @ApiOperation("User login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        try {
            LoginResponse response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(new LoginResponse(null, null, null, e.getMessage()));
        }
    }
    
    @PostMapping("/register")
    @ApiOperation("User registration")
    public ResponseEntity<String> register(@Valid @RequestBody RegisterRequest request) {
        try {
            String message = authService.register(request);
            return ResponseEntity.ok(message);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
    
    @GetMapping("/health")
    @ApiOperation("Health check")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Auth service is running");
    }
}
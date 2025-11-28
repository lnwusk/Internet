package com.courseapp.service;

import com.courseapp.dto.LoginRequest;
import com.courseapp.dto.LoginResponse;
import com.courseapp.dto.RegisterRequest;
import com.courseapp.entity.User;
import com.courseapp.repository.UserRepository;
import com.courseapp.security.JwtTokenUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenUtil jwtTokenUtil;
    
    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("Invalid credentials");
        }
        
        String token = jwtTokenUtil.generateToken(user.getUsername(), user.getId());
        return new LoginResponse(token, user.getUsername(), user.getId());
    }
    
    public String register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("Username already exists");
        }
        
        User user = new User();
        user.setUsername(request.getUsername());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setEmail(request.getEmail());
        user.setRealName(request.getRealName());
        user.setStudentId(request.getStudentId());
        
        userRepository.save(user);
        return "User registered successfully";
    }
}
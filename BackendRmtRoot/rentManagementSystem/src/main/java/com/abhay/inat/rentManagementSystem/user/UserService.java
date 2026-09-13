package com.abhay.inat.rentManagementSystem.user;

import com.abhay.inat.rentManagementSystem.user.dto.AuthResponse;
import com.abhay.inat.rentManagementSystem.user.dto.LoginRequest;
import com.abhay.inat.rentManagementSystem.user.dto.RegisterRequest;
import com.abhay.inat.rentManagementSystem.user.dto.UserResponse;

public interface UserService {
    UserResponse register(RegisterRequest request);
    AuthResponse login(LoginRequest request);
}

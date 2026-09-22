package com.abhay.inat.rentManagementSystem.user;

import com.abhay.inat.rentManagementSystem.user.dto.AuthResponse;
import com.abhay.inat.rentManagementSystem.user.dto.LoginRequest;
import com.abhay.inat.rentManagementSystem.user.dto.RegisterRequest;
import com.abhay.inat.rentManagementSystem.user.dto.UserResponse;

import java.util.List;

public interface UserService {
    UserResponse register(RegisterRequest request);
    AuthResponse login(LoginRequest request);

    List<UserResponse> listPendingUsers();
    List<UserResponse> listAllUsers();
    UserResponse decideApproval(Long userId, boolean approve);
    void updateFcmToken(Long userId, String fcmToken);
}

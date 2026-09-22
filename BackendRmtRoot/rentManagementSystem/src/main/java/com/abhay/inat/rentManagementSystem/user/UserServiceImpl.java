package com.abhay.inat.rentManagementSystem.user;

import com.abhay.inat.rentManagementSystem.common.enums.UserRole;
import com.abhay.inat.rentManagementSystem.common.enums.UserStatus;
import com.abhay.inat.rentManagementSystem.common.exception.DuplicateResourceException;
import com.abhay.inat.rentManagementSystem.common.exception.InvalidStateException;
import com.abhay.inat.rentManagementSystem.common.exception.ResourceNotFoundException;
import com.abhay.inat.rentManagementSystem.notification.FcmService;
import com.abhay.inat.rentManagementSystem.security.JwtUtil;
import com.abhay.inat.rentManagementSystem.user.dto.AuthResponse;
import com.abhay.inat.rentManagementSystem.user.dto.LoginRequest;
import com.abhay.inat.rentManagementSystem.user.dto.RegisterRequest;
import com.abhay.inat.rentManagementSystem.user.dto.UserResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;
    private final FcmService fcmService;

    @Override
    public UserResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new DuplicateResourceException("An account with this email already exists");
        }

        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .phone(request.getPhone())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(UserRole.CUSTOMER)
                .status(UserStatus.PENDING_APPROVAL)
                .build();

        User saved = userRepository.save(user);

        return toResponse(saved);
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
            );
        } catch (Exception ex) {
            throw new BadCredentialsException("Invalid email or password");
        }

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        // Blocked accounts cannot log in at all. Pending-approval accounts CAN log in
        // (so the app can show them an "awaiting approval" screen) but every other
        // endpoint should check status == APPROVED before allowing real actions.
        if (user.getStatus() == UserStatus.BLOCKED) {
            throw new BadCredentialsException("This account has been blocked. Contact the admin.");
        }

        String token = jwtUtil.generateToken(user.getId(), user.getEmail(), user.getRole().name());

        return AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .role(user.getRole().name())
                .status(user.getStatus().name())
                .build();
    }

    @Override
    public List<UserResponse> listPendingUsers() {
        return userRepository.findByStatus(UserStatus.PENDING_APPROVAL).stream().map(this::toResponse).toList();
    }

    @Override
    public List<UserResponse> listAllUsers() {
        return userRepository.findAll().stream().map(this::toResponse).toList();
    }

    @Override
    public UserResponse decideApproval(Long userId, boolean approve) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        if (user.getStatus() != UserStatus.PENDING_APPROVAL) {
            throw new InvalidStateException(
                    "Only pending users can be approved or rejected (current status: " + user.getStatus() + ")");
        }

        user.setStatus(approve ? UserStatus.APPROVED : UserStatus.BLOCKED);

        User saved = userRepository.save(user);

        fcmService.notifyUser(
                saved.getId(),
                approve ? "Account Approved" : "Account Update",
                approve
                        ? "Your account has been approved. You can now request rentals."
                        : "Your account request was not approved. Contact the admin for details.");

        return toResponse(saved);
    }

    @Override
    public void updateFcmToken(Long userId, String fcmToken) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));
        user.setFcmToken(fcmToken);
        userRepository.save(user);
    }

    private UserResponse toResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .role(user.getRole().name())
                .status(user.getStatus().name())
                .build();
    }
}

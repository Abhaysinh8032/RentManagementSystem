package com.abhay.inat.rentManagementSystem.user;

import com.abhay.inat.rentManagementSystem.common.ApiResponse;
import com.abhay.inat.rentManagementSystem.notification.dto.FcmTokenRequest;
import com.abhay.inat.rentManagementSystem.security.CurrentUserResolver;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * Separate from AuthController (register/login, pre-auth) and
 * AdminUserController (admin managing other users) - this is the current
 * user managing their own data. Falls under anyRequest().authenticated() in
 * SecurityConfig already, no security changes needed.
 */
@RestController
@RequiredArgsConstructor
public class UserProfileController {

    private final UserService userService;
    private final CurrentUserResolver currentUserResolver;

    @PutMapping("/users/fcm-token")
    public ResponseEntity<ApiResponse<Void>> updateFcmToken(
            @Valid @RequestBody FcmTokenRequest request, Authentication authentication) {
        var user = currentUserResolver.resolve(authentication);
        userService.updateFcmToken(user.getId(), request.getFcmToken());
        return ResponseEntity.ok(ApiResponse.success("FCM token registered", null));
    }
}

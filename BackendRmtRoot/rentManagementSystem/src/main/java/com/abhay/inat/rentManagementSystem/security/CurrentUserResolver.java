package com.abhay.inat.rentManagementSystem.security;

import com.abhay.inat.rentManagementSystem.common.exception.ResourceNotFoundException;
import com.abhay.inat.rentManagementSystem.user.User;
import com.abhay.inat.rentManagementSystem.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

/**
 * Small shared helper so every controller doesn't repeat "look up the logged-in
 * User row from the JWT-authenticated email" logic.
 */
@Component
@RequiredArgsConstructor
public class CurrentUserResolver {

    private final UserRepository userRepository;

    public User resolve(Authentication authentication) {
        String email = authentication.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found: " + email));
    }
}

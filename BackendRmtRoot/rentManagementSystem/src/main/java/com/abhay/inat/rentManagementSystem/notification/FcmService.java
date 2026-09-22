package com.abhay.inat.rentManagementSystem.notification;

import com.abhay.inat.rentManagementSystem.user.UserRepository;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@Slf4j
@RequiredArgsConstructor
public class FcmService {

    private final UserRepository userRepository;
    private final FirebaseApp firebaseApp; // null if not configured - see FirebaseConfig

    public void notifyUser(Long userId, String title, String body) {
        if (firebaseApp == null) {
            log.info("Firebase not configured - skipping notification to user {}: \"{}\"", userId, title);
            return;
        }

        userRepository.findById(userId).ifPresent(user -> {
            String token = user.getFcmToken();
            if (token == null || token.isBlank()) {
                log.info("User {} has no FCM token registered yet - skipping notification", userId);
                return;
            }

            Message message = Message.builder()
                    .setToken(token)
                    .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                    .build();

            try {
                FirebaseMessaging.getInstance(firebaseApp).send(message);
            } catch (FirebaseMessagingException e) {
                // Never let a notification failure break the actual business
                // operation (approval, payment verification, etc.) that triggered
                // it - log and move on.
                log.warn("Failed to send FCM notification to user {}: {}", userId, e.getMessage());
            }
        });
    }
}

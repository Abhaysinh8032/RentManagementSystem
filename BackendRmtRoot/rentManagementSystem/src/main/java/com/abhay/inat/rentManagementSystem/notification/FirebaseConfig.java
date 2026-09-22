package com.abhay.inat.rentManagementSystem.notification;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

/**
 * Deliberately resilient: if the Firebase service account file isn't present
 * yet (nobody has set up a Firebase project for this app), this returns null
 * instead of throwing - so the whole application still starts up fine and
 * every other already-working feature (auth, properties, rentals, billing)
 * is completely unaffected. FcmService checks for null and just logs +
 * no-ops instead of sending. Push notifications go live automatically the
 * moment a real credentials file is dropped in and the app restarts - no
 * other code change needed.
 */
@Configuration
@Slf4j
public class FirebaseConfig {

    @Value("${app.firebase.credentials-path}")
    private String credentialsPath;

    @Bean
    public FirebaseApp firebaseApp() {
        if (!FirebaseApp.getApps().isEmpty()) {
            return FirebaseApp.getInstance();
        }
        log.info(credentialsPath);
        File file = new File(credentialsPath);
//        File file = new File("E:/Projects2026/rentManagementSystem/rMTRoot/BackendRmtRoot/rentManagementSystem/src/main/resources/firebase-service-account.json");
        if (!file.exists()) {
            log.warn("Firebase credentials file not found at '{}' - push notifications are disabled until this is configured. See README.", credentialsPath);
            return null;
        }

        try (FileInputStream serviceAccount = new FileInputStream(file)) {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();
            return FirebaseApp.initializeApp(options);
        } catch (IOException e) {
            log.warn("Failed to initialize Firebase - push notifications disabled: {}", e.getMessage());
            return null;
        }
    }
}

package com.abhay.inat.rentManagementSystem.notification.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class FcmTokenRequest {
    @NotBlank(message = "fcmToken is required")
    private String fcmToken;
}

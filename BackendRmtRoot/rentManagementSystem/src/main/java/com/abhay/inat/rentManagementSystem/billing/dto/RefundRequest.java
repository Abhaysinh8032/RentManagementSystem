package com.abhay.inat.rentManagementSystem.billing.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RefundRequest {
    private String refundReference;
    private String adminNote;
}

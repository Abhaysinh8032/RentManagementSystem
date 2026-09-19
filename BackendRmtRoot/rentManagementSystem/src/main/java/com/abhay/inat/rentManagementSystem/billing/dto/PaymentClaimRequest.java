package com.abhay.inat.rentManagementSystem.billing.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PaymentClaimRequest {

    @NotBlank(message = "Payment reference / transaction id is required")
    private String paymentReference;

    @NotBlank(message = "Payment proof image URL is required")
    private String paymentProofUrl;
}

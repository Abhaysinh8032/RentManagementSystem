package com.abhay.inat.rentManagementSystem.billing.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PaymentClaimRequest {

    @NotBlank(message = "Payment reference / transaction id is required")
    private String paymentReference;

    // Full-replace semantics: this call can be repeated any time before the
    // bill is decided (PAID/REFUNDED) to update the reference and/or swap out
    // images - whatever list is sent becomes the complete proof image set,
    // it's not an incremental add. See BillingServiceImpl.claimPayment.
    @NotEmpty(message = "At least one payment proof image is required") 
    @Size(max = 5, message = "A claim can have at most 5 proof images")
    private List<String> proofImageUrls;
}

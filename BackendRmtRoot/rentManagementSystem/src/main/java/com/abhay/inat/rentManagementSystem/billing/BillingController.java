package com.abhay.inat.rentManagementSystem.billing;

import com.abhay.inat.rentManagementSystem.billing.dto.BillResponse;
import com.abhay.inat.rentManagementSystem.billing.dto.PaymentClaimRequest;
import com.abhay.inat.rentManagementSystem.billing.dto.PaymentDecisionRequest;
import com.abhay.inat.rentManagementSystem.billing.dto.RefundRequest;
import com.abhay.inat.rentManagementSystem.common.ApiResponse;
import com.abhay.inat.rentManagementSystem.common.enums.UserRole;
import com.abhay.inat.rentManagementSystem.security.CurrentUserResolver;
import com.abhay.inat.rentManagementSystem.user.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class BillingController {

    private final BillingService billingService;
    private final CurrentUserResolver currentUserResolver;

    // ---- Customer-facing ----

    @GetMapping("/bills/mine")
    public ResponseEntity<ApiResponse<List<BillResponse>>> listMine(Authentication authentication) {
        User user = currentUserResolver.resolve(authentication);
        return ResponseEntity.ok(ApiResponse.success("Your bills", billingService.listMine(user.getId())));
    }

    @GetMapping("/rental-requests/{rentalRequestId}/bills")
    public ResponseEntity<ApiResponse<List<BillResponse>>> listByRentalRequest(
            @PathVariable Long rentalRequestId, Authentication authentication) {
        User user = currentUserResolver.resolve(authentication);
        boolean isAdmin = user.getRole() == UserRole.ADMIN;
        return ResponseEntity.ok(ApiResponse.success(
                "Bills for this rental request",
                billingService.listByRentalRequest(rentalRequestId, user.getId(), isAdmin)));
    }

    @PutMapping("/bills/{id}/claim-payment")
    public ResponseEntity<ApiResponse<BillResponse>> claimPayment(
            @PathVariable Long id, @Valid @RequestBody PaymentClaimRequest request, Authentication authentication) {
        User user = currentUserResolver.resolve(authentication);
        return ResponseEntity.ok(ApiResponse.success(
                "Payment claim submitted. The admin will review it shortly.",
                billingService.claimPayment(id, user.getId(), request)));
    }

    // ---- Admin-only ----

    @PutMapping("/admin/bills/{id}/verify")
    public ResponseEntity<ApiResponse<BillResponse>> verify(
            @PathVariable Long id, @RequestBody PaymentDecisionRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Payment claim reviewed", billingService.verifyPayment(id, request)));
    }

    @PutMapping("/admin/bills/{id}/refund")
    public ResponseEntity<ApiResponse<BillResponse>> refund(
            @PathVariable Long id, @RequestBody RefundRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Deposit marked as refunded", billingService.refundDeposit(id, request)));
    }
}

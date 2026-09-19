package com.abhay.inat.rentManagementSystem.billing;

import com.abhay.inat.rentManagementSystem.billing.dto.BillResponse;
import com.abhay.inat.rentManagementSystem.billing.dto.PaymentClaimRequest;
import com.abhay.inat.rentManagementSystem.billing.dto.PaymentDecisionRequest;
import com.abhay.inat.rentManagementSystem.billing.dto.RefundRequest;

import java.math.BigDecimal;
import java.util.List;

public interface BillingService {

    // Called internally by RentalServiceImpl right after a RentalRequest is created -
    // not exposed as its own REST endpoint.
    List<BillResponse> generateBillsForRequest(Long rentalRequestId, BigDecimal rentAmount, BigDecimal depositAmount);

    List<BillResponse> listByRentalRequest(Long rentalRequestId, Long currentUserId, boolean isAdmin);

    List<BillResponse> listMine(Long currentUserId);

    BillResponse claimPayment(Long billId, Long currentUserId, PaymentClaimRequest request);

    BillResponse verifyPayment(Long billId, PaymentDecisionRequest request);

    BillResponse refundDeposit(Long billId, RefundRequest request);
}

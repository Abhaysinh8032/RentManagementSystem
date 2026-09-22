package com.abhay.inat.rentManagementSystem.billing;

import com.abhay.inat.rentManagementSystem.billing.dto.BillResponse;
import com.abhay.inat.rentManagementSystem.billing.dto.PaymentClaimRequest;
import com.abhay.inat.rentManagementSystem.billing.dto.PaymentDecisionRequest;
import com.abhay.inat.rentManagementSystem.billing.dto.RefundRequest;
import com.abhay.inat.rentManagementSystem.common.enums.BillStatus;
import com.abhay.inat.rentManagementSystem.common.enums.BillType;
import com.abhay.inat.rentManagementSystem.common.enums.RentalStatus;
import com.abhay.inat.rentManagementSystem.common.exception.InvalidStateException;
import com.abhay.inat.rentManagementSystem.common.exception.ResourceNotFoundException;
import com.abhay.inat.rentManagementSystem.notification.FcmService;
import com.abhay.inat.rentManagementSystem.rental.RentalRequest;
import com.abhay.inat.rentManagementSystem.rental.RentalRequestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class BillingServiceImpl implements BillingService {

    private final BillRepository billRepository;
    // Read-only dependency on the rental package, purely to check bill ownership
    // and to confirm RETURNED status before a refund. RentalServiceImpl depends
    // on BillingService in the other direction (to generate bills) - both are
    // one-directional at the method level, just pointing at each other's package.
    private final RentalRequestRepository rentalRequestRepository;
    private final FcmService fcmService;

    @Override
    @Transactional
    public List<BillResponse> generateBillsForRequest(Long rentalRequestId, BigDecimal rentAmount, BigDecimal depositAmount) {
        Bill rentBill = Bill.builder()
                .rentalRequestId(rentalRequestId)
                .billType(BillType.RENT)
                .amount(rentAmount)
                .status(BillStatus.PENDING_PAYMENT)
                .build();

        Bill depositBill = Bill.builder()
                .rentalRequestId(rentalRequestId)
                .billType(BillType.DEPOSIT)
                .amount(depositAmount)
                .status(BillStatus.PENDING_PAYMENT)
                .build();

        List<Bill> saved = billRepository.saveAll(List.of(rentBill, depositBill));
        return saved.stream().map(this::toResponse).toList();
    }

    @Override
    public List<BillResponse> listByRentalRequest(Long rentalRequestId, Long currentUserId, boolean isAdmin) {
        RentalRequest rentalRequest = findRentalRequestOrThrow(rentalRequestId);

        if (!isAdmin && !rentalRequest.getUserId().equals(currentUserId)) {
            throw new AccessDeniedException("You do not have access to these bills");
        }

        return billRepository.findByRentalRequestId(rentalRequestId).stream().map(this::toResponse).toList();
    }

    @Override
    public List<BillResponse> listMine(Long currentUserId) {
        List<Long> myRequestIds = rentalRequestRepository.findByUserId(currentUserId)
                .stream()
                .map(RentalRequest::getId)
                .toList();

        if (myRequestIds.isEmpty()) {
            return List.of();
        }

        return billRepository.findByRentalRequestIdIn(myRequestIds).stream().map(this::toResponse).toList();
    }

    @Override
    @Transactional
    public BillResponse claimPayment(Long billId, Long currentUserId, PaymentClaimRequest request) {
        Bill bill = findBillOrThrow(billId);
        RentalRequest rentalRequest = findRentalRequestOrThrow(bill.getRentalRequestId());

        if (!rentalRequest.getUserId().equals(currentUserId)) {
            throw new AccessDeniedException("This bill does not belong to you");
        }

        if (bill.getStatus() != BillStatus.PENDING_PAYMENT) {
            throw new InvalidStateException(
                    "This bill is not awaiting payment (current status: " + bill.getStatus() + ")");
        }

        bill.setPaymentReference(request.getPaymentReference());
        bill.setPaymentProofUrl(request.getPaymentProofUrl());
        bill.setStatus(BillStatus.PAYMENT_CLAIMED);
        bill.setClaimedAt(Instant.now());

        return toResponse(billRepository.save(bill));
    }

    @Override
    @Transactional
    public BillResponse verifyPayment(Long billId, PaymentDecisionRequest request) {
        Bill bill = findBillOrThrow(billId);

        if (bill.getStatus() != BillStatus.PAYMENT_CLAIMED) {
            throw new InvalidStateException(
                    "This bill has no pending payment claim to verify (current status: " + bill.getStatus() + ")");
        }

        // False claim: revert to PENDING_PAYMENT (not REJECTED-forever) so the
        // user can see it needs fixing and resubmit proof.
        bill.setStatus(request.isApprove() ? BillStatus.PAID : BillStatus.PENDING_PAYMENT);
        bill.setAdminNote(request.getAdminNote());
        bill.setVerifiedAt(Instant.now());

        Bill saved = billRepository.save(bill);

        RentalRequest rentalRequest = findRentalRequestOrThrow(saved.getRentalRequestId());
        String billLabel = saved.getBillType() == BillType.RENT ? "Rent" : "Deposit";
        fcmService.notifyUser(
                rentalRequest.getUserId(),
                request.isApprove() ? billLabel + " Payment Verified" : billLabel + " Payment Claim Rejected",
                request.isApprove()
                        ? "Your " + billLabel.toLowerCase() + " payment has been verified."
                        : "Your " + billLabel.toLowerCase() + " payment claim could not be verified - please check and resubmit.");

        return toResponse(saved);
    }

    @Override
    @Transactional
    public BillResponse refundDeposit(Long billId, RefundRequest request) {
        Bill bill = findBillOrThrow(billId);

        if (bill.getBillType() != BillType.DEPOSIT) {
            throw new InvalidStateException("Only deposit bills can be refunded");
        }
        if (bill.getStatus() != BillStatus.PAID) {
            throw new InvalidStateException(
                    "Deposit must be marked PAID before it can be refunded (current status: " + bill.getStatus() + ")");
        }

        RentalRequest rentalRequest = findRentalRequestOrThrow(bill.getRentalRequestId());
        if (rentalRequest.getStatus() != RentalStatus.RETURNED) {
            throw new InvalidStateException(
                    "Deposit can only be refunded after the property has been returned and verified");
        }

        bill.setStatus(BillStatus.REFUNDED);
        bill.setRefundReference(request.getRefundReference());
        bill.setAdminNote(request.getAdminNote());
        bill.setRefundedAt(Instant.now());

        Bill saved = billRepository.save(bill);

        fcmService.notifyUser(
                rentalRequest.getUserId(),
                "Deposit Refunded",
                "Your security deposit has been refunded.");

        return toResponse(saved);
    }

    private Bill findBillOrThrow(Long id) {
        return billRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Bill not found with id: " + id));
    }

    private RentalRequest findRentalRequestOrThrow(Long id) {
        return rentalRequestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Rental request not found with id: " + id));
    }

    private BillResponse toResponse(Bill b) {
        return BillResponse.builder()
                .id(b.getId())
                .rentalRequestId(b.getRentalRequestId())
                .billType(b.getBillType().name())
                .amount(b.getAmount())
                .status(b.getStatus().name())
                .paymentReference(b.getPaymentReference())
                .paymentProofUrl(b.getPaymentProofUrl())
                .claimedAt(b.getClaimedAt())
                .verifiedAt(b.getVerifiedAt())
                .refundReference(b.getRefundReference())
                .refundedAt(b.getRefundedAt())
                .adminNote(b.getAdminNote())
                .build();
    }
}

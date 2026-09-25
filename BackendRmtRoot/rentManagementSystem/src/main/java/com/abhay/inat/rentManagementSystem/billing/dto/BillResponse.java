package com.abhay.inat.rentManagementSystem.billing.dto;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Getter
@Builder
public class BillResponse {
    private Long id;
    private Long rentalRequestId;
    private String billType;
    private BigDecimal amount;
    private String status;
    private String paymentReference;
    private List<String> proofImageUrls;
    private Instant claimedAt;
    private Instant verifiedAt;
    private String refundReference;
    private Instant refundedAt;
    private String adminNote;
}

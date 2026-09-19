package com.abhay.inat.rentManagementSystem.billing;

import com.abhay.inat.rentManagementSystem.common.BaseEntity;
import com.abhay.inat.rentManagementSystem.common.enums.BillStatus;
import com.abhay.inat.rentManagementSystem.common.enums.BillType;
import com.abhay.inat.rentManagementSystem.rental.RentalRequest;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.SuperBuilder;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "bills")
@Getter
@Setter
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class Bill extends BaseEntity {

    @Column(name = "rental_request_id", nullable = false)
    private Long rentalRequestId;

    // Same pattern as RentalRequest.property/user: read-only, exists only so
    // Hibernate generates the FK constraint. Service code uses rentalRequestId.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "rental_request_id", insertable = false, updatable = false)
    private RentalRequest rentalRequest;

    @Enumerated(EnumType.STRING)
    @Column(name = "bill_type", nullable = false, length = 20)
    private BillType billType;

    @Column(nullable = false)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private BillStatus status;

    // Set when the user submits a claim: a UTR/transaction id and a screenshot
    // URL. The image itself is uploaded client-side (e.g. to Supabase Storage);
    // this column just stores the resulting public URL.
    @Column(name = "payment_reference", length = 100)
    private String paymentReference;

    @Column(name = "payment_proof_url", columnDefinition = "TEXT")
    private String paymentProofUrl;

    @Column(name = "claimed_at")
    private Instant claimedAt;

    @Column(name = "verified_at")
    private Instant verifiedAt;

    // Only ever populated on DEPOSIT bills.
    @Column(name = "refund_reference", length = 100)
    private String refundReference;

    @Column(name = "refunded_at")
    private Instant refundedAt;

    @Column(name = "admin_note", columnDefinition = "TEXT")
    private String adminNote;
}

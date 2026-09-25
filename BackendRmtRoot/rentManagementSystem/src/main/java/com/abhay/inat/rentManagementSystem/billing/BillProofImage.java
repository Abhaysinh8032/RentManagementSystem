package com.abhay.inat.rentManagementSystem.billing;

import com.abhay.inat.rentManagementSystem.common.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.SuperBuilder;

/**
 * Replaces Bill.paymentProofUrl (single string). One row per screenshot;
 * a claim can have several (e.g. a UPI confirmation screen plus a bank
 * statement line). Full-replace semantics on every claimPayment() call - see
 * BillingServiceImpl.
 */
@Entity
@Table(name = "bill_proof_images")
@Getter
@Setter
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class BillProofImage extends BaseEntity {

    @Column(name = "bill_id", nullable = false)
    private Long billId;

    @Column(name = "image_url", nullable = false, columnDefinition = "TEXT")
    private String imageUrl;
}

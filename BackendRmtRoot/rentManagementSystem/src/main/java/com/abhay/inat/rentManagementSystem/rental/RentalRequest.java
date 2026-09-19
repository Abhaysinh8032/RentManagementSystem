package com.abhay.inat.rentManagementSystem.rental;

import com.abhay.inat.rentManagementSystem.common.BaseEntity;
import com.abhay.inat.rentManagementSystem.common.enums.RentalStatus;
import com.abhay.inat.rentManagementSystem.property.Property;
import com.abhay.inat.rentManagementSystem.user.User;
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

import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "rental_requests")
@Getter
@Setter
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class RentalRequest extends BaseEntity {

    @Column(name = "property_id", nullable = false)
    private Long propertyId;

    // Read-only mirror of property_id purely so Hibernate generates a real FK
    // constraint (properties.id) under ddl-auto=update. All service code still
    // reads/writes propertyId directly - this field is never set manually.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "property_id", insertable = false, updatable = false)
    private Property property;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false)
    private User user;

    @Column(nullable = false)
    private Integer quantity;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private RentalStatus status;

    @Column(name = "admin_note", columnDefinition = "TEXT")
    private String adminNote;

    // Populated when the return is verified - "GOOD" or "DAMAGED" for now,
    // kept as a plain string so a DAMAGE bill type can be added later without
    // touching this column.
    @Column(name = "return_condition", length = 20)
    private String returnCondition;

    @Column(name = "return_note", columnDefinition = "TEXT")
    private String returnNote;

    @Column(name = "requested_at", nullable = false)
    private Instant requestedAt;

    @Column(name = "decided_at")
    private Instant decidedAt;

    @Column(name = "return_requested_at")
    private Instant returnRequestedAt;

    @Column(name = "returned_at")
    private Instant returnedAt;
}

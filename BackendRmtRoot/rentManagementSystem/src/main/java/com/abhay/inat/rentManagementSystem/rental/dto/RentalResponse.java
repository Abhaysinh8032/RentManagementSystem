package com.abhay.inat.rentManagementSystem.rental.dto;

import com.abhay.inat.rentManagementSystem.billing.dto.BillResponse;
import lombok.Builder;
import lombok.Getter;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

@Getter
@Builder
public class RentalResponse {
    private Long id;
    private Long propertyId;
    private String propertyName;
    private Long userId;
    private String userName;
    private Integer quantity;
    private LocalDate startDate;
    private LocalDate endDate;
    private String status;
    private String adminNote;
    private String returnCondition;
    private String returnNote;
    private Instant requestedAt;
    private Instant decidedAt;
    private Instant returnRequestedAt;
    private Instant returnedAt;
    private List<BillResponse> bills;
}

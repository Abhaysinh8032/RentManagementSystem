package com.abhay.inat.rentManagementSystem.rental.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ReturnDecisionRequest {
    // false = admin disputes that the property was actually returned in good order;
    // reverts the request back to APPROVED instead of restocking it.
    private boolean approve;
    private boolean damaged;
    private String adminNote;
}

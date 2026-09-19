package com.abhay.inat.rentManagementSystem.rental.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class DecisionRequest {
    private boolean approve;
    private String adminNote;
}

package com.abhay.inat.rentManagementSystem.property.dto;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@Builder
public class PropertyResponse {
    private Long id;
    private String name;
    private String category;
    private String description;
    private String imageUrl;
    private Integer totalQuantity;
    private Integer availableQuantity;
    private BigDecimal pricePerUnitPerDay;
    private BigDecimal depositPerUnit;
    private Boolean active;
}

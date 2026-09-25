package com.abhay.inat.rentManagementSystem.property.dto;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Builder
public class PropertyResponse {
    private Long id;
    private String name;
    private String category;
    private String description;
    private List<String> imageUrls;
    private Integer totalQuantity;
    private Integer availableQuantity;
    private BigDecimal pricePerUnitPerDay;
    private BigDecimal depositPerUnit;
    private Boolean active;
}

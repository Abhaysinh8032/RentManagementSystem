package com.abhay.inat.rentManagementSystem.property.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PropertyRequest {

    @NotBlank(message = "Name is required")
    private String name;

    private String category;

    private String description;

    // Full-replace semantics: whatever list is sent on update becomes the
    // complete image set - it's not an incremental add. Optional (a property
    // can have zero images), capped to keep the gallery sane.
//    @Size(max = 6, message = "A property can have at most 6 images")
    private List<String> imageUrls;

    @NotNull(message = "Total quantity is required")
    @Min(value = 1, message = "Total quantity must be at least 1")
    private Integer totalQuantity;

    @NotNull(message = "Price per unit per day is required")
    @DecimalMin(value = "0.0", inclusive = false, message = "Price must be greater than 0")
    private BigDecimal pricePerUnitPerDay;

    @NotNull(message = "Deposit per unit is required")
    @DecimalMin(value = "0.0", message = "Deposit cannot be negative")
    private BigDecimal depositPerUnit;
}

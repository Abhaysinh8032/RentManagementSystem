package com.abhay.inat.rentManagementSystem.property;

import com.abhay.inat.rentManagementSystem.common.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.SuperBuilder;

import java.math.BigDecimal;

@Entity
@Table(name = "properties")
@Getter
@Setter
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class Property extends BaseEntity {

    @Column(nullable = false, length = 150)
    private String name;

    @Column(length = 60)
    private String category;

    @Column(columnDefinition = "TEXT")
    private String description;

    // NOTE: the old single "image_url" column stays in the DB (Hibernate's
    // ddl-auto=update never drops removed columns) but is no longer read or
    // written anywhere - images now live in the property_images table via
    // PropertyImage. See README for the optional cleanup SQL.
    //@Column(name = "image_url", columnDefinition = "TEXT")
    //private String imageUrl;

    @Column(name = "total_quantity", nullable = false)
    private Integer totalQuantity;

    // Real-time stock counter: decremented when a request is APPROVED,
    // incremented back when a return is verified (RETURNED). See RentalServiceImpl.
    @Column(name = "available_quantity", nullable = false)
    private Integer availableQuantity;

    @Column(name = "price_per_unit_per_day", nullable = false)
    private BigDecimal pricePerUnitPerDay;

    // Flat deposit charged per rented unit, e.g. deposit for one bench.
    @Column(name = "deposit_per_unit", nullable = false)
    private BigDecimal depositPerUnit;

    @Column(nullable = false)
    private Boolean active;
}

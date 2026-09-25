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

/**
 * Replaces Property.imageUrl (single string). One row per image; ordering is
 * just insertion order (auto-increment id), which is enough since there's no
 * reordering feature - the first image returned is treated as the cover photo
 * by the client.
 */
@Entity
@Table(name = "property_images")
@Getter
@Setter
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class PropertyImage extends BaseEntity {

    @Column(name = "property_id", nullable = false)
    private Long propertyId;

    @Column(name = "image_url", nullable = false, columnDefinition = "TEXT")
    private String imageUrl;
}

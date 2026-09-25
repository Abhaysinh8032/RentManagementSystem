package com.abhay.inat.rentManagementSystem.property;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PropertyImageRepository extends JpaRepository<PropertyImage, Long> {
    List<PropertyImage> findByPropertyIdOrderByIdAsc(Long propertyId);
    void deleteByPropertyId(Long propertyId);
}

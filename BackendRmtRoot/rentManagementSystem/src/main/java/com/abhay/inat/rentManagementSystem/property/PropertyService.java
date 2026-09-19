package com.abhay.inat.rentManagementSystem.property;

import com.abhay.inat.rentManagementSystem.property.dto.PropertyRequest;
import com.abhay.inat.rentManagementSystem.property.dto.PropertyResponse;

import java.util.List;

public interface PropertyService {
    PropertyResponse create(PropertyRequest request);
    PropertyResponse update(Long id, PropertyRequest request);
    PropertyResponse setActive(Long id, boolean active);
    PropertyResponse getById(Long id);
    List<PropertyResponse> listActive();
    List<PropertyResponse> listAllForAdmin();
}

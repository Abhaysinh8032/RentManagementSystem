package com.abhay.inat.rentManagementSystem.property;

import com.abhay.inat.rentManagementSystem.common.exception.ResourceNotFoundException;
import com.abhay.inat.rentManagementSystem.property.dto.PropertyRequest;
import com.abhay.inat.rentManagementSystem.property.dto.PropertyResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PropertyServiceImpl implements PropertyService {

    private final PropertyRepository propertyRepository;

    @Override
    public PropertyResponse create(PropertyRequest request) {
        Property property = Property.builder()
                .name(request.getName())
                .category(request.getCategory())
                .description(request.getDescription())
                .imageUrl(request.getImageUrl())
                .totalQuantity(request.getTotalQuantity())
                .availableQuantity(request.getTotalQuantity()) // starts fully in stock
                .pricePerUnitPerDay(request.getPricePerUnitPerDay())
                .depositPerUnit(request.getDepositPerUnit())
                .active(true)
                .build();

        return toResponse(propertyRepository.save(property));
    }

    @Override
    public PropertyResponse update(Long id, PropertyRequest request) {
        Property property = findOrThrow(id);

        // If admin raises totalQuantity, pass the increase straight into availableQuantity.
        // If admin lowers it, reduce availableQuantity too but never below zero
        // (don't retroactively cancel rentals that are already out).
        int delta = request.getTotalQuantity() - property.getTotalQuantity();
        int newAvailable = Math.max(0, property.getAvailableQuantity() + delta);

        property.setName(request.getName());
        property.setCategory(request.getCategory());
        property.setDescription(request.getDescription());
        property.setImageUrl(request.getImageUrl());
        property.setTotalQuantity(request.getTotalQuantity());
        property.setAvailableQuantity(newAvailable);
        property.setPricePerUnitPerDay(request.getPricePerUnitPerDay());
        property.setDepositPerUnit(request.getDepositPerUnit());

        return toResponse(propertyRepository.save(property));
    }

    @Override
    public PropertyResponse setActive(Long id, boolean active) {
        Property property = findOrThrow(id);
        property.setActive(active);
        return toResponse(propertyRepository.save(property));
    }

    @Override
    public PropertyResponse getById(Long id) {
        return toResponse(findOrThrow(id));
    }

    @Override
    public List<PropertyResponse> listActive() {
        return propertyRepository.findByActiveTrue().stream().map(this::toResponse).toList();
    }

    @Override
    public List<PropertyResponse> listAllForAdmin() {
        return propertyRepository.findAll().stream().map(this::toResponse).toList();
    }

    private Property findOrThrow(Long id) {
        return propertyRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Property not found with id: " + id));
    }

    private PropertyResponse toResponse(Property p) {
        return PropertyResponse.builder()
                .id(p.getId())
                .name(p.getName())
                .category(p.getCategory())
                .description(p.getDescription())
                .imageUrl(p.getImageUrl())
                .totalQuantity(p.getTotalQuantity())
                .availableQuantity(p.getAvailableQuantity())
                .pricePerUnitPerDay(p.getPricePerUnitPerDay())
                .depositPerUnit(p.getDepositPerUnit())
                .active(p.getActive())
                .build();
    }
}

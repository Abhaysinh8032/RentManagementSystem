package com.abhay.inat.rentManagementSystem.property;

import com.abhay.inat.rentManagementSystem.common.ApiResponse;
import com.abhay.inat.rentManagementSystem.property.dto.PropertyRequest;
import com.abhay.inat.rentManagementSystem.property.dto.PropertyResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class PropertyController {

    private final PropertyService propertyService;

    // ---- Customer-facing (any authenticated user) ----

    @GetMapping("/properties")
    public ResponseEntity<ApiResponse<List<PropertyResponse>>> listActive() {
        return ResponseEntity.ok(ApiResponse.success("Active properties", propertyService.listActive()));
    }

    @GetMapping("/properties/{id}")
    public ResponseEntity<ApiResponse<PropertyResponse>> getById(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success("Property detail", propertyService.getById(id)));
    }

    // ---- Admin-only ----

    @PostMapping("/admin/properties")
    public ResponseEntity<ApiResponse<PropertyResponse>> create(@Valid @RequestBody PropertyRequest request) {
        PropertyResponse response = propertyService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Property created", response));
    }

    @PutMapping("/admin/properties/{id}")
    public ResponseEntity<ApiResponse<PropertyResponse>> update(@PathVariable Long id,
                                                                 @Valid @RequestBody PropertyRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Property updated", propertyService.update(id, request)));
    }

    @PutMapping("/admin/properties/{id}/active")
    public ResponseEntity<ApiResponse<PropertyResponse>> setActive(@PathVariable Long id,
                                                                    @RequestParam boolean active) {
        return ResponseEntity.ok(ApiResponse.success("Property status updated", propertyService.setActive(id, active)));
    }

    @GetMapping("/admin/properties")
    public ResponseEntity<ApiResponse<List<PropertyResponse>>> listAllForAdmin() {
        return ResponseEntity.ok(ApiResponse.success("All properties", propertyService.listAllForAdmin()));
    }
}

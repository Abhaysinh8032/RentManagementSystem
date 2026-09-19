package com.abhay.inat.rentManagementSystem.rental;

import com.abhay.inat.rentManagementSystem.common.ApiResponse;
import com.abhay.inat.rentManagementSystem.common.enums.RentalStatus;
import com.abhay.inat.rentManagementSystem.common.enums.UserRole;
import com.abhay.inat.rentManagementSystem.rental.dto.CreateRentalRequest;
import com.abhay.inat.rentManagementSystem.rental.dto.DecisionRequest;
import com.abhay.inat.rentManagementSystem.rental.dto.RentalResponse;
import com.abhay.inat.rentManagementSystem.rental.dto.ReturnDecisionRequest;
import com.abhay.inat.rentManagementSystem.security.CurrentUserResolver;
import com.abhay.inat.rentManagementSystem.user.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class RentalController {

    private final RentalService rentalService;
    private final CurrentUserResolver currentUserResolver;

    // ---- Customer-facing ----

    @PostMapping("/rental-requests")
    public ResponseEntity<ApiResponse<RentalResponse>> createRequest(
            @Valid @RequestBody CreateRentalRequest request, Authentication authentication) {
        User user = currentUserResolver.resolve(authentication);
        RentalResponse response = rentalService.createRequest(user.getId(), request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Rental request submitted", response));
    }

    @GetMapping("/rental-requests/mine")
    public ResponseEntity<ApiResponse<List<RentalResponse>>> listMine(Authentication authentication) {
        User user = currentUserResolver.resolve(authentication);
        return ResponseEntity.ok(ApiResponse.success("Your rental requests", rentalService.listMine(user.getId())));
    }

    @GetMapping("/rental-requests/{id}")
    public ResponseEntity<ApiResponse<RentalResponse>> getById(@PathVariable Long id, Authentication authentication) {
        User user = currentUserResolver.resolve(authentication);
        boolean isAdmin = user.getRole() == UserRole.ADMIN;
        return ResponseEntity.ok(ApiResponse.success("Rental request detail", rentalService.getById(id, user.getId(), isAdmin)));
    }

    @PutMapping("/rental-requests/{id}/return-request")
    public ResponseEntity<ApiResponse<RentalResponse>> requestReturn(@PathVariable Long id, Authentication authentication) {
        User user = currentUserResolver.resolve(authentication);
        return ResponseEntity.ok(ApiResponse.success("Return request submitted", rentalService.requestReturn(id, user.getId())));
    }

    // ---- Admin-only ----

    @GetMapping("/admin/rental-requests")
    public ResponseEntity<ApiResponse<List<RentalResponse>>> listAllForAdmin(
            @RequestParam(required = false) RentalStatus status) {
        return ResponseEntity.ok(ApiResponse.success("Rental requests", rentalService.listAllForAdmin(status)));
    }

    @PutMapping("/admin/rental-requests/{id}/decision")
    public ResponseEntity<ApiResponse<RentalResponse>> decide(
            @PathVariable Long id, @RequestBody DecisionRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Rental request reviewed", rentalService.decide(id, request)));
    }

    @PutMapping("/admin/rental-requests/{id}/return-decision")
    public ResponseEntity<ApiResponse<RentalResponse>> decideReturn(
            @PathVariable Long id, @RequestBody ReturnDecisionRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Return reviewed", rentalService.decideReturn(id, request)));
    }
}

package com.abhay.inat.rentManagementSystem.rental;

import com.abhay.inat.rentManagementSystem.billing.BillingService;
import com.abhay.inat.rentManagementSystem.billing.dto.BillResponse;
import com.abhay.inat.rentManagementSystem.common.enums.RentalStatus;
import com.abhay.inat.rentManagementSystem.common.enums.UserStatus;
import com.abhay.inat.rentManagementSystem.common.exception.InsufficientStockException;
import com.abhay.inat.rentManagementSystem.common.exception.InvalidStateException;
import com.abhay.inat.rentManagementSystem.common.exception.ResourceNotFoundException;
import com.abhay.inat.rentManagementSystem.property.Property;
import com.abhay.inat.rentManagementSystem.property.PropertyRepository;
import com.abhay.inat.rentManagementSystem.rental.dto.CreateRentalRequest;
import com.abhay.inat.rentManagementSystem.rental.dto.DecisionRequest;
import com.abhay.inat.rentManagementSystem.rental.dto.RentalResponse;
import com.abhay.inat.rentManagementSystem.rental.dto.ReturnDecisionRequest;
import com.abhay.inat.rentManagementSystem.user.User;
import com.abhay.inat.rentManagementSystem.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RentalServiceImpl implements RentalService {

    private final RentalRequestRepository rentalRequestRepository;
    private final PropertyRepository propertyRepository;
    private final UserRepository userRepository;
    private final BillingService billingService;

    @Override
    @Transactional
    public RentalResponse createRequest(Long userId, CreateRentalRequest request) {
        User requester = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (requester.getStatus() != UserStatus.APPROVED) {
            throw new InvalidStateException(
                    "Your account must be approved by the admin before you can request a rental");
        }

        Property property = propertyRepository.findById(request.getPropertyId())
                .orElseThrow(() -> new ResourceNotFoundException("Property not found with id: " + request.getPropertyId()));

        if (!Boolean.TRUE.equals(property.getActive())) {
            throw new InvalidStateException("This property is not currently available for rent");
        }

        if (!request.getEndDate().isAfter(request.getStartDate())) {
            throw new InvalidStateException("End date must be after start date");
        }

        // Fast-fail check for a good error message immediately. The authoritative,
        // race-condition-safe check happens again with a row lock at approval time
        // in decide() - stock isn't actually reserved until an admin approves.
        if (property.getAvailableQuantity() < request.getQuantity()) {
            throw new InsufficientStockException(
                    "Only " + property.getAvailableQuantity() + " unit(s) of \"" + property.getName() + "\" available right now");
        }

        long days = Math.max(1, ChronoUnit.DAYS.between(request.getStartDate(), request.getEndDate()));
        BigDecimal rentAmount = property.getPricePerUnitPerDay()
                .multiply(BigDecimal.valueOf(request.getQuantity()))
                .multiply(BigDecimal.valueOf(days));
        BigDecimal depositAmount = property.getDepositPerUnit().multiply(BigDecimal.valueOf(request.getQuantity()));

        RentalRequest rentalRequest = RentalRequest.builder()
                .propertyId(property.getId())
                .userId(userId)
                .quantity(request.getQuantity())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .status(RentalStatus.PENDING)
                .requestedAt(Instant.now())
                .build();

        rentalRequest = rentalRequestRepository.save(rentalRequest);

        List<BillResponse> bills = billingService.generateBillsForRequest(rentalRequest.getId(), rentAmount, depositAmount);

        return toResponse(rentalRequest, property, bills);
    }

    @Override
    public RentalResponse getById(Long id, Long currentUserId, boolean isAdmin) {
        RentalRequest rentalRequest = findOrThrow(id);
        if (!isAdmin && !rentalRequest.getUserId().equals(currentUserId)) {
            throw new AccessDeniedException("This rental request does not belong to you");
        }
        return toResponse(rentalRequest, isAdmin, currentUserId);
    }

    @Override
    public List<RentalResponse> listMine(Long userId) {
        return rentalRequestRepository.findByUserId(userId).stream()
                .map(rr -> toResponse(rr, false, userId))
                .toList();
    }

    @Override
    public List<RentalResponse> listAllForAdmin(RentalStatus statusFilter) {
        List<RentalRequest> requests = statusFilter == null
                ? rentalRequestRepository.findAll()
                : rentalRequestRepository.findByStatus(statusFilter);

        return requests.stream().map(rr -> toResponse(rr, true, null)).toList();
    }

    @Override
    @Transactional
    public RentalResponse decide(Long id, DecisionRequest request) {
        RentalRequest rentalRequest = findOrThrow(id);

        if (rentalRequest.getStatus() != RentalStatus.PENDING) {
            throw new InvalidStateException(
                    "Only pending requests can be approved or rejected (current status: " + rentalRequest.getStatus() + ")");
        }

        if (request.isApprove()) {
            // Row-locked re-check: the fast-fail check in createRequest() is just
            // for UX. This is the check that actually prevents double-booking when
            // two admins (or two approvals) race each other.
            Property property = propertyRepository.findByIdForUpdate(rentalRequest.getPropertyId())
                    .orElseThrow(() -> new ResourceNotFoundException("Property not found"));

            if (property.getAvailableQuantity() < rentalRequest.getQuantity()) {
                throw new InsufficientStockException(
                        "Not enough stock remains to approve this request (available: " + property.getAvailableQuantity() + ")");
            }

            property.setAvailableQuantity(property.getAvailableQuantity() - rentalRequest.getQuantity());
            propertyRepository.save(property);

            rentalRequest.setStatus(RentalStatus.APPROVED);
        } else {
            rentalRequest.setStatus(RentalStatus.REJECTED);
        }

        rentalRequest.setAdminNote(request.getAdminNote());
        rentalRequest.setDecidedAt(Instant.now());

        rentalRequest = rentalRequestRepository.save(rentalRequest);
        return toResponse(rentalRequest, true, null);
    }

    @Override
    @Transactional
    public RentalResponse requestReturn(Long id, Long userId) {
        RentalRequest rentalRequest = findOrThrow(id);

        if (!rentalRequest.getUserId().equals(userId)) {
            throw new AccessDeniedException("This rental request does not belong to you");
        }

        if (rentalRequest.getStatus() != RentalStatus.APPROVED) {
            throw new InvalidStateException(
                    "Only an active (approved) rental can be returned (current status: " + rentalRequest.getStatus() + ")");
        }

        rentalRequest.setStatus(RentalStatus.RETURN_REQUESTED);
        rentalRequest.setReturnRequestedAt(Instant.now());

        rentalRequest = rentalRequestRepository.save(rentalRequest);
        return toResponse(rentalRequest, false, userId);
    }

    @Override
    @Transactional
    public RentalResponse decideReturn(Long id, ReturnDecisionRequest request) {
        RentalRequest rentalRequest = findOrThrow(id);

        if (rentalRequest.getStatus() != RentalStatus.RETURN_REQUESTED) {
            throw new InvalidStateException(
                    "There is no pending return to verify on this request (current status: " + rentalRequest.getStatus() + ")");
        }

        if (request.isApprove()) {
            Property property = propertyRepository.findByIdForUpdate(rentalRequest.getPropertyId())
                    .orElseThrow(() -> new ResourceNotFoundException("Property not found"));

            property.setAvailableQuantity(property.getAvailableQuantity() + rentalRequest.getQuantity());
            propertyRepository.save(property);

            rentalRequest.setStatus(RentalStatus.RETURNED);
            rentalRequest.setReturnedAt(Instant.now());
            rentalRequest.setReturnCondition(request.isDamaged() ? "DAMAGED" : "GOOD");
        } else {
            // Return didn't actually check out (e.g. item wasn't really handed back yet) -
            // put it back to APPROVED so the customer can submit a return request again later.
            rentalRequest.setStatus(RentalStatus.APPROVED);
        }

        rentalRequest.setReturnNote(request.getAdminNote());

        rentalRequest = rentalRequestRepository.save(rentalRequest);
        return toResponse(rentalRequest, true, null);
    }

    private RentalRequest findOrThrow(Long id) {
        return rentalRequestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Rental request not found with id: " + id));
    }

    private RentalResponse toResponse(RentalRequest rr, boolean isAdmin, Long currentUserId) {
        Property property = propertyRepository.findById(rr.getPropertyId()).orElse(null);
        List<BillResponse> bills = billingService.listByRentalRequest(
                rr.getId(), currentUserId != null ? currentUserId : rr.getUserId(), isAdmin);
        return toResponse(rr, property, bills);
    }

    private RentalResponse toResponse(RentalRequest rr, Property property, List<BillResponse> bills) {
        User user = userRepository.findById(rr.getUserId()).orElse(null);

        return RentalResponse.builder()
                .id(rr.getId())
                .propertyId(rr.getPropertyId())
                .propertyName(property != null ? property.getName() : null)
                .userId(rr.getUserId())
                .userName(user != null ? user.getName() : null)
                .quantity(rr.getQuantity())
                .startDate(rr.getStartDate())
                .endDate(rr.getEndDate())
                .status(rr.getStatus().name())
                .adminNote(rr.getAdminNote())
                .returnCondition(rr.getReturnCondition())
                .returnNote(rr.getReturnNote())
                .requestedAt(rr.getRequestedAt())
                .decidedAt(rr.getDecidedAt())
                .returnRequestedAt(rr.getReturnRequestedAt())
                .returnedAt(rr.getReturnedAt())
                .bills(bills)
                .build();
    }
}

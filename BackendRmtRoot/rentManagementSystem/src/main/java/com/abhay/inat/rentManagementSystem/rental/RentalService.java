package com.abhay.inat.rentManagementSystem.rental;

import com.abhay.inat.rentManagementSystem.common.enums.RentalStatus;
import com.abhay.inat.rentManagementSystem.rental.dto.CreateRentalRequest;
import com.abhay.inat.rentManagementSystem.rental.dto.DecisionRequest;
import com.abhay.inat.rentManagementSystem.rental.dto.RentalResponse;
import com.abhay.inat.rentManagementSystem.rental.dto.ReturnDecisionRequest;

import java.util.List;

public interface RentalService {

    RentalResponse createRequest(Long userId, CreateRentalRequest request);

    RentalResponse getById(Long id, Long currentUserId, boolean isAdmin);

    List<RentalResponse> listMine(Long userId);

    List<RentalResponse> listAllForAdmin(RentalStatus statusFilter);

    RentalResponse decide(Long id, DecisionRequest request);

    RentalResponse requestReturn(Long id, Long userId);

    RentalResponse decideReturn(Long id, ReturnDecisionRequest request);
}

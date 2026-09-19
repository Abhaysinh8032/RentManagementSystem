package com.abhay.inat.rentManagementSystem.rental;

import com.abhay.inat.rentManagementSystem.common.enums.RentalStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RentalRequestRepository extends JpaRepository<RentalRequest, Long> {
    List<RentalRequest> findByUserId(Long userId);
    List<RentalRequest> findByStatus(RentalStatus status);
}

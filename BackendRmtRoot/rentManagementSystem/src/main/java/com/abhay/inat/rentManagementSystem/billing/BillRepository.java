package com.abhay.inat.rentManagementSystem.billing;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BillRepository extends JpaRepository<Bill, Long> {
    List<Bill> findByRentalRequestId(Long rentalRequestId);
    List<Bill> findByRentalRequestIdIn(List<Long> rentalRequestIds);
}

package com.abhay.inat.rentManagementSystem.billing;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BillProofImageRepository extends JpaRepository<BillProofImage, Long> {
    List<BillProofImage> findByBillIdOrderByIdAsc(Long billId);
    void deleteByBillId(Long billId);
}

package com.abhay.inat.rentManagementSystem.user;

import com.abhay.inat.rentManagementSystem.common.enums.UserStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
    List<User> findByStatus(UserStatus status);
}

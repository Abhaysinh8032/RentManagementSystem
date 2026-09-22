package com.abhay.inat.rentManagementSystem.user;

import com.abhay.inat.rentManagementSystem.common.ApiResponse;
import com.abhay.inat.rentManagementSystem.user.dto.UserResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin/users")
@RequiredArgsConstructor
public class AdminUserController {

    private final UserService userService;

    @GetMapping("/pending")
    public ResponseEntity<ApiResponse<List<UserResponse>>> listPending() {
        return ResponseEntity.ok(ApiResponse.success("Users awaiting approval", userService.listPendingUsers()));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<UserResponse>>> listAll() {
        return ResponseEntity.ok(ApiResponse.success("All users", userService.listAllUsers()));
    }

    @PutMapping("/{id}/approve")
    public ResponseEntity<ApiResponse<UserResponse>> decide(@PathVariable Long id, @RequestParam boolean approve) {
        String message = approve ? "User approved" : "User rejected and blocked";
        return ResponseEntity.ok(ApiResponse.success(message, userService.decideApproval(id, approve)));
    }
}

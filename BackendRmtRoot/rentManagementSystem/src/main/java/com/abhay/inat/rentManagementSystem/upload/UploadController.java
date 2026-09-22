package com.abhay.inat.rentManagementSystem.upload;

import com.abhay.inat.rentManagementSystem.common.ApiResponse;
import com.abhay.inat.rentManagementSystem.common.exception.InvalidStateException;
import com.abhay.inat.rentManagementSystem.common.exception.UploadFailedException;
import com.abhay.inat.rentManagementSystem.upload.dto.UploadResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Set;

@RestController
@RequiredArgsConstructor
public class UploadController {

    private static final long MAX_FILE_SIZE_BYTES = 5L * 1024 * 1024; // 5MB
    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of("image/jpeg", "image/png", "image/webp");

    private final CloudinaryStorageService cloudinaryStorageService;
    private final SupabaseStorageService supabaseStorageService;

    /** Admin only (falls under /admin/** in SecurityConfig) - only admins create/edit properties. */
    @PostMapping("/admin/uploads/property-image")
    public ResponseEntity<ApiResponse<UploadResponse>> uploadPropertyImage(@RequestParam("file") MultipartFile file) {
        byte[] bytes = validateAndRead(file);
        String url = cloudinaryStorageService.upload(bytes, file.getOriginalFilename(), file.getContentType());
        return ResponseEntity.ok(ApiResponse.success("Image uploaded", UploadResponse.builder().url(url).build()));
    }

    /**
     * Any authenticated user (falls under anyRequest().authenticated()) -
     * customers upload their own payment proof. Deliberately not tied to a
     * specific bill id: upload first to get a URL, then pass that URL into
     * the existing PUT /bills/{id}/claim-payment call, same two-step pattern
     * as property images (upload -> get URL -> use URL in the create/update call).
     */
    @PostMapping("/uploads/payment-proof-image")
    public ResponseEntity<ApiResponse<UploadResponse>> uploadPaymentProofImage(@RequestParam("file") MultipartFile file) {
        byte[] bytes = validateAndRead(file);
        String url = supabaseStorageService.upload(bytes, file.getOriginalFilename(), file.getContentType());
        return ResponseEntity.ok(ApiResponse.success("Image uploaded", UploadResponse.builder().url(url).build()));
    }

    private byte[] validateAndRead(MultipartFile file) {
        if (file.isEmpty()) {
            throw new InvalidStateException("File is empty");
        }
        if (file.getSize() > MAX_FILE_SIZE_BYTES) {
            throw new InvalidStateException("File exceeds the 5MB limit");
        }

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw new InvalidStateException("Only JPEG, PNG or WEBP images are allowed");
        }

        try {
            return file.getBytes();
        } catch (IOException e) {
            throw new UploadFailedException("Could not read the uploaded file: " + e.getMessage());
        }
    }
}

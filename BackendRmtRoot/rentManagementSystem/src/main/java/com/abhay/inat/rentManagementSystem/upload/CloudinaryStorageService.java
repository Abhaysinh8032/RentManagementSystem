package com.abhay.inat.rentManagementSystem.upload;

import com.abhay.inat.rentManagementSystem.common.exception.UploadFailedException;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * PROPERTY IMAGES ONLY. Uses the official Cloudinary Java SDK, which handles
 * Cloudinary's signed-upload requirement internally. Chosen for this use
 * case specifically for its on-the-fly transformation/CDN features (useful
 * for browsed listing thumbnails) - see SupabaseStorageService for why
 * payment-proof images use a different provider entirely.
 */
@Service
public class CloudinaryStorageService implements ImageStorageService {

    @Value("${app.cloudinary.cloud-name}")
    private String cloudName;

    @Value("${app.cloudinary.api-key}")
    private String apiKey;

    @Value("${app.cloudinary.api-secret}")
    private String apiSecret;

    private Cloudinary cloudinary;

    @PostConstruct
    void init() {
        cloudinary = new Cloudinary(ObjectUtils.asMap(
                "cloud_name", cloudName,
                "api_key", apiKey,
                "api_secret", apiSecret,
                "secure", true));
    }

    @Override
    public String upload(byte[] bytes, String originalFilename, String contentType) {
        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> result = cloudinary.uploader().upload(bytes, ObjectUtils.asMap(
                    "folder", "properties",
                    "resource_type", "image"
            ));

            String secureUrl = (String) result.get("secure_url");
            if (secureUrl == null) {
                throw new UploadFailedException("Cloudinary did not return a URL for the uploaded image");
            }
            return secureUrl;
        } catch (Exception e) {
            throw new UploadFailedException("Image upload failed: " + e.getMessage());
        }
    }
}

package com.abhay.inat.rentManagementSystem.upload;

import com.abhay.inat.rentManagementSystem.common.exception.UploadFailedException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.UUID;

/**
 * PAYMENT-PROOF IMAGES ONLY (not property images - see CloudinaryStorageService).
 * Uses Supabase Storage's plain REST API via java.net.http, no SDK dependency.
 * No transformation is applied - the raw bytes are stored exactly as uploaded,
 * which matters here: an admin needs to read an exact transaction reference or
 * amount off this screenshot, so nothing should ever compress or reformat it.
 *
 * Separate bucket from anything else in the Supabase project (your Postgres
 * DB usage is completely unrelated and unaffected by any of this).
 *
 * SECURITY NOTE worth a decision, not just a code comment: this uploads to a
 * bucket assumed to be public-read (same pattern as the property-image
 * bucket), so the URL is viewable by anyone who has it. Object paths are
 * random UUIDs (unguessable), but a payment screenshot can contain bank/UPI
 * details, so "unguessable but technically public" is a real trade-off, not
 * a non-issue. If that's a concern before this goes in front of a real
 * client, the fix is switching this bucket to private and generating a
 * short-lived signed URL per view instead of a permanent public one - a
 * bigger change than a config flag, so flag it if you want that done before
 * launch rather than after.
 */
@Service
public class SupabaseStorageService implements ImageStorageService {

    @Value("${app.supabase-storage.storage-url}")
    private String storageUrl; // e.g. https://YOUR_PROJECT.supabase.co/storage/v1

    @Value("${app.supabase-storage.service-role-key}")
    private String serviceRoleKey;

    @Value("${app.supabase-storage.payment-proof-bucket}")
    private String bucket;

    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Override
    public String upload(byte[] bytes, String originalFilename, String contentType) {
        String objectPath = "payment-proofs/" + UUID.randomUUID() + extensionOf(originalFilename);
        String uploadUrl = storageUrl + "/object/" + bucket + "/" + objectPath;

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(uploadUrl))
                .header("apikey", serviceRoleKey)
                .header("Authorization", "Bearer " + serviceRoleKey)
                .header("Content-Type", contentType)
                .PUT(HttpRequest.BodyPublishers.ofByteArray(bytes))
                .build();

        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 300) {
                throw new UploadFailedException("Supabase Storage rejected the upload: " + response.body());
            }
        } catch (IOException e) {
            throw new UploadFailedException("Image upload failed: " + e.getMessage());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new UploadFailedException("Image upload was interrupted");
        }

        return storageUrl + "/object/public/" + bucket + "/" + objectPath;
    }

    private String extensionOf(String filename) {
        if (filename == null) return ".jpg";
        int dot = filename.lastIndexOf('.');
        return dot == -1 ? ".jpg" : filename.substring(dot).toLowerCase();
    }
}

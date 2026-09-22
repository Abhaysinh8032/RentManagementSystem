package com.abhay.inat.rentManagementSystem.upload;

/**
 * Two implementations, used for two different purposes - not interchangeable
 * at any single call site, so UploadController injects both concrete classes
 * directly rather than picking one via a bean qualifier. The shared contract
 * exists so swapping either provider later (e.g. payment-proof storage off
 * Supabase onto Cloudflare R2) means writing one new class against this
 * interface and changing one wire-up line in UploadController - nothing else
 * in the codebase needs to know or care which provider is behind it.
 */
public interface ImageStorageService {
    String upload(byte[] bytes, String originalFilename, String contentType);
}

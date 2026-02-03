package com.viet.backend.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class CloudinaryService {

    private final Cloudinary cloudinary;

    /**
     * Uploads a file to Cloudinary and returns the URL.
     *
     * @param file   The file to upload.
     * @param folder The folder name on Cloudinary.
     * @return The secure URL of the uploaded image.
     */
    public String uploadFile(MultipartFile file, String folder) {
        try {
            Map<?, ?> uploadResult = cloudinary.uploader().upload(file.getBytes(),
                    ObjectUtils.asMap("folder", folder));
            return uploadResult.get("secure_url").toString();
        } catch (IOException e) {
            log.error("Error uploading file to Cloudinary: {}", e.getMessage());
            throw new RuntimeException("Failed to upload image to Cloudinary", e);
        }
    }

    /**
     * Deletes a file from Cloudinary using its public ID.
     *
     * @param publicId The public ID of the image to delete.
     */
    public void deleteFile(String publicId) {
        try {
            cloudinary.uploader().destroy(publicId, ObjectUtils.emptyMap());
        } catch (IOException e) {
            log.error("Error deleting file from Cloudinary: {}", e.getMessage());
            throw new RuntimeException("Failed to delete image from Cloudinary", e);
        }
    }

    /**
     * Extracts the public ID from a Cloudinary URL to use for deletion.
     * 
     * @param url The Cloudinary secure URL.
     * @return The public ID of the image.
     */
    public String getPublicIdFromUrl(String url) {
        // Example:
        // https://res.cloudinary.com/demo/image/upload/v123456/folder/sample.jpg
        // Public ID: folder/sample
        try {
            String[] parts = url.split("/");
            String filename = parts[parts.length - 1];
            // String folder = parts[parts.length - 2];

            // Check if there are nested folders
            int uploadIndex = -1;
            for (int i = 0; i < parts.length; i++) {
                if (parts[i].equals("upload")) {
                    uploadIndex = i;
                    break;
                }
            }

            if (uploadIndex != -1 && parts.length > uploadIndex + 2) {
                StringBuilder publicId = new StringBuilder();
                for (int i = uploadIndex + 2; i < parts.length - 1; i++) {
                    publicId.append(parts[i]).append("/");
                }
                publicId.append(filename.substring(0, filename.lastIndexOf(".")));
                return publicId.toString();
            }

            return filename.substring(0, filename.lastIndexOf("."));
        } catch (Exception e) {
            log.warn("Could not extract publicId from URL: {}", url);
            return null;
        }
    }
}

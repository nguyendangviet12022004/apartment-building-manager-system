package com.viet.backend.controller;

import com.viet.backend.service.CloudinaryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("api/v1/files")
@RequiredArgsConstructor
public class FileUploadController {

    private final CloudinaryService cloudinaryService;

    /**
     * Uploads multiple files (images or videos) to Cloudinary.
     *
     * @param files  The files to upload (Multipart).
     * @param folder Optional folder name on Cloudinary.
     * @return List of secure URLs of the uploaded files.
     */
    @PostMapping("/upload")
    public ResponseEntity<List<String>> uploadFiles(
            @RequestParam("files") MultipartFile[] files,
            @RequestParam(value = "folder", required = false, defaultValue = "general") String folder) {

        List<String> urls = cloudinaryService.uploadMultipleFiles(files, folder);
        return ResponseEntity.ok(urls);
    }

    /**
     * Uploads a single file (image or video) to Cloudinary.
     *
     * @param file   The file to upload.
     * @param folder Optional folder name.
     * @return Secure URL of the uploaded file.
     */
    @PostMapping("/upload/single")
    public ResponseEntity<String> uploadSingleFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "folder", required = false, defaultValue = "general") String folder) {

        String url = cloudinaryService.uploadFile(file, folder);
        return ResponseEntity.ok(url);
    }
}

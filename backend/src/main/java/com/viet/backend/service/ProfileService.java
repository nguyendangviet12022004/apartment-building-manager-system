package com.viet.backend.service;

import com.viet.backend.dto.ProfileDTO;
import com.viet.backend.model.Apartment;
import com.viet.backend.model.Resident;
import com.viet.backend.model.User;
import com.viet.backend.repository.ApartmentRepository;
import com.viet.backend.repository.ResidentRepository;
import com.viet.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ProfileService {

    private final UserRepository      userRepository;
    private final ResidentRepository  residentRepository;
    private final ApartmentRepository apartmentRepository;

    // ── GET profile ──────────────────────────────────────────────────────────
    public ProfileDTO.Response getProfile(Integer userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + userId));

        Optional<Resident>  resOpt = residentRepository.findByUserId(userId);
        Optional<Apartment> aptOpt = apartmentRepository.findByResidentUserId(userId);

        return buildResponse(user, resOpt.orElse(null), aptOpt.orElse(null));
    }

    // ── PUT profile ──────────────────────────────────────────────────────────
    @Transactional
    public ProfileDTO.Response updateProfile(Integer userId, ProfileDTO.UpdateRequest req) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + userId));

        // Update user basic info
        if (req.getFirstname() != null) user.setFirstname(req.getFirstname());
        if (req.getLastname()  != null) user.setLastname(req.getLastname());
        if (req.getPhone()     != null) user.setPhone(req.getPhone());
        if (req.getDateOfBirth() != null) user.setDateOfBirth(req.getDateOfBirth());
        if (req.getGender()    != null) user.setGender(req.getGender());
        if (req.getAvatarUrl() != null) user.setAvatarUrl(req.getAvatarUrl());
        
        // Update preferences
        if (req.getLanguage() != null) user.setLanguage(req.getLanguage());
        if (req.getEmailNotifications() != null) user.setEmailNotifications(req.getEmailNotifications());
        if (req.getPushNotifications() != null) user.setPushNotifications(req.getPushNotifications());
        if (req.getTheme() != null) user.setTheme(req.getTheme());
        
        userRepository.save(user);

        // Update resident info
        Resident resident = residentRepository.findByUserId(userId)
                .orElse(Resident.builder().user(user).build());

        if (req.getIdentityCard() != null) {
            Optional<Resident> existingWithId = residentRepository.findByIdentityCard(req.getIdentityCard());
            if (existingWithId.isPresent() && !existingWithId.get().getUser().getId().equals(userId)) {
                throw new jakarta.persistence.EntityExistsException("Identity Card already exists in the system.");
            }
            resident.setIdentityCard(req.getIdentityCard());
        }
        
        // Handle emergency contact (store as "Name|Phone")
        if (req.getEmergencyContactName() != null || req.getEmergencyContactPhone() != null) {
            String name = req.getEmergencyContactName() != null ? req.getEmergencyContactName() : "";
            String phone = req.getEmergencyContactPhone() != null ? req.getEmergencyContactPhone() : "";
            resident.setEmergencyContact(name + "|" + phone);
        }
        
        // Handle relationship
        if (req.getEmergencyContactRelationship() != null) {
            resident.setEmergencyContactRelationship(req.getEmergencyContactRelationship());
        }
        
        residentRepository.save(resident);

        Optional<Apartment> aptOpt = apartmentRepository.findByResidentUserId(userId);
        return buildResponse(user, resident, aptOpt.orElse(null));
    }

    // ── Internal builder ─────────────────────────────────────────────────────
    private ProfileDTO.Response buildResponse(User user, Resident resident, Apartment apartment) {

        String firstName = nvl(user.getFirstname());
        String lastName  = nvl(user.getLastname());
        String fullName  = (firstName + " " + lastName).trim();
        String initials  = initials(firstName, lastName);
        String accountId = "RE-" + String.format("%05d", user.getId());

        // ── BR-03 Masking ─────────────────────────────────────────────────────
        String emailFull   = user.getEmail();
        String emailMasked = maskEmail(emailFull);
        String phoneFull   = user.getPhone();
        String phoneMasked = phoneFull != null ? maskPhone(phoneFull) : null;
        String dateOfBirth = user.getDateOfBirth();
        String gender      = user.getGender();

        // ── Resident data ─────────────────────────────────────────────────────
        String identityCard    = null;
        String emergencyName   = null;
        String emergencyPhone  = null;
        String relationship    = null;
        if (resident != null) {
            identityCard   = resident.getIdentityCard();
            relationship   = resident.getEmergencyContactRelationship();
            // emergencyContact stored as "Name|Phone" or just phone for now
            String ec = resident.getEmergencyContact();
            if (ec != null && ec.contains("|")) {
                String[] parts = ec.split("\\|", 2);
                emergencyName  = parts[0];
                emergencyPhone = parts[1];
            } else {
                emergencyPhone = ec;
            }
        }

        // ── Apartment data ────────────────────────────────────────────────────
        Long    aptId      = null;
        String  aptCode    = null;
        String  aptCodeFull= null;
        String  blockCode  = null;
        Integer floor      = null;
        Double  area       = null;
        String  aptStatus  = null;
        String  moveIn     = null;
        if (apartment != null) {
            aptId      = apartment.getId();
            aptCode    = apartment.getApartmentCode();
            aptCodeFull= apartment.getApartmentCode();
            blockCode  = apartment.getBlock() != null ? apartment.getBlock().getBlockCode() : null;
            floor      = apartment.getFloor();
            area       = apartment.getArea();
            aptStatus  = apartment.getStatus();
        }

        // ── BR-01 Completion ─────────────────────────────────────────────────
        List<ProfileDTO.CompletionItem> items = buildCompletionItems(
                user, resident, apartment, phoneFull);
        int completion = items.stream()
                .filter(ProfileDTO.CompletionItem::isCompleted)
                .mapToInt(ProfileDTO.CompletionItem::getWeight)
                .sum();

        return ProfileDTO.Response.builder()
                .userId(user.getId())
                .accountId(accountId)
                .firstname(firstName)
                .lastname(lastName)
                .fullName(fullName)
                .initials(initials)
                .avatarUrl(user.getAvatarUrl())
                .emailFull(emailFull)
                .emailMasked(emailMasked)
                .phoneFull(phoneFull)
                .phoneMasked(phoneMasked)
                .emailVerified(true)   // extend when email-verify flow added
                .phoneVerified(phoneFull != null)
                .dateOfBirth(dateOfBirth)
                .gender(gender)
                .identityCard(identityCard)
                .emergencyContactName(emergencyName)
                .emergencyContactPhone(emergencyPhone)
                .emergencyContactRelationship(relationship != null ? relationship : "")
                .apartmentId(aptId)
                .apartmentCode(aptCode)
                .apartmentCodeFull(aptCodeFull)
                .blockCode(blockCode)
                .floor(floor)
                .area(area)
                .apartmentStatus(aptStatus)
                .moveInDate(moveIn)
                .ownershipStatus("Owner")  // extend when lease/ownership entity exists
                .vehicles(List.of())       // extend when Vehicle entity added
                .twoFactorEnabled(false)
                .language(user.getLanguage() != null ? user.getLanguage() : "English")
                .emailNotifications(user.getEmailNotifications() != null ? user.getEmailNotifications() : true)
                .pushNotifications(user.getPushNotifications() != null ? user.getPushNotifications() : true)
                .theme(user.getTheme() != null ? user.getTheme() : "Light")
                .profileCompletion(Math.min(completion, 100))
                .completionItems(items)
                .build();
    }

    // ── BR-01 Completion items ────────────────────────────────────────────────
    // Total = 30 (name+email+phone) + 10 (photo) + 10 (dob) + 15 (emergency)
    //       + 10 (email verified) + 10 (phone verified) + 15 (vehicle) = 100
    private List<ProfileDTO.CompletionItem> buildCompletionItems(
            User user, Resident resident, Apartment apartment, String phone) {

        List<ProfileDTO.CompletionItem> list = new ArrayList<>();

        boolean hasName  = notBlank(user.getFirstname()) && notBlank(user.getLastname());
        boolean hasEmail = notBlank(user.getEmail());
        boolean hasPhone = phone != null && !phone.isBlank();

        list.add(item("Name, Email & Phone",  hasName && hasEmail && hasPhone, 30));
        list.add(item("Profile photo",        user.getAvatarUrl() != null,  10));
        list.add(item("Date of birth",        user.getDateOfBirth() != null,  10));
        list.add(item("Emergency contact",
                resident != null && notBlank(resident.getEmergencyContact()), 15));
        list.add(item("Email verified",       true,   10));   // assume verified on register
        list.add(item("Phone verified",       hasPhone, 10));
        list.add(item("Vehicle registered",   false,  15));   // no vehicle entity yet

        return list;
    }

    private ProfileDTO.CompletionItem item(String label, boolean done, int weight) {
        return ProfileDTO.CompletionItem.builder()
                .label(label).completed(done).weight(weight).build();
    }

    // ── Masking helpers (BR-03) ───────────────────────────────────────────────
    private String maskEmail(String email) {
        if (email == null) return null;
        int at = email.indexOf('@');
        if (at <= 1) return email;
        return email.charAt(0) + "***" + email.substring(at);
    }

    private String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) return phone;
        // Show first 3 and last 4 digits: "090-***-4567"
        String digits = phone.replaceAll("[^0-9]", "");
        if (digits.length() < 7) return phone;
        return digits.substring(0, 3) + "-***-"
                + digits.substring(digits.length() - 4);
    }

    // ── Utils ─────────────────────────────────────────────────────────────────
    private String nvl(String s) { return s == null ? "" : s; }
    private boolean notBlank(String s) { return s != null && !s.isBlank(); }

    private String initials(String first, String last) {
        String f = first.isEmpty() ? "" : String.valueOf(first.charAt(0));
        String l = last.isEmpty()  ? "" : String.valueOf(last.charAt(0));
        return (f + l).toUpperCase();
    }
}
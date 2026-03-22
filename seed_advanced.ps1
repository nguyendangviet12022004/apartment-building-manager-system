$ErrorActionPreference = "Stop"

$seedFile = ".seed_done"
if (Test-Path $seedFile) {
    Write-Host "================================================="
    Write-Host " DATABASE ALREADY SEEDED! (Found .seed_done flag)"
    Write-Host " Exiting to prevent duplicates as requested."
    Write-Host "================================================="
    exit
}

Write-Host "========================================="
Write-Host "   ADVANCED DATA SEEDER (BOOKINGS, ETC)  "
Write-Host "========================================="

$baseUrl = "http://127.0.0.1:8080/api/v1"

# 1. Initialize Admin
Write-Host "`n[1/5] Initializing Admin..."
$adminUser = '{"firstname":"Admin","lastname":"Pro","email":"admin_booking@example.com","password":"Password1!","role":"ADMIN","identityCard":"000000000000","emergencyContact":"0000000000"}'
Try {
    $regRes = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -ContentType "application/json" -Body $adminUser
    $adminToken = $regRes.accessToken
} Catch {
    # If admin already exists, just login
    $adminToken = (Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body '{"email":"admin_booking@example.com","password":"Password1!"}').accessToken
}

$adminHeaders = @{"Authorization" = "Bearer $adminToken"}
Write-Host "-> Admin ready."

# 2. Create Blocks & Apartments for testing Bookings
Write-Host "`n[2/5] Creating Amenities Area & Apartments..."
$b_res = $null
Try {
    $b_res = Invoke-RestMethod -Uri "$baseUrl/blocks" -Method Post -ContentType "application/json" -Headers $adminHeaders -Body '{"blockCode":"BMK","description":"Booking Mock Block"}'
} Catch {
    # Block may already exist, let's fetch it
    $allBlocks = Invoke-RestMethod -Uri "$baseUrl/blocks" -Method Get -Headers $adminHeaders
    foreach ($b in $allBlocks) {
        if ($b.blockCode -eq "BMK") { $b_res = $b }
    }
}
$blockId = $b_res.id

# Create apartment to link with resident
$apt_res = $null
Try {
    $apt_res = Invoke-RestMethod -Uri "$baseUrl/apartments" -Method Post -ContentType "application/json" -Headers $adminHeaders -Body "{""apartmentCode"":""BMK-0808-MOK"",""floor"":8,""area"":100.0,""status"":""AVAILABLE"",""blockId"":$blockId}"
} Catch {
    # Fetch it
    $allApts = Invoke-RestMethod -Uri "$baseUrl/apartments?size=100" -Method Get -Headers $adminHeaders
    foreach ($a in $allApts.content) {
        if ($a.apartmentCode -eq "BMK-0808-MOK") { $apt_res = $a }
    }
}
$aptId = $apt_res.id
Write-Host "-> Apartment ready (ID: $aptId)."

# 3. Create AMENITY Services
Write-Host "`n[3/5] Creating AMENITY Services..."
$amenities = @(
    '{"serviceName":"Tennis Court","unit":"Hour","unitPrice":50000,"description":"Premium Tennis Court","serviceType":"AMENITY","metered":true,"active":true,"capacity":2,"openingTime":"06:00:00","closingTime":"22:00:00"}',
    '{"serviceName":"Swimming Pool","unit":"Session","unitPrice":20000,"description":"Rooftop Swimming Pool","serviceType":"AMENITY","metered":true,"active":true,"capacity":30,"openingTime":"06:00:00","closingTime":"20:00:00"}',
    '{"serviceName":"BBQ Area","unit":"Hour","unitPrice":100000,"description":"Family BBQ Area","serviceType":"AMENITY","metered":true,"active":true,"capacity":4,"openingTime":"10:00:00","closingTime":"22:00:00"}'
)

$createdAmenities = @()
foreach ($a in $amenities) {
    Try {
        $res = Invoke-RestMethod -Uri "$baseUrl/services" -Method Post -ContentType "application/json" -Headers $adminHeaders -Body $a
        $createdAmenities += $res
        Write-Host "  -> Added Amenity: $($res.serviceName)"
    } Catch {
        # Already exists or error
    }
}
if ($createdAmenities.Count -eq 0) {
    $allSvcs = Invoke-RestMethod -Uri "$baseUrl/services/all" -Method Get -Headers $adminHeaders | Where-Object { $_.serviceType -eq "AMENITY" }
    foreach ($svc in $allSvcs) { $createdAmenities += $svc }
    Write-Host "  -> Loaded existing Amenities."
}

# 4. Register Resident (linked to Apartment)
Write-Host "`n[4/5] Registering Resident to make a Booking..."
$residentUser = @{
    firstname = "Demo"
    lastname = "Booker"
    email = "booker_demo@example.com"
    password = "Password123!"
    role = "USER"
    identityCard = "888899990000"
    emergencyContact = "0112233445"
    apartmentId = $aptId
}

$userToken = $null
$userId = $null
Try {
    $userBody = $residentUser | ConvertTo-Json
    $res = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -ContentType "application/json" -Body $userBody
    $userToken = $res.accessToken
    $userId = $res.userId
    Write-Host "-> Resident Registered."
} Catch {
    Write-Host "-> Resident already registered. Logging in..."
    $logRes = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body '{"email":"booker_demo@example.com","password":"Password123!"}'
    $userToken = $logRes.accessToken
    $userId = $logRes.userId
}
$userHeaders = @{"Authorization" = "Bearer $userToken"; "X-User-ID" = "$userId"}


# 5. Create Bookings
Write-Host "`n[5/5] Creating Service Bookings..."
if ($createdAmenities.Count -gt 0) {
    $tennisId = $createdAmenities[0].id
    $poolId = $createdAmenities[1].id
    
    # Book Tennis (Tomorrow 14:00 to 16:00)
    $startTime = (Get-Date).AddDays(1).Date.AddHours(14).ToString("yyyy-MM-ddTHH:mm:ss")
    $endTime = (Get-Date).AddDays(1).Date.AddHours(16).ToString("yyyy-MM-ddTHH:mm:ss")
    
    $booking1 = @{
        serviceId = $tennisId
        startTime = $startTime
        endTime = $endTime
        quantity = 1
        note = "Weekend match"
    }
    
    Try {
        $body = $booking1 | ConvertTo-Json
        Invoke-RestMethod -Uri "$baseUrl/bookings" -Method Post -ContentType "application/json" -Headers $userHeaders -Body $body | Out-Null
        Write-Host "  -> Booked Tennis Court successfully!"
    } Catch {
        Write-Host "  -> Tennis booking ignored (probably conflicts / already booked)."
    }

    # Book Swimming Pool (Day after tomorrow 08:00 to 10:00)
    $startTime2 = (Get-Date).AddDays(2).Date.AddHours(8).ToString("yyyy-MM-ddTHH:mm:ss")
    $endTime2 = (Get-Date).AddDays(2).Date.AddHours(10).ToString("yyyy-MM-ddTHH:mm:ss")
    
    $booking2 = @{
        serviceId = $poolId
        startTime = $startTime2
        endTime = $endTime2
        quantity = 2
        note = "Family swim"
    }

    Try {
        $body = $booking2 | ConvertTo-Json
        Invoke-RestMethod -Uri "$baseUrl/bookings" -Method Post -ContentType "application/json" -Headers $userHeaders -Body $body | Out-Null
        Write-Host "  -> Booked Swimming Pool successfully!"
    } Catch {
        Write-Host "  -> Pool booking ignored."
    }

} else {
    Write-Host "-> No AMENITY services found to book."
}


Write-Host "`n========================================="
Write-Host "     SEED COMPLETED SUCCESSFULLY!        "
Write-Host "========================================="

# Mark as completely seeded so it doesn't run again later!
"x" | Out-File -FilePath $seedFile -Encoding ASCII
Write-Host "Created .seed_done flag."

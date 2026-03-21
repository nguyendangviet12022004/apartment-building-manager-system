$ErrorActionPreference = "Stop"

Write-Host "========================================="
Write-Host "   APARTMENT BUILDING SYSTEM SEEDER      "
Write-Host "========================================="

# 1. Initialize Admin
Write-Host "`n[1/7] Initializing Super Admin..."
$adminUser = '{"firstname":"Admin","lastname":"Super","email":"superadmin_master@example.com","password":"Password1!","role":"ADMIN","identityCard":"000000000000","emergencyContact":"0000000000"}'
$regRes = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/auth/register" -Method Post -ContentType "application/json" -Body $adminUser
$token = $regRes.accessToken
$headers = @{"Authorization" = "Bearer $token"}
Write-Host "-> Success! Token received."

# 2. Register Users
Write-Host "`n[2/7] Registering Residents..."
$users = @(
    '{"firstname":"John","lastname":"Doe","email":"johndoe_seed@example.com","password":"Password123!","role":"USER","identityCard":"123456789012","emergencyContact":"0987654321"}',
    '{"firstname":"Jane","lastname":"Smith","email":"janesmith_seed@example.com","password":"Password123!","role":"USER","identityCard":"987654321098","emergencyContact":"0123456789"}'
)
foreach ($u in $users) {
    Try {
        Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/auth/register" -Method Post -ContentType "application/json" -Body $u | Out-Null
    } Catch { }
}
Write-Host "-> Residents created (or already exist)."

# 3. Create Blocks
Write-Host "`n[3/7] Creating Blocks..."
$blocks = @(
    '{"blockCode":"SDA","description":"Seed Block A - Premium"}',
    '{"blockCode":"SDB","description":"Seed Block B - Studio"}'
)
foreach ($b in $blocks) {
    Try {
        Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/blocks" -Method Post -ContentType "application/json" -Headers $headers -Body $b | Out-Null
    } Catch { }
}
Write-Host "-> Blocks created."

# 4. Create Apartments
Write-Host "`n[4/7] Generating Apartments dynamically..."
$fetchedBlocks = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/blocks" -Method Get -Headers $headers
foreach ($b in $fetchedBlocks) {
    if ($b.blockCode.Length -eq 3) {
        $id = $b.id
        $code = $b.blockCode
        
        $apts = @(
            "{""apartmentCode"":""$code-0101-A1B"",""floor"":1,""area"":65.5,""status"":""AVAILABLE"",""blockId"":$id}",
            "{""apartmentCode"":""$code-0202-C3D"",""floor"":2,""area"":70.0,""status"":""AVAILABLE"",""blockId"":$id}",
            "{""apartmentCode"":""$code-0303-E5F"",""floor"":3,""area"":80.0,""status"":""OCCUPIED"",""blockId"":$id}"
        )
        
        foreach ($a in $apts) {
            Try {
                Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/apartments" -Method Post -ContentType "application/json" -Headers $headers -Body $a | Out-Null
            } Catch { }
        }
    }
}
Write-Host "-> Apartments successfully linked to Blocks."

# 5. Create Requests
Write-Host "`n[5/7] Submitting Resident Requests..."
$boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
$multipartBody1 = "--$boundary`r`nContent-Disposition: form-data; name=`"title`"`r`n`r`nWater Leak`r`n--$boundary`r`nContent-Disposition: form-data; name=`"description`"`r`n`r`nKitchen sink leaking.`r`n--$boundary--"
$multipartBody2 = "--$boundary`r`nContent-Disposition: form-data; name=`"title`"`r`n`r`nBroken Light`r`n--$boundary`r`nContent-Disposition: form-data; name=`"description`"`r`n`r`nHallway light is broken.`r`n--$boundary--"

Try {
    # Using User ID 2 & 3 conservatively, assuming they exist.
    Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/requests/user/2" -Method Post -Headers $headers -ContentType "multipart/form-data; boundary=$boundary" -Body $multipartBody1 | Out-Null
    Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/requests/user/3" -Method Post -Headers $headers -ContentType "multipart/form-data; boundary=$boundary" -Body $multipartBody2 | Out-Null
} Catch { }
Write-Host "-> Requests submitted."

$headersAdmin = @{"Authorization" = "Bearer $token"; "X-User-ID" = "1"}
Try {
    Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/requests/1/timeline?solvedBy=2026-03-30T10:00:00" -Method Patch -Headers $headersAdmin | Out-Null
    Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/requests/1/status?status=APPROVED&response=Noted" -Method Patch -Headers $headersAdmin | Out-Null
} Catch { }


# 6. Create Services
Write-Host "`n[6/7] Initializing Building Services..."
$services = @(
    '{"serviceName":"Management Fee","unit":"month","unitPrice":500000,"description":"Monthly management fee","serviceType":"FIXED","metered":false,"active":true}',
    '{"serviceName":"Electricity","unit":"kWh","unitPrice":3500,"description":"Electricity usage","serviceType":"METERED","metered":true,"active":true}',
    '{"serviceName":"Water","unit":"m3","unitPrice":25000,"description":"Water usage","serviceType":"METERED","metered":true,"active":true}',
    '{"serviceName":"Parking Motorbike","unit":"vehicle","unitPrice":120000,"description":"Motorbike parking","serviceType":"PARKING","metered":false,"active":true}'
)

$createdServiceIds = @()
foreach ($s in $services) {
    Try {
        $res = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/services" -Method Post -ContentType "application/json" -Headers $headers -Body $s
        $createdServiceIds += $res.id
    } Catch { }
}
if ($createdServiceIds.Count -eq 0) {
    $allServices = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/services" -Method Get -Headers $headers
    foreach ($svc in $allServices) { $createdServiceIds += $svc.id }
}
Write-Host "-> Services initialized."


# 7. Create Invoices
Write-Host "`n[7/7] Generating Monthly Invoices..."
$fetchedApts = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/apartments?size=100" -Method Get -Headers $headers
$content = $fetchedApts.content

if ($content) {
    $invoiceCounter = 1
    foreach ($apt in $content) {
        $aptId = $apt.id
        
        $invUnpaid = @{
            apartmentId = $aptId
            invoiceCode = "INV-$(Get-Date -f 'yyyyMM')-$invoiceCounter"
            invoiceDate = "2026-03-01T00:00:00"
            dueDate     = "2026-03-15T00:00:00"
            lateFee     = 0.0
            status      = "UNPAID"
            items       = @()
        }
        $invoiceCounter++
        
        if ($createdServiceIds.Count -gt 0) {
            $invUnpaid.items += @{ serviceId = $createdServiceIds[0]; quantity = 1 }
        }
        if ($createdServiceIds.Count -gt 1) {
            $invUnpaid.items += @{ serviceId = $createdServiceIds[1]; quantity = (Get-Random -Minimum 100 -Maximum 500) }
        }

        $invPaid = @{
            apartmentId = $aptId
            invoiceCode = "INV-$(Get-Date -f 'yyyyMM')-$invoiceCounter"
            invoiceDate = "2026-02-01T00:00:00"
            dueDate     = "2026-02-15T00:00:00"
            lateFee     = 0.0
            status      = "PAID"
            items       = @()
        }
        $invoiceCounter++
        
        if ($createdServiceIds.Count -gt 0) {
            $invPaid.items += @{ serviceId = $createdServiceIds[0]; quantity = 1 }
        }

        Try {
            Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/invoices" -Method Post -ContentType "application/json" -Headers $headers -Body ($invUnpaid | ConvertTo-Json -Depth 5) | Out-Null
            Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/v1/invoices" -Method Post -ContentType "application/json" -Headers $headers -Body ($invPaid | ConvertTo-Json -Depth 5) | Out-Null
        } Catch { }
    }
    Write-Host "-> Simulated Invoices assigned to all apartments."
}

Write-Host "`n========================================="
Write-Host "           SEEDING COMPLETED             "
Write-Host "========================================="

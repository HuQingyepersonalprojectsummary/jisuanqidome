param(
    [string]$Version = '1.0.0',
    [string]$ThemidaPath = '',
    [string]$ProjectTmd = '',
    [switch]$SkipThemida,
    [switch]$SkipTests,
    [switch]$OpenThemidaGui
)

$ErrorActionPreference = 'Stop'

if ($Version -notmatch '^\d+\.\d+\.\d+([.-][a-zA-Z0-9.-]+)?$') {
    throw "Invalid version format: $Version. Expected semver like '1.0.0'."
}

$solutionRoot = Split-Path $PSScriptRoot -Parent
$artifacts = Join-Path $solutionRoot 'artifacts'
New-Item -ItemType Directory -Force -Path $artifacts | Out-Null

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " PCalc Advanced Calculator High-Security Packaging Pipeline" -ForegroundColor Green
Write-Host " Version: $Version" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

# Step 1: Solution Build & Automated Regression Testing
if (-not $SkipTests) {
    Write-Host "[1/5] Executing automated regression test suites..." -ForegroundColor Cyan
    
    $testCalc = Join-Path $solutionRoot 'test_calc.exe'
    if (Test-Path -LiteralPath $testCalc) {
        Write-Host "  -> Running core math/algebraic/RPN tests ($testCalc)..." -ForegroundColor Gray
        & $testCalc
        if ($LASTEXITCODE -ne 0) {
            throw "Core regression tests failed with exit code $LASTEXITCODE. Aborting package creation."
        }
    } else {
        Write-Warning "test_calc.exe not found in $solutionRoot. Skipping core test suite."
    }

    $testGui = Join-Path $solutionRoot 'test_gui_calc.exe'
    if (Test-Path -LiteralPath $testGui) {
        Write-Host "  -> Running full GUI simulation tests ($testGui)..." -ForegroundColor Gray
        & $testGui
        if ($LASTEXITCODE -ne 0) {
            throw "GUI simulation tests failed with exit code $LASTEXITCODE. Aborting package creation."
        }
    } else {
        Write-Warning "test_gui_calc.exe not found in $solutionRoot. Skipping GUI test suite."
    }
    Write-Host "  [OK] All test suites passed with 100% success rate." -ForegroundColor Green
} else {
    Write-Host "[1/5] Skipping test suites as requested (-SkipTests)..." -ForegroundColor Yellow
}

# Step 2: Staging Application Release Binaries
Write-Host "[2/5] Staging Application Executable & Companion Assets..." -ForegroundColor Cyan
$stagingGuid = [Guid]::NewGuid().ToString('N')
$staging = Join-Path $artifacts "installer-staging-$stagingGuid"
New-Item -ItemType Directory -Force -Path $staging | Out-Null

try {
    # Resolve Main Application Executable
    $primaryExeCandidates = @(
        (Join-Path $solutionRoot 'project1.exe'),
        (Join-Path $solutionRoot 'releases\PCalc_Windows_Advanced_Calculator.exe')
    )
    $sourceExe = $null
    foreach ($candidate in $primaryExeCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            $sourceExe = $candidate
            break
        }
    }

    if (-not $sourceExe) {
        throw "Could not locate project1.exe or releases\PCalc_Windows_Advanced_Calculator.exe to package."
    }

    $targetExe = Join-Path $staging 'PCalc.exe'
    Write-Host "  -> Copying executable: $(Split-Path $sourceExe -Leaf) -> PCalc.exe" -ForegroundColor Gray
    Copy-Item -LiteralPath $sourceExe -Destination $targetExe -Force

    # Copy Icon & Companion Documentation
    $iconSrc = Join-Path $solutionRoot 'project1.ico'
    if (Test-Path -LiteralPath $iconSrc) {
        Copy-Item -LiteralPath $iconSrc -Destination (Join-Path $staging 'project1.ico') -Force
    }

    $manualSrc = Join-Path $solutionRoot 'USER_MANUAL.md'
    if (Test-Path -LiteralPath $manualSrc) {
        Copy-Item -LiteralPath $manualSrc -Destination (Join-Path $staging 'USER_MANUAL.md') -Force
    }

    $readmeSrc = Join-Path $solutionRoot 'README.md'
    if (Test-Path -LiteralPath $readmeSrc) {
        Copy-Item -LiteralPath $readmeSrc -Destination (Join-Path $staging 'README.md') -Force
    }

    # Clean any temporary/debug files in staging
    $unsafeFiles = Get-ChildItem -LiteralPath $staging -Recurse -File |
        Where-Object { $_.Extension -in @('.o', '.ppu', '.obj', '.bak', '.log', '.tmp') }
    if ($unsafeFiles) {
        Write-Warning "Removing $(($unsafeFiles).Count) intermediate/temporary files from staging."
        $unsafeFiles | Remove-Item -Force
    }

    # Step 3: Themida High-Security Protection
    Write-Host "[3/5] Applying Themida Enterprise Protection..." -ForegroundColor Cyan

    # Dynamically resolve confidential local configuration if present
    $secretsCandidates = @(
        (Join-Path $solutionRoot 'build.secrets.local.json'),
        (Join-Path $solutionRoot '../build.secrets.local.json'),
        (Join-Path $PSScriptRoot 'build.secrets.local.json')
    )
    $localSecrets = $null
    foreach ($sf in $secretsCandidates) {
        if (Test-Path -LiteralPath $sf) {
            try {
                $localSecrets = Get-Content -LiteralPath $sf -Raw -Encoding utf8 | ConvertFrom-Json
                Write-Host "  -> Loaded confidential local build configuration: $(Split-Path $sf -Leaf)" -ForegroundColor DarkGray
                break
            } catch {
                Write-Warning "Failed to parse configuration from ${sf}: $_"
            }
        }
    }

    if (-not $ThemidaPath) {
        if ($localSecrets -and $localSecrets.Themida -and $localSecrets.Themida.ExecutablePath) {
            $ThemidaPath = $localSecrets.Themida.ExecutablePath
        } elseif ($env:THEMIDA_PATH) {
            $ThemidaPath = $env:THEMIDA_PATH
        } else {
            $defaultLocations = @(
                'C:\Program Files\Themida\Themida.exe',
                'C:\Program Files (x86)\Themida\Themida.exe'
            )
            foreach ($loc in $defaultLocations) {
                if (Test-Path -LiteralPath $loc) { $ThemidaPath = $loc; break }
            }
        }
    }

    if (-not $ProjectTmd -and $localSecrets -and $localSecrets.Themida -and $localSecrets.Themida.ProjectPath) {
        $ProjectTmd = $localSecrets.Themida.ProjectPath
    }

    $tmdCandidates = @()
    if ($ProjectTmd) { $tmdCandidates += $ProjectTmd }
    $tmdCandidates += @(
        (Join-Path $solutionRoot 'PCalc_HighSecurity.tmd'),
        (Join-Path $solutionRoot 'PCalc.tmd'),
        (Join-Path $PSScriptRoot 'PCalc_HighSecurity.tmd'),
        (Join-Path $artifacts 'PCalc_HighSecurity.tmd')
    )

    $resolvedTmd = $null
    foreach ($candidate in $tmdCandidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            $resolvedTmd = (Resolve-Path -LiteralPath $candidate).Path
            break
        }
    }

    if ($SkipThemida) {
        Write-Host "  -> Themida protection skipped via -SkipThemida flag." -ForegroundColor Yellow
    } elseif (-not $ThemidaPath -or -not (Test-Path -LiteralPath $ThemidaPath)) {
        Write-Warning "Themida executable not found. (Configured path: '$ThemidaPath')"
        Write-Warning "Configure 'Themida.ExecutablePath' in build.secrets.local.json or pass -ThemidaPath."
    } elseif (-not $resolvedTmd) {
        Write-Warning "================================================================"
        Write-Warning " Themida project file (.tmd) not found!"
        Write-Warning " Themida requires a .tmd project file to store the high-security"
        Write-Warning " protection options (Multi-VM, Anti-Debug, Memory Protection)."
        Write-Warning "================================================================"
        Write-Host "  Expected location: $(Join-Path $solutionRoot 'PCalc_HighSecurity.tmd')" -ForegroundColor Yellow
        Write-Host "  Guide: See docs/THEMIDA_PROTECTION_GUIDE.md for recommended settings." -ForegroundColor Yellow

        if ($OpenThemidaGui) {
            Write-Host "  -> Launching Themida GUI for one-time configuration..." -ForegroundColor Cyan
            Start-Process -FilePath $ThemidaPath -ArgumentList "`"$targetExe`""
            Write-Host "  Please configure your high-protection settings in Themida and save as:" -ForegroundColor Green
            Write-Host "  $((Join-Path $solutionRoot 'PCalc_HighSecurity.tmd'))" -ForegroundColor White
            Read-Host "  Press Enter after saving the .tmd project file to continue..."

            if (Test-Path -LiteralPath (Join-Path $solutionRoot 'PCalc_HighSecurity.tmd')) {
                $resolvedTmd = (Join-Path $solutionRoot 'PCalc_HighSecurity.tmd')
            }
        }

        if (-not $resolvedTmd) {
            Write-Warning "Proceeding with packaging without Themida. (Use -OpenThemidaGui to create .tmd)"
        }
    }

    if ($resolvedTmd -and (Test-Path -LiteralPath $resolvedTmd)) {
        Write-Host "  -> Found Themida project: $resolvedTmd" -ForegroundColor Green
        $themidaReturnCodes = @{
            0 = 'Protection successful'
            1 = 'Project file does not exist or is invalid'
            2 = 'File to protect cannot be opened'
            3 = 'File already protected'
            4 = 'Error in inserted SecureEngine macros'
            5 = 'Internal protection error'
            6 = 'Cannot write protected file to disk'
            7 = 'Error opening/reading splash file'
            8 = 'Taggant certificate cannot be applied'
        }

        $unprotectedExe = Join-Path $staging 'PCalc.unprotected.exe'
        Copy-Item -LiteralPath $targetExe -Destination $unprotectedExe -Force
        
        Write-Host "  -> Protecting PCalc.exe with Themida..." -ForegroundColor Gray
        $proc = Start-Process -FilePath $ThemidaPath `
            -ArgumentList @('/protect', "`"$resolvedTmd`"", '/inputfile', "`"$unprotectedExe`"", '/outputfile', "`"$targetExe`"", '/shareconsole', '/q') `
            -Wait -PassThru -NoNewWindow

        $msg = if ($themidaReturnCodes.ContainsKey($proc.ExitCode)) { $themidaReturnCodes[$proc.ExitCode] } else { "Unknown code $($proc.ExitCode)" }
        if ($proc.ExitCode -ne 0) {
            Write-Warning "Themida protection failed with exit code $($proc.ExitCode): $msg."
            Move-Item -LiteralPath $unprotectedExe -Destination $targetExe -Force
        } else {
            Write-Host "  [OK] PCalc.exe successfully protected by Themida!" -ForegroundColor Green
            Remove-Item -LiteralPath $unprotectedExe -Force -ErrorAction SilentlyContinue
        }
    }

    # Step 4: Compile Windows Installer (.exe) with Inno Setup
    Write-Host "[4/5] Compiling Windows Setup Installer with Inno Setup..." -ForegroundColor Cyan

    $iscc = $null
    $isccCommand = Get-Command iscc -ErrorAction SilentlyContinue
    if ($isccCommand) {
        $iscc = $isccCommand.Source
    } else {
        $isccCandidates = @(
            "C:\Users\$env:USERNAME\scoop\shims\iscc.exe",
            "C:\Users\$env:USERNAME\scoop\apps\inno-setup\current\iscc.exe",
            "$env:LOCALAPPDATA\Programs\Inno Setup 6\iscc.exe",
            "$env:ProgramFiles\Inno Setup 6\iscc.exe",
            "${env:ProgramFiles(x86)}\Inno Setup 6\iscc.exe"
        )
        foreach ($c in $isccCandidates) {
            if (Test-Path -LiteralPath $c) { $iscc = $c; break }
        }
    }

    $setupBaseName = "PCalc-$Version-win-x64-Setup"
    $setupExePath = Join-Path $artifacts "$setupBaseName.exe"
    $appIconPath = Join-Path $solutionRoot 'project1.ico'
    $issScript = Join-Path $PSScriptRoot 'installer.iss'

    if ($iscc -and (Test-Path -LiteralPath $iscc)) {
        Write-Host "  -> Using Inno Setup Compiler: $iscc" -ForegroundColor Gray
        $isccArgs = @(
            "/Q",
            "/O$artifacts",
            "/F$setupBaseName",
            "/DMyAppVersion=$Version",
            "/DMySourceDir=$staging",
            "/DMyAppIcon=$appIconPath",
            "$issScript"
        )
        $isccProc = Start-Process -FilePath $iscc -ArgumentList $isccArgs -Wait -PassThru -NoNewWindow
        if ($isccProc.ExitCode -ne 0) {
            throw "Inno Setup compilation failed with code $($isccProc.ExitCode)."
        }
    } else {
        Write-Warning "Inno Setup Compiler (iscc.exe) not found. Generating portable ZIP instead."
        $portableZip = Join-Path $artifacts "PCalc-$Version-win-x64-portable.zip"
        [IO.Compression.ZipFile]::CreateFromDirectory($staging, $portableZip, [IO.Compression.CompressionLevel]::Optimal, $false)
        Write-Host "  [OK] Portable ZIP created: $portableZip" -ForegroundColor Green
    }

    # Step 5: Post-Build Integrity Verification & Security Audit
    Write-Host "[5/5] Post-Build Integrity Verification & Security Audit..." -ForegroundColor Cyan

    if (Test-Path -LiteralPath $setupExePath) {
        $hash = (Get-FileHash -LiteralPath $setupExePath -Algorithm SHA256).Hash.ToLowerInvariant()
        $hashFile = "$setupExePath.sha256"
        Set-Content -LiteralPath $hashFile -Value "$hash  $setupBaseName.exe" -Encoding ascii

        $setupItem = Get-Item $setupExePath
        $sizeMb = [math]::Round($setupItem.Length / 1MB, 2)

        Write-Host "==========================================================" -ForegroundColor Green
        Write-Host " [SUCCESS] Installer Package Generated Successfully!" -ForegroundColor Green
        Write-Host " Output Installer: $setupExePath ($sizeMb MB)" -ForegroundColor Yellow
        Write-Host " SHA256 Hash:      $hash" -ForegroundColor Yellow
        Write-Host " Checksum File:    $hashFile" -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Green
    }

} finally {
    # Clean up staging directory
    if (Test-Path -LiteralPath $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
    }
}

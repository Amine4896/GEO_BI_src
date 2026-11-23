# =====================================================================
# TP1 Geo BI - execution complete (parties I et II)
#   powershell -ExecutionPolicy Bypass -File .\run_all.ps1
# =====================================================================
$ErrorActionPreference = "Continue"   # les erreurs sont detectees via $LASTEXITCODE
Set-Location $PSScriptRoot

$psql = "C:\Program Files\PostgreSQL\17\bin\psql.exe"
if (-not $env:PGHOST) { $env:PGHOST = "localhost" }
if (-not $env:PGPORT) { $env:PGPORT = "5432" }
if (-not $env:PGUSER) { $env:PGUSER = "postgres" }
$env:PGCLIENTENCODING = "UTF8"
$env:PGOPTIONS = "-c client_min_messages=warning"   # masque les NOTICE (DROP IF EXISTS...)

if (-not $env:PGPASSWORD) {
    $sec = Read-Host "Mot de passe PostgreSQL (postgres)" -AsSecureString
    $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}

function Run-Sql($db, $file) {
    Write-Host "`n>>> $file" -ForegroundColor Cyan
    & $psql -d $db -v ON_ERROR_STOP=1 -q -f $file
    if ($LASTEXITCODE -ne 0) { throw "Echec : $file" }
}
function Run-Py($file) {
    Write-Host "`n>>> $file" -ForegroundColor Cyan
    python $file
    if ($LASTEXITCODE -ne 0) { throw "Echec : $file" }
}

# I. Modele physique
Run-Sql "postgres"  "sql\01_create_database.sql"
Run-Sql "geobi_tp1" "sql\02_schema.sql"

# II.1 Donnees attributaires
Run-Py  "scripts\01_excel_par_entite.py"
$env:PGDATABASE = "geobi_tp1"
Run-Py  "scripts\02_charger_staging_attributs.py"
Run-Sql "geobi_tp1" "sql\03_integration_attributs.sql"

# II.2 Donnees spatiales (Option 2 : jointure sur le code)
Run-Py  "scripts\03_charger_staging_shp.py"
Run-Sql "geobi_tp1" "sql\04_integration_geom.sql"

# Controles
Run-Sql "geobi_tp1" "sql\05_controles.sql"

Write-Host "`nTermine." -ForegroundColor Green

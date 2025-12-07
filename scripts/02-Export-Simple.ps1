#Requires -Version 5.1

<#
.SYNOPSIS
    Export simple et direct des tables Access vers CSV
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$AccessDbPath = "c:\Users\joels\OneDrive - Serrentino\Documents\5 - Informatique\Mes projets developpement\2_Projets Office\2025 - projet-low-code-benevoles\SAS-Benevolat.accdb",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "c:\Users\joels\OneDrive - Serrentino\Documents\5 - Informatique\Mes projets developpement\2_Projets Office\2025 - projet-low-code-benevoles\exports"
)

$ErrorActionPreference = "Stop"

# Créer dossier de sortie
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

Write-Host "========================================"  -ForegroundColor Cyan
Write-Host "EXPORT ACCES VERS CSV" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Base: $AccessDbPath" -ForegroundColor White
Write-Host "Sortie: $OutputFolder" -ForegroundColor White
Write-Host ""

# Connexion Access
Write-Host "Connexion a la base Access..." -ForegroundColor Yellow

try {
    $access = New-Object -ComObject Access.Application
    $access.Visible = $false
    $access.OpenCurrentDatabase($AccessDbPath, $false)
    Write-Host "OK - Base ouverte" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "ERREUR: $_" -ForegroundColor Red
    exit 1
}

# Fonction d'export
function Export-Table {
    param(
        [string]$TableName,
        [string]$FileName
    )
    
    try {
        Write-Host "Export de $TableName..." -ForegroundColor Cyan
        $outputPath = Join-Path $OutputFolder $FileName
        
        # Utiliser ADO pour exporter (contourne les problemes de separateurs)
        $conn = New-Object -ComObject ADODB.Connection
        $rs = New-Object -ComObject ADODB.Recordset
        
        $connStr = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=$AccessDbPath;"
        $conn.Open($connStr)
        
        $rs.Open("SELECT * FROM [$TableName]", $conn)
        
        # Creer le CSV manuellement
        $csv = @()
        
        # En-tetes
        $headers = @()
        for ($i = 0; $i -lt $rs.Fields.Count; $i++) {
            $headers += $rs.Fields.Item($i).Name
        }
        $csv += $headers -join ","
        
        # Donnees
        while (-not $rs.EOF) {
            $row = @()
            for ($i = 0; $i -lt $rs.Fields.Count; $i++) {
                $value = $rs.Fields.Item($i).Value
                if ($null -eq $value) {
                    $row += ""
                }
                else {
                    # Echapper les guillemets et virgules
                    $value = $value.ToString().Replace('"', '""')
                    if ($value -match '[,"]') {
                        $row += """$value"""
                    }
                    else {
                        $row += $value
                    }
                }
            }
            $csv += $row -join ","
            $rs.MoveNext()
        }
        
        # Sauvegarder
        $csv | Out-File $outputPath -Encoding UTF8
        
        $rs.Close()
        $conn.Close()
        
        $lineCount = ($csv.Count - 1)  # -1 pour l'en-tete
        Write-Host "  OK - $lineCount enregistrements" -ForegroundColor Green
        
        return $lineCount
    }
    catch {
        Write-Host "  ERREUR: $_" -ForegroundColor Red
        return 0
    }
}

# Lister les tables disponibles
Write-Host "Tables disponibles dans la base:" -ForegroundColor Yellow
$tables = @()
foreach ($table in $access.CurrentDb().TableDefs) {
    if (-not ($table.Name.StartsWith("MSys") -or $table.Name.StartsWith("~"))) {
        $tables += $table.Name
        Write-Host "  - $($table.Name)" -ForegroundColor Gray
    }
}
Write-Host ""

# Export des tables principales
Write-Host "Debut de l'export..." -ForegroundColor Yellow
Write-Host ""

$results = @{}

# Export PERSONNE
if ($tables -contains "PERSONNE") {
    $results["PERSONNE"] = Export-Table -TableName "PERSONNE" -FileName "PERSONNE.csv"
}

# Export BENEVOLE  
if ($tables -contains "BENEVOLE") {
    $results["BENEVOLE"] = Export-Table -TableName "BENEVOLE" -FileName "BENEVOLE.csv"
}

# Export BENEFICIAIRE
if ($tables -contains "BENEFICIAIRE") {
    $results["BENEFICIAIRE"] = Export-Table -TableName "BENEFICIAIRE" -FileName "BENEFICIAIRE.csv"
}

# Export ACTIVITE
if ($tables -contains "ACTIVITE") {
    $results["ACTIVITE"] = Export-Table -TableName "ACTIVITE" -FileName "ACTIVITE.csv"
}

# Export EVENEMENT
if ($tables -contains "EVENEMENT") {
    $results["EVENEMENT"] = Export-Table -TableName "EVENEMENT" -FileName "EVENEMENT.csv"
}

# Export PARTICIPANT
if ($tables -contains "PARTICIPANT") {
    $results["PARTICIPANT"] = Export-Table -TableName "PARTICIPANT" -FileName "PARTICIPANT.csv"
}

# Export DONNER
if ($tables -contains "DONNER") {
    $results["DONNER"] = Export-Table -TableName "DONNER" -FileName "DONNER.csv"
}

# Export RECEVOIR
if ($tables -contains "RECEVOIR") {
    $results["RECEVOIR"] = Export-Table -TableName "RECEVOIR" -FileName "RECEVOIR.csv"
}

# Export LOCALITE
if ($tables -contains "LOCALITE") {
    $results["LOCALITE"] = Export-Table -TableName "LOCALITE" -FileName "LOCALITE.csv"
}

Write-Host ""
Write-Host "Fermeture de la base..." -ForegroundColor Yellow

try {
    $access.CloseCurrentDatabase()
    $access.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($access) | Out-Null
    Write-Host "OK - Base fermee" -ForegroundColor Green
}
catch {
    Write-Host "Avertissement: $_" -ForegroundColor Yellow
}

# Rapport final
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "EXPORT TERMINE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Fichiers crees:" -ForegroundColor White

foreach ($key in $results.Keys) {
    Write-Host "  - $key.csv : $($results[$key]) lignes" -ForegroundColor Green
}

Write-Host ""
Write-Host "Repertoire: $OutputFolder" -ForegroundColor Cyan
Write-Host ""
Write-Host "PROCHAINE ETAPE:" -ForegroundColor Yellow
Write-Host "  1. Verifier les fichiers CSV" -ForegroundColor White
Write-Host "  2. Analyser la structure des donnees" -ForegroundColor White
Write-Host "  3. Creer les scripts de fusion (PERSONNE + BENEVOLE, etc.)" -ForegroundColor White
Write-Host ""

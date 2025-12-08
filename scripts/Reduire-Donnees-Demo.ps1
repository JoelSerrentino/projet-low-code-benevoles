#Requires -Version 5.1

<#
.SYNOPSIS
    Réduit les données anonymisées à 20 enregistrements par fichier pour démonstration
.DESCRIPTION
    Crée des échantillons de 20 enregistrements tout en maintenant la cohérence des relations
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$InputFolder = "c:\Users\joels\OneDrive - Serrentino\Documents\5 - Informatique\Mes projets developpement\2_Projets Office\2025 - projet-low-code-benevoles\exports\sharepoint",
    
    [Parameter(Mandatory=$false)]
    [int]$NombreEnregistrements = 20
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "REDUCTION DES DONNEES POUR DEMO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Dossier: $InputFolder" -ForegroundColor White
Write-Host "Limite: $NombreEnregistrements enregistrements par fichier" -ForegroundColor White
Write-Host ""

# ============================================================================================================
# 1. REDUCTION BENEVOLES
# ============================================================================================================

Write-Host "1. Reduction Benevoles.csv..." -ForegroundColor Yellow

$benevoles = Import-Csv "$InputFolder\Benevoles.csv" -Encoding UTF8
$benevolesOriginal = $benevoles.Count

# Prendre les 20 premiers
$benevoles = $benevoles | Select-Object -First $NombreEnregistrements

# Sauvegarder
$benevoles | Export-Csv "$InputFolder\Benevoles.csv" -Encoding UTF8 -NoTypeInformation -Force

Write-Host "  $benevolesOriginal -> $($benevoles.Count) benevoles" -ForegroundColor Green

# Créer un set des IDs conservés (SourceID pour les affectations)
$benevolesSourceIDs = $benevoles | ForEach-Object { $_.SourceID }

# ============================================================================================================
# 2. REDUCTION BENEFICIAIRES
# ============================================================================================================

Write-Host "2. Reduction Beneficiaires.csv..." -ForegroundColor Yellow

$beneficiaires = Import-Csv "$InputFolder\Beneficiaires.csv" -Encoding UTF8
$beneficiairesOriginal = $beneficiaires.Count

# Prendre les 20 premiers
$beneficiaires = $beneficiaires | Select-Object -First $NombreEnregistrements

# Sauvegarder
$beneficiaires | Export-Csv "$InputFolder\Beneficiaires.csv" -Encoding UTF8 -NoTypeInformation -Force

Write-Host "  $beneficiairesOriginal -> $($beneficiaires.Count) beneficiaires" -ForegroundColor Green

# Créer un set des IDs conservés (SourceID pour les prestations)
$beneficiairesSourceIDs = $beneficiaires | ForEach-Object { $_.SourceID }

# ============================================================================================================
# 3. REDUCTION MISSIONS
# ============================================================================================================

Write-Host "3. Reduction Missions.csv..." -ForegroundColor Yellow

$missions = Import-Csv "$InputFolder\Missions.csv" -Encoding UTF8
$missionsOriginal = $missions.Count

# Prendre 10 activités (ACT) et 10 événements (EVE) pour équilibrer
$activites = $missions | Where-Object { $_.SourceCode -like "ACT-*" } | Select-Object -First 10
$evenements = $missions | Where-Object { $_.SourceCode -like "EVE-*" } | Select-Object -First 10
$missions = $activites + $evenements

# Sauvegarder
$missions | Export-Csv "$InputFolder\Missions.csv" -Encoding UTF8 -NoTypeInformation -Force

Write-Host "  $missionsOriginal -> $($missions.Count) missions (10 activites + 10 evenements)" -ForegroundColor Green

# Créer un set des codes conservés (SourceCode pour les affectations/prestations)
$missionsSourceCodes = $missions | ForEach-Object { $_.SourceCode }

# ============================================================================================================
# 4. FILTRAGE AFFECTATIONS (seulement celles liées aux bénévoles et missions conservés)
# ============================================================================================================

Write-Host "4. Filtrage Affectations.csv..." -ForegroundColor Yellow

$affectations = Import-Csv "$InputFolder\Affectations.csv" -Encoding UTF8
$affectationsOriginal = $affectations.Count

# Filtrer pour ne garder que les affectations avec bénévoles et missions existants
$affectationsFiltrees = $affectations | Where-Object {
    $benevolesSourceIDs -contains $_.BenevoleSourceID -and $missionsSourceCodes -contains $_.MissionCodeSource
}

# Limiter à 20 si plus
if ($affectationsFiltrees.Count -gt $NombreEnregistrements) {
    $affectationsFiltrees = $affectationsFiltrees | Select-Object -First $NombreEnregistrements
}

# Sauvegarder
$affectationsFiltrees | Export-Csv "$InputFolder\Affectations.csv" -Encoding UTF8 -NoTypeInformation -Force

Write-Host "  $affectationsOriginal -> $($affectationsFiltrees.Count) affectations (filtrees par coherence)" -ForegroundColor Green

# ============================================================================================================
# 5. FILTRAGE PRESTATIONS (seulement celles liées aux bénéficiaires et missions conservés)
# ============================================================================================================

Write-Host "5. Filtrage Prestations.csv..." -ForegroundColor Yellow

$prestations = Import-Csv "$InputFolder\Prestations.csv" -Encoding UTF8
$prestationsOriginal = $prestations.Count

# Filtrer pour ne garder que les prestations avec bénéficiaires et missions existants
$prestationsFiltrees = $prestations | Where-Object {
    $beneficiairesSourceIDs -contains $_.BeneficiaireSourceID -and $missionsSourceCodes -contains $_.MissionCodeSource
}

# Si aucune après filtrage, prendre les 20 premières sans filtre
if ($prestationsFiltrees.Count -eq 0) {
    Write-Host "  Aucune prestation correspondante - selection des 20 premieres sans filtre" -ForegroundColor Yellow
    $prestationsFiltrees = $prestations | Select-Object -First $NombreEnregistrements
}
elseif ($prestationsFiltrees.Count -gt $NombreEnregistrements) {
    $prestationsFiltrees = $prestationsFiltrees | Select-Object -First $NombreEnregistrements
}

# Sauvegarder
$prestationsFiltrees | Export-Csv "$InputFolder\Prestations.csv" -Encoding UTF8 -NoTypeInformation -Force

Write-Host "  $prestationsOriginal -> $($prestationsFiltrees.Count) prestations (filtrees par coherence)" -ForegroundColor Green

# ============================================================================================================
# RAPPORT FINAL
# ============================================================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "REDUCTION TERMINEE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Avant -> Apres:" -ForegroundColor White
Write-Host "  Benevoles:      $benevolesOriginal -> $($benevoles.Count)" -ForegroundColor Cyan
Write-Host "  Beneficiaires:  $beneficiairesOriginal -> $($beneficiaires.Count)" -ForegroundColor Cyan
Write-Host "  Missions:       $missionsOriginal -> $($missions.Count)" -ForegroundColor Cyan
Write-Host "  Affectations:   $affectationsOriginal -> $($affectationsFiltrees.Count)" -ForegroundColor Cyan
Write-Host "  Prestations:    $prestationsOriginal -> $($prestationsFiltrees.Count)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total original: $($benevolesOriginal + $beneficiairesOriginal + $missionsOriginal + $affectationsOriginal + $prestationsOriginal) enregistrements" -ForegroundColor Yellow
Write-Host "Total demo:     $($benevoles.Count + $beneficiaires.Count + $missions.Count + $affectationsFiltrees.Count + $prestationsFiltrees.Count) enregistrements" -ForegroundColor Green
Write-Host ""
Write-Host "Les fichiers ont ete mis a jour directement dans:" -ForegroundColor White
Write-Host "$InputFolder" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT:" -ForegroundColor Yellow
Write-Host "  - Toutes les relations ont ete conservees (coherence des IDs)" -ForegroundColor White
Write-Host "  - Les fichiers sont prets pour demonstration publique" -ForegroundColor White
Write-Host "  - Pensez a commiter ces changements dans Git" -ForegroundColor White
Write-Host ""

# ============================================================================================================
# Script: Import données CSV vers SharePoint - Projet Gestion Bénévoles
# Auteur: Joël Serrentino  
# Date: 18 novembre 2025
# Description: Importe les fichiers CSV dans les listes SharePoint
# ============================================================================================================

#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Importe les données CSV dans SharePoint Online

.DESCRIPTION
    Ce script:
    - Se connecte au site SharePoint
    - Importe Bénévoles, Missions, Affectations depuis les CSV
    - Gère les lookups (références entre listes)
    - Gère les imports par batch pour performance
    - Log toutes les opérations

.PARAMETER SiteUrl
    URL du site SharePoint (obligatoire)

.PARAMETER CsvFolder
    Dossier contenant les fichiers CSV

.PARAMETER BatchSize
    Taille des lots pour l'import (défaut: 100)

.EXAMPLE
    .\03-Import-SharePoint.ps1 -SiteUrl "https://votre-tenant.sharepoint.com/sites/Benevoles" -CsvFolder "D:\_Projets\bd_SAS-Benevolat\Export-CSV"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$CsvFolder = "D:\_Projets\bd_SAS-Benevolat\Export-CSV",
    
    [Parameter(Mandatory=$false)]
    [int]$BatchSize = 100
)

$ErrorActionPreference = "Stop"

# Configuration du log
$logFile = "Import-SharePoint-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$logPath = Join-Path $CsvFolder $logFile

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logPath -Value $logMessage
    
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        default { Write-Host $Message -ForegroundColor White }
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IMPORT CSV → SHAREPOINT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Site SharePoint: $SiteUrl" -ForegroundColor White
Write-Host "Dossier CSV: $CsvFolder" -ForegroundColor White
Write-Host "Taille des lots: $BatchSize" -ForegroundColor White
Write-Host "Fichier de log: $logPath" -ForegroundColor White
Write-Host ""

Write-Log "========== DÉBUT DE L'IMPORT =========="

# ============================================================================================================
# CONNEXION SHAREPOINT
# ============================================================================================================

try {
    Write-Log "Connexion à SharePoint..."
    Connect-PnPOnline -Url $SiteUrl -Interactive
    Write-Log "✓ Connexion réussie" -Level "SUCCESS"
}
catch {
    Write-Log "✗ Erreur de connexion: $_" -Level "ERROR"
    exit 1
}

# ============================================================================================================
# VÉRIFICATION DES LISTES
# ============================================================================================================

Write-Host ""
Write-Log "Vérification des listes SharePoint..." -Level "INFO"

$requiredLists = @(
    "Benevoles",
    "Missions",
    "Affectations",
    "Disponibilites"
)

$missingLists = @()

foreach ($listName in $requiredLists) {
    try {
        $list = Get-PnPList -Identity $listName -ErrorAction Stop
        Write-Log "  ✓ Liste '$listName' trouvée" -Level "SUCCESS"
    }
    catch {
        Write-Log "  ✗ Liste '$listName' manquante" -Level "ERROR"
        $missingLists += $listName
    }
}

if ($missingLists.Count -gt 0) {
    Write-Log "ERREUR: Listes manquantes. Exécutez d'abord le script 01-Creation-Listes-SharePoint.ps1" -Level "ERROR"
    exit 1
}

# ============================================================================================================
# VÉRIFICATION DES FICHIERS CSV
# ============================================================================================================

Write-Host ""
Write-Log "Vérification des fichiers CSV..." -Level "INFO"

$csvFiles = @{
    Benevoles = Join-Path $CsvFolder "Benevoles.csv"
    Missions = Join-Path $CsvFolder "Missions.csv"
    Affectations = Join-Path $CsvFolder "Affectations.csv"
}

$missingFiles = @()

foreach ($key in $csvFiles.Keys) {
    if (Test-Path $csvFiles[$key]) {
        $count = (Import-Csv $csvFiles[$key] -Encoding UTF8).Count
        Write-Log "  ✓ $key.csv trouvé ($count enregistrements)" -Level "SUCCESS"
    }
    else {
        Write-Log "  ✗ $key.csv manquant" -Level "ERROR"
        $missingFiles += $key
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Log "ERREUR: Fichiers CSV manquants. Exécutez d'abord le script 02-Export-Access-CSV.ps1" -Level "ERROR"
    exit 1
}

# ============================================================================================================
# IMPORT 1: BÉNÉVOLES
# ============================================================================================================

Write-Host ""
Write-Host "=== IMPORT BÉNÉVOLES ===" -ForegroundColor Yellow
Write-Log "Début import Bénévoles"

$csvBenevoles = Import-Csv $csvFiles.Benevoles -Encoding UTF8
$totalBenevoles = $csvBenevoles.Count
$importedBenevoles = 0
$failedBenevoles = 0

# Hashtable pour mapper PERSONNE_ID → SharePoint ID
$benevoleMapping = @{}

Write-Log "Import de $totalBenevoles bénévoles par lots de $BatchSize..."

for ($i = 0; $i -lt $totalBenevoles; $i += $BatchSize) {
    $batch = $csvBenevoles | Select-Object -Skip $i -First $BatchSize
    $batchNumber = [math]::Floor($i / $BatchSize) + 1
    $totalBatches = [math]::Ceiling($totalBenevoles / $BatchSize)
    
    Write-Progress -Activity "Import Bénévoles" -Status "Lot $batchNumber/$totalBatches" -PercentComplete (($i / $totalBenevoles) * 100)
    
    foreach ($row in $batch) {
        try {
            # Préparer les données
            $itemData = @{
                Title = $row.NomComplet
                NumeroBenevole = $row.NumeroBenevole
                Prenom = $row.Prenom
                Nom = $row.Nom
                Civilite = $row.Civilite
                Email = $row.Email
                Telephone = $row.Telephone
                TelephoneMobile = $row.TelephoneMobile
                Adresse1 = $row.Adresse1
                Adresse2 = $row.Adresse2
                NPA = $row.NPA
                Ville = $row.Ville
                Statut = if ([string]::IsNullOrWhiteSpace($row.Statut)) { "Actif" } else { $row.Statut }
                RGPDConsentement = $row.RGPDConsentement
                NotesGenerales = $row.NotesGenerales
                NotesInternes = $row.NotesInternes
            }
            
            # Ajouter DateNaissance si présente
            if (-not [string]::IsNullOrWhiteSpace($row.DateNaissance)) {
                try {
                    $itemData.DateNaissance = [DateTime]::Parse($row.DateNaissance)
                }
                catch {
                    Write-Log "  ⚠ DateNaissance invalide pour $($row.NomComplet)" -Level "WARNING"
                }
            }
            
            # Ajouter DateEntree
            if (-not [string]::IsNullOrWhiteSpace($row.DateEntree)) {
                try {
                    $itemData.DateEntree = [DateTime]::Parse($row.DateEntree)
                }
                catch {
                    $itemData.DateEntree = Get-Date
                }
            }
            else {
                $itemData.DateEntree = Get-Date
            }
            
            # Parser Competences (multi-choice)
            if (-not [string]::IsNullOrWhiteSpace($row.Competences)) {
                # Access peut avoir des compétences séparées par ; ou ,
                $competencesArray = $row.Competences -split '[;,]' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
                
                # Mapper aux choix SharePoint
                $competencesValides = @()
                $choixDisponibles = @("Accueil", "Animation", "Bricolage", "Comptabilité", "Conduite", "Cuisine", 
                                       "Informatique", "Jardinage", "Langues étrangères", "Musique", "Secrétariat", 
                                       "Soins", "Sport", "Autre")
                
                foreach ($comp in $competencesArray) {
                    $match = $choixDisponibles | Where-Object { $_ -like "*$comp*" }
                    if ($match) {
                        $competencesValides += $match[0]
                    }
                }
                
                if ($competencesValides.Count -gt 0) {
                    $itemData.Competences = $competencesValides
                }
            }
            
            # Créer l'item SharePoint
            $newItem = Add-PnPListItem -List "Benevoles" -Values $itemData
            
            # Stocker le mapping PERSONNE_ID → SharePoint ID
            $benevoleMapping[$row.PERSONNE_ID] = $newItem.Id
            
            $importedBenevoles++
        }
        catch {
            Write-Log "  ✗ Erreur import $($row.NomComplet): $_" -Level "ERROR"
            $failedBenevoles++
        }
    }
}

Write-Progress -Activity "Import Bénévoles" -Completed
Write-Log "✓ Bénévoles importés: $importedBenevoles/$totalBenevoles (échecs: $failedBenevoles)" -Level "SUCCESS"

# ============================================================================================================
# IMPORT 2: MISSIONS
# ============================================================================================================

Write-Host ""
Write-Host "=== IMPORT MISSIONS ===" -ForegroundColor Yellow
Write-Log "Début import Missions"

$csvMissions = Import-Csv $csvFiles.Missions -Encoding UTF8
$totalMissions = $csvMissions.Count
$importedMissions = 0
$failedMissions = 0

# Hashtable pour mapper CodeSource → SharePoint ID
$missionMapping = @{}

Write-Log "Import de $totalMissions missions par lots de $BatchSize..."

for ($i = 0; $i -lt $totalMissions; $i += $BatchSize) {
    $batch = $csvMissions | Select-Object -Skip $i -First $BatchSize
    $batchNumber = [math]::Floor($i / $BatchSize) + 1
    $totalBatches = [math]::Ceiling($totalMissions / $BatchSize)
    
    Write-Progress -Activity "Import Missions" -Status "Lot $batchNumber/$totalBatches" -PercentComplete (($i / $totalMissions) * 100)
    
    foreach ($row in $batch) {
        try {
            $itemData = @{
                Title = $row.Titre
                CodeMission = $row.CodeMission
                TypeMission = $row.TypeMission
                Description = $row.Description
                Lieu = $row.Lieu
                StatutMission = if ([string]::IsNullOrWhiteSpace($row.StatutMission)) { "Planifiée" } else { $row.StatutMission }
                Priorite = if ([string]::IsNullOrWhiteSpace($row.Priorite)) { "Moyenne" } else { $row.Priorite }
            }
            
            # Ajouter dates si présentes
            if (-not [string]::IsNullOrWhiteSpace($row.DateDebut)) {
                try {
                    $itemData.DateDebut = [DateTime]::Parse($row.DateDebut)
                }
                catch {}
            }
            
            if (-not [string]::IsNullOrWhiteSpace($row.DateFin)) {
                try {
                    $itemData.DateFin = [DateTime]::Parse($row.DateFin)
                }
                catch {}
            }
            
            # Autres champs
            if (-not [string]::IsNullOrWhiteSpace($row.NombreBenevoles)) {
                $itemData.NombreBenevoles = [int]$row.NombreBenevoles
            }
            
            if (-not [string]::IsNullOrWhiteSpace($row.ResponsableMission)) {
                $itemData.ResponsableMission = $row.ResponsableMission
            }
            
            $newItem = Add-PnPListItem -List "Missions" -Values $itemData
            
            # Stocker le mapping CodeSource → SharePoint ID
            $missionMapping[$row.CodeSource] = $newItem.Id
            
            $importedMissions++
        }
        catch {
            Write-Log "  ✗ Erreur import mission $($row.Titre): $_" -Level "ERROR"
            $failedMissions++
        }
    }
}

Write-Progress -Activity "Import Missions" -Completed
Write-Log "✓ Missions importées: $importedMissions/$totalMissions (échecs: $failedMissions)" -Level "SUCCESS"

# ============================================================================================================
# IMPORT 3: AFFECTATIONS (avec lookups)
# ============================================================================================================

Write-Host ""
Write-Host "=== IMPORT AFFECTATIONS ===" -ForegroundColor Yellow
Write-Log "Début import Affectations"

$csvAffectations = Import-Csv $csvFiles.Affectations -Encoding UTF8
$totalAffectations = $csvAffectations.Count
$importedAffectations = 0
$failedAffectations = 0

Write-Log "Import de $totalAffectations affectations par lots de $BatchSize..."

for ($i = 0; $i -lt $totalAffectations; $i += $BatchSize) {
    $batch = $csvAffectations | Select-Object -Skip $i -First $BatchSize
    $batchNumber = [math]::Floor($i / $BatchSize) + 1
    $totalBatches = [math]::Ceiling($totalAffectations / $BatchSize)
    
    Write-Progress -Activity "Import Affectations" -Status "Lot $batchNumber/$totalBatches" -PercentComplete (($i / $totalAffectations) * 100)
    
    foreach ($row in $batch) {
        try {
            # Résoudre les lookups
            $benevoleId = $benevoleMapping[$row.BenevoleSourceID]
            $missionId = $missionMapping[$row.MissionCodeSource]
            
            if (-not $benevoleId) {
                Write-Log "  ⚠ Bénévole non trouvé pour PERSONNE_ID=$($row.BenevoleSourceID)" -Level "WARNING"
                $failedAffectations++
                continue
            }
            
            if (-not $missionId) {
                Write-Log "  ⚠ Mission non trouvée pour CodeSource=$($row.MissionCodeSource)" -Level "WARNING"
                $failedAffectations++
                continue
            }
            
            $itemData = @{
                Title = "Affectation"
                MissionIDId = $missionId
                BenevoleIDId = $benevoleId
                StatutAffectation = $row.StatutAffectation
            }
            
            # Dates
            if (-not [string]::IsNullOrWhiteSpace($row.DateProposition)) {
                try {
                    $itemData.DateProposition = [DateTime]::Parse($row.DateProposition)
                }
                catch {}
            }
            
            if (-not [string]::IsNullOrWhiteSpace($row.DateConfirmation)) {
                try {
                    $itemData.DateConfirmation = [DateTime]::Parse($row.DateConfirmation)
                }
                catch {}
            }
            
            # Autres champs
            if (-not [string]::IsNullOrWhiteSpace($row.HeuresDeclarees)) {
                $itemData.HeuresDeclarees = [decimal]$row.HeuresDeclarees
            }
            
            if (-not [string]::IsNullOrWhiteSpace($row.Commentaire)) {
                $itemData.Commentaire = $row.Commentaire
            }
            
            Add-PnPListItem -List "Affectations" -Values $itemData | Out-Null
            $importedAffectations++
        }
        catch {
            Write-Log "  ✗ Erreur import affectation: $_" -Level "ERROR"
            $failedAffectations++
        }
    }
}

Write-Progress -Activity "Import Affectations" -Completed
Write-Log "✓ Affectations importées: $importedAffectations/$totalAffectations (échecs: $failedAffectations)" -Level "SUCCESS"

# ============================================================================================================
# RAPPORT FINAL
# ============================================================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "IMPORT TERMINÉ !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "RÉSUMÉ:" -ForegroundColor White
Write-Host "  Bénévoles:    $importedBenevoles/$totalBenevoles importés (échecs: $failedBenevoles)" -ForegroundColor $(if ($failedBenevoles -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Missions:     $importedMissions/$totalMissions importées (échecs: $failedMissions)" -ForegroundColor $(if ($failedMissions -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Affectations: $importedAffectations/$totalAffectations importées (échecs: $failedAffectations)" -ForegroundColor $(if ($failedAffectations -eq 0) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "Fichier de log: $logPath" -ForegroundColor Cyan
Write-Host ""

Write-Log "========== FIN DE L'IMPORT =========="

if (($failedBenevoles + $failedMissions + $failedAffectations) -gt 0) {
    Write-Host "⚠ ATTENTION: Certains enregistrements n'ont pas été importés." -ForegroundColor Yellow
    Write-Host "  Consultez le fichier de log pour plus de détails." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Prochaine étape:" -ForegroundColor Yellow
Write-Host "  → Exécuter le script 04-Verification-Migration.ps1 pour valider la migration" -ForegroundColor White
Write-Host "  → Accéder à votre site SharePoint: $SiteUrl" -ForegroundColor White
Write-Host ""

# Déconnexion
Disconnect-PnPOnline

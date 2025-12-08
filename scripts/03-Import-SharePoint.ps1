# ============================================================================================================
# Script: Import données CSV vers SharePoint - Projet Gestion Bénévoles
# Auteur: Joël Serrentino  
# Date: 18 novembre 2025
# Version: 2.0 (inclut bénéficiaires et prestations)
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
    - Importe Bénévoles, Missions, Affectations, Bénéficiaires, Prestations depuis les CSV
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

# ============================================================================================================
# FONCTIONS DE MAPPING POUR VALEURS DE CHOIX SHAREPOINT
# ============================================================================================================

function Map-StatutBenevole {
    param([string]$Statut)
    
    # SharePoint accepte: Actif, Inactif, Suspendu, En attente
    # CSV contient: Actif, Ancien, En attente, Ponctuel
    
    switch ($Statut) {
        "Ancien" { return "Inactif" }
        "Ponctuel" { return "Actif" }
        "Actif" { return "Actif" }
        "En attente" { return "En attente" }
        default { return "Actif" }
    }
}

function Map-Civilite {
    param([string]$Civilite)
    
    # SharePoint accepte: M., Mme, Autre
    # CSV contient: Madame, Monsieur
    
    switch ($Civilite) {
        "Madame" { return "Mme" }
        "Monsieur" { return "M." }
        default { return "Autre" }
    }
}

function Map-TypeMission {
    param([string]$TypeMission)
    
    # SharePoint accepte: Récurrente, Ponctuelle
    # CSV contient: Recurrente, Ponctuelle
    
    switch ($TypeMission) {
        "Recurrente" { return "Récurrente" }
        "Ponctuelle" { return "Ponctuelle" }
        default { return "Ponctuelle" }
    }
}

function Map-StatutMission {
    param([string]$StatutMission)
    
    # SharePoint accepte: Brouillon, Planifiée, En cours, Clôturée, Annulée
    # CSV contient: Planifiee
    
    switch ($StatutMission) {
        "Planifiee" { return "Planifiée" }
        "Brouillon" { return "Brouillon" }
        "En cours" { return "En cours" }
        "Cloturee" { return "Clôturée" }
        "Annulee" { return "Annulée" }
        default { return "Planifiée" }
    }
}

function Map-Priorite {
    param([string]$Priorite)
    
    # SharePoint accepte: Faible, Moyenne, Haute, Critique
    # Pas de changement nécessaire
    
    switch ($Priorite) {
        "Faible" { return "Faible" }
        "Moyenne" { return "Moyenne" }
        "Haute" { return "Haute" }
        "Critique" { return "Critique" }
        default { return "Moyenne" }
    }
}

function Parse-DateSafe {
    param([string]$DateString)
    
    if ([string]::IsNullOrWhiteSpace($DateString)) {
        return $null
    }
    
    try {
        return [DateTime]::Parse($DateString)
    }
    catch {
        return $null
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
    Write-Log "Vérification de la connexion à SharePoint..."
    
    # Vérifier si déjà connecté
    $existingConnection = Get-PnPConnection -ErrorAction SilentlyContinue
    
    if ($existingConnection -and $existingConnection.Url -eq $SiteUrl) {
        Write-Log "✓ Connexion existante détectée" -Level "SUCCESS"
    }
    else {
        Write-Log "Connexion à SharePoint avec ClientId..."
        Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "13c089c9-8dc9-43fb-8676-039c61c0dfac"
        Write-Log "✓ Connexion réussie" -Level "SUCCESS"
    }
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
                Civilite = Map-Civilite $row.Civilite
                EmailBenevole = $row.Email
                Telephone = $row.Telephone
                TelephoneMobile = $row.TelephoneMobile
                Adresse1 = $row.Adresse1
                Adresse2 = $row.Adresse2
                NPA = $row.NPA
                Ville = $row.Ville
                Statut = Map-StatutBenevole $row.Statut
                RGPDConsentement = $row.RGPDConsentement
                NotesGenerales = $row.NotesGenerales
                NotesInternes = $row.NotesInternes
            }
            
            # Ajouter DateNaissance si présente
            $dateNaissance = Parse-DateSafe $row.DateNaissance
            if ($dateNaissance) {
                $itemData.DateNaissance = $dateNaissance
            }
            
            # Ajouter DateEntree
            $dateEntree = Parse-DateSafe $row.DateEntree
            if ($dateEntree) {
                $itemData.DateEntree = $dateEntree
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
                    if ($match -and $match.Count -gt 0) {
                        $competencesValides += $match[0]
                    }
                }
                
                if ($competencesValides.Count -gt 0) {
                    $itemData.Competences = $competencesValides
                }
            }
            
            # Créer l'item SharePoint
            $newItem = Add-PnPListItem -List "Benevoles" -Values $itemData
            
            # Stocker le mapping SourceID → SharePoint ID
            if (-not [string]::IsNullOrWhiteSpace($row.SourceID)) {
                $benevoleMapping[$row.SourceID] = $newItem.Id
            }
            
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
                TypeMission = Map-TypeMission $row.TypeMission
                DescriptionMission = $row.Description
                LieuMission = $row.Lieu
                StatutMission = Map-StatutMission $row.StatutMission
                Priorite = Map-Priorite $row.Priorite
            }
            
            # Ajouter dates si présentes
            $dateDebut = Parse-DateSafe $row.DateDebut
            if ($dateDebut) {
                $itemData.DateDebut = $dateDebut
            }
            
            $dateFin = Parse-DateSafe $row.DateFin
            if ($dateFin) {
                $itemData.DateFin = $dateFin
            }
            
            # Autres champs
            if (-not [string]::IsNullOrWhiteSpace($row.NombreBenevoles)) {
                $itemData.NombreBenevoles = [int]$row.NombreBenevoles
            }
            
            if (-not [string]::IsNullOrWhiteSpace($row.ResponsableMission)) {
                $itemData.ResponsableMission = $row.ResponsableMission
            }
            
            $newItem = Add-PnPListItem -List "Missions" -Values $itemData
            
            # Stocker le mapping SourceCode → SharePoint ID
            if (-not [string]::IsNullOrWhiteSpace($row.SourceCode)) {
                $missionMapping[$row.SourceCode] = $newItem.Id
            }
            
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
                MissionID = $missionId
                BenevoleID = $benevoleId
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
# IMPORT 4: BÉNÉFICIAIRES
# ============================================================================================================

Write-Host ""
Write-Host "=== Import des BÉNÉFICIAIRES ===" -ForegroundColor Yellow
Write-Log "--- Import Bénéficiaires ---"

$csvBeneficiaires = Import-Csv "$CsvFolder\Beneficiaires.csv" -Encoding UTF8
$totalBeneficiaires = $csvBeneficiaires.Count
$importedBeneficiaires = 0
$failedBeneficiaires = 0

Write-Host "  Nombre de bénéficiaires à importer: $totalBeneficiaires" -ForegroundColor Cyan

$batchBeneficiaires = @()
$batchCounterBenef = 0

foreach ($row in $csvBeneficiaires) {
    $batchCounterBenef++
    
    try {
        $itemData = @{
            Title = "$($row.CIVILITE) $($row.NOM) $($row.PRENOM)".Trim()
            NumeroBeneficiaire = $row.NumeroBeneficiaire
            PrenomBnf = $row.PRENOM
            NomBnf = $row.NOM
            CiviliteBnf = $row.CIVILITE
            Adresse1Bnf = $row.ADRESSE1
            NPABnf = $row.NPA
            VilleBnf = $row.VILLE
            Besoins = $row.Besoins
            StatutBnf = $row.Statut
            RGPDConsentementBnf = if ($row.RGPDConsentement -eq "Oui") { $true } else { $false }
        }
        
        # DateDebutBnf avec Parse-DateSafe
        $dateDebut = Parse-DateSafe $row.DateDebut
        if ($dateDebut) {
            $itemData.DateDebutBnf = $dateDebut
        }
        
        # Champs optionnels
        if (-not [string]::IsNullOrWhiteSpace($row.ADRESSE2)) { $itemData.Adresse2Bnf = $row.ADRESSE2 }
        if (-not [string]::IsNullOrWhiteSpace($row.TELEPHONE)) { $itemData.TelephoneBnf = $row.TELEPHONE }
        if (-not [string]::IsNullOrWhiteSpace($row.EMAIL)) { $itemData.EmailBnf = $row.EMAIL }
        if (-not [string]::IsNullOrWhiteSpace($row.Referent)) { $itemData.Referent = $row.Referent }
        if (-not [string]::IsNullOrWhiteSpace($row.Horaires)) { $itemData.Horaires = $row.Horaires }
        if (-not [string]::IsNullOrWhiteSpace($row.Historique)) { $itemData.HistoriqueBnf = $row.Historique }
        
        $dateConsentement = Parse-DateSafe $row.RGPDDateConsentement
        if ($dateConsentement) {
            $itemData.RGPDDateConsentementBnf = $dateConsentement
        }
        
        Add-PnPListItem -List "Beneficiaires" -Values $itemData | Out-Null
        $importedBeneficiaires++
        
        Write-Progress -Activity "Import Bénéficiaires" -Status "$importedBeneficiaires/$totalBeneficiaires" -PercentComplete (($importedBeneficiaires / $totalBeneficiaires) * 100)
    }
    catch {
        Write-Log "  ✗ Erreur import bénéficiaire $($row.NOM): $_" -Level "ERROR"
        $failedBeneficiaires++
    }
}

Write-Progress -Activity "Import Bénéficiaires" -Completed
Write-Log "✓ Bénéficiaires importés: $importedBeneficiaires/$totalBeneficiaires (échecs: $failedBeneficiaires)" -Level "SUCCESS"

# ============================================================================================================
# IMPORT 5: PRESTATIONS
# ============================================================================================================

Write-Host ""
Write-Host "=== Import des PRESTATIONS ===" -ForegroundColor Yellow
Write-Log "--- Import Prestations ---"

# Créer mapping PERSONNE_ID → SharePoint ID pour bénéficiaires
Write-Host "  → Chargement mapping bénéficiaires..." -ForegroundColor Cyan
$beneficiairesMapping = @{}
$allBeneficiaires = Get-PnPListItem -List "Beneficiaires" -Fields "ID","NumeroBeneficiaire" -PageSize 500

foreach ($item in $allBeneficiaires) {
    $numBenef = $item.FieldValues.NumeroBeneficiaire
    if ($numBenef -match "BNF-(\d+)") {
        $personneId = [int]$matches[1]
        $beneficiairesMapping[$personneId] = $item.Id
    }
}
Write-Host "    ✓ $($beneficiairesMapping.Count) bénéficiaires chargés" -ForegroundColor Green

$csvPrestations = Import-Csv "$CsvFolder\Prestations.csv" -Encoding UTF8
$totalPrestations = $csvPrestations.Count
$importedPrestations = 0
$failedPrestations = 0

Write-Host "  Nombre de prestations à importer: $totalPrestations" -ForegroundColor Cyan

foreach ($row in $csvPrestations) {
    try {
        # Résoudre lookup Bénéficiaire via NumeroBeneficiaire
        if ([string]::IsNullOrWhiteSpace($row.BeneficiaireSourceID)) {
            Write-Log "  ⚠ BeneficiaireSourceID vide" -Level "WARNING"
            $failedPrestations++
            continue
        }
        
        $beneficiaireId = $beneficiairesMapping[[int]$row.BeneficiaireSourceID]
        if (-not $beneficiaireId) {
            Write-Log "  ⚠ Bénéficiaire non trouvé pour ID=$($row.BeneficiaireSourceID)" -Level "WARNING"
            $failedPrestations++
            continue
        }
        
        # Résoudre lookup Mission via SourceCode
        if ([string]::IsNullOrWhiteSpace($row.MissionCodeSource)) {
            Write-Log "  ⚠ MissionCodeSource vide" -Level "WARNING"
            $failedPrestations++
            continue
        }
        
        $missionId = $missionMapping[$row.MissionCodeSource]
        if (-not $missionId) {
            Write-Log "  ⚠ Mission non trouvée pour SourceCode=$($row.MissionCodeSource)" -Level "WARNING"
            $failedPrestations++
            continue
        }
        
        $itemData = @{
            Title = "Prestation-$beneficiaireId-$missionId"
            BeneficiaireID = $beneficiaireId
            MissionIDPrestation = $missionId
            FrequencePrestation = $row.Frequence
            StatutPrestation = $row.StatutPrestation
        }
        
        # Dates avec Parse-DateSafe
        $dateDebut = Parse-DateSafe $row.DateDebut
        if ($dateDebut) {
            $itemData.DateDebutPrestation = $dateDebut
        }
        
        $derniereVisite = Parse-DateSafe $row.DerniereVisite
        if ($derniereVisite) {
            $itemData.DerniereVisite = $derniereVisite
        }
        
        Add-PnPListItem -List "Prestations" -Values $itemData | Out-Null
        $importedPrestations++
        
        Write-Progress -Activity "Import Prestations" -Status "$importedPrestations/$totalPrestations" -PercentComplete (($importedPrestations / $totalPrestations) * 100)
    }
    catch {
        Write-Log "  ✗ Erreur import prestation: $_" -Level "ERROR"
        $failedPrestations++
    }
}

Write-Progress -Activity "Import Prestations" -Completed
Write-Log "✓ Prestations importées: $importedPrestations/$totalPrestations (échecs: $failedPrestations)" -Level "SUCCESS"

# ============================================================================================================
# RAPPORT FINAL
# ============================================================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "IMPORT TERMINÉ !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "RÉSUMÉ:" -ForegroundColor White
Write-Host "  Bénévoles:      $importedBenevoles/$totalBenevoles importés (échecs: $failedBenevoles)" -ForegroundColor $(if ($failedBenevoles -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Missions:       $importedMissions/$totalMissions importées (échecs: $failedMissions)" -ForegroundColor $(if ($failedMissions -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Affectations:   $importedAffectations/$totalAffectations importées (échecs: $failedAffectations)" -ForegroundColor $(if ($failedAffectations -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Bénéficiaires:  $importedBeneficiaires/$totalBeneficiaires importés (échecs: $failedBeneficiaires)" -ForegroundColor $(if ($failedBeneficiaires -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Prestations:    $importedPrestations/$totalPrestations importées (échecs: $failedPrestations)" -ForegroundColor $(if ($failedPrestations -eq 0) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "Fichier de log: $logPath" -ForegroundColor Cyan
Write-Host ""

Write-Log "========== FIN DE L'IMPORT =========="

if (($failedBenevoles + $failedMissions + $failedAffectations + $failedBeneficiaires + $failedPrestations) -gt 0) {
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

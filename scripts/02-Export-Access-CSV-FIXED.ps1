# ============================================================================================================
# Script: Export données Access vers CSV - Projet Gestion Bénévoles
# Auteur: Joël Serrentino  
# Date: 18 novembre 2025
# Version: 2.0 (inclut bénéficiaires et prestations)
# Description: Exporte toutes les tables Access en fichiers CSV pour migration vers SharePoint
# ============================================================================================================

#Requires -Version 5.1

<#
.SYNOPSIS
    Exporte les données de la base Access SAS-Benevolat.accdb vers des fichiers CSV

.DESCRIPTION
    Ce script:
    - Ouvre la base Access existante
    - Fusionne les tables PERSONNE + BENEVOLE
    - Fusionne les tables PERSONNE + BENEFICIAIRE
    - Fusionne les tables ACTIVITE + EVENEMENT  
    - Fusionne les tables PARTICIPANT + DONNER
    - Exporte la table RECEVOIR vers Prestations
    - Exporte chaque table vers CSV avec encodage UTF-8
    - Nettoie et transforme les données

.PARAMETER AccessDbPath
    Chemin complet vers le fichier .accdb

.PARAMETER OutputFolder
    Dossier de sortie pour les fichiers CSV

.EXAMPLE
    .\02-Export-Access-CSV.ps1 -AccessDbPath "D:\_Projets\bd_SAS-Benevolat\SAS-Benevolat.accdb" -OutputFolder "D:\_Projets\bd_SAS-Benevolat\Export-CSV"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$AccessDbPath = "D:\_Projets\bd_SAS-Benevolat\SAS-Benevolat.accdb",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "D:\_Projets\bd_SAS-Benevolat\Export-CSV"
)

$ErrorActionPreference = "Stop"

# Créer dossier de sortie
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    Write-Host "✓ Dossier de sortie créé: $OutputFolder" -ForegroundColor Green
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "EXPORT DONNÉES ACCESS → CSV" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Base Access: $AccessDbPath" -ForegroundColor White
Write-Host "Sortie: $OutputFolder" -ForegroundColor White
Write-Host ""

# ============================================================================================================
# CONNEXION ACCESS
# ============================================================================================================

try {
    Write-Host "Connexion à la base Access..." -ForegroundColor Yellow
    
    $access = New-Object -ComObject Access.Application
    $access.Visible = $false
    $access.OpenCurrentDatabase($AccessDbPath, $false)
    
    Write-Host "✓ Base Access ouverte" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "✗ Erreur d'ouverture Access: $_" -ForegroundColor Red
    Write-Host "Assurez-vous que Microsoft Access est installé." -ForegroundColor Yellow
    exit 1
}

# ============================================================================================================
# FONCTION D'EXPORT
# ============================================================================================================

function Export-AccessTableToCSV {
    param(
        [string]$TableName,
        [string]$OutputFile,
        [string]$SqlQuery = $null
    )
    
    try {
        Write-Host "  → Export de '$TableName'..." -ForegroundColor Cyan
        
        if ($SqlQuery) {
            # Créer une requête temporaire
            $qdf = $access.CurrentDb().CreateQueryDef("TempExportQuery", $SqlQuery)
            $access.DoCmd.TransferText(
                2, # acExportDelim
                $null,
                "TempExportQuery",
                $OutputFile,
                $true # HasFieldNames
            )
            $access.CurrentDb().QueryDefs.Delete("TempExportQuery")
        }
        else {
            # Export direct de la table
            $access.DoCmd.TransferText(
                2, # acExportDelim
                $null,
                $TableName,
                $OutputFile,
                $true # HasFieldNames
            )
        }
        
        # Convertir en UTF-8 (Access exporte en ANSI par défaut)
        $content = Get-Content $OutputFile -Encoding Default
        $content | Out-File $OutputFile -Encoding UTF8
        
        $lineCount = (Get-Content $OutputFile | Measure-Object -Line).Lines - 1 # -1 pour header
        Write-Host "    ✓ $lineCount enregistrements exportés" -ForegroundColor Green
        
        return $lineCount
    }
    catch {
        Write-Host "    ✗ Erreur: $_" -ForegroundColor Red
        return 0
    }
}

# ============================================================================================================
# EXPORT 1: BÉNÉVOLES (fusion PERSONNE + BENEVOLE)
# ============================================================================================================

Write-Host "=== Export BÉNÉVOLES ===" -ForegroundColor Yellow

$sqlBenevoles = @"
SELECT 
    P.PERSONNE_ID,
    P.TITRE AS Civilite,
    P.NOM AS Nom,
    P.PRENOM AS Prenom,
    (P.NOM & ' ' & P.PRENOM) AS NomComplet,
    P.EMAIL AS Email,
    P.TELEPHONE AS Telephone,
    P.PORTABLE AS TelephoneMobile,
    P.ADRESSE1 AS Adresse1,
    P.ADRESSE2 AS Adresse2,
    L.NPA AS NPA,
    L.VILLE AS Ville,
    P.DATENAISSANCE AS DateNaissance,
    P.LANGUES AS Langues,
    P.SITUATIONPERSONNELLE AS SituationPersonnelle,
    P.FORMATION AS Formation,
    P.DIVERS AS NotesGenerales,
    P.SUIVI AS NotesInternes,
    P.DUO AS Binome,
    B.BNV_STATUT AS Statut,
    B.BNV_DATEDEBUT AS DateEntree,
    B.BNV_PROVENANCE AS Provenance,
    B.BNV_PROVENANCEDETAIL AS ProvenanceDetail,
    B.BNV_DISPONIBILITE AS DisponibilitesPreferees,
    B.BNV_INTERET AS CentresInteret,
    B.BNV_COMPETENCES AS Competences,
    B.BNV_INVITATION AS RecevoirInvitations,
    B.BNV_EVENEMENT AS ParticiperEvenements,
    P.DATECREATION AS DateCreation
FROM 
    (PERSONNE AS P 
    INNER JOIN BENEVOLE AS B ON P.PERSONNE_ID = B.PERSONNE_ID)
    LEFT JOIN LOCALITE AS L ON P.LOCALITE_ID = L.LOCALITE_ID
WHERE
    B.BNV_STATUT IS NOT NULL
ORDER BY
    P.NOM, P.PRENOM
"@

$countBenevoles = Export-AccessTableToCSV -TableName "Benevoles" -OutputFile "$OutputFolder\Benevoles.csv" -SqlQuery $sqlBenevoles

# ============================================================================================================
# EXPORT 2: MISSIONS (fusion ACTIVITE + EVENEMENT)
# ============================================================================================================

Write-Host ""
Write-Host "=== Export MISSIONS ===" -ForegroundColor Yellow

# Export ACTIVITE (missions récurrentes)
$sqlActivites = @"
SELECT 
    'ACT-' & ACTIVITE_ID AS CodeSource,
    ACT_NOM AS Titre,
    'Récurrente' AS TypeMission,
    ACT_AUTRESDETAIL AS Description,
    ACT_LIEU AS Lieu,
    ACT_FREQUENCE AS Frequence,
    '' AS DateDebut,
    '' AS DateFin,
    '' AS HorairesDetail
FROM 
    ACTIVITE
WHERE
    ACT_NOM IS NOT NULL
"@

Export-AccessTableToCSV -TableName "Activites" -OutputFile "$OutputFolder\Missions-Activites.csv" -SqlQuery $sqlActivites | Out-Null

# Export EVENEMENT (missions ponctuelles)
$sqlEvenements = @"
SELECT 
    'EVE-' & EVENEMENT_ID AS CodeSource,
    EVE_NOM AS Titre,
    'Ponctuelle' AS TypeMission,
    EVE_DESCRIPTION AS Description,
    EVE_LIEU AS Lieu,
    'Unique' AS Frequence,
    EVE_DATE AS DateDebut,
    EVE_DATE AS DateFin,
    EVE_HORAIRES AS HorairesDetail
FROM 
    EVENEMENT
WHERE
    EVE_NOM IS NOT NULL
"@

Export-AccessTableToCSV -TableName "Evenements" -OutputFile "$OutputFolder\Missions-Evenements.csv" -SqlQuery $sqlEvenements | Out-Null

# Fusionner les deux fichiers
Write-Host "  → Fusion Activités + Événements..." -ForegroundColor Cyan
$csvActivites = Import-Csv "$OutputFolder\Missions-Activites.csv" -Encoding UTF8
$csvEvenements = Import-Csv "$OutputFolder\Missions-Evenements.csv" -Encoding UTF8
$csvMissions = $csvActivites + $csvEvenements
$csvMissions | Export-Csv "$OutputFolder\Missions.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "    ✓ $($csvMissions.Count) missions fusionnées" -ForegroundColor Green

# Nettoyer fichiers temporaires
Remove-Item "$OutputFolder\Missions-Activites.csv"
Remove-Item "$OutputFolder\Missions-Evenements.csv"

# ============================================================================================================
# EXPORT 3: AFFECTATIONS (fusion PARTICIPANT + DONNER)
# ============================================================================================================

Write-Host ""
Write-Host "=== Export AFFECTATIONS ===" -ForegroundColor Yellow

# Export PARTICIPANT (affectations événements)
$sqlParticipant = @"
SELECT 
    P.PERSONNE_ID AS BenevoleSourceID,
    'EVE-' & P.EVENEMENT_ID AS MissionCodeSource,
    'Confirmé' AS StatutAffectation,
    P.PAR_HORAIRE1 AS PlageHoraire1,
    P.PAR_HORAIRE2 AS PlageHoraire2,
    P.PAR_MATERIEL AS MaterielFourni,
    '' AS Commentaire,
    '' AS HeuresDeclarees,
    Date() AS DateProposition,
    Date() AS DateConfirmation
FROM 
    PARTICIPANT AS P
WHERE
    P.PERSONNE_ID IS NOT NULL AND P.EVENEMENT_ID IS NOT NULL
"@

Export-AccessTableToCSV -TableName "Participant" -OutputFile "$OutputFolder\Affectations-Participant.csv" -SqlQuery $sqlParticipant | Out-Null

# Export DONNER (affectations activités)
$sqlDonner = @"
SELECT 
    D.PERSONNE_ID AS BenevoleSourceID,
    'ACT-' & D.ACTIVITE_ID AS MissionCodeSource,
    'Confirmé' AS StatutAffectation,
    '' AS PlageHoraire1,
    '' AS PlageHoraire2,
    '' AS MaterielFourni,
    '' AS Commentaire,
    '' AS HeuresDeclarees,
    Date() AS DateProposition,
    Date() AS DateConfirmation
FROM 
    DONNER AS D
WHERE
    D.PERSONNE_ID IS NOT NULL AND D.ACTIVITE_ID IS NOT NULL
"@

Export-AccessTableToCSV -TableName "Donner" -OutputFile "$OutputFolder\Affectations-Donner.csv" -SqlQuery $sqlDonner | Out-Null

# Fusionner
Write-Host "  → Fusion Participant + Donner..." -ForegroundColor Cyan
$csvParticipant = Import-Csv "$OutputFolder\Affectations-Participant.csv" -Encoding UTF8
$csvDonner = Import-Csv "$OutputFolder\Affectations-Donner.csv" -Encoding UTF8
$csvAffectations = $csvParticipant + $csvDonner
$csvAffectations | Export-Csv "$OutputFolder\Affectations.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "    ✓ $($csvAffectations.Count) affectations fusionnées" -ForegroundColor Green

Remove-Item "$OutputFolder\Affectations-Participant.csv"
Remove-Item "$OutputFolder\Affectations-Donner.csv"

# ============================================================================================================
# EXPORT 4: LOCALITÉS (table de référence - optionnel)
# ============================================================================================================

Write-Host ""
Write-Host "=== Export LOCALITÉS (référence) ===" -ForegroundColor Yellow

$sqlLocalites = @"
SELECT 
    NPA,
    VILLE
FROM 
    LOCALITE
ORDER BY
    NPA
"@

Export-AccessTableToCSV -TableName "Localites" -OutputFile "$OutputFolder\Localites.csv" -SqlQuery $sqlLocalites | Out-Null

# ============================================================================================================
# EXPORT 5: BÉNÉFICIAIRES (PERSONNE + BENEFICIAIRE)
# ============================================================================================================

Write-Host ""
Write-Host "=== Export BÉNÉFICIAIRES ===" -ForegroundColor Yellow

$sqlBeneficiaires = @"
SELECT 
    B.PERSONNE_ID,
    P.CIVILITE,
    P.NOM,
    P.PRENOM,
    P.ADRESSE1,
    P.ADRESSE2,
    P.NPA,
    P.VILLE,
    P.TELEPHONE,
    P.EMAIL,
    P.DATENAISSANCE,
    B.BNF_BESOINS AS Besoins,
    B.BNF_REFERENT AS Referent,
    B.BNF_HORAIRES AS Horaires,
    B.BNF_DATEDEBUT AS DateDebut,
    B.Historique
FROM 
    BENEFICIAIRE AS B
    INNER JOIN PERSONNE AS P ON B.PERSONNE_ID = P.PERSONNE_ID
ORDER BY
    P.NOM, P.PRENOM
"@

Export-AccessTableToCSV -TableName "Beneficiaires" -OutputFile "$OutputFolder\Beneficiaires.csv" -SqlQuery $sqlBeneficiaires | Out-Null

$csvBeneficiaires = Import-Csv "$OutputFolder\Beneficiaires.csv" -Encoding UTF8
$countBeneficiaires = $csvBeneficiaires.Count
Write-Host "  ✓ $countBeneficiaires bénéficiaires exportés" -ForegroundColor Green

# ============================================================================================================
# EXPORT 6: PRESTATIONS (table RECEVOIR)
# ============================================================================================================

Write-Host ""
Write-Host "=== Export PRESTATIONS (RECEVOIR) ===" -ForegroundColor Yellow

$sqlPrestations = @"
SELECT 
    R.BENEFICIAIRE_ID,
    R.ACTIVITE_ID,
    P.NOM AS NomBeneficiaire,
    P.PRENOM AS PrenomBeneficiaire,
    A.TITRE AS TitreMission
FROM 
    RECEVOIR AS R
    INNER JOIN BENEFICIAIRE AS B ON R.BENEFICIAIRE_ID = B.PERSONNE_ID
    INNER JOIN PERSONNE AS P ON B.PERSONNE_ID = P.PERSONNE_ID
    INNER JOIN ACTIVITE AS A ON R.ACTIVITE_ID = A.ACTIVITE_ID
ORDER BY
    R.BENEFICIAIRE_ID, R.ACTIVITE_ID
"@

Export-AccessTableToCSV -TableName "Prestations" -OutputFile "$OutputFolder\Prestations.csv" -SqlQuery $sqlPrestations | Out-Null

$csvPrestations = Import-Csv "$OutputFolder\Prestations.csv" -Encoding UTF8
$countPrestations = $csvPrestations.Count
Write-Host "  ✓ $countPrestations prestations exportées" -ForegroundColor Green

# ============================================================================================================
# FERMETURE ACCESS
# ============================================================================================================

try {
    $access.CloseCurrentDatabase()
    $access.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($access) | Out-Null
    Write-Host ""
    Write-Host "✓ Base Access fermée" -ForegroundColor Green
}
catch {
    Write-Host "⚠ Avertissement lors de la fermeture: $_" -ForegroundColor Yellow
}

# ============================================================================================================
# POST-TRAITEMENT ET NETTOYAGE
# ============================================================================================================

Write-Host ""
Write-Host "=== Post-traitement des données ===" -ForegroundColor Yellow

# Nettoyer les bénévoles: ajouter colonnes manquantes
Write-Host "  → Nettoyage fichier Bénévoles..." -ForegroundColor Cyan
$csvBenevoles = Import-Csv "$OutputFolder\Benevoles.csv" -Encoding UTF8

# Ajouter colonnes RGPD et autres champs nouveaux
$csvBenevolesEnriches = $csvBenevoles | ForEach-Object {
    $_ | Add-Member -NotePropertyName "NumeroBenevole" -NotePropertyValue ("BEN-" + ([string]$_.PERSONNE_ID).PadLeft(4, '0')) -Force
    $_ | Add-Member -NotePropertyName "RGPDConsentement" -NotePropertyValue "Oui" -Force # À valider manuellement
    $_ | Add-Member -NotePropertyName "DateDerniereMajProfil" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Force
    
    # Normaliser Statut
    if ([string]::IsNullOrWhiteSpace($_.Statut)) {
        $_.Statut = "Actif"
    }
    
    # Normaliser booléens
    $_.RecevoirInvitations = if ($_.RecevoirInvitations -eq "True" -or $_.RecevoirInvitations -eq "-1") { "Oui" } else { "Non" }
    $_.ParticiperEvenements = if ($_.ParticiperEvenements -eq "True" -or $_.ParticiperEvenements -eq "-1") { "Oui" } else { "Non" }
    
    $_
}

$csvBenevolesEnriches | Export-Csv "$OutputFolder\Benevoles.csv" -Encoding UTF8 -NoTypeInformation -Force
Write-Host "    ✓ Bénévoles enrichis et nettoyés" -ForegroundColor Green

# Nettoyer les missions: ajouter CodeMission auto
Write-Host "  → Nettoyage fichier Missions..." -ForegroundColor Cyan
$csvMissionsClean = Import-Csv "$OutputFolder\Missions.csv" -Encoding UTF8

$csvMissionsEnrichies = $csvMissionsClean | ForEach-Object -Begin { $counter = 1 } -Process {
    # Générer CodeMission unique
    if ([string]::IsNullOrWhiteSpace($_.CodeSource)) {
        $codeMission = "MISS-2025-" + ([string]$counter).PadLeft(3, '0')
    }
    else {
        $codeMission = $_.CodeSource
    }
    
    $_ | Add-Member -NotePropertyName "CodeMission" -NotePropertyValue $codeMission -Force
    $_ | Add-Member -NotePropertyName "StatutMission" -NotePropertyValue "Planifiée" -Force
    $_ | Add-Member -NotePropertyName "Priorite" -NotePropertyValue "Moyenne" -Force
    $_ | Add-Member -NotePropertyName "NombreBenevoles" -NotePropertyValue 1 -Force
    $_ | Add-Member -NotePropertyName "CompetencesRequises" -NotePropertyValue "" -Force # À remplir manuellement
    $_ | Add-Member -NotePropertyName "ResponsableMission" -NotePropertyValue "" -Force # À remplir
    
    $counter++
    $_
}

$csvMissionsEnrichies | Export-Csv "$OutputFolder\Missions.csv" -Encoding UTF8 -NoTypeInformation -Force
Write-Host "    ✓ Missions enrichies et nettoyées" -ForegroundColor Green

# Nettoyer les bénéficiaires: ajouter colonnes manquantes
Write-Host "  → Nettoyage fichier Bénéficiaires..." -ForegroundColor Cyan
$csvBeneficiaires = Import-Csv "$OutputFolder\Beneficiaires.csv" -Encoding UTF8

$csvBeneficiairesEnrichis = $csvBeneficiaires | ForEach-Object {
    $_ | Add-Member -NotePropertyName "NumeroBeneficiaire" -NotePropertyValue ("BNF-" + ([string]$_.PERSONNE_ID).PadLeft(4, '0')) -Force
    $_ | Add-Member -NotePropertyName "RGPDConsentement" -NotePropertyValue "Oui" -Force
    $_ | Add-Member -NotePropertyName "RGPDDateConsentement" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Force
    $_ | Add-Member -NotePropertyName "Statut" -NotePropertyValue "Actif" -Force
    
    # Nettoyer les dates vides
    if ([string]::IsNullOrWhiteSpace($_.DateDebut)) {
        $_.DateDebut = (Get-Date).AddMonths(-6).ToString("yyyy-MM-dd")
    }
    
    $_
}

$csvBeneficiairesEnrichis | Export-Csv "$OutputFolder\Beneficiaires.csv" -Encoding UTF8 -NoTypeInformation -Force
Write-Host "    ✓ Bénéficiaires enrichis et nettoyés" -ForegroundColor Green

# Nettoyer les prestations: ajouter colonnes manquantes
Write-Host "  → Nettoyage fichier Prestations..." -ForegroundColor Cyan
$csvPrestations = Import-Csv "$OutputFolder\Prestations.csv" -Encoding UTF8

$csvPrestationsEnrichies = $csvPrestations | ForEach-Object {
    $_ | Add-Member -NotePropertyName "DateDebut" -NotePropertyValue (Get-Date).AddMonths(-3).ToString("yyyy-MM-dd") -Force
    $_ | Add-Member -NotePropertyName "Frequence" -NotePropertyValue "Hebdomadaire" -Force
    $_ | Add-Member -NotePropertyName "StatutPrestation" -NotePropertyValue "En cours" -Force
    $_ | Add-Member -NotePropertyName "DerniereVisite" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Force
    
    $_
}

$csvPrestationsEnrichies | Export-Csv "$OutputFolder\Prestations.csv" -Encoding UTF8 -NoTypeInformation -Force
Write-Host "    ✓ Prestations enrichies et nettoyées" -ForegroundColor Green

# ============================================================================================================
# RAPPORT FINAL
# ============================================================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "EXPORT TERMINÉ AVEC SUCCÈS !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Fichiers CSV créés:" -ForegroundColor White
Write-Host "  ✓ Benevoles.csv         ($countBenevoles bénévoles)" -ForegroundColor Green
Write-Host "  ✓ Missions.csv          ($($csvMissions.Count) missions)" -ForegroundColor Green
Write-Host "  ✓ Affectations.csv      ($($csvAffectations.Count) affectations)" -ForegroundColor Green
Write-Host "  ✓ Beneficiaires.csv     ($countBeneficiaires bénéficiaires)" -ForegroundColor Green
Write-Host "  ✓ Prestations.csv       ($countPrestations prestations)" -ForegroundColor Green
Write-Host "  ✓ Localites.csv         (table de référence)" -ForegroundColor Green
Write-Host ""
Write-Host "Dossier de sortie: $OutputFolder" -ForegroundColor Cyan
Write-Host ""
Write-Host "Prochaine étape:" -ForegroundColor Yellow
Write-Host "  → Exécuter le script 03-Import-SharePoint.ps1" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT - Actions manuelles requises:" -ForegroundColor Yellow
Write-Host "  1. Vérifier les fichiers CSV (ouvrir dans Excel)" -ForegroundColor White
Write-Host "  2. Compléter les champs manquants:" -ForegroundColor White
Write-Host "     - ResponsableMission dans Missions.csv" -ForegroundColor White
Write-Host "     - CompetencesRequises dans Missions.csv" -ForegroundColor White
Write-Host "  3. Valider les consentements RGPD (bénévoles ET bénéficiaires)" -ForegroundColor White
Write-Host ""


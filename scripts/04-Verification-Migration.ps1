# ============================================================================================================
# Script: Vérification Migration Access → SharePoint - Projet Gestion Bénévoles
# Auteur: Joël Serrentino  
# Date: 18 novembre 2025
# Version: 2.0 (inclut bénéficiaires et prestations)
# Description: Vérifie l'intégrité et la complétude de la migration
# ============================================================================================================

#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Vérifie la migration des données Access vers SharePoint

.DESCRIPTION
    Ce script:
    - Compare les comptages Access vs SharePoint (bénévoles, missions, affectations, bénéficiaires, prestations)
    - Vérifie l'intégrité des lookups
    - Valide la qualité des données
    - Génère un rapport de vérification HTML

.PARAMETER AccessDbPath
    Chemin vers la base Access d'origine

.PARAMETER SiteUrl
    URL du site SharePoint

.PARAMETER ReportPath
    Chemin pour le rapport de vérification (optionnel)

.EXAMPLE
    .\04-Verification-Migration.ps1 -AccessDbPath "D:\_Projets\bd_SAS-Benevolat\SAS-Benevolat.accdb" -SiteUrl "https://votre-tenant.sharepoint.com/sites/Benevoles"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$AccessDbPath = "D:\_Projets\bd_SAS-Benevolat\SAS-Benevolat.accdb",
    
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = "D:\_Projets\bd_SAS-Benevolat\Rapport-Verification-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VÉRIFICATION MIGRATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Base Access: $AccessDbPath" -ForegroundColor White
Write-Host "Site SharePoint: $SiteUrl" -ForegroundColor White
Write-Host "Rapport: $ReportPath" -ForegroundColor White
Write-Host ""

# Structure pour stocker les résultats
$verificationResults = @{
    DateVerification = Get-Date
    AccessDbPath = $AccessDbPath
    SiteUrl = $SiteUrl
    Comparaisons = @()
    ProblemesTrouves = @()
    Statistiques = @{}
}

# ============================================================================================================
# CONNEXION ACCESS
# ============================================================================================================

Write-Host "Connexion à Access..." -ForegroundColor Yellow

try {
    $access = New-Object -ComObject Access.Application
    $access.Visible = $false
    $access.OpenCurrentDatabase($AccessDbPath, $true) # Mode lecture seule
    Write-Host "✓ Base Access ouverte" -ForegroundColor Green
}
catch {
    Write-Host "✗ Erreur d'ouverture Access: $_" -ForegroundColor Red
    exit 1
}

# ============================================================================================================
# CONNEXION SHAREPOINT
# ============================================================================================================

Write-Host "Connexion à SharePoint..." -ForegroundColor Yellow

try {
    Connect-PnPOnline -Url $SiteUrl -Interactive
    Write-Host "✓ Connexion SharePoint réussie" -ForegroundColor Green
}
catch {
    Write-Host "✗ Erreur de connexion SharePoint: $_" -ForegroundColor Red
    $access.CloseCurrentDatabase()
    $access.Quit()
    exit 1
}

Write-Host ""

# ============================================================================================================
# FONCTION: COMPTER ENREGISTREMENTS ACCESS
# ============================================================================================================

function Get-AccessRecordCount {
    param([string]$TableName)
    
    try {
        $db = $access.CurrentDb()
        $rs = $db.OpenRecordset("SELECT COUNT(*) AS Total FROM [$TableName]")
        $count = $rs.Fields("Total").Value
        $rs.Close()
        return $count
    }
    catch {
        Write-Host "  ⚠ Impossible de compter les enregistrements dans '$TableName'" -ForegroundColor Yellow
        return -1
    }
}

# ============================================================================================================
# FONCTION: COMPTER ENREGISTREMENTS SHAREPOINT
# ============================================================================================================

function Get-SharePointItemCount {
    param([string]$ListName)
    
    try {
        $list = Get-PnPList -Identity $ListName
        return $list.ItemCount
    }
    catch {
        Write-Host "  ⚠ Impossible de compter les items dans '$ListName'" -ForegroundColor Yellow
        return -1
    }
}

# ============================================================================================================
# VÉRIFICATION 1: COMPTAGE DES ENREGISTREMENTS
# ============================================================================================================

Write-Host "=== VÉRIFICATION 1: Comptage des enregistrements ===" -ForegroundColor Yellow
Write-Host ""

# Bénévoles (fusion PERSONNE + BENEVOLE)
Write-Host "Bénévoles:" -ForegroundColor Cyan
try {
    $db = $access.CurrentDb()
    $rsBenevoles = $db.OpenRecordset("SELECT COUNT(*) AS Total FROM PERSONNE INNER JOIN BENEVOLE ON PERSONNE.PERSONNE_ID = BENEVOLE.PERSONNE_ID WHERE BENEVOLE.BNV_STATUT IS NOT NULL")
    $countAccessBenevoles = $rsBenevoles.Fields("Total").Value
    $rsBenevoles.Close()
}
catch {
    $countAccessBenevoles = -1
}

$countSharePointBenevoles = Get-SharePointItemCount -ListName "Benevoles"

$deltaBenevoles = $countSharePointBenevoles - $countAccessBenevoles
$statusBenevoles = if ($deltaBenevoles -eq 0) { "✓ OK" } elseif ($deltaBenevoles -lt 0) { "✗ MANQUE" } else { "⚠ TROP" }

Write-Host "  Access:     $countAccessBenevoles bénévoles" -ForegroundColor White
Write-Host "  SharePoint: $countSharePointBenevoles bénévoles" -ForegroundColor White
Write-Host "  Différence: $deltaBenevoles | $statusBenevoles" -ForegroundColor $(if ($deltaBenevoles -eq 0) { "Green" } else { "Red" })
Write-Host ""

$verificationResults.Comparaisons += @{
    Entite = "Bénévoles"
    Access = $countAccessBenevoles
    SharePoint = $countSharePointBenevoles
    Delta = $deltaBenevoles
    Statut = $statusBenevoles
}

# Missions (fusion ACTIVITE + EVENEMENT)
Write-Host "Missions:" -ForegroundColor Cyan
$countAccessActivites = Get-AccessRecordCount -TableName "ACTIVITE"
$countAccessEvenements = Get-AccessRecordCount -TableName "EVENEMENT"
$countAccessMissions = $countAccessActivites + $countAccessEvenements

$countSharePointMissions = Get-SharePointItemCount -ListName "Missions"

$deltaMissions = $countSharePointMissions - $countAccessMissions
$statusMissions = if ($deltaMissions -eq 0) { "✓ OK" } elseif ($deltaMissions -lt 0) { "✗ MANQUE" } else { "⚠ TROP" }

Write-Host "  Access:     $countAccessActivites activités + $countAccessEvenements événements = $countAccessMissions missions" -ForegroundColor White
Write-Host "  SharePoint: $countSharePointMissions missions" -ForegroundColor White
Write-Host "  Différence: $deltaMissions | $statusMissions" -ForegroundColor $(if ($deltaMissions -eq 0) { "Green" } else { "Red" })
Write-Host ""

$verificationResults.Comparaisons += @{
    Entite = "Missions"
    Access = $countAccessMissions
    SharePoint = $countSharePointMissions
    Delta = $deltaMissions
    Statut = $statusMissions
}

# Affectations (fusion PARTICIPANT + DONNER)
Write-Host "Affectations:" -ForegroundColor Cyan
$countAccessParticipant = Get-AccessRecordCount -TableName "PARTICIPANT"
$countAccessDonner = Get-AccessRecordCount -TableName "DONNER"
$countAccessAffectations = $countAccessParticipant + $countAccessDonner

$countSharePointAffectations = Get-SharePointItemCount -ListName "Affectations"

$deltaAffectations = $countSharePointAffectations - $countAccessAffectations
$statusAffectations = if ($deltaAffectations -eq 0) { "✓ OK" } elseif ($deltaAffectations -lt 0) { "✗ MANQUE" } else { "⚠ TROP" }

Write-Host "  Access:     $countAccessParticipant participants + $countAccessDonner donner = $countAccessAffectations affectations" -ForegroundColor White
Write-Host "  SharePoint: $countSharePointAffectations affectations" -ForegroundColor White
Write-Host "  Différence: $deltaAffectations | $statusAffectations" -ForegroundColor $(if ($deltaAffectations -eq 0) { "Green" } else { "Red" })
Write-Host ""

$verificationResults.Comparaisons += @{
    Entite = "Affectations"
    Access = $countAccessAffectations
    SharePoint = $countSharePointAffectations
    Delta = $deltaAffectations
    Statut = $statusAffectations
}

# Bénéficiaires (fusion PERSONNE + BENEFICIAIRE)
Write-Host "Bénéficiaires:" -ForegroundColor Cyan
$countAccessBeneficiaires = Get-AccessRecordCount -TableName "BENEFICIAIRE"
$countSharePointBeneficiaires = Get-SharePointItemCount -ListName "Beneficiaires"

$deltaBeneficiaires = $countSharePointBeneficiaires - $countAccessBeneficiaires
$statusBeneficiaires = if ($deltaBeneficiaires -eq 0) { "✓ OK" } elseif ($deltaBeneficiaires -lt 0) { "✗ MANQUE" } else { "⚠ TROP" }

Write-Host "  Access:     $countAccessBeneficiaires bénéficiaires" -ForegroundColor White
Write-Host "  SharePoint: $countSharePointBeneficiaires bénéficiaires" -ForegroundColor White
Write-Host "  Différence: $deltaBeneficiaires | $statusBeneficiaires" -ForegroundColor $(if ($deltaBeneficiaires -eq 0) { "Green" } else { "Red" })
Write-Host ""

$verificationResults.Comparaisons += @{
    Entite = "Bénéficiaires"
    Access = $countAccessBeneficiaires
    SharePoint = $countSharePointBeneficiaires
    Delta = $deltaBeneficiaires
    Statut = $statusBeneficiaires
}

# Prestations (table RECEVOIR)
Write-Host "Prestations:" -ForegroundColor Cyan
$countAccessPrestations = Get-AccessRecordCount -TableName "RECEVOIR"
$countSharePointPrestations = Get-SharePointItemCount -ListName "Prestations"

$deltaPrestations = $countSharePointPrestations - $countAccessPrestations
$statusPrestations = if ($deltaPrestations -eq 0) { "✓ OK" } elseif ($deltaPrestations -lt 0) { "✗ MANQUE" } else { "⚠ TROP" }

Write-Host "  Access:     $countAccessPrestations prestations (RECEVOIR)" -ForegroundColor White
Write-Host "  SharePoint: $countSharePointPrestations prestations" -ForegroundColor White
Write-Host "  Différence: $deltaPrestations | $statusPrestations" -ForegroundColor $(if ($deltaPrestations -eq 0) { "Green" } else { "Red" })
Write-Host ""

$verificationResults.Comparaisons += @{
    Entite = "Prestations"
    Access = $countAccessPrestations
    SharePoint = $countSharePointPrestations
    Delta = $deltaPrestations
    Statut = $statusPrestations
}

# ============================================================================================================
# VÉRIFICATION 2: INTÉGRITÉ DES LOOKUPS
# ============================================================================================================

Write-Host "=== VÉRIFICATION 2: Intégrité des lookups ===" -ForegroundColor Yellow
Write-Host ""

Write-Host "Vérification des références Affectations..." -ForegroundColor Cyan

$affectations = Get-PnPListItem -List "Affectations" -PageSize 500

$affectationsSansBenevole = 0
$affectationsSansMission = 0

foreach ($aff in $affectations) {
    if ($null -eq $aff["MissionIDId"]) {
        $affectationsSansMission++
        $verificationResults.ProblemesTrouves += "Affectation ID=$($aff.Id) sans MissionID"
    }
    
    if ($null -eq $aff["BenevoleIDId"]) {
        $affectationsSansBenevole++
        $verificationResults.ProblemesTrouves += "Affectation ID=$($aff.Id) sans BenevoleID"
    }
}

Write-Host "  Affectations sans bénévole: $affectationsSansBenevole" -ForegroundColor $(if ($affectationsSansBenevole -eq 0) { "Green" } else { "Red" })
Write-Host "  Affectations sans mission: $affectationsSansMission" -ForegroundColor $(if ($affectationsSansMission -eq 0) { "Green" } else { "Red" })
Write-Host ""

$verificationResults.Statistiques["AffectationsSansBenevole"] = $affectationsSansBenevole
$verificationResults.Statistiques["AffectationsSansMission"] = $affectationsSansMission

Write-Host "Vérification des références Prestations..." -ForegroundColor Cyan

$prestations = Get-PnPListItem -List "Prestations" -PageSize 500

$prestationsSansBeneficiaire = 0
$prestationsSansMission = 0

foreach ($prest in $prestations) {
    if ($null -eq $prest["BeneficiaireID"]) {
        $prestationsSansBeneficiaire++
        $verificationResults.ProblemesTrouves += "Prestation ID=$($prest.Id) sans BeneficiaireID"
    }
    
    if ($null -eq $prest["MissionIDPrestation"]) {
        $prestationsSansMission++
        $verificationResults.ProblemesTrouves += "Prestation ID=$($prest.Id) sans MissionID"
    }
}

Write-Host "  Prestations sans bénéficiaire: $prestationsSansBeneficiaire" -ForegroundColor $(if ($prestationsSansBeneficiaire -eq 0) { "Green" } else { "Red" })
Write-Host "  Prestations sans mission: $prestationsSansMission" -ForegroundColor $(if ($prestationsSansMission -eq 0) { "Green" } else { "Red" })
Write-Host ""

$verificationResults.Statistiques["PrestationsSansBeneficiaire"] = $prestationsSansBeneficiaire
$verificationResults.Statistiques["PrestationsSansMission"] = $prestationsSansMission

# ============================================================================================================
# VÉRIFICATION 3: QUALITÉ DES DONNÉES
# ============================================================================================================

Write-Host "=== VÉRIFICATION 3: Qualité des données ===" -ForegroundColor Yellow
Write-Host ""

Write-Host "Analyse des bénévoles..." -ForegroundColor Cyan

$benevoles = Get-PnPListItem -List "Benevoles" -PageSize 500

$benevoleSansEmail = 0
$benevoleSansTelephone = 0
$benevoleSansRGPD = 0

foreach ($ben in $benevoles) {
    if ([string]::IsNullOrWhiteSpace($ben["Email"])) {
        $benevoleSansEmail++
        $verificationResults.ProblemesTrouves += "Bénévole '$($ben["Title"])' (ID=$($ben.Id)) sans email"
    }
    
    if ([string]::IsNullOrWhiteSpace($ben["Telephone"]) -and [string]::IsNullOrWhiteSpace($ben["TelephoneMobile"])) {
        $benevoleSansTelephone++
    }
    
    if ($ben["RGPDConsentement"] -ne "Oui") {
        $benevoleSansRGPD++
        $verificationResults.ProblemesTrouves += "Bénévole '$($ben["Title"])' (ID=$($ben.Id)) sans consentement RGPD valide"
    }
}

Write-Host "  Bénévoles sans email: $benevoleSansEmail" -ForegroundColor $(if ($benevoleSansEmail -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Bénévoles sans téléphone: $benevoleSansTelephone" -ForegroundColor $(if ($benevoleSansTelephone -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Bénévoles sans consentement RGPD: $benevoleSansRGPD" -ForegroundColor $(if ($benevoleSansRGPD -eq 0) { "Green" } else { "Red" })
Write-Host ""

$verificationResults.Statistiques["BenevoleSansEmail"] = $benevoleSansEmail
$verificationResults.Statistiques["BenevoleSansTelephone"] = $benevoleSansTelephone
$verificationResults.Statistiques["BenevoleSansRGPD"] = $benevoleSansRGPD

# Analyse des missions
Write-Host "Analyse des missions..." -ForegroundColor Cyan

$missions = Get-PnPListItem -List "Missions" -PageSize 500

$missionsSansResponsable = 0
$missionsSansDate = 0

foreach ($mission in $missions) {
    if ([string]::IsNullOrWhiteSpace($mission["ResponsableMission"])) {
        $missionsSansResponsable++
    }
    
    if ($null -eq $mission["DateDebut"]) {
        $missionsSansDate++
        $verificationResults.ProblemesTrouves += "Mission '$($mission["Title"])' (ID=$($mission.Id)) sans date de début"
    }
}

Write-Host "  Missions sans responsable: $missionsSansResponsable" -ForegroundColor Yellow
Write-Host "  Missions sans date de début: $missionsSansDate" -ForegroundColor $(if ($missionsSansDate -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

$verificationResults.Statistiques["MissionsSansResponsable"] = $missionsSansResponsable
$verificationResults.Statistiques["MissionsSansDate"] = $missionsSansDate

# Analyse des bénéficiaires
Write-Host "Analyse des bénéficiaires..." -ForegroundColor Cyan

$beneficiaires = Get-PnPListItem -List "Beneficiaires" -PageSize 500

$beneficiairesSansAdresse = 0
$beneficiairesSansBesoins = 0
$beneficiairesSansRGPD = 0

foreach ($benef in $beneficiaires) {
    if ([string]::IsNullOrWhiteSpace($benef["Adresse1Bnf"]) -or [string]::IsNullOrWhiteSpace($benef["VilleBnf"])) {
        $beneficiairesSansAdresse++
        $verificationResults.ProblemesTrouves += "Bénéficiaire '$($benef["Title"])' (ID=$($benef.Id)) sans adresse complète"
    }
    
    if ([string]::IsNullOrWhiteSpace($benef["Besoins"])) {
        $beneficiairesSansBesoins++
        $verificationResults.ProblemesTrouves += "Bénéficiaire '$($benef["Title"])' (ID=$($benef.Id)) sans besoins identifiés"
    }
    
    if ($benef["RGPDConsentementBnf"] -ne $true) {
        $beneficiairesSansRGPD++
        $verificationResults.ProblemesTrouves += "Bénéficiaire '$($benef["Title"])' (ID=$($benef.Id)) sans consentement RGPD"
    }
}

Write-Host "  Bénéficiaires sans adresse: $beneficiairesSansAdresse" -ForegroundColor $(if ($beneficiairesSansAdresse -eq 0) { "Green" } else { "Red" })
Write-Host "  Bénéficiaires sans besoins: $beneficiairesSansBesoins" -ForegroundColor $(if ($beneficiairesSansBesoins -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Bénéficiaires sans RGPD: $beneficiairesSansRGPD" -ForegroundColor $(if ($beneficiairesSansRGPD -eq 0) { "Green" } else { "Red" })
Write-Host ""

$verificationResults.Statistiques["BeneficiairesSansAdresse"] = $beneficiairesSansAdresse
$verificationResults.Statistiques["BeneficiairesSansBesoins"] = $beneficiairesSansBesoins
$verificationResults.Statistiques["BeneficiairesSansRGPD"] = $beneficiairesSansRGPD

# ============================================================================================================
# VÉRIFICATION 4: DOUBLONS
# ============================================================================================================

Write-Host "=== VÉRIFICATION 4: Détection de doublons ===" -ForegroundColor Yellow
Write-Host ""

Write-Host "Recherche de doublons dans Bénévoles..." -ForegroundColor Cyan

# Grouper par email
$emailGroups = $benevoles | Where-Object { -not [string]::IsNullOrWhiteSpace($_["Email"]) } | Group-Object -Property { $_["Email"] }
$doublonsEmail = $emailGroups | Where-Object { $_.Count -gt 1 }

if ($doublonsEmail) {
    Write-Host "  ✗ $($doublonsEmail.Count) emails en doublon trouvés" -ForegroundColor Red
    foreach ($doublon in $doublonsEmail) {
        $verificationResults.ProblemesTrouves += "Email en doublon: $($doublon.Name) ($($doublon.Count) occurrences)"
        Write-Host "    - $($doublon.Name): $($doublon.Count) occurrences" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  ✓ Aucun doublon d'email" -ForegroundColor Green
}

Write-Host ""

# ============================================================================================================
# FERMETURE ACCESS
# ============================================================================================================

try {
    $access.CloseCurrentDatabase()
    $access.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($access) | Out-Null
}
catch {
    Write-Host "⚠ Avertissement lors de la fermeture Access" -ForegroundColor Yellow
}

# ============================================================================================================
# GÉNÉRATION DU RAPPORT HTML
# ============================================================================================================

Write-Host "Génération du rapport HTML..." -ForegroundColor Yellow

$htmlReport = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Rapport de Vérification Migration - $(Get-Date -Format 'dd/MM/yyyy HH:mm')</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #0078d4; border-bottom: 3px solid #0078d4; padding-bottom: 10px; }
        h2 { color: #106ebe; margin-top: 30px; border-bottom: 2px solid #106ebe; padding-bottom: 5px; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; background-color: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        th { background-color: #0078d4; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background-color: #f1f1f1; }
        .ok { color: green; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        .info-box { background-color: #e7f3ff; border-left: 4px solid #0078d4; padding: 15px; margin: 15px 0; }
        .problem-box { background-color: #fff4e5; border-left: 4px solid #ff8c00; padding: 15px; margin: 15px 0; }
        ul { list-style-type: none; padding-left: 0; }
        li { padding: 5px 0; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #ccc; color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <h1>📊 Rapport de Vérification Migration Access → SharePoint</h1>
    
    <div class="info-box">
        <strong>Date de vérification:</strong> $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')<br>
        <strong>Base Access:</strong> $AccessDbPath<br>
        <strong>Site SharePoint:</strong> $SiteUrl
    </div>
    
    <h2>1. Comparaison des comptages</h2>
    <table>
        <tr>
            <th>Entité</th>
            <th>Access</th>
            <th>SharePoint</th>
            <th>Différence</th>
            <th>Statut</th>
        </tr>
"@

foreach ($comp in $verificationResults.Comparaisons) {
    $cssClass = if ($comp.Delta -eq 0) { "ok" } else { "error" }
    $htmlReport += @"
        <tr>
            <td><strong>$($comp.Entite)</strong></td>
            <td>$($comp.Access)</td>
            <td>$($comp.SharePoint)</td>
            <td class="$cssClass">$($comp.Delta)</td>
            <td class="$cssClass">$($comp.Statut)</td>
        </tr>
"@
}

$htmlReport += @"
    </table>
    
    <h2>2. Intégrité des lookups</h2>
    <ul>
        <li>Affectations sans bénévole: <span class="$(if ($affectationsSansBenevole -eq 0) { 'ok' } else { 'error' })">$affectationsSansBenevole</span></li>
        <li>Affectations sans mission: <span class="$(if ($affectationsSansMission -eq 0) { 'ok' } else { 'error' })">$affectationsSansMission</span></li>
    </ul>
    
    <h2>3. Qualité des données</h2>
    <h3>Bénévoles</h3>
    <ul>
        <li>Sans email: <span class="$(if ($benevoleSansEmail -eq 0) { 'ok' } else { 'warning' })">$benevoleSansEmail</span></li>
        <li>Sans téléphone: <span class="$(if ($benevoleSansTelephone -eq 0) { 'ok' } else { 'warning' })">$benevoleSansTelephone</span></li>
        <li>Sans consentement RGPD: <span class="$(if ($benevoleSansRGPD -eq 0) { 'ok' } else { 'error' })">$benevoleSansRGPD</span></li>
    </ul>
    
    <h3>Missions</h3>
    <ul>
        <li>Sans responsable: <span class="warning">$missionsSansResponsable</span></li>
        <li>Sans date de début: <span class="$(if ($missionsSansDate -eq 0) { 'ok' } else { 'warning' })">$missionsSansDate</span></li>
    </ul>
"@

if ($verificationResults.ProblemesTrouves.Count -gt 0) {
    $htmlReport += @"
    <h2>⚠ Problèmes détectés</h2>
    <div class="problem-box">
        <ul>
"@
    foreach ($probleme in $verificationResults.ProblemesTrouves | Select-Object -First 50) {
        $htmlReport += "            <li>$probleme</li>`n"
    }
    
    if ($verificationResults.ProblemesTrouves.Count -gt 50) {
        $htmlReport += "            <li><em>... et $($verificationResults.ProblemesTrouves.Count - 50) autres problèmes</em></li>`n"
    }
    
    $htmlReport += @"
        </ul>
    </div>
"@
}
else {
    $htmlReport += @"
    <h2>✓ Aucun problème critique détecté</h2>
    <div class="info-box">
        La migration semble s'être déroulée correctement. Aucun problème bloquant n'a été détecté.
    </div>
"@
}

$htmlReport += @"
    <div class="footer">
        <p>Rapport généré automatiquement par le script 04-Verification-Migration.ps1</p>
        <p>Projet Low-Code Gestion Bénévoles - Joël Serrentino</p>
    </div>
</body>
</html>
"@

$htmlReport | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host "✓ Rapport HTML généré: $ReportPath" -ForegroundColor Green

# ============================================================================================================
# RÉSUMÉ FINAL
# ============================================================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "VÉRIFICATION TERMINÉE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$totalProblemes = $verificationResults.ProblemesTrouves.Count

if ($totalProblemes -eq 0) {
    Write-Host "✓ MIGRATION RÉUSSIE !" -ForegroundColor Green
    Write-Host "  Aucun problème critique détecté." -ForegroundColor Green
}
elseif ($totalProblemes -lt 10) {
    Write-Host "⚠ MIGRATION RÉUSSIE AVEC AVERTISSEMENTS" -ForegroundColor Yellow
    Write-Host "  $totalProblemes problème(s) mineur(s) détecté(s)." -ForegroundColor Yellow
}
else {
    Write-Host "✗ MIGRATION INCOMPLÈTE" -ForegroundColor Red
    Write-Host "  $totalProblemes problème(s) détecté(s) à corriger." -ForegroundColor Red
}

Write-Host ""
Write-Host "Rapport détaillé: $ReportPath" -ForegroundColor Cyan
Write-Host "Ouvrez ce fichier dans un navigateur pour voir tous les détails." -ForegroundColor White
Write-Host ""

# Ouvrir le rapport dans le navigateur par défaut
Start-Process $ReportPath

Write-Host "Prochaines étapes:" -ForegroundColor Yellow
Write-Host "  1. Consulter le rapport HTML" -ForegroundColor White
Write-Host "  2. Corriger les problèmes identifiés si nécessaire" -ForegroundColor White
Write-Host "  3. Commencer à créer l'application Power Apps" -ForegroundColor White
Write-Host "  4. Configurer les workflows Power Automate" -ForegroundColor White
Write-Host ""

Disconnect-PnPOnline

#Requires -Version 5.1

<#
.SYNOPSIS
    Corrige le fichier Prestations.csv en assignant des BeneficiaireSourceID valides
.DESCRIPTION
    Prend les 20 prestations et assigne aléatoirement des bénéficiaires existants
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SharePointFolder = "c:\Users\joels\OneDrive - Serrentino\Documents\5 - Informatique\Mes projets developpement\2_Projets Office\2025 - projet-low-code-benevoles\exports\sharepoint"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CORRECTION PRESTATIONS.CSV" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Charger les bénéficiaires disponibles
$beneficiaires = Import-Csv "$SharePointFolder\Beneficiaires.csv" -Encoding UTF8
$beneficiairesIDs = $beneficiaires | Select-Object -ExpandProperty SourceID

Write-Host "Beneficiaires disponibles: $($beneficiairesIDs.Count)" -ForegroundColor Cyan

# Charger les missions disponibles
$missions = Import-Csv "$SharePointFolder\Missions.csv" -Encoding UTF8
$missionsSourceCodes = $missions | Where-Object { $_.SourceCode -like "ACT-*" } | Select-Object -ExpandProperty SourceCode

Write-Host "Missions (activites) disponibles: $($missionsSourceCodes.Count)" -ForegroundColor Cyan
Write-Host ""

# Créer 20 prestations en assignant des paires bénéficiaire-mission
$prestations = @()
$random = New-Object System.Random

for ($i = 0; $i -lt 20; $i++) {
    # Sélectionner un bénéficiaire aléatoire
    $beneficiaireID = $beneficiairesIDs[$random.Next(0, $beneficiairesIDs.Count)]
    
    # Sélectionner une mission aléatoire
    $missionCode = $missionsSourceCodes[$random.Next(0, $missionsSourceCodes.Count)]
    
    # Créer la prestation
    $prestations += [PSCustomObject]@{
        BeneficiaireSourceID = $beneficiaireID
        MissionCodeSource = $missionCode
        DateDebut = (Get-Date).AddMonths(-$random.Next(1, 12)).ToString("yyyy-MM-dd")
        Frequence = @("Hebdomadaire", "Bi-hebdomadaire", "Mensuelle", "Ponctuelle")[$random.Next(0, 4)]
        StatutPrestation = @("En_cours", "Terminee", "Suspendue")[$random.Next(0, 3)]
        DerniereVisite = (Get-Date).AddDays(-$random.Next(1, 30)).ToString("yyyy-MM-dd HH:mm:ss")
    }
}

# Sauvegarder
$prestations | Export-Csv "$SharePointFolder\Prestations.csv" -Encoding UTF8 -NoTypeInformation

Write-Host "✓ $($prestations.Count) prestations corrigees et sauvegardees" -ForegroundColor Green
Write-Host ""
Write-Host "Fichier mis a jour:" -ForegroundColor White
Write-Host "  $SharePointFolder\Prestations.csv" -ForegroundColor Cyan
Write-Host ""
Write-Host "Exemple de prestations creees:" -ForegroundColor Yellow
$prestations | Select-Object -First 3 | Format-Table -AutoSize
Write-Host ""

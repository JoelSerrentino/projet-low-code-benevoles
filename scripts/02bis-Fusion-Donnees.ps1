#Requires -Version 5.1

<#
.SYNOPSIS
    Fusion et transformation des donnees Access exportees pour SharePoint
    
.DESCRIPTION
    Ce script prend les fichiers CSV bruts exportes et les transforme en format SharePoint:
    - Fusion PERSONNE + BENEVOLE -> Benevoles.csv
    - Fusion PERSONNE + BENEFICIAIRE -> Beneficiaires.csv
    - Fusion ACTIVITE + EVENEMENT -> Missions.csv
    - Fusion PARTICIPANT + DONNER -> Affectations.csv
    - Transformation RECEVOIR -> Prestations.csv
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SourceFolder = "c:\Users\joels\OneDrive - Serrentino\Documents\5 - Informatique\Mes projets developpement\2_Projets Office\2025 - projet-low-code-benevoles\exports",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "c:\Users\joels\OneDrive - Serrentino\Documents\5 - Informatique\Mes projets developpement\2_Projets Office\2025 - projet-low-code-benevoles\exports\sharepoint"
)

$ErrorActionPreference = "Stop"

# Creer dossier de sortie
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FUSION ET TRANSFORMATION DES DONNEES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Source: $SourceFolder" -ForegroundColor White
Write-Host "Sortie: $OutputFolder" -ForegroundColor White
Write-Host ""

# Charger les donnees brutes
Write-Host "Chargement des donnees brutes..." -ForegroundColor Yellow
$personnes = Import-Csv "$SourceFolder\PERSONNE.csv" -Encoding UTF8
$benevoles = Import-Csv "$SourceFolder\BENEVOLE.csv" -Encoding UTF8
$beneficiaires = Import-Csv "$SourceFolder\BENEFICIAIRE.csv" -Encoding UTF8
$activites = Import-Csv "$SourceFolder\ACTIVITE.csv" -Encoding UTF8
$evenements = Import-Csv "$SourceFolder\EVENEMENT.csv" -Encoding UTF8
$donner = Import-Csv "$SourceFolder\DONNER.csv" -Encoding UTF8
$participant = Import-Csv "$SourceFolder\PARTICIPANT.csv" -Encoding UTF8
$recevoir = Import-Csv "$SourceFolder\RECEVOIR.csv" -Encoding UTF8
$localites = Import-Csv "$SourceFolder\LOCALITE.csv" -Encoding UTF8

Write-Host "  OK - Donnees chargees" -ForegroundColor Green
Write-Host ""

# ============================================================================
# 1. BENEVOLES = PERSONNE + BENEVOLE
# ============================================================================

Write-Host "1. Fusion PERSONNE + BENEVOLE..." -ForegroundColor Cyan

$benevolesHash = @{}
foreach ($b in $benevoles) {
    if ($b.PERSONNE_ID) {
        $benevolesHash[$b.PERSONNE_ID] = $b
    }
}

$localitesHash = @{}
foreach ($l in $localites) {
    if ($l.LOCALITE_ID) {
        $localitesHash[$l.LOCALITE_ID] = $l
    }
}

$benevolesFinaux = @()

foreach ($p in $personnes) {
    if (-not $p.PERSONNE_ID) { continue }
    
    $b = $benevolesHash[$p.PERSONNE_ID]
    if ($b) {
        # Recuperer localite
        $loc = $null
        if ($p.LOCALITE_ID) {
            $loc = $localitesHash[$p.LOCALITE_ID]
        }
        
        $benevolesFinaux += [PSCustomObject]@{
            NumeroBenevole = "BEN-" + $p.PERSONNE_ID.PadLeft(5, '0')
            Civilite = $p.TITRE
            Nom = $p.NOM
            Prenom = $p.PRENOM
            NomComplet = "$($p.NOM) $($p.PRENOM)".Trim()
            Email = $p.EMAIL
            Telephone = $p.TELEPHONE
            TelephoneMobile = $p.PORTABLE
            Adresse1 = $p.ADRESSE1
            Adresse2 = $p.ADRESSE2
            NPA = if ($loc) { $loc.NPA } else { "" }
            Ville = if ($loc) { $loc.VILLE } else { "" }
            DateNaissance = $p.DATENAISSANCE
            Langues = $p.LANGUES
            SituationPersonnelle = $p.SITUATIONPERSONNELLE
            Formation = $p.FORMATION
            NotesGenerales = $p.DIVERS
            NotesInternes = $p.SUIVI
            Binome = $p.DUO
            Statut = if ($b.BNV_STATUT) { $b.BNV_STATUT } else { "Actif" }
            DateEntree = $b.BNV_DATEDEBUT
            Provenance = $b.BNV_PROVENANCE
            ProvenanceDetail = $b.BNV_PROVENANCEDETAIL
            DisponibilitesPreferees = $b.BNV_DISPONIBILITE
            CentresInteret = $b.BNV_INTERET
            Competences = $b.BNV_COMPETENCES
            RecevoirInvitations = if ($b.BNV_INVITATION -eq "True") { "Oui" } else { "Non" }
            ParticiperEvenements = if ($b.BNV_EVENEMENT -eq "True") { "Oui" } else { "Non" }
            DateCreation = $p.DATECREATION
            DateDerniereMajProfil = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            RGPDConsentement = "A_VERIFIER"
            SourceID = $p.PERSONNE_ID
        }
    }
}

$benevolesFinaux | Export-Csv "$OutputFolder\Benevoles.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "  OK - $($benevolesFinaux.Count) benevoles crees" -ForegroundColor Green

# ============================================================================
# 2. BENEFICIAIRES = PERSONNE + BENEFICIAIRE
# ============================================================================

Write-Host "2. Fusion PERSONNE + BENEFICIAIRE..." -ForegroundColor Cyan

$beneficiairesHash = @{}
foreach ($bf in $beneficiaires) {
    if ($bf.PERSONNE_ID) {
        $beneficiairesHash[$bf.PERSONNE_ID] = $bf
    }
}

$beneficiairesFinaux = @()

foreach ($p in $personnes) {
    if (-not $p.PERSONNE_ID) { continue }
    
    $bf = $beneficiairesHash[$p.PERSONNE_ID]
    if ($bf) {
        $loc = $null
        if ($p.LOCALITE_ID) {
            $loc = $localitesHash[$p.LOCALITE_ID]
        }
        
        $beneficiairesFinaux += [PSCustomObject]@{
            NumeroBeneficiaire = "BNF-" + $p.PERSONNE_ID.PadLeft(5, '0')
            Civilite = $p.TITRE
            Nom = $p.NOM
            Prenom = $p.PRENOM
            NomComplet = "$($p.NOM) $($p.PRENOM)".Trim()
            Adresse1 = $p.ADRESSE1
            Adresse2 = $p.ADRESSE2
            NPA = if ($loc) { $loc.NPA } else { "" }
            Ville = if ($loc) { $loc.VILLE } else { "" }
            Telephone = $p.TELEPHONE
            Email = $p.EMAIL
            DateNaissance = $p.DATENAISSANCE
            Besoins = $bf.BNF_BESOINS
            Referent = $bf.BNF_REFERENT
            Horaires = $bf.BNF_HORAIRES
            DateDebut = $bf.BNF_DATEDEBUT
            Historique = $bf.Historique
            Statut = "Actif"
            RGPDConsentement = "A_VERIFIER"
            RGPDDateConsentement = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            SourceID = $p.PERSONNE_ID
        }
    }
}

$beneficiairesFinaux | Export-Csv "$OutputFolder\Beneficiaires.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "  OK - $($beneficiairesFinaux.Count) beneficiaires crees" -ForegroundColor Green

# ============================================================================
# 3. MISSIONS = ACTIVITE + EVENEMENT
# ============================================================================

Write-Host "3. Fusion ACTIVITE + EVENEMENT..." -ForegroundColor Cyan

$missionsFinales = @()
$missionCounter = 1

# Activites (missions recurrentes)
foreach ($act in $activites) {
    $missionsFinales += [PSCustomObject]@{
        CodeMission = "ACT-" + $act.ACTIVITE_ID.PadLeft(4, '0')
        Titre = $act.ACT_NOM
        TypeMission = "Recurrente"
        Description = $act.ACT_AUTRESDETAIL
        Lieu = $act.ACT_LIEU
        Frequence = if ($act.ACT_FREQUENCE) { $act.ACT_FREQUENCE } else { "Hebdomadaire" }
        DateDebut = ""
        DateFin = ""
        HorairesDetail = ""
        StatutMission = "Planifiee"
        Priorite = "Moyenne"
        NombreBenevoles = 1
        CompetencesRequises = ""
        ResponsableMission = ""
        SourceType = "ACTIVITE"
        SourceID = $act.ACTIVITE_ID
    }
}

# Evenements (missions ponctuelles)
foreach ($eve in $evenements) {
    $missionsFinales += [PSCustomObject]@{
        CodeMission = "EVE-" + $eve.EVENEMENT_ID.PadLeft(4, '0')
        Titre = $eve.EVE_NOM
        TypeMission = "Ponctuelle"
        Description = $eve.EVE_DESCRIPTION
        Lieu = $eve.EVE_LIEU
        Frequence = "Unique"
        DateDebut = $eve.EVE_DATE
        DateFin = $eve.EVE_DATE
        HorairesDetail = $eve.EVE_HORAIRES
        StatutMission = "Planifiee"
        Priorite = "Moyenne"
        NombreBenevoles = 1
        CompetencesRequises = ""
        ResponsableMission = ""
        SourceType = "EVENEMENT"
        SourceID = $eve.EVENEMENT_ID
    }
}

$missionsFinales | Export-Csv "$OutputFolder\Missions.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "  OK - $($missionsFinales.Count) missions creees" -ForegroundColor Green
Write-Host "     - $($activites.Count) activites recurrentes" -ForegroundColor Gray
Write-Host "     - $($evenements.Count) evenements ponctuels" -ForegroundColor Gray

# ============================================================================
# 4. AFFECTATIONS = PARTICIPANT + DONNER
# ============================================================================

Write-Host "4. Fusion PARTICIPANT + DONNER..." -ForegroundColor Cyan

$affectationsFinales = @()

# PARTICIPANT (benevoles sur evenements)
foreach ($part in $participant) {
    $affectationsFinales += [PSCustomObject]@{
        BenevoleSourceID = $part.PERSONNE_ID
        MissionCodeSource = "EVE-" + $part.EVENEMENT_ID.PadLeft(4, '0')
        StatutAffectation = "Confirme"
        PlageHoraire1 = $part.PAR_HORAIRE1
        PlageHoraire2 = $part.PAR_HORAIRE2
        MaterielFourni = $part.PAR_MATERIEL
        Commentaire = ""
        HeuresDeclarees = ""
        DateProposition = Get-Date -Format "yyyy-MM-dd"
        DateConfirmation = Get-Date -Format "yyyy-MM-dd"
    }
}

# DONNER (benevoles sur activites)
foreach ($don in $donner) {
    $affectationsFinales += [PSCustomObject]@{
        BenevoleSourceID = $don.PERSONNE_ID
        MissionCodeSource = "ACT-" + $don.ACTIVITE_ID.PadLeft(4, '0')
        StatutAffectation = "Confirme"
        PlageHoraire1 = ""
        PlageHoraire2 = ""
        MaterielFourni = ""
        Commentaire = ""
        HeuresDeclarees = ""
        DateProposition = Get-Date -Format "yyyy-MM-dd"
        DateConfirmation = Get-Date -Format "yyyy-MM-dd"
    }
}

$affectationsFinales | Export-Csv "$OutputFolder\Affectations.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "  OK - $($affectationsFinales.Count) affectations creees" -ForegroundColor Green
Write-Host "     - $($participant.Count) participations evenements" -ForegroundColor Gray
Write-Host "     - $($donner.Count) affectations activites" -ForegroundColor Gray

# ============================================================================
# 5. PRESTATIONS = RECEVOIR
# ============================================================================

Write-Host "5. Transformation RECEVOIR -> Prestations..." -ForegroundColor Cyan

$prestationsFinales = @()

foreach ($rec in $recevoir) {
    $prestationsFinales += [PSCustomObject]@{
        BeneficiaireSourceID = $rec.BENEFICIAIRE_ID
        MissionCodeSource = "ACT-" + $rec.ACTIVITE_ID.PadLeft(4, '0')
        DateDebut = (Get-Date).AddMonths(-6).ToString("yyyy-MM-dd")
        Frequence = "Hebdomadaire"
        StatutPrestation = "En_cours"
        DerniereVisite = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

$prestationsFinales | Export-Csv "$OutputFolder\Prestations.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "  OK - $($prestationsFinales.Count) prestations creees" -ForegroundColor Green

# ============================================================================
# RAPPORT FINAL
# ============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "FUSION TERMINEE AVEC SUCCES" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Fichiers SharePoint crees:" -ForegroundColor White
Write-Host "  - Benevoles.csv:      $($benevolesFinaux.Count) enregistrements" -ForegroundColor Green
Write-Host "  - Beneficiaires.csv:  $($beneficiairesFinaux.Count) enregistrements" -ForegroundColor Green
Write-Host "  - Missions.csv:       $($missionsFinales.Count) enregistrements" -ForegroundColor Green
Write-Host "  - Affectations.csv:   $($affectationsFinales.Count) enregistrements" -ForegroundColor Green
Write-Host "  - Prestations.csv:    $($prestationsFinales.Count) enregistrements" -ForegroundColor Green
Write-Host ""
Write-Host "Repertoire: $OutputFolder" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT - Actions manuelles:" -ForegroundColor Yellow
Write-Host "  1. Verifier les fichiers CSV (specialement les lookups)" -ForegroundColor White
Write-Host "  2. Valider les consentements RGPD (colonne A_VERIFIER)" -ForegroundColor White
Write-Host "  3. Completer les champs ResponsableMission et CompetencesRequises" -ForegroundColor White
Write-Host ""
Write-Host "PROCHAINE ETAPE:" -ForegroundColor Yellow
Write-Host "  Executer le script 03-Import-SharePoint.ps1" -ForegroundColor White
Write-Host ""

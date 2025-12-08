#Requires -Version 5.1

<#
.SYNOPSIS
    Anonymise les données sensibles dans les fichiers CSV SharePoint
.DESCRIPTION
    Remplace les données réelles par des données fictives tout en conservant la structure
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$InputFolder = "c:\Users\joels\OneDrive - Serrentino\Documents\5 - Informatique\Mes projets developpement\2_Projets Office\2025 - projet-low-code-benevoles\exports\sharepoint",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = "c:\Users\joels\OneDrive - Serrentino\Documents\5 - Informatique\Mes projets developpement\2_Projets Office\2025 - projet-low-code-benevoles\exports\sharepoint-anonymise"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ANONYMISATION DES DONNEES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Source: $InputFolder" -ForegroundColor White
Write-Host "Sortie: $OutputFolder" -ForegroundColor White
Write-Host ""

# Créer dossier de sortie
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

# Données fictives
$prenomsFictifs = @(
    "Sophie", "Marie", "Isabelle", "Catherine", "Nathalie",
    "Pierre", "Jean", "Marc", "Philippe", "Laurent",
    "Julie", "Christine", "Sylvie", "Sandrine", "Valérie",
    "Michel", "Bernard", "Alain", "François", "Thierry",
    "Anne", "Martine", "Françoise", "Monique", "Nicole",
    "Patrick", "Daniel", "Christian", "Jacques", "André",
    "Céline", "Stéphanie", "Corinne", "Brigitte", "Dominique",
    "Eric", "Pascal", "Olivier", "Bruno", "Vincent",
    "Agnès", "Geneviève", "Véronique", "Chantal", "Jacqueline",
    "Robert", "René", "Georges", "Henri", "Louis"
)

$nomsFictifs = @(
    "Martin", "Bernard", "Dubois", "Thomas", "Robert",
    "Petit", "Durand", "Leroy", "Moreau", "Simon",
    "Laurent", "Lefebvre", "Michel", "Garcia", "David",
    "Bertrand", "Roux", "Vincent", "Fournier", "Morel",
    "Girard", "André", "Mercier", "Dupont", "Lambert",
    "Bonnet", "François", "Martinez", "Legrand", "Garnier",
    "Faure", "Rousseau", "Blanc", "Guerin", "Muller",
    "Henry", "Roussel", "Nicolas", "Perrin", "Meyer",
    "Clement", "Dufour", "Fontaine", "Chevalier", "Robin"
)

$ruesFictives = @(
    "Rue de la Paix", "Avenue des Champs", "Chemin des Fleurs",
    "Route de Genève", "Rue du Commerce", "Avenue du Lac",
    "Chemin de la Forêt", "Rue des Acacias", "Boulevard du Rhône",
    "Rue de la Gare", "Avenue de la Source", "Chemin des Vignes",
    "Rue du Parc", "Route de Lausanne", "Avenue Victor Hugo",
    "Rue Jean Jaurès", "Chemin de Bellevue", "Route des Acacias",
    "Rue de la Mairie", "Avenue de la Liberté", "Chemin du Moulin",
    "Rue du Stade", "Route de Ferney", "Avenue des Alpes",
    "Rue de la Fontaine", "Chemin de la Colline", "Route de Meyrin",
    "Rue des Ecoles", "Avenue de France", "Chemin des Pins"
)

$villesFictives = @{
    "1200" = "GENEVE"
    "1201" = "GENEVE"
    "1202" = "GENEVE"
    "1203" = "GENEVE"
    "1204" = "GENEVE"
    "1205" = "GENEVE"
    "1206" = "GENEVE"
    "1207" = "GENEVE"
    "1208" = "GENEVE"
    "1209" = "GENEVE"
    "1213" = "PETIT-LANCY"
    "1214" = "VERNIER"
    "1215" = "GENEVE-AEROPORT"
    "1216" = "COINTRIN"
    "1217" = "MEYRIN"
    "1218" = "GRAND-SACONNEX"
    "1219" = "CHATELAINE"
    "1220" = "AVUSY"
    "1227" = "CAROUGE"
    "1228" = "PLAN-LES-OUATES"
}

$npas = @("1200", "1201", "1202", "1203", "1204", "1205", "1206", "1207", "1208", "1209",
          "1213", "1214", "1217", "1218", "1227", "1228")

# Fonction pour générer un email fictif
function Get-EmailFictif {
    param([string]$Nom, [string]$Prenom, [int]$Index)
    
    $nomClean = $Nom.ToLower() -replace '[àâä]','a' -replace '[éèêë]','e' -replace '[îï]','i' -replace '[ôö]','o' -replace '[ùûü]','u' -replace '[ç]','c' -replace '[^a-z]',''
    $prenomClean = $Prenom.ToLower() -replace '[àâä]','a' -replace '[éèêë]','e' -replace '[îï]','i' -replace '[ôö]','o' -replace '[ùûü]','u' -replace '[ç]','c' -replace '[^a-z]',''
    
    $domaines = @("email.ch", "exemple.ch", "mail.ch", "contact.ch", "test.ch")
    $domaine = $domaines[$Index % $domaines.Count]
    
    return "$($prenomClean).$($nomClean)@$domaine"
}

# Fonction pour générer un téléphone fictif suisse
function Get-TelephoneFictif {
    param([string]$Type = "fixe")
    
    if ($Type -eq "mobile") {
        $prefix = "07" + (Get-Random -Minimum 6 -Maximum 10)
        $numero = (Get-Random -Minimum 100 -Maximum 1000).ToString().PadLeft(3, '0') + 
                  (Get-Random -Minimum 10 -Maximum 100).ToString().PadLeft(2, '0') + 
                  (Get-Random -Minimum 10 -Maximum 100).ToString().PadLeft(2, '0')
        return "41$prefix$numero"
    }
    else {
        $prefix = "022"
        $numero = (Get-Random -Minimum 100 -Maximum 1000).ToString().PadLeft(3, '0') + 
                  (Get-Random -Minimum 10 -Maximum 100).ToString().PadLeft(2, '0') + 
                  (Get-Random -Minimum 10 -Maximum 100).ToString().PadLeft(2, '0')
        return "41$prefix$numero"
    }
}

# Fonction pour anonymiser date de naissance
function Get-DateNaissanceFictive {
    $annee = Get-Random -Minimum 1940 -Maximum 2000
    $mois = Get-Random -Minimum 1 -Maximum 13
    $jour = Get-Random -Minimum 1 -Maximum 29
    return (Get-Date -Year $annee -Month $mois -Day $jour).ToString("dd/MM/yyyy 00:00:00")
}

# ============================================================================================================
# ANONYMISATION BENEVOLES
# ============================================================================================================

Write-Host "1. Anonymisation Benevoles.csv..." -ForegroundColor Yellow

$benevoles = Import-Csv "$InputFolder\Benevoles.csv" -Encoding UTF8

$benevolesAnonymes = @()
$index = 0

foreach ($b in $benevoles) {
    $index++
    
    $prenom = $prenomsFictifs[$index % $prenomsFictifs.Count]
    $nom = $nomsFictifs[$index % $nomsFictifs.Count]
    $npa = $npas[(Get-Random -Minimum 0 -Maximum $npas.Count)]
    $ville = $villesFictives[$npa]
    
    $bAnonyme = [PSCustomObject]@{
        NumeroBenevole = $b.NumeroBenevole
        Civilite = $b.Civilite
        Nom = $nom
        Prenom = $prenom
        NomComplet = "$nom $prenom"
        Email = Get-EmailFictif -Nom $nom -Prenom $prenom -Index $index
        Telephone = Get-TelephoneFictif -Type "fixe"
        TelephoneMobile = Get-TelephoneFictif -Type "mobile"
        Adresse1 = $ruesFictives[(Get-Random -Minimum 0 -Maximum $ruesFictives.Count)] + " " + (Get-Random -Minimum 1 -Maximum 100)
        Adresse2 = ""
        NPA = $npa
        Ville = $ville
        DateNaissance = Get-DateNaissanceFictive
        Langues = "Français"
        SituationPersonnelle = ""
        Formation = ""
        NotesGenerales = ""
        NotesInternes = ""
        Binome = ""
        Statut = $b.Statut
        DateEntree = $b.DateEntree
        Provenance = $b.Provenance
        ProvenanceDetail = ""
        DisponibilitesPreferees = ""
        CentresInteret = ""
        Competences = ""
        RecevoirInvitations = $b.RecevoirInvitations
        ParticiperEvenements = $b.ParticiperEvenements
        DateCreation = $b.DateCreation
        DateDerniereMajProfil = $b.DateDerniereMajProfil
        RGPDConsentement = "Oui"
        SourceID = $b.SourceID
    }
    
    $benevolesAnonymes += $bAnonyme
}

$benevolesAnonymes | Export-Csv "$OutputFolder\Benevoles.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "  OK - $($benevolesAnonymes.Count) benevoles anonymises" -ForegroundColor Green

# ============================================================================================================
# ANONYMISATION BENEFICIAIRES
# ============================================================================================================

Write-Host "2. Anonymisation Beneficiaires.csv..." -ForegroundColor Yellow

$beneficiaires = Import-Csv "$InputFolder\Beneficiaires.csv" -Encoding UTF8

$beneficiairesAnonymes = @()
$index = 0

foreach ($bf in $beneficiaires) {
    $index++
    
    $prenom = $prenomsFictifs[($index + 25) % $prenomsFictifs.Count]
    $nom = $nomsFictifs[($index + 25) % $nomsFictifs.Count]
    $npa = $npas[(Get-Random -Minimum 0 -Maximum $npas.Count)]
    $ville = $villesFictives[$npa]
    
    $bfAnonyme = [PSCustomObject]@{
        NumeroBeneficiaire = $bf.NumeroBeneficiaire
        Civilite = $bf.Civilite
        Nom = $nom
        Prenom = $prenom
        NomComplet = "$nom $prenom"
        Email = Get-EmailFictif -Nom $nom -Prenom $prenom -Index $index
        Telephone = Get-TelephoneFictif -Type "fixe"
        Adresse1 = $ruesFictives[(Get-Random -Minimum 0 -Maximum $ruesFictives.Count)] + " " + (Get-Random -Minimum 1 -Maximum 100)
        Adresse2 = ""
        NPA = $npa
        Ville = $ville
        DateNaissance = Get-DateNaissanceFictive
        Besoins = ""
        Referent = ""
        Horaires = ""
        DateDebut = $bf.DateDebut
        Historique = ""
        Statut = $bf.Statut
        RGPDConsentement = "Oui"
        RGPDDateConsentement = $bf.RGPDDateConsentement
        SourceID = $bf.SourceID
    }
    
    $beneficiairesAnonymes += $bfAnonyme
}

$beneficiairesAnonymes | Export-Csv "$OutputFolder\Beneficiaires.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "  OK - $($beneficiairesAnonymes.Count) beneficiaires anonymises" -ForegroundColor Green

# ============================================================================================================
# COPIE MISSIONS (pas de données sensibles)
# ============================================================================================================

Write-Host "3. Copie Missions.csv..." -ForegroundColor Yellow

$missions = Import-Csv "$InputFolder\Missions.csv" -Encoding UTF8

# Anonymiser les lieux et descriptions
$missionsAnonymes = @()
foreach ($m in $missions) {
    $mAnonyme = [PSCustomObject]@{
        CodeMission = $m.CodeMission
        Titre = $m.Titre
        TypeMission = $m.TypeMission
        Description = ""
        Lieu = "Genève"
        Frequence = $m.Frequence
        DateDebut = $m.DateDebut
        DateFin = $m.DateFin
        HorairesDetail = ""
        StatutMission = $m.StatutMission
        Priorite = $m.Priorite
        NombreBenevoles = $m.NombreBenevoles
        CompetencesRequises = ""
        ResponsableMission = ""
        SourceCode = $m.SourceCode
    }
    $missionsAnonymes += $mAnonyme
}

$missionsAnonymes | Export-Csv "$OutputFolder\Missions.csv" -Encoding UTF8 -NoTypeInformation
Write-Host "  OK - $($missionsAnonymes.Count) missions copiees" -ForegroundColor Green

# ============================================================================================================
# COPIE AFFECTATIONS (IDs seulement)
# ============================================================================================================

Write-Host "4. Copie Affectations.csv..." -ForegroundColor Yellow

Copy-Item "$InputFolder\Affectations.csv" "$OutputFolder\Affectations.csv" -Force
$affectations = Import-Csv "$OutputFolder\Affectations.csv" -Encoding UTF8
Write-Host "  OK - $($affectations.Count) affectations copiees" -ForegroundColor Green

# ============================================================================================================
# COPIE PRESTATIONS (IDs seulement)
# ============================================================================================================

Write-Host "5. Copie Prestations.csv..." -ForegroundColor Yellow

Copy-Item "$InputFolder\Prestations.csv" "$OutputFolder\Prestations.csv" -Force
$prestations = Import-Csv "$OutputFolder\Prestations.csv" -Encoding UTF8
Write-Host "  OK - $($prestations.Count) prestations copiees" -ForegroundColor Green

# ============================================================================================================
# RAPPORT FINAL
# ============================================================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "ANONYMISATION TERMINEE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Fichiers anonymises:" -ForegroundColor White
Write-Host "  - Benevoles.csv: $($benevolesAnonymes.Count) enregistrements" -ForegroundColor Green
Write-Host "  - Beneficiaires.csv: $($beneficiairesAnonymes.Count) enregistrements" -ForegroundColor Green
Write-Host "  - Missions.csv: $($missionsAnonymes.Count) enregistrements" -ForegroundColor Green
Write-Host "  - Affectations.csv: $($affectations.Count) enregistrements" -ForegroundColor Green
Write-Host "  - Prestations.csv: $($prestations.Count) enregistrements" -ForegroundColor Green
Write-Host ""
Write-Host "Repertoire: $OutputFolder" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT:" -ForegroundColor Yellow
Write-Host "  - Toutes les donnees personnelles ont ete anonymisees" -ForegroundColor White
Write-Host "  - Les IDs et codes ont ete conserves pour la structure" -ForegroundColor White
Write-Host "  - Les fichiers sont prets pour partage ou tests" -ForegroundColor White
Write-Host ""

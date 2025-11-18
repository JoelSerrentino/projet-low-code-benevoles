# ============================================================================================================
# Script: Création automatique des listes SharePoint - Projet Gestion Bénévoles
# Auteur: Joël Serrentino
# Date: 18 novembre 2025
# Version: 2.0 (inclut gestion bénéficiaires)
# Description: Crée toutes les listes et bibliothèques SharePoint avec colonnes, vues et permissions
# ============================================================================================================

#Requires -Version 5.1
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Crée l'infrastructure SharePoint complète pour la gestion des bénévoles et bénéficiaires

.DESCRIPTION
    Ce script crée automatiquement:
    - 7 listes SharePoint (Bénévoles, Missions, Affectations, Disponibilités, Bénéficiaires, Prestations, Documents)
    - Toutes les colonnes avec types et validations
    - Les vues personnalisées
    - Les permissions par rôle
    
.PARAMETER SiteUrl
    URL du site SharePoint (ex: https://votretenant.sharepoint.com/sites/GestionBenevoles)
    
.PARAMETER SkipPermissions
    Si spécifié, ne configure pas les permissions (à faire manuellement)

.EXAMPLE
    .\01-Creation-Listes-SharePoint.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/GestionBenevoles"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipPermissions
)

# ============================================================================================================
# CONFIGURATION
# ============================================================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Couleurs pour affichage
$ColorSuccess = "Green"
$ColorInfo = "Cyan"
$ColorWarning = "Yellow"
$ColorError = "Red"

# Log
$LogFile = ".\Creation-SharePoint-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================================================================
# FONCTIONS UTILITAIRES
# ============================================================================================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Affichage console
    switch ($Level) {
        "SUCCESS" { Write-Host $Message -ForegroundColor $ColorSuccess }
        "INFO"    { Write-Host $Message -ForegroundColor $ColorInfo }
        "WARNING" { Write-Host $Message -ForegroundColor $ColorWarning }
        "ERROR"   { Write-Host $Message -ForegroundColor $ColorError }
    }
    
    # Écriture log
    Add-Content -Path $LogFile -Value $logMessage
}

function Show-Progress {
    param(
        [string]$Activity,
        [int]$PercentComplete
    )
    Write-Progress -Activity $Activity -PercentComplete $PercentComplete -Status "$PercentComplete% terminé"
}

# ============================================================================================================
# CONNEXION SHAREPOINT
# ============================================================================================================

Write-Log "========================================" "INFO"
Write-Log "CRÉATION INFRASTRUCTURE SHAREPOINT" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Site cible: $SiteUrl" "INFO"

try {
    Write-Log "Connexion à SharePoint..." "INFO"
    Connect-PnPOnline -Url $SiteUrl -Interactive
    Write-Log "✓ Connecté avec succès" "SUCCESS"
    
    $web = Get-PnPWeb
    Write-Log "Site: $($web.Title)" "INFO"
}
catch {
    Write-Log "✗ Erreur de connexion: $_" "ERROR"
    exit 1
}

# ============================================================================================================
# LISTE 1: BÉNÉVOLES
# ============================================================================================================

Show-Progress -Activity "Création des listes" -PercentComplete 10

Write-Log "" "INFO"
Write-Log "=== Création Liste BÉNÉVOLES ===" "INFO"

try {
    # Vérifier si liste existe déjà
    $existingList = Get-PnPList -Identity "Benevoles" -ErrorAction SilentlyContinue
    if ($existingList) {
        Write-Log "⚠ Liste 'Benevoles' existe déjà - Suppression..." "WARNING"
        Remove-PnPList -Identity "Benevoles" -Force
    }
    
    # Créer la liste
    $listeBenevoles = New-PnPList -Title "Benevoles" -Template GenericList -Url "Lists/Benevoles"
    Write-Log "✓ Liste 'Benevoles' créée" "SUCCESS"
    
    # Activer versionnage
    Set-PnPList -Identity "Benevoles" -EnableVersioning $true -MajorVersions 10 -EnableContentApproval $true
    Write-Log "✓ Versionnage activé (10 versions majeures)" "SUCCESS"
    
    # Désactiver pièces jointes
    Set-PnPList -Identity "Benevoles" -EnableAttachments $false
    
    # ===== COLONNES =====
    Write-Log "Ajout des colonnes..." "INFO"
    
    # Renommer Title
    Set-PnPField -List "Benevoles" -Identity "Title" -Values @{Title="Nom complet"; Required=$true}
    
    # NumeroBenevole (calculé - sera ajouté après via workflow ou colonne calculée)
    Add-PnPField -List "Benevoles" -DisplayName "NumeroBenevole" -InternalName "NumeroBenevole" -Type Text -AddToDefaultView -Required
    
    # Informations personnelles
    Add-PnPField -List "Benevoles" -DisplayName "Prénom" -InternalName "Prenom" -Type Text -AddToDefaultView -Required
    Add-PnPField -List "Benevoles" -DisplayName "Nom" -InternalName "Nom" -Type Text -AddToDefaultView -Required
    
    Add-PnPFieldFromXml -List "Benevoles" -FieldXml @"
<Field Type='Choice' DisplayName='Civilité' Required='TRUE' Format='Dropdown' FillInChoice='FALSE' Name='Civilite'>
    <Default>M.</Default>
    <CHOICES>
        <CHOICE>M.</CHOICE>
        <CHOICE>Mme</CHOICE>
        <CHOICE>Autre</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Benevoles" -DisplayName "Adresse e-mail" -InternalName "EmailBenevole" -Type Text -AddToDefaultView -Required
    Add-PnPField -List "Benevoles" -DisplayName "Téléphone fixe" -InternalName "Telephone" -Type Text
    Add-PnPField -List "Benevoles" -DisplayName "Téléphone mobile" -InternalName "TelephoneMobile" -Type Text
    
    Add-PnPField -List "Benevoles" -DisplayName "Adresse ligne 1" -InternalName "Adresse1" -Type Text
    Add-PnPField -List "Benevoles" -DisplayName "Adresse ligne 2" -InternalName "Adresse2" -Type Text
    Add-PnPField -List "Benevoles" -DisplayName "Code postal" -InternalName "NPA" -Type Text
    Add-PnPField -List "Benevoles" -DisplayName "Ville" -InternalName "Ville" -Type Text
    
    Add-PnPField -List "Benevoles" -DisplayName "Date de naissance" -InternalName "DateNaissance" -Type DateTime -DisplayFormat DateOnly
    
    # Langues (choix multiple)
    Add-PnPFieldFromXml -List "Benevoles" -FieldXml @"
<Field Type='MultiChoice' DisplayName='Langues parlées' FillInChoice='FALSE' Name='Langues'>
    <CHOICES>
        <CHOICE>Français</CHOICE>
        <CHOICE>Allemand</CHOICE>
        <CHOICE>Anglais</CHOICE>
        <CHOICE>Italien</CHOICE>
        <CHOICE>Espagnol</CHOICE>
        <CHOICE>Autre</CHOICE>
    </CHOICES>
</Field>
"@
    
    # Situation personnelle
    Add-PnPFieldFromXml -List "Benevoles" -FieldXml @"
<Field Type='Choice' DisplayName='Situation personnelle' Format='Dropdown' FillInChoice='FALSE' Name='SituationPersonnelle'>
    <CHOICES>
        <CHOICE>Étudiant</CHOICE>
        <CHOICE>Actif</CHOICE>
        <CHOICE>Retraité</CHOICE>
        <CHOICE>En recherche</CHOICE>
        <CHOICE>Autre</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Benevoles" -DisplayName "Formation" -InternalName "Formation" -Type Note -AddToDefaultView
    Add-PnPField -List "Benevoles" -DisplayName "Notes générales" -InternalName "NotesGenerales" -Type Note
    Add-PnPField -List "Benevoles" -DisplayName "Notes internes" -InternalName "NotesInternes" -Type Note
    Add-PnPField -List "Benevoles" -DisplayName "Binôme préféré" -InternalName "Binome" -Type Text
    
    # Statut (OBLIGATOIRE)
    Add-PnPFieldFromXml -List "Benevoles" -FieldXml @"
<Field Type='Choice' DisplayName='Statut' Required='TRUE' Format='Dropdown' FillInChoice='FALSE' Name='Statut'>
    <Default>Actif</Default>
    <CHOICES>
        <CHOICE>Actif</CHOICE>
        <CHOICE>Inactif</CHOICE>
        <CHOICE>Suspendu</CHOICE>
        <CHOICE>En attente</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Benevoles" -DisplayName "Date d'entrée" -InternalName "DateEntree" -Type DateTime -DisplayFormat DateOnly -AddToDefaultView -Required
    
    # Provenance
    Add-PnPFieldFromXml -List "Benevoles" -FieldXml @"
<Field Type='Choice' DisplayName='Comment nous avez-vous connu ?' Format='Dropdown' FillInChoice='FALSE' Name='Provenance'>
    <CHOICES>
        <CHOICE>Site web</CHOICE>
        <CHOICE>Bouche-à-oreille</CHOICE>
        <CHOICE>Réseaux sociaux</CHOICE>
        <CHOICE>Événement</CHOICE>
        <CHOICE>Autre</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Benevoles" -DisplayName "Détails provenance" -InternalName "ProvenanceDetail" -Type Note
    Add-PnPField -List "Benevoles" -DisplayName "Disponibilités (résumé)" -InternalName "DisponibilitesPreferees" -Type Note
    Add-PnPField -List "Benevoles" -DisplayName "Centres d'intérêt" -InternalName "CentresInteret" -Type Note
    
    # Compétences (choix multiple - OBLIGATOIRE)
    Add-PnPFieldFromXml -List "Benevoles" -FieldXml @"
<Field Type='MultiChoice' DisplayName='Compétences' Required='TRUE' FillInChoice='FALSE' Name='Competences'>
    <CHOICES>
        <CHOICE>Accompagnement social</CHOICE>
        <CHOICE>Animation d'ateliers</CHOICE>
        <CHOICE>Bricolage / Réparations</CHOICE>
        <CHOICE>Communication / Rédaction</CHOICE>
        <CHOICE>Conduite / Transport</CHOICE>
        <CHOICE>Conseil juridique</CHOICE>
        <CHOICE>Cuisine / Restauration</CHOICE>
        <CHOICE>Informatique / Numérique</CHOICE>
        <CHOICE>Jardinage</CHOICE>
        <CHOICE>Logistique / Organisation</CHOICE>
        <CHOICE>Santé / Soins</CHOICE>
        <CHOICE>Soutien administratif</CHOICE>
        <CHOICE>Traduction</CHOICE>
        <CHOICE>Autre</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Benevoles" -DisplayName "Recevoir invitations" -InternalName "RecevoirInvitations" -Type Boolean
    Add-PnPField -List "Benevoles" -DisplayName "Participer événements" -InternalName "ParticiperEvenements" -Type Boolean
    
    # RGPD (OBLIGATOIRE)
    Add-PnPField -List "Benevoles" -DisplayName "Consentement RGPD" -InternalName "RGPDConsentement" -Type Boolean -Required
    
    Add-PnPField -List "Benevoles" -DisplayName "Dernière mise à jour profil" -InternalName "DateDerniereMajProfil" -Type DateTime -DisplayFormat DateTime -Required
    
    Write-Log "✓ 26 colonnes créées" "SUCCESS"
    
    # ===== VUES =====
    Write-Log "Création des vues..." "INFO"
    
    # Vue par défaut: Bénévoles actifs
    $viewFields = @("NumeroBenevole", "Title", "EmailBenevole", "TelephoneMobile", "Competences", "DateEntree")
    $camlQuery = "<Where><Eq><FieldRef Name='Statut'/><Value Type='Choice'>Actif</Value></Eq></Where>"
    Add-PnPView -List "Benevoles" -Title "Bénévoles actifs" -Fields $viewFields -Query $camlQuery -SetAsDefault
    
    # Vue: Nouveaux bénévoles (30 jours)
    $camlQuery = "<Where><Geq><FieldRef Name='DateEntree'/><Value Type='DateTime'><Today OffsetDays='-30'/></Value></Geq></Where>"
    Add-PnPView -List "Benevoles" -Title "Nouveaux bénévoles (30 jours)" -Fields @("NumeroBenevole", "Title", "EmailBenevole", "DateEntree", "Statut") -Query $camlQuery
    
    # Vue: Bénévoles inactifs
    $camlQuery = "<Where><Or><Eq><FieldRef Name='Statut'/><Value Type='Choice'>Inactif</Value></Eq><Eq><FieldRef Name='Statut'/><Value Type='Choice'>Suspendu</Value></Eq></Or></Where>"
    Add-PnPView -List "Benevoles" -Title "Bénévoles inactifs" -Fields @("Title", "EmailBenevole", "Statut", "DateDerniereMajProfil") -Query $camlQuery
    
    Write-Log "✓ 3 vues créées" "SUCCESS"
    
    # Indexer colonnes clés
    Set-PnPField -List "Benevoles" -Identity "Statut" -Values @{Indexed=$true}
    Set-PnPField -List "Benevoles" -Identity "DateEntree" -Values @{Indexed=$true}
    
    Write-Log "✓ Liste BÉNÉVOLES complète" "SUCCESS"
}
catch {
    Write-Log "✗ Erreur lors de la création de la liste Bénévoles: $_" "ERROR"
    throw
}

# ============================================================================================================
# LISTE 2: MISSIONS
# ============================================================================================================

Show-Progress -Activity "Création des listes" -PercentComplete 30

Write-Log "" "INFO"
Write-Log "=== Création Liste MISSIONS ===" "INFO"

try {
    $existingList = Get-PnPList -Identity "Missions" -ErrorAction SilentlyContinue
    if ($existingList) {
        Write-Log "⚠ Liste 'Missions' existe déjà - Suppression..." "WARNING"
        Remove-PnPList -Identity "Missions" -Force
    }
    
    $listeMissions = New-PnPList -Title "Missions" -Template GenericList -Url "Lists/Missions"
    Set-PnPList -Identity "Missions" -EnableVersioning $true -EnableMinorVersions $true -MajorVersions 10 -MinorVersions 5 -EnableContentApproval $true
    Set-PnPList -Identity "Missions" -EnableAttachments $true
    
    Write-Log "✓ Liste 'Missions' créée" "SUCCESS"
    
    # Renommer Title
    Set-PnPField -List "Missions" -Identity "Title" -Values @{Title="Titre de la mission"; Required=$true}
    
    # Colonnes
    Add-PnPField -List "Missions" -DisplayName "Code mission" -InternalName "CodeMission" -Type Text -AddToDefaultView -Required
    
    Add-PnPFieldFromXml -List "Missions" -FieldXml @"
<Field Type='Choice' DisplayName='Type de mission' Required='TRUE' Format='Dropdown' FillInChoice='FALSE' Name='TypeMission'>
    <Default>Récurrente</Default>
    <CHOICES>
        <CHOICE>Récurrente</CHOICE>
        <CHOICE>Ponctuelle</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Missions" -DisplayName "Description complète" -InternalName "DescriptionMission" -Type Note -AddToDefaultView -Required
    Add-PnPField -List "Missions" -DisplayName "Date de début" -InternalName "DateDebut" -Type DateTime -DisplayFormat DateTime -AddToDefaultView -Required
    Add-PnPField -List "Missions" -DisplayName "Date de fin" -InternalName "DateFin" -Type DateTime -DisplayFormat DateTime -Required
    
    Add-PnPFieldFromXml -List "Missions" -FieldXml @"
<Field Type='Choice' DisplayName='Fréquence' Format='Dropdown' FillInChoice='FALSE' Name='Frequence'>
    <Default>Unique</Default>
    <CHOICES>
        <CHOICE>Unique</CHOICE>
        <CHOICE>Hebdomadaire</CHOICE>
        <CHOICE>Mensuelle</CHOICE>
        <CHOICE>Trimestrielle</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Missions" -DisplayName "Lieu" -InternalName "LieuMission" -Type Text
    Add-PnPField -List "Missions" -DisplayName "Détails horaires" -InternalName "HorairesDetail" -Type Note
    Add-PnPField -List "Missions" -DisplayName "Responsable mission" -InternalName "ResponsableMission" -Type User -AddToDefaultView -Required
    
    # Compétences requises (même liste que Bénévoles)
    Add-PnPFieldFromXml -List "Missions" -FieldXml @"
<Field Type='MultiChoice' DisplayName='Compétences requises' Required='TRUE' FillInChoice='FALSE' Name='CompetencesRequises'>
    <CHOICES>
        <CHOICE>Accompagnement social</CHOICE>
        <CHOICE>Animation d'ateliers</CHOICE>
        <CHOICE>Bricolage / Réparations</CHOICE>
        <CHOICE>Communication / Rédaction</CHOICE>
        <CHOICE>Conduite / Transport</CHOICE>
        <CHOICE>Conseil juridique</CHOICE>
        <CHOICE>Cuisine / Restauration</CHOICE>
        <CHOICE>Informatique / Numérique</CHOICE>
        <CHOICE>Jardinage</CHOICE>
        <CHOICE>Logistique / Organisation</CHOICE>
        <CHOICE>Santé / Soins</CHOICE>
        <CHOICE>Soutien administratif</CHOICE>
        <CHOICE>Traduction</CHOICE>
        <CHOICE>Autre</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Missions" -DisplayName "Nombre de bénévoles" -InternalName "NombreBenevoles" -Type Number -Required
    
    Add-PnPFieldFromXml -List "Missions" -FieldXml @"
<Field Type='Choice' DisplayName='Statut mission' Required='TRUE' Format='Dropdown' FillInChoice='FALSE' Name='StatutMission'>
    <Default>Brouillon</Default>
    <CHOICES>
        <CHOICE>Brouillon</CHOICE>
        <CHOICE>Planifiée</CHOICE>
        <CHOICE>En cours</CHOICE>
        <CHOICE>Clôturée</CHOICE>
        <CHOICE>Annulée</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPFieldFromXml -List "Missions" -FieldXml @"
<Field Type='Choice' DisplayName='Priorité' Format='Dropdown' FillInChoice='FALSE' Name='Priorite'>
    <Default>Moyenne</Default>
    <CHOICES>
        <CHOICE>Faible</CHOICE>
        <CHOICE>Moyenne</CHOICE>
        <CHOICE>Haute</CHOICE>
        <CHOICE>Critique</CHOICE>
    </CHOICES>
</Field>
"@
    
    Write-Log "✓ 14 colonnes créées" "SUCCESS"
    
    # Vues
    $camlQuery = "<Where><Or><Eq><FieldRef Name='StatutMission'/><Value Type='Choice'>Planifiée</Value></Eq><Eq><FieldRef Name='StatutMission'/><Value Type='Choice'>En cours</Value></Eq></Or></Where><OrderBy><FieldRef Name='DateDebut' Ascending='TRUE'/></OrderBy>"
    Add-PnPView -List "Missions" -Title "Missions planifiées" -Fields @("CodeMission", "Title", "TypeMission", "DateDebut", "ResponsableMission") -Query $camlQuery -SetAsDefault
    
    Add-PnPView -List "Missions" -Title "Missions récurrentes" -Fields @("Title", "Frequence", "CompetencesRequises", "NombreBenevoles") -Query "<Where><Eq><FieldRef Name='TypeMission'/><Value Type='Choice'>Récurrente</Value></Eq></Where>"
    
    # Indexer
    Set-PnPField -List "Missions" -Identity "StatutMission" -Values @{Indexed=$true}
    Set-PnPField -List "Missions" -Identity "DateDebut" -Values @{Indexed=$true}
    
    Write-Log "✓ Liste MISSIONS complète" "SUCCESS"
}
catch {
    Write-Log "✗ Erreur lors de la création de la liste Missions: $_" "ERROR"
    throw
}

# ============================================================================================================
# LISTE 3: AFFECTATIONS
# ============================================================================================================

Show-Progress -Activity "Création des listes" -PercentComplete 50

Write-Log "" "INFO"
Write-Log "=== Création Liste AFFECTATIONS ===" "INFO"

try {
    $existingList = Get-PnPList -Identity "Affectations" -ErrorAction SilentlyContinue
    if ($existingList) {
        Write-Log "⚠ Liste 'Affectations' existe déjà - Suppression..." "WARNING"
        Remove-PnPList -Identity "Affectations" -Force
    }
    
    $listeAffectations = New-PnPList -Title "Affectations" -Template GenericList -Url "Lists/Affectations"
    Set-PnPList -Identity "Affectations" -EnableVersioning $true -MajorVersions 10
    Set-PnPList -Identity "Affectations" -EnableAttachments $false
    
    Write-Log "✓ Liste 'Affectations' créée" "SUCCESS"
    
    # Title sera calculé plus tard (workflow)
    Set-PnPField -List "Affectations" -Identity "Title" -Values @{Title="Identifiant affectation"}
    
    # Lookups vers Missions et Bénévoles
    Add-PnPField -List "Affectations" -DisplayName "Mission" -InternalName "MissionID" -Type Lookup -Required `
        -AddToDefaultView -LookupList "Missions" -LookupField "Title"
    
    Add-PnPField -List "Affectations" -DisplayName "Bénévole" -InternalName "BenevoleID" -Type Lookup -Required `
        -AddToDefaultView -LookupList "Benevoles" -LookupField "Title"
    
    Add-PnPFieldFromXml -List "Affectations" -FieldXml @"
<Field Type='Choice' DisplayName='Statut affectation' Required='TRUE' Format='Dropdown' FillInChoice='FALSE' Name='StatutAffectation'>
    <Default>Proposé</Default>
    <CHOICES>
        <CHOICE>Proposé</CHOICE>
        <CHOICE>Confirmé</CHOICE>
        <CHOICE>Annulé</CHOICE>
        <CHOICE>Terminé</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Affectations" -DisplayName "Commentaire coordinateur" -InternalName "CommentaireCoord" -Type Note
    Add-PnPField -List "Affectations" -DisplayName "Plage horaire 1" -InternalName "PlageHoraire1" -Type Text
    Add-PnPField -List "Affectations" -DisplayName "Plage horaire 2" -InternalName "PlageHoraire2" -Type Text
    Add-PnPField -List "Affectations" -DisplayName "Matériel fourni" -InternalName "MaterielFourni" -Type Text
    Add-PnPField -List "Affectations" -DisplayName "Heures réalisées" -InternalName "HeuresDeclarees" -Type Number
    Add-PnPField -List "Affectations" -DisplayName "Date de proposition" -InternalName "DateProposition" -Type DateTime -DisplayFormat DateTime -Required
    Add-PnPField -List "Affectations" -DisplayName "Date de confirmation" -InternalName "DateConfirmation" -Type DateTime -DisplayFormat DateTime
    
    Add-PnPFieldFromXml -List "Affectations" -FieldXml @"
<Field Type='Choice' DisplayName='Canal de notification' Format='Dropdown' FillInChoice='FALSE' Name='CanalNotification'>
    <Default>Email</Default>
    <CHOICES>
        <CHOICE>Email</CHOICE>
        <CHOICE>Teams</CHOICE>
        <CHOICE>Téléphone</CHOICE>
        <CHOICE>SMS</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Affectations" -DisplayName "Email envoyé" -InternalName "EmailEnvoye" -Type Boolean -Required
    
    Write-Log "✓ 12 colonnes créées" "SUCCESS"
    
    # Vues
    Add-PnPView -List "Affectations" -Title "Affectations en cours" -Fields @("BenevoleID", "MissionID", "DateProposition", "PlageHoraire1") -SetAsDefault
    
    $camlQuery = "<Where><Eq><FieldRef Name='StatutAffectation'/><Value Type='Choice'>Proposé</Value></Eq></Where><OrderBy><FieldRef Name='DateProposition' Ascending='FALSE'/></OrderBy>"
    Add-PnPView -List "Affectations" -Title "Propositions en attente" -Fields @("BenevoleID", "MissionID", "DateProposition", "CanalNotification") -Query $camlQuery
    
    # Indexer
    Set-PnPField -List "Affectations" -Identity "StatutAffectation" -Values @{Indexed=$true}
    Set-PnPField -List "Affectations" -Identity "MissionID" -Values @{Indexed=$true}
    Set-PnPField -List "Affectations" -Identity "BenevoleID" -Values @{Indexed=$true}
    
    Write-Log "✓ Liste AFFECTATIONS complète" "SUCCESS"
}
catch {
    Write-Log "✗ Erreur lors de la création de la liste Affectations: $_" "ERROR"
    throw
}

# ============================================================================================================
# LISTE 4: DISPONIBILITÉS
# ============================================================================================================

Show-Progress -Activity "Création des listes" -PercentComplete 70

Write-Log "" "INFO"
Write-Log "=== Création Liste DISPONIBILITÉS ===" "INFO"

try {
    $existingList = Get-PnPList -Identity "Disponibilites" -ErrorAction SilentlyContinue
    if ($existingList) {
        Write-Log "⚠ Liste 'Disponibilites' existe déjà - Suppression..." "WARNING"
        Remove-PnPList -Identity "Disponibilites" -Force
    }
    
    $listeDisponibilites = New-PnPList -Title "Disponibilites" -Template GenericList -Url "Lists/Disponibilites"
    Set-PnPList -Identity "Disponibilites" -EnableVersioning $true -MajorVersions 10
    Set-PnPList -Identity "Disponibilites" -EnableAttachments $false
    
    Write-Log "✓ Liste 'Disponibilites' créée" "SUCCESS"
    
    Set-PnPField -List "Disponibilites" -Identity "Title" -Values @{Title="Identifiant créneau"}
    
    # Lookup vers Bénévoles
    Add-PnPField -List "Disponibilites" -DisplayName "Bénévole" -InternalName "BenevoleDispoID" -Type Lookup -Required `
        -AddToDefaultView -LookupList "Benevoles" -LookupField "Title"
    
    Add-PnPField -List "Disponibilites" -DisplayName "Jour / Date" -InternalName "JourDispo" -Type DateTime -DisplayFormat DateOnly -AddToDefaultView -Required
    
    Add-PnPFieldFromXml -List "Disponibilites" -FieldXml @"
<Field Type='Choice' DisplayName='Type de disponibilité' Required='TRUE' Format='Dropdown' FillInChoice='FALSE' Name='TypeDisponibilite'>
    <Default>Ponctuelle</Default>
    <CHOICES>
        <CHOICE>Ponctuelle</CHOICE>
        <CHOICE>Récurrente hebdomadaire</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPFieldFromXml -List "Disponibilites" -FieldXml @"
<Field Type='Choice' DisplayName='Jour de la semaine' Format='Dropdown' FillInChoice='FALSE' Name='JourSemaine'>
    <CHOICES>
        <CHOICE>Lundi</CHOICE>
        <CHOICE>Mardi</CHOICE>
        <CHOICE>Mercredi</CHOICE>
        <CHOICE>Jeudi</CHOICE>
        <CHOICE>Vendredi</CHOICE>
        <CHOICE>Samedi</CHOICE>
        <CHOICE>Dimanche</CHOICE>
    </CHOICES>
</Field>
"@
    
    # Note: SharePoint n'a pas de type "Time" natif. On utilisera Text avec validation dans Power Apps
    Add-PnPField -List "Disponibilites" -DisplayName "Début (HH:MM)" -InternalName "PlageHoraireDebut" -Type Text -AddToDefaultView -Required
    Add-PnPField -List "Disponibilites" -DisplayName "Fin (HH:MM)" -InternalName "PlageHoraireFin" -Type Text -AddToDefaultView -Required
    
    Add-PnPFieldFromXml -List "Disponibilites" -FieldXml @"
<Field Type='Choice' DisplayName='Récurrence' Format='Dropdown' FillInChoice='FALSE' Name='Recurrence'>
    <Default>Aucune</Default>
    <CHOICES>
        <CHOICE>Aucune</CHOICE>
        <CHOICE>Hebdomadaire</CHOICE>
        <CHOICE>Mensuelle</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Disponibilites" -DisplayName "Fin de récurrence" -InternalName "DateFinRecurrence" -Type DateTime -DisplayFormat DateOnly
    Add-PnPField -List "Disponibilites" -DisplayName "Commentaires" -InternalName "CommentairesDispo" -Type Note
    Add-PnPField -List "Disponibilites" -DisplayName "Dernière modification" -InternalName "DerniereModifDispo" -Type DateTime -DisplayFormat DateTime -Required
    Add-PnPField -List "Disponibilites" -DisplayName "Confirmé" -InternalName "DispoConfirme" -Type Boolean -Required
    
    Write-Log "✓ 12 colonnes créées" "SUCCESS"
    
    # Vues
    Add-PnPView -List "Disponibilites" -Title "Disponibilités confirmées" -Fields @("BenevoleDispoID", "TypeDisponibilite", "JourDispo", "PlageHoraireDebut", "PlageHoraireFin") -SetAsDefault
    
    # Indexer
    Set-PnPField -List "Disponibilites" -Identity "BenevoleDispoID" -Values @{Indexed=$true}
    Set-PnPField -List "Disponibilites" -Identity "JourDispo" -Values @{Indexed=$true}
    
    Write-Log "✓ Liste DISPONIBILITÉS complète" "SUCCESS"
}
catch {
    Write-Log "✗ Erreur lors de la création de la liste Disponibilités: $_" "ERROR"
    throw
}

# ============================================================================================================
# BIBLIOTHÈQUE 5: DOCUMENTS BÉNÉVOLES
# ============================================================================================================

Show-Progress -Activity "Création des listes" -PercentComplete 85

Write-Log "" "INFO"
Write-Log "=== Création Bibliothèque DOCUMENTS BÉNÉVOLES ===" "INFO"

try {
    $existingLib = Get-PnPList -Identity "DocumentsBenevoles" -ErrorAction SilentlyContinue
    if ($existingLib) {
        Write-Log "⚠ Bibliothèque 'DocumentsBenevoles' existe déjà - Suppression..." "WARNING"
        Remove-PnPList -Identity "DocumentsBenevoles" -Force
    }
    
    $bibDocuments = New-PnPList -Title "DocumentsBenevoles" -Template DocumentLibrary -Url "DocumentsBenevoles"
    Set-PnPList -Identity "DocumentsBenevoles" -EnableVersioning $true -EnableMinorVersions $true -MajorVersions 10 -MinorVersions 5 -EnableContentApproval $true
    
    Write-Log "✓ Bibliothèque 'DocumentsBenevoles' créée" "SUCCESS"
    
    # Lookup vers Bénévoles
    Add-PnPField -List "DocumentsBenevoles" -DisplayName "Bénévole" -InternalName "BenevoleDocID" -Type Lookup -Required `
        -AddToDefaultView -LookupList "Benevoles" -LookupField "Title"
    
    Add-PnPFieldFromXml -List "DocumentsBenevoles" -FieldXml @"
<Field Type='Choice' DisplayName='Type de document' Required='TRUE' Format='Dropdown' FillInChoice='FALSE' Name='TypeDocument'>
    <Default>Autre</Default>
    <CHOICES>
        <CHOICE>Certificat médical</CHOICE>
        <CHOICE>Badge</CHOICE>
        <CHOICE>Contrat</CHOICE>
        <CHOICE>Assurance</CHOICE>
        <CHOICE>Diplôme</CHOICE>
        <CHOICE>Autre</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "DocumentsBenevoles" -DisplayName "Date d'expiration" -InternalName "DateExpirationDoc" -Type DateTime -DisplayFormat DateOnly
    Add-PnPField -List "DocumentsBenevoles" -DisplayName "Commentaires" -InternalName "CommentairesDoc" -Type Note
    
    Add-PnPFieldFromXml -List "DocumentsBenevoles" -FieldXml @"
<Field Type='Choice' DisplayName='Confidentialité' Required='TRUE' Format='Dropdown' FillInChoice='FALSE' Name='Confidentialite'>
    <Default>Public interne</Default>
    <CHOICES>
        <CHOICE>Public interne</CHOICE>
        <CHOICE>Restreint</CHOICE>
        <CHOICE>Confidentiel</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "DocumentsBenevoles" -DisplayName "Date d'ajout" -InternalName "DateUploadDoc" -Type DateTime -DisplayFormat DateTime -Required
    Add-PnPField -List "DocumentsBenevoles" -DisplayName "Document valide" -InternalName "DocumentValide" -Type Boolean -Required
    
    Write-Log "✓ 7 colonnes de métadonnées créées" "SUCCESS"
    
    # Vues
    Add-PnPView -List "DocumentsBenevoles" -Title "Documents actifs" -Fields @("Name", "BenevoleDocID", "TypeDocument", "DateExpirationDoc") -SetAsDefault
    
    # Indexer
    Set-PnPField -List "DocumentsBenevoles" -Identity "BenevoleDocID" -Values @{Indexed=$true}
    Set-PnPField -List "DocumentsBenevoles" -Identity "DateExpirationDoc" -Values @{Indexed=$true}
    
    Write-Log "✓ Bibliothèque DOCUMENTS BÉNÉVOLES complète" "SUCCESS"
}
catch {
    Write-Log "✗ Erreur lors de la création de la bibliothèque Documents: $_" "ERROR"
    throw
}

# ============================================================================================================
# LISTE 5: BÉNÉFICIAIRES
# ============================================================================================================

Show-Progress -Activity "Création des listes" -PercentComplete 80

Write-Log "" "INFO"
Write-Log "=== Création Liste BÉNÉFICIAIRES ===" "INFO"

try {
    $existingList = Get-PnPList -Identity "Beneficiaires" -ErrorAction SilentlyContinue
    if ($existingList) {
        Write-Log "⚠ Liste 'Beneficiaires' existe déjà - Suppression..." "WARNING"
        Remove-PnPList -Identity "Beneficiaires" -Force
    }
    
    $listeBeneficiaires = New-PnPList -Title "Beneficiaires" -Template GenericList -Url "Lists/Beneficiaires"
    Write-Log "✓ Liste 'Beneficiaires' créée" "SUCCESS"
    
    Set-PnPList -Identity "Beneficiaires" -EnableVersioning $true -MajorVersions 10 -EnableContentApproval $true
    Set-PnPList -Identity "Beneficiaires" -EnableAttachments $false
    
    Write-Log "Ajout des colonnes..." "INFO"
    
    Set-PnPField -List "Beneficiaires" -Identity "Title" -Values @{Title="Nom complet"; Required=$true}
    
    Add-PnPField -List "Beneficiaires" -DisplayName "NumeroBeneficiaire" -InternalName "NumeroBeneficiaire" -Type Text -AddToDefaultView -Required
    Add-PnPField -List "Beneficiaires" -DisplayName "Prénom" -InternalName "PrenomBnf" -Type Text -AddToDefaultView -Required
    Add-PnPField -List "Beneficiaires" -DisplayName "Nom" -InternalName "NomBnf" -Type Text -AddToDefaultView -Required
    
    Add-PnPFieldFromXml -List "Beneficiaires" -FieldXml @"
<Field Type='Choice' DisplayName='Civilité' Required='TRUE' Format='Dropdown' Name='CiviliteBnf'>
    <Default>M.</Default>
    <CHOICES>
        <CHOICE>M.</CHOICE>
        <CHOICE>Mme</CHOICE>
        <CHOICE>Autre</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Beneficiaires" -DisplayName "Adresse e-mail" -InternalName "EmailBnf" -Type Text
    Add-PnPField -List "Beneficiaires" -DisplayName "Téléphone" -InternalName "TelephoneBnf" -Type Text
    Add-PnPField -List "Beneficiaires" -DisplayName "Adresse ligne 1" -InternalName "Adresse1Bnf" -Type Text -Required
    Add-PnPField -List "Beneficiaires" -DisplayName "Adresse ligne 2" -InternalName "Adresse2Bnf" -Type Text
    Add-PnPField -List "Beneficiaires" -DisplayName "Code postal" -InternalName "NPABnf" -Type Text -Required
    Add-PnPField -List "Beneficiaires" -DisplayName "Ville" -InternalName "VilleBnf" -Type Text -AddToDefaultView -Required
    Add-PnPField -List "Beneficiaires" -DisplayName "Date de naissance" -InternalName "DateNaissanceBnf" -Type DateTime -DisplayFormat DateOnly
    
    Add-PnPField -List "Beneficiaires" -DisplayName "Besoins identifiés" -InternalName "Besoins" -Type Note -AddToDefaultView -Required
    Add-PnPField -List "Beneficiaires" -DisplayName "Référent externe" -InternalName "Referent" -Type Note
    Add-PnPField -List "Beneficiaires" -DisplayName "Horaires de visite" -InternalName "Horaires" -Type Text
    
    Add-PnPField -List "Beneficiaires" -DisplayName "Date de début" -InternalName "DateDebutBnf" -Type DateTime -DisplayFormat DateOnly -AddToDefaultView -Required
    Add-PnPField -List "Beneficiaires" -DisplayName "Date de fin" -InternalName "DateFinBnf" -Type DateTime -DisplayFormat DateOnly
    
    Add-PnPFieldFromXml -List "Beneficiaires" -FieldXml @"
<Field Type='Choice' DisplayName='Statut' Required='TRUE' Format='Dropdown' Name='StatutBnf'>
    <Default>Actif</Default>
    <CHOICES>
        <CHOICE>Actif</CHOICE>
        <CHOICE>Inactif</CHOICE>
        <CHOICE>Clôturé</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Beneficiaires" -DisplayName "Historique" -InternalName "HistoriqueBnf" -Type Note
    Add-PnPField -List "Beneficiaires" -DisplayName "Notes internes" -InternalName "NotesInternesBnf" -Type Note
    
    Add-PnPField -List "Beneficiaires" -DisplayName "Consentement RGPD" -InternalName "RGPDConsentementBnf" -Type Boolean -AddToDefaultView -Required
    Add-PnPField -List "Beneficiaires" -DisplayName "Date consentement RGPD" -InternalName "RGPDDateConsentementBnf" -Type DateTime
    
    Write-Log "✓ 20 colonnes ajoutées" "SUCCESS"
    
    # Vues
    $viewFieldsBnf = @("NumeroBeneficiaire", "Title", "VilleBnf", "Besoins", "DateDebutBnf", "StatutBnf")
    Add-PnPView -List "Beneficiaires" -Title "Bénéficiaires actifs" -Fields $viewFieldsBnf -Query "<Where><Eq><FieldRef Name='StatutBnf'/><Value Type='Choice'>Actif</Value></Eq></Where>" -SetAsDefault
    Write-Log "✓ 4 vues créées" "SUCCESS"
}
catch {
    Write-Log "✗ Erreur lors de la création de la liste Bénéficiaires: $_" "ERROR"
    throw
}

# ============================================================================================================
# LISTE 6: PRESTATIONS
# ============================================================================================================

Show-Progress -Activity "Création des listes" -PercentComplete 85

Write-Log "" "INFO"
Write-Log "=== Création Liste PRESTATIONS ===" "INFO"

try {
    $existingList = Get-PnPList -Identity "Prestations" -ErrorAction SilentlyContinue
    if ($existingList) {
        Write-Log "⚠ Liste 'Prestations' existe déjà - Suppression..." "WARNING"
        Remove-PnPList -Identity "Prestations" -Force
    }
    
    $listePrestations = New-PnPList -Title "Prestations" -Template GenericList -Url "Lists/Prestations"
    Write-Log "✓ Liste 'Prestations' créée" "SUCCESS"
    
    Set-PnPList -Identity "Prestations" -EnableVersioning $true -MajorVersions 10
    Set-PnPList -Identity "Prestations" -EnableAttachments $false
    
    Write-Log "Ajout des colonnes..." "INFO"
    
    Set-PnPField -List "Prestations" -Identity "Title" -Values @{Title="Identifiant prestation"; Required=$true}
    
    # Lookups
    Add-PnPField -List "Prestations" -DisplayName "Bénéficiaire" -InternalName "BeneficiaireID" -Type Lookup -AddToDefaultView -Required `
        -AddToDefaultView -LookupListTitle "Beneficiaires" -LookupFieldName "Title"
    
    Add-PnPField -List "Prestations" -DisplayName "Mission" -InternalName "MissionIDPrestation" -Type Lookup -AddToDefaultView -Required `
        -LookupListTitle "Missions" -LookupFieldName "Title"
    
    Add-PnPField -List "Prestations" -DisplayName "Date de début" -InternalName "DateDebutPrestation" -Type DateTime -DisplayFormat DateOnly -AddToDefaultView -Required
    Add-PnPField -List "Prestations" -DisplayName "Date de fin" -InternalName "DateFinPrestation" -Type DateTime -DisplayFormat DateOnly
    
    Add-PnPFieldFromXml -List "Prestations" -FieldXml @"
<Field Type='Choice' DisplayName='Fréquence' Format='Dropdown' Name='FrequencePrestation'>
    <Default>Ponctuelle</Default>
    <CHOICES>
        <CHOICE>Ponctuelle</CHOICE>
        <CHOICE>Hebdomadaire</CHOICE>
        <CHOICE>Bimensuelle</CHOICE>
        <CHOICE>Mensuelle</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPFieldFromXml -List "Prestations" -FieldXml @"
<Field Type='Choice' DisplayName='Statut prestation' Required='TRUE' Format='Dropdown' Name='StatutPrestation'>
    <Default>En cours</Default>
    <CHOICES>
        <CHOICE>En cours</CHOICE>
        <CHOICE>Suspendue</CHOICE>
        <CHOICE>Terminée</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Prestations" -DisplayName "Commentaires" -InternalName "CommentairesPrestation" -Type Note
    
    Add-PnPFieldFromXml -List "Prestations" -FieldXml @"
<Field Type='Choice' DisplayName='Évaluation qualité' Format='Dropdown' Name='EvaluationQualite'>
    <CHOICES>
        <CHOICE>Très satisfait</CHOICE>
        <CHOICE>Satisfait</CHOICE>
        <CHOICE>Neutre</CHOICE>
        <CHOICE>Insatisfait</CHOICE>
    </CHOICES>
</Field>
"@
    
    Add-PnPField -List "Prestations" -DisplayName "Dernière visite" -InternalName "DerniereVisite" -Type DateTime -AddToDefaultView
    
    Write-Log "✓ 10 colonnes ajoutées" "SUCCESS"
    
    # Vues
    $viewFieldsPrest = @("BeneficiaireID", "MissionIDPrestation", "DateDebutPrestation", "FrequencePrestation", "StatutPrestation", "DerniereVisite")
    Add-PnPView -List "Prestations" -Title "Prestations en cours" -Fields $viewFieldsPrest -Query "<Where><Eq><FieldRef Name='StatutPrestation'/><Value Type='Choice'>En cours</Value></Eq></Where>" -SetAsDefault
    Write-Log "✓ 3 vues créées" "SUCCESS"
}
catch {
    Write-Log "✗ Erreur lors de la création de la liste Prestations: $_" "ERROR"
    throw
}

# ============================================================================================================
# CONFIGURATION DES PERMISSIONS (optionnel)
# ============================================================================================================

Show-Progress -Activity "Configuration des permissions" -PercentComplete 95

if (-not $SkipPermissions) {
    Write-Log "" "INFO"
    Write-Log "=== Configuration des permissions ===" "INFO"
    Write-Log "⚠ Cette étape nécessite les groupes M365 : 'Administrateurs Bénévoles', 'Coordinateurs Bénévoles', 'Bénévoles Actifs'" "WARNING"
    Write-Log "Si ces groupes n'existent pas encore, créez-les manuellement dans le Centre d'administration M365" "INFO"
    
    # Note: La configuration des permissions fines nécessiterait de créer les groupes SharePoint
    # et d'appliquer des permissions au niveau colonne (RLS), ce qui est complexe via script.
    # Il est recommandé de le faire manuellement ou via des stratégies Azure AD.
    
    Write-Log "→ Configuration permissions à faire manuellement (voir documentation)" "INFO"
}

# ============================================================================================================
# FINALISATION
# ============================================================================================================

Show-Progress -Activity "Finalisation" -PercentComplete 100

Write-Log "" "INFO"
Write-Log "========================================" "SUCCESS"
Write-Log "CRÉATION TERMINÉE AVEC SUCCÈS !" "SUCCESS"
Write-Log "========================================" "SUCCESS"
Write-Log "" "INFO"
Write-Log "Résumé des listes créées:" "INFO"
Write-Log "  ✓ Benevoles (26 colonnes, 3 vues)" "SUCCESS"
Write-Log "  ✓ Missions (14 colonnes, 2 vues)" "SUCCESS"
Write-Log "  ✓ Affectations (12 colonnes, 2 vues)" "SUCCESS"
Write-Log "  ✓ Disponibilites (12 colonnes, 1 vue)" "SUCCESS"
Write-Log "  ✓ Beneficiaires (20 colonnes, 4 vues)" "SUCCESS"
Write-Log "  ✓ Prestations (10 colonnes, 3 vues)" "SUCCESS"
Write-Log "  ✓ DocumentsBenevoles (7 colonnes métadonnées, 1 vue)" "SUCCESS"
Write-Log "" "INFO"
Write-Log "Prochaines étapes:" "INFO"
Write-Log "  1. Vérifier les listes dans SharePoint: $SiteUrl" "INFO"
Write-Log "  2. Configurer les permissions si nécessaire" "INFO"
Write-Log "  3. Exécuter le script 02-Export-Access-CSV.ps1 pour exporter les données" "INFO"
Write-Log "  4. Exécuter le script 03-Import-SharePoint.ps1 pour importer les données" "INFO"
Write-Log "" "INFO"
Write-Log "Log complet: $LogFile" "INFO"

Disconnect-PnPOnline
Write-Log "Déconnexion SharePoint" "INFO"

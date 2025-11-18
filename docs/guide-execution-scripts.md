# 🚀 Guide d'exécution des scripts PowerShell

> Guide complet pour migrer automatiquement votre base Access vers SharePoint en 4 étapes

---

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [Installation PnP.PowerShell](#installation-pnppowershell)
3. [Préparation](#préparation)
4. [Exécution des scripts](#exécution-des-scripts)
5. [Dépannage](#dépannage)
6. [FAQ](#faq)

---

## ✅ Prérequis

### Configuration minimale

- **Windows 10/11** ou Windows Server 2016+
- **PowerShell 5.1** ou supérieur (vérifier : `$PSVersionTable.PSVersion`)
- **Microsoft Access** installé (version 2013+)
- **Connexion Internet** stable
- **Compte Microsoft 365** avec accès SharePoint

### Permissions requises

| Ressource | Permission minimale | Rôle |
|-----------|-------------------|------|
| **SharePoint Online** | Propriétaire du site | Créer listes, importer données |
| **Base Access** | Lecture | Exporter données |
| **Système de fichiers** | Lecture/Écriture | Dossier `D:\_Projets\bd_SAS-Benevolat` |

### Licences Microsoft 365

- ✅ SharePoint Online Plan 1 ou supérieur
- ✅ Power Apps inclus dans M365 ou licence dédiée
- ✅ Power Automate inclus dans M365

---

## 📦 Installation PnP.PowerShell

### Méthode 1 : Installation automatique (recommandée)

```powershell
# Ouvrir PowerShell en tant qu'administrateur
# Clic droit sur PowerShell → "Exécuter en tant qu'administrateur"

# Installer le module PnP.PowerShell
Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force

# Vérifier l'installation
Get-Module -Name PnP.PowerShell -ListAvailable
```

**Résultat attendu :**
```
    Directory: C:\Users\[Votre-Nom]\Documents\PowerShell\Modules

ModuleType Version    Name                     ExportedCommands
---------- -------    ----                     ----------------
Script     2.3.0      PnP.PowerShell           {Add-PnPAlert, Add-PnPApp...}
```

### Méthode 2 : Installation avec politique d'exécution

Si vous obtenez une erreur de politique d'exécution :

```powershell
# Autoriser l'exécution de scripts (temporaire)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Installer PnP.PowerShell
Install-Module -Name PnP.PowerShell -Scope CurrentUser

# Vérifier
Get-InstalledModule -Name PnP.PowerShell
```

### Résolution problème "Impossible de télécharger depuis PSGallery"

```powershell
# Enregistrer PSGallery comme source fiable
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

# Réessayer l'installation
Install-Module -Name PnP.PowerShell -Scope CurrentUser
```

---

## 🛠️ Préparation

### 1. Vérifier la base Access

```powershell
# Naviguer vers le dossier du projet
cd "D:\_Projets\bd_SAS-Benevolat"

# Vérifier que la base existe
Test-Path ".\SAS-Benevolat.accdb"
# Résultat attendu : True

# Vérifier la taille (doit être > 0)
(Get-Item ".\SAS-Benevolat.accdb").Length / 1MB
# Résultat attendu : ~3.85 MB
```

### 2. Créer le site SharePoint

1. **Se connecter à SharePoint Online** : https://[votre-tenant].sharepoint.com
2. **Créer un nouveau site** :
   - Cliquer sur **"Créer un site"**
   - Choisir **"Site d'équipe"**
   - Nom : `Gestion Bénévoles SAS`
   - Confidentialité : **Privé** (recommandé)
   - URL : `/sites/GestionBenevoles` ou `/sites/Benevoles`
3. **Noter l'URL complète** : `https://[votre-tenant].sharepoint.com/sites/GestionBenevoles`

### 3. Créer la structure de dossiers locale

```powershell
# Créer le dossier pour les CSV exportés
New-Item -ItemType Directory -Path "D:\_Projets\bd_SAS-Benevolat\Export-CSV" -Force

# Créer le dossier pour les logs
New-Item -ItemType Directory -Path "D:\_Projets\bd_SAS-Benevolat\Logs" -Force

# Vérifier
Get-ChildItem "D:\_Projets\bd_SAS-Benevolat"
```

---

## 🎯 Exécution des scripts

### SCRIPT 1 : Création des listes SharePoint

**Objectif :** Créer automatiquement les 5 listes SharePoint avec toutes les colonnes, vues et configurations.

#### Commande

```powershell
# Se placer dans le dossier scripts
cd "D:\_Projets\bd_SAS-Benevolat\scripts"

# Exécuter le script (remplacer [votre-tenant] par votre tenant M365)
.\01-Creation-Listes-SharePoint.ps1 -SiteUrl "https://[votre-tenant].sharepoint.com/sites/GestionBenevoles"
```

#### Exemple concret

```powershell
# Exemple avec tenant "contoso"
.\01-Creation-Listes-SharePoint.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/GestionBenevoles"
```

#### Que fait ce script ?

1. **Connexion SharePoint** (authentification interactive - fenêtre popup)
2. **Création Liste "Benevoles"** avec 26 colonnes :
   - Colonnes texte : NumeroBenevole, Nom, Prenom, Email, etc.
   - Colonnes choix : Civilite, Statut, Competences (multi-choix)
   - Colonnes date : DateNaissance, DateEntree
   - Colonnes booléen : RGPDConsentement
3. **Création Liste "Missions"** avec 14 colonnes
4. **Création Liste "Affectations"** avec 12 colonnes (+ lookups)
5. **Création Liste "Disponibilites"** avec 12 colonnes
6. **Création Bibliothèque "DocumentsBenevoles"** avec 7 colonnes métadonnées

#### Résultat attendu

```
========================================
CRÉATION DES LISTES SHAREPOINT
========================================
Site: https://contoso.sharepoint.com/sites/GestionBenevoles

Connexion à SharePoint...
✓ Connecté à SharePoint

=== Création Liste Bénévoles ===
  → Création de la liste...
  → Ajout des colonnes (26)...
  → Configuration des vues...
  → Indexation des colonnes...
✓ Liste Bénévoles créée avec succès (26 colonnes, 3 vues)

=== Création Liste Missions ===
  → Création de la liste...
  → Ajout des colonnes (14)...
✓ Liste Missions créée avec succès (14 colonnes, 2 vues)

[... autres listes ...]

========================================
CRÉATION TERMINÉE AVEC SUCCÈS !
========================================
```

#### Vérification

1. **Aller sur SharePoint** : https://[votre-tenant].sharepoint.com/sites/GestionBenevoles
2. **Cliquer sur "Contenu du site"**
3. **Vérifier la présence de 5 listes** :
   - ✅ Benevoles
   - ✅ Missions
   - ✅ Affectations
   - ✅ Disponibilites
   - ✅ DocumentsBenevoles

#### ⏱️ Durée estimée : 3-5 minutes

---

### SCRIPT 2 : Export Access vers CSV

**Objectif :** Extraire toutes les données Access et les transformer en fichiers CSV prêts pour SharePoint.

#### Commande

```powershell
# Depuis le dossier scripts
.\02-Export-Access-CSV.ps1

# OU avec paramètres personnalisés
.\02-Export-Access-CSV.ps1 `
    -AccessDbPath "D:\_Projets\bd_SAS-Benevolat\SAS-Benevolat.accdb" `
    -OutputFolder "D:\_Projets\bd_SAS-Benevolat\Export-CSV"
```

#### Que fait ce script ?

1. **Ouvre la base Access** en mode lecture seule
2. **Fusionne PERSONNE + BENEVOLE** :
   - Requête SQL avec jointure
   - Ajout colonnes RGPD et NumeroBenevole auto-généré
   - Export → `Benevoles.csv`
3. **Fusionne ACTIVITE + EVENEMENT** :
   - Activités récurrentes + Événements ponctuels
   - Ajout CodeMission unique
   - Export → `Missions.csv`
4. **Fusionne PARTICIPANT + DONNER** :
   - Toutes les affectations bénévoles/missions
   - Export → `Affectations.csv`
5. **Export LOCALITE** → `Localites.csv` (référence)
6. **Post-traitement** :
   - Nettoyage des données
   - Normalisation des booléens
   - Enrichissement automatique

#### Résultat attendu

```
========================================
EXPORT DONNÉES ACCESS → CSV
========================================
Base Access: D:\_Projets\bd_SAS-Benevolat\SAS-Benevolat.accdb
Sortie: D:\_Projets\bd_SAS-Benevolat\Export-CSV

Connexion à la base Access...
✓ Base Access ouverte

=== Export BÉNÉVOLES ===
  → Export de 'Benevoles'...
    ✓ 215 enregistrements exportés

=== Export MISSIONS ===
  → Export de 'Activites'...
  → Export de 'Evenements'...
  → Fusion Activités + Événements...
    ✓ 87 missions fusionnées

=== Export AFFECTATIONS ===
  → Export de 'Participant'...
  → Export de 'Donner'...
  → Fusion Participant + Donner...
    ✓ 1042 affectations fusionnées

=== Export LOCALITÉS (référence) ===
  → Export de 'Localites'...
    ✓ 342 enregistrements exportés

✓ Base Access fermée

=== Post-traitement des données ===
  → Nettoyage fichier Bénévoles...
    ✓ Bénévoles enrichis et nettoyés
  → Nettoyage fichier Missions...
    ✓ Missions enrichies et nettoyées

========================================
EXPORT TERMINÉ AVEC SUCCÈS !
========================================

Fichiers CSV créés:
  ✓ Benevoles.csv         (215 bénévoles)
  ✓ Missions.csv          (87 missions)
  ✓ Affectations.csv      (1042 affectations)
  ✓ Localites.csv         (table de référence)

Dossier de sortie: D:\_Projets\bd_SAS-Benevolat\Export-CSV
```

#### Vérification

```powershell
# Lister les fichiers CSV créés
Get-ChildItem "D:\_Projets\bd_SAS-Benevolat\Export-CSV\*.csv"

# Compter les lignes d'un fichier (exemple Bénévoles)
(Import-Csv "D:\_Projets\bd_SAS-Benevolat\Export-CSV\Benevoles.csv").Count

# Ouvrir dans Excel pour inspection visuelle
Invoke-Item "D:\_Projets\bd_SAS-Benevolat\Export-CSV\Benevoles.csv"
```

#### ⏱️ Durée estimée : 2-3 minutes

#### ⚠️ Actions manuelles requises

Avant de passer au script 3, **vérifier et compléter** :

1. **Ouvrir `Missions.csv`** dans Excel
2. **Compléter la colonne `ResponsableMission`** (si vide)
3. **Compléter la colonne `CompetencesRequises`** pour chaque mission
4. **Vérifier les dates** (format `yyyy-MM-dd`)
5. **Enregistrer** les modifications

---

### SCRIPT 3 : Import CSV vers SharePoint

**Objectif :** Importer massivement les données CSV dans les listes SharePoint avec gestion intelligente des lookups.

#### Commande

```powershell
# Import standard
.\03-Import-SharePoint.ps1 -SiteUrl "https://[votre-tenant].sharepoint.com/sites/GestionBenevoles"

# Import avec paramètres personnalisés
.\03-Import-SharePoint.ps1 `
    -SiteUrl "https://contoso.sharepoint.com/sites/GestionBenevoles" `
    -CsvFolder "D:\_Projets\bd_SAS-Benevolat\Export-CSV" `
    -BatchSize 50
```

#### Paramètres disponibles

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `-SiteUrl` | URL du site SharePoint | *(obligatoire)* |
| `-CsvFolder` | Dossier contenant les CSV | `D:\_Projets\bd_SAS-Benevolat\Export-CSV` |
| `-BatchSize` | Taille des lots (performance) | `100` |

#### Que fait ce script ?

1. **Connexion SharePoint** (authentification interactive)
2. **Vérification prérequis** :
   - Listes SharePoint existent ?
   - Fichiers CSV présents ?
3. **Import Bénévoles** (par lots de 100) :
   - Lecture `Benevoles.csv`
   - Création items SharePoint
   - **Mapping PERSONNE_ID → SharePoint ID** (stocké en mémoire)
4. **Import Missions** :
   - Lecture `Missions.csv`
   - **Mapping CodeSource → SharePoint ID**
5. **Import Affectations** :
   - Utilisation des mappings précédents
   - Création **lookups** automatiques (BenevoleID, MissionID)
6. **Génération log détaillé** avec timestamp

#### Résultat attendu

```
========================================
IMPORT CSV → SHAREPOINT
========================================
Site SharePoint: https://contoso.sharepoint.com/sites/GestionBenevoles
Dossier CSV: D:\_Projets\bd_SAS-Benevolat\Export-CSV
Taille des lots: 100
Fichier de log: D:\_Projets\bd_SAS-Benevolat\Export-CSV\Import-SharePoint-20251118-143022.log

Connexion à SharePoint...
✓ Connexion réussie

Vérification des listes SharePoint...
  ✓ Liste 'Benevoles' trouvée
  ✓ Liste 'Missions' trouvée
  ✓ Liste 'Affectations' trouvée
  ✓ Liste 'Disponibilites' trouvée

Vérification des fichiers CSV...
  ✓ Benevoles.csv trouvé (215 enregistrements)
  ✓ Missions.csv trouvé (87 enregistrements)
  ✓ Affectations.csv trouvé (1042 enregistrements)

=== IMPORT BÉNÉVOLES ===
Import de 215 bénévoles par lots de 100...
[████████████████████████████████] 100%
✓ Bénévoles importés: 215/215 (échecs: 0)

=== IMPORT MISSIONS ===
Import de 87 missions par lots de 100...
[████████████████████████████████] 100%
✓ Missions importées: 87/87 (échecs: 0)

=== IMPORT AFFECTATIONS ===
Import de 1042 affectations par lots de 100...
[████████████████████████████████] 100%
✓ Affectations importées: 1038/1042 (échecs: 4)

========================================
IMPORT TERMINÉ !
========================================

RÉSUMÉ:
  Bénévoles:    215/215 importés (échecs: 0)
  Missions:     87/87 importées (échecs: 0)
  Affectations: 1038/1042 importées (échecs: 4)

Fichier de log: D:\_Projets\bd_SAS-Benevolat\Export-CSV\Import-SharePoint-20251118-143022.log

⚠ ATTENTION: Certains enregistrements n'ont pas été importés.
  Consultez le fichier de log pour plus de détails.

Prochaine étape:
  → Exécuter le script 04-Verification-Migration.ps1 pour valider la migration
  → Accéder à votre site SharePoint: https://contoso.sharepoint.com/sites/GestionBenevoles
```

#### Vérification rapide

```powershell
# Compter les items importés dans SharePoint
Connect-PnPOnline -Url "https://[votre-tenant].sharepoint.com/sites/GestionBenevoles" -Interactive

(Get-PnPList -Identity "Benevoles").ItemCount
(Get-PnPList -Identity "Missions").ItemCount
(Get-PnPList -Identity "Affectations").ItemCount
```

#### ⏱️ Durée estimée : 5-10 minutes (selon volume)

---

### SCRIPT 4 : Vérification de la migration

**Objectif :** Générer un rapport HTML complet comparant Access vs SharePoint et détectant les problèmes de qualité.

#### Commande

```powershell
.\04-Verification-Migration.ps1 `
    -AccessDbPath "D:\_Projets\bd_SAS-Benevolat\SAS-Benevolat.accdb" `
    -SiteUrl "https://[votre-tenant].sharepoint.com/sites/GestionBenevoles"

# Avec chemin rapport personnalisé
.\04-Verification-Migration.ps1 `
    -AccessDbPath "D:\_Projets\bd_SAS-Benevolat\SAS-Benevolat.accdb" `
    -SiteUrl "https://contoso.sharepoint.com/sites/GestionBenevoles" `
    -ReportPath "D:\_Projets\bd_SAS-Benevolat\Rapport-Final.html"
```

#### Que fait ce script ?

1. **Connexion simultanée** Access + SharePoint
2. **Vérification 1 : Comptage** :
   - Bénévoles : Access vs SharePoint
   - Missions : (Activités + Événements) vs SharePoint
   - Affectations : (Participant + Donner) vs SharePoint
3. **Vérification 2 : Intégrité lookups** :
   - Affectations sans bénévole ?
   - Affectations sans mission ?
4. **Vérification 3 : Qualité données** :
   - Bénévoles sans email
   - Bénévoles sans consentement RGPD
   - Missions sans responsable
5. **Vérification 4 : Doublons** :
   - Emails en doublon
6. **Génération rapport HTML** interactif
7. **Ouverture automatique** dans navigateur

#### Résultat attendu

```
========================================
VÉRIFICATION MIGRATION
========================================
Base Access: D:\_Projets\bd_SAS-Benevolat\SAS-Benevolat.accdb
Site SharePoint: https://contoso.sharepoint.com/sites/GestionBenevoles
Rapport: D:\_Projets\bd_SAS-Benevolat\Rapport-Verification-20251118-145533.html

Connexion à Access...
✓ Base Access ouverte
Connexion à SharePoint...
✓ Connexion SharePoint réussie

=== VÉRIFICATION 1: Comptage des enregistrements ===

Bénévoles:
  Access:     215 bénévoles
  SharePoint: 215 bénévoles
  Différence: 0 | ✓ OK

Missions:
  Access:     45 activités + 42 événements = 87 missions
  SharePoint: 87 missions
  Différence: 0 | ✓ OK

Affectations:
  Access:     678 participants + 364 donner = 1042 affectations
  SharePoint: 1038 affectations
  Différence: -4 | ✗ MANQUE

=== VÉRIFICATION 2: Intégrité des lookups ===

Vérification des références Affectations...
  Affectations sans bénévole: 0
  Affectations sans mission: 0

=== VÉRIFICATION 3: Qualité des données ===

Analyse des bénévoles...
  Bénévoles sans email: 3
  Bénévoles sans téléphone: 12
  Bénévoles sans consentement RGPD: 8

Analyse des missions...
  Missions sans responsable: 15
  Missions sans date de début: 2

=== VÉRIFICATION 4: Détection de doublons ===

Recherche de doublons dans Bénévoles...
  ✓ Aucun doublon d'email

Génération du rapport HTML...
✓ Rapport HTML généré: D:\_Projets\bd_SAS-Benevolat\Rapport-Verification-20251118-145533.html

========================================
VÉRIFICATION TERMINÉE
========================================

⚠ MIGRATION RÉUSSIE AVEC AVERTISSEMENTS
  28 problème(s) mineur(s) détecté(s).

Rapport détaillé: D:\_Projets\bd_SAS-Benevolat\Rapport-Verification-20251118-145533.html
Ouvrez ce fichier dans un navigateur pour voir tous les détails.
```

#### Rapport HTML généré

Le rapport HTML s'ouvre automatiquement et contient :

- 📊 **Tableau comparatif** Access vs SharePoint
- 🔗 **Statut des lookups** (références intactes)
- ✅ **Indicateurs de qualité** (emails, RGPD, etc.)
- ⚠️ **Liste détaillée des problèmes** (avec ID des items concernés)
- 🎨 **Design moderne** avec couleurs et icônes

#### ⏱️ Durée estimée : 3-5 minutes

---

## 🔧 Dépannage

### Problème 1 : "Le module PnP.PowerShell n'est pas installé"

**Erreur :**
```
The term 'Connect-PnPOnline' is not recognized...
```

**Solution :**
```powershell
Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force
Import-Module PnP.PowerShell
```

---

### Problème 2 : "Impossible de se connecter à SharePoint"

**Erreur :**
```
AADSTS50076: Due to a configuration change made by your administrator...
```

**Solutions :**

1. **Vérifier authentification multifacteur (MFA)** :
   - Si MFA activé → Utiliser `-Interactive` (popup de connexion)
   - Alternative : Créer une App Registration Azure AD

2. **Vérifier permissions** :
   ```powershell
   # Tester la connexion manuellement
   Connect-PnPOnline -Url "https://[tenant].sharepoint.com/sites/GestionBenevoles" -Interactive
   
   # Vérifier l'accès
   Get-PnPWeb
   ```

3. **Autoriser PnP.PowerShell dans Azure AD** :
   - Aller sur https://admin.microsoft.com
   - Azure AD → Applications d'entreprise
   - Chercher "PnP Management Shell"
   - Autoriser l'application

---

### Problème 3 : "Access Database Engine not found"

**Erreur :**
```
Impossible de créer l'objet COM Access.Application
```

**Solution :**
```powershell
# Vérifier si Access est installé
Test-Path "C:\Program Files\Microsoft Office\root\Office16\MSACCESS.EXE"

# Si False → Installer Microsoft Access ou Access Runtime
# Télécharger Access Runtime (gratuit) :
# https://www.microsoft.com/fr-fr/download/details.aspx?id=50040
```

---

### Problème 4 : "Le fichier CSV contient des caractères illisibles"

**Erreur :** Caractères accentués remplacés par �

**Solution :**
```powershell
# Le script exporte déjà en UTF-8, mais pour vérifier :
$content = Get-Content "D:\_Projets\bd_SAS-Benevolat\Export-CSV\Benevoles.csv" -Encoding UTF8
$content | Out-File "D:\_Projets\bd_SAS-Benevolat\Export-CSV\Benevoles-UTF8.csv" -Encoding UTF8
```

---

### Problème 5 : "Certaines affectations ne sont pas importées"

**Cause :** Lookups introuvables (bénévole ou mission n'existe pas)

**Solution :**
```powershell
# Consulter le fichier de log
Get-Content "D:\_Projets\bd_SAS-Benevolat\Export-CSV\Import-SharePoint-*.log" | Select-String "WARNING"

# Exemple de ligne problématique :
# [WARNING] Bénévole non trouvé pour PERSONNE_ID=999

# Action : Vérifier que tous les bénévoles ont bien été importés d'abord
```

---

### Problème 6 : "Script trop lent"

**Solutions d'optimisation :**

```powershell
# Réduire la taille des lots (moins de mémoire, plus lent)
.\03-Import-SharePoint.ps1 -SiteUrl "..." -BatchSize 50

# Augmenter la taille des lots (plus rapide, plus de mémoire)
.\03-Import-SharePoint.ps1 -SiteUrl "..." -BatchSize 200

# Désactiver la progression visuelle (gain ~10%)
$ProgressPreference = 'SilentlyContinue'
.\03-Import-SharePoint.ps1 -SiteUrl "..."
```

---

### Problème 7 : "Échec création colonne choix multiple"

**Erreur :**
```
Exception calling "Add" with "1" argument(s): "A duplicate field name "Competences" was found."
```

**Solution :**
```powershell
# La colonne existe déjà → Supprimer et recréer
Connect-PnPOnline -Url "https://[tenant].sharepoint.com/sites/GestionBenevoles" -Interactive

# Supprimer la liste problématique
Remove-PnPList -Identity "Benevoles" -Force

# Relancer le script 01
.\01-Creation-Listes-SharePoint.ps1 -SiteUrl "..."
```

---

## ❓ FAQ

### Q1 : Puis-je exécuter les scripts plusieurs fois ?

**R :** Oui, mais :
- **Script 01** : Échec si listes existent déjà → Supprimer d'abord les listes
- **Script 02** : Oui, écrase les CSV existants
- **Script 03** : **NON** → Créera des doublons. Supprimer les items SharePoint avant.
- **Script 04** : Oui, génère un nouveau rapport à chaque fois

---

### Q2 : Comment supprimer toutes les données SharePoint pour recommencer ?

```powershell
Connect-PnPOnline -Url "https://[tenant].sharepoint.com/sites/GestionBenevoles" -Interactive

# Supprimer toutes les listes
Remove-PnPList -Identity "Affectations" -Force
Remove-PnPList -Identity "Disponibilites" -Force
Remove-PnPList -Identity "Missions" -Force
Remove-PnPList -Identity "Benevoles" -Force
Remove-PnPList -Identity "DocumentsBenevoles" -Force

# Relancer script 01
```

---

### Q3 : Combien de temps prend la migration complète ?

| Script | Durée estimée | Dépend de |
|--------|---------------|-----------|
| 01 - Création listes | 3-5 min | Connexion réseau |
| 02 - Export Access | 2-3 min | Taille base Access |
| 03 - Import SharePoint | 5-10 min | Nombre d'enregistrements |
| 04 - Vérification | 3-5 min | Nombre d'enregistrements |
| **TOTAL** | **15-25 minutes** | - |

---

### Q4 : Les scripts peuvent-ils migrer les fichiers (documents) ?

**R :** Non, les scripts actuels ne migrent que les **métadonnées**. Pour les fichiers :

```powershell
# Migration manuelle recommandée
# 1. Créer un dossier temporaire
New-Item -ItemType Directory -Path "D:\_Projets\bd_SAS-Benevolat\Documents-Export"

# 2. Copier manuellement les fichiers attachés Access
# (Access stocke les pièces jointes différemment selon la version)

# 3. Uploader vers SharePoint via interface web ou script personnalisé
```

---

### Q5 : Comment gérer les erreurs d'import partiel ?

**R :** Le script 04 génère un rapport détaillé. Actions recommandées :

1. **Consulter le log d'import** :
   ```powershell
   notepad "D:\_Projets\bd_SAS-Benevolat\Export-CSV\Import-SharePoint-*.log"
   ```

2. **Identifier les enregistrements en échec**

3. **Corriger manuellement** dans SharePoint (pour quelques items) **OU** :
   - Corriger le CSV source
   - Supprimer les items SharePoint
   - Relancer l'import

---

### Q6 : Puis-je personnaliser les scripts ?

**R :** Oui ! Les scripts sont commentés et modulaires. Exemples de personnalisation :

```powershell
# Ajouter une colonne personnalisée dans script 01
Add-PnPField -List "Benevoles" -DisplayName "VilleDOrigine" -InternalName "VilleDOrigine" -Type Text

# Modifier la requête SQL dans script 02
$sqlBenevoles = @"
SELECT 
    P.PERSONNE_ID,
    P.NOM,
    [Votre_Colonne_Custom]
FROM PERSONNE AS P
"@

# Ajuster la taille des lots dans script 03
$BatchSize = 50  # Au lieu de 100
```

---

### Q7 : Les scripts fonctionnent-ils avec SharePoint On-Premises ?

**R :** **Non**, les scripts utilisent `PnP.PowerShell` qui cible **SharePoint Online uniquement**.

Pour SharePoint On-Premises, utilisez :
```powershell
# SharePoint Server 2016/2019/SE
Install-Module -Name SharePointPnPPowerShellOnline  # Version legacy
# OU
# Adapter les scripts pour utiliser CSOM (.NET)
```

---

### Q8 : Comment planifier une exécution automatique ?

**R :** Utiliser le Planificateur de tâches Windows :

```powershell
# Créer une tâche planifiée (exemple : tous les lundis 8h)
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File D:\_Projets\bd_SAS-Benevolat\scripts\02-Export-Access-CSV.ps1"

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 8am

Register-ScheduledTask -TaskName "Export Access Benevoles" `
    -Action $action -Trigger $trigger
```

⚠️ **Attention** : L'authentification SharePoint Interactive ne fonctionne pas en mode non-interactif.  
→ Pour l'automatisation, configurer une **App Registration Azure AD** avec certificat.

---

## 📞 Support

Si vous rencontrez un problème non documenté :

1. **Consulter les logs** :
   ```powershell
   Get-ChildItem "D:\_Projets\bd_SAS-Benevolat\Export-CSV\*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content
   ```

2. **Vérifier les prérequis** (section en haut de ce guide)

3. **Contacter l'équipe projet** : Joël Serrentino

---

## 📚 Ressources supplémentaires

- [Documentation PnP.PowerShell](https://pnp.github.io/powershell/)
- [SharePoint REST API](https://learn.microsoft.com/en-us/sharepoint/dev/sp-add-ins/get-to-know-the-sharepoint-rest-service)
- [Power Apps Documentation](https://learn.microsoft.com/en-us/power-apps/)

---

**Dernière mise à jour :** 18 novembre 2025  
**Version :** 1.0  
**Auteur :** Joël Serrentino

# 🚀 Démarrage Rapide - Migration Access → SharePoint

**Date:** 7 décembre 2025  
**Statut environnement:** ✅ PRÊT

---

## ✅ Prérequis vérifiés

- ✅ **PowerShell 7.5.4** installé
- ✅ **Module PnP.PowerShell 3.1.0** installé
- ✅ **Base Access** présente: `SAS-Benevolat.accdb` (3.8 MB)
- ✅ **Scripts** disponibles dans `.\scripts\`

---

## 📋 Étapes d'exécution

### ÉTAPE 1: Créer le site SharePoint ⚠️ MANUEL

**Action requise:** Créer le site SharePoint avant d'exécuter les scripts.

1. **Ouvrir le Centre d'administration SharePoint**
   - URL: https://[votre-tenant]-admin.sharepoint.com
   - Ou via: https://admin.microsoft.com → Centres d'administration → SharePoint

2. **Créer un nouveau site**
   - Cliquer sur **"Sites actifs"** → **"+ Créer"**
   - Choisir: **"Site d'équipe"**
   
3. **Paramètres du site**
   - **Nom du site:** `Gestion Bénévoles SAS`
   - **Description:** `Application de gestion des bénévoles et bénéficiaires`
   - **Langue:** Français
   - **URL:** https://[votre-tenant].sharepoint.com/sites/GestionBenevoles
   - **Propriétaire:** Votre compte administrateur
   - **Confidentialité:** Privé (seulement les membres peuvent accéder)

4. **Finaliser**
   - Cliquer sur **"Terminer"**
   - Attendre 1-2 minutes pour la création

5. **Noter l'URL complète**
   - Exemple: `https://contoso.sharepoint.com/sites/GestionBenevoles`
   - Vous en aurez besoin pour les scripts

---

### ÉTAPE 2: Créer les listes SharePoint ⚡ AUTOMATIQUE

**Durée estimée:** 4-6 minutes

```powershell
# Se positionner dans le dossier scripts
cd "c:\Data local\2025 - projet-low-code-benevoles\projet-low-code-benevoles\scripts"

# Exécuter le script de création (REMPLACER [votre-tenant] par votre tenant réel)
.\01-Creation-Listes-SharePoint.ps1 -SiteUrl "https://[votre-tenant].sharepoint.com/sites/GestionBenevoles"
```

**Ce qui sera créé:**
- ✅ 7 listes SharePoint
  - Bénévoles (26 colonnes)
  - Missions (14 colonnes)
  - Affectations (12 colonnes)
  - Disponibilités (12 colonnes)
  - Bénéficiaires (20 colonnes)
  - Prestations (10 colonnes)
  - Documents Bénévoles (8 colonnes)
- ✅ Toutes les colonnes avec validations
- ✅ Vues personnalisées
- ✅ Configuration des permissions

**À la première exécution:**
- Une fenêtre de connexion Microsoft 365 s'ouvrira
- Connectez-vous avec votre compte administrateur
- Autorisez l'accès PnP.PowerShell

---

### ÉTAPE 3: Exporter les données Access ⚡ AUTOMATIQUE

**Durée estimée:** 2-3 minutes

```powershell
# Toujours dans le dossier scripts
.\02-Export-Access-CSV.ps1
```

**Ce qui sera généré:**
- ✅ Fichiers CSV dans `.\exports\`
  - Benevoles.csv
  - Missions.csv
  - Affectations.csv
  - Beneficiaires.csv
  - Prestations.csv

**Vérification rapide:**
```powershell
# Vérifier que les fichiers ont été créés
Get-ChildItem .\exports\*.csv | Select-Object Name, Length, LastWriteTime
```

---

### ÉTAPE 4: Importer les données dans SharePoint ⚡ AUTOMATIQUE

**Durée estimée:** 5-10 minutes (selon le volume)

```powershell
# Importer les données (REMPLACER [votre-tenant])
.\03-Import-SharePoint.ps1 -SiteUrl "https://[votre-tenant].sharepoint.com/sites/GestionBenevoles" -CSVFolder ".\exports"
```

**Ordre d'import (automatique):**
1. Bénévoles (entités principales)
2. Missions (activités)
3. Affectations (liens bénévoles ↔ missions)
4. Bénéficiaires (personnes aidées)
5. Prestations (services rendus)

---

### ÉTAPE 5: Vérifier la migration ⚡ AUTOMATIQUE

**Durée estimée:** 1-2 minutes

```powershell
# Générer un rapport de vérification (REMPLACER [votre-tenant])
.\04-Verification-Migration.ps1 -SiteUrl "https://[votre-tenant].sharepoint.com/sites/GestionBenevoles"
```

**Résultat:**
- ✅ Rapport HTML généré: `Rapport-Verification-Migration-[date].html`
- Ouvrir le fichier dans votre navigateur
- Vérifier:
  - Nombre d'enregistrements migrés
  - Intégrité des données
  - Anomalies éventuelles

---

## 🎯 Prochaines étapes après migration

Une fois la migration terminée avec succès:

1. **Construire l'application Power Apps**
   - Consulter: `docs\architecture-power-apps.md`
   - 11 écrans à créer
   
2. **Créer les workflows Power Automate**
   - Consulter: `docs\workflows-power-automate.md`
   - 7 flux automatisés

3. **Tests utilisateurs**
   - Valider avec les coordinateurs
   - Ajuster selon feedback

---

## ⚠️ Points d'attention

### Pendant l'exécution

- ✅ **Connexion Internet stable** requise
- ✅ **Ne pas fermer PowerShell** pendant l'exécution
- ✅ **Base Access fermée** (pas ouverte dans Microsoft Access)
- ✅ Les logs sont créés automatiquement dans `.\scripts\`

### En cas d'erreur

1. **Lire le message d'erreur** (souvent explicite)
2. **Consulter le fichier log** dans `.\scripts\`
3. **Vérifier les permissions** SharePoint
4. **Consulter**: `docs\guide-execution-scripts.md` (section Dépannage)

### Sauvegarde

```powershell
# Avant de commencer, faire une copie de la base Access
Copy-Item ".\SAS-Benevolat.accdb" ".\SAS-Benevolat.BACKUP.accdb"
```

---

## 📞 Support

**Documentation complète:**
- Guide détaillé: `docs\guide-execution-scripts.md`
- Architecture: `docs\architecture-power-apps.md`
- Workflows: `docs\workflows-power-automate.md`

**En cas de blocage:**
1. Consulter la section FAQ du guide d'exécution
2. Vérifier les logs générés
3. Relancer le script après correction

---

## ✅ Checklist avant de commencer

- [x] Site SharePoint créé ✅ FAIT (7 déc 2025)
- [x] URL du site notée: https://serrentino.sharepoint.com/sites/GestionBenevoles
- [x] Compte administrateur prêt
- [x] Sauvegarde de la base Access faite
- [x] PowerShell ouvert dans le bon dossier
- [x] Connexion Internet stable
- [x] **7 listes SharePoint créées avec succès** ✅

---

## 📊 État actuel (7 décembre 2025)

### ✅ PHASE 1 TERMINÉE - Infrastructure SharePoint

**Listes créées:**
1. ✅ Bénévoles (26 colonnes, 3 vues)
2. ✅ Missions (14 colonnes, 2 vues)
3. ✅ Affectations (12 colonnes, 2 vues)
4. ✅ Disponibilités (12 colonnes, 1 vue)
5. ✅ Documents Bénévoles (7 colonnes, 1 vue)
6. ✅ Bénéficiaires (20 colonnes, 4 vues)
7. ✅ Prestations (10 colonnes, 3 vues)

**Application Entra ID:**
- ID: `13c089c9-8dc9-43fb-8676-039c61c0dfac`
- Permissions: SharePoint configurées

**Logs:** `scripts/Creation-SharePoint-20251207-132313.log`

---

## 🚀 PROCHAINE ÉTAPE : Export des données

### ÉTAPE 2: Exporter les données Access ⚡ AUTOMATIQUE (À FAIRE)

**Durée estimée:** 2-3 minutes

```powershell
# Se positionner dans le dossier scripts
cd "c:\Data local\2025 - projet-low-code-benevoles\projet-low-code-benevoles\scripts"

# Exécuter le script d'export
.\02-Export-Access-CSV.ps1
```

**Ce qui sera généré:**
- ✅ Fichiers CSV dans `.\exports\`
  - Benevoles.csv
  - Missions.csv
  - Affectations.csv
  - Beneficiaires.csv
  - Prestations.csv

---

## ✅ Checklist avant de commencer (MISE À JOUR)

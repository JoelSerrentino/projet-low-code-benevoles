# Notes de migration - Ajout gestion des bénéficiaires

**Date:** 18 novembre 2025  
**Demande utilisateur:** Inclure la gestion des bénéficiaires dans Power Apps

---

## ✅ Modifications effectuées

### 1. Documentation SharePoint (`docs/specifications-sharepoint.md`)

**Ajout de 2 nouvelles listes:**

#### Liste 5: Bénéficiaires (20 colonnes)
- **NumeroBeneficiaire** (auto, format BNF-0001)
- **Informations personnelles:** Civilité, Nom, Prénom, DateNaissance
- **Coordonnées:** Adresse (2 lignes), NPA, Ville, Téléphone, Email
- **Besoins:** Besoins identifiés (multiligne), Référent externe, Horaires visite
- **Suivi:** DateDebut, DateFin, Statut (Actif/Inactif/Clôturé), Historique
- **Notes:** NotesInternes (réservé coordinateurs)
- **RGPD:** RGPDConsentement (obligatoire), RGPDDateConsentement

**4 vues créées:**
1. Bénéficiaires actifs (par défaut)
2. Nouveaux bénéficiaires (30 derniers jours)
3. Bénéficiaires clôturés
4. Conformité RGPD

#### Liste 6: Prestations (10 colonnes)
Représente la table RECEVOIR d'Access (bénéficiaires ↔ missions)

- **BeneficiaireID** (lookup vers Beneficiaires)
- **MissionID** (lookup vers Missions)
- **DateDebut, DateFin**
- **Frequence:** Ponctuelle/Hebdomadaire/Bimensuelle/Mensuelle
- **StatutPrestation:** En cours/Suspendue/Terminée
- **Commentaires**
- **EvaluationQualite:** Très satisfait → Insatisfait
- **DerniereVisite** (date et heure)

**3 vues créées:**
1. Prestations en cours (par défaut)
2. Prestations par mission
3. Alertes inactivité (> 60 jours sans visite)

**Permissions:**
- Coordinateurs: Lire, Créer, Modifier
- Administrateurs: Contrôle total
- Bénévoles: **Aucun accès** (données sensibles)

---

### 2. Architecture Power Apps (`docs/architecture-power-apps.md`)

**Ajout de 3 nouveaux écrans:**

#### Écran 9: Liste des Bénéficiaires (`scr_ListeBeneficiaires`)
- Recherche par nom/ville
- Filtre par statut (Actif/Inactif/Clôturé)
- Galerie avec: Nom, Ville, Nombre de prestations actives
- Bouton création nouveau bénéficiaire

#### Écran 10: Fiche Bénéficiaire (`scr_FicheBeneficiaire`)
- Formulaire complet (identité, coordonnées, besoins, suivi)
- Validation RGPD obligatoire si statut = Actif
- Historique enrichi automatiquement
- Liste des prestations du bénéficiaire
- Boutons: Enregistrer, Annuler

#### Écran 11: Gestion des Prestations (`scr_GestionPrestations`)
- Sélection bénéficiaire + mission
- Création lien avec dates, fréquence, commentaires
- Galerie prestations actives
- Badge alerte si inactivité > 60 jours

**Mise à jour dashboard (Écran 1):**
- Ajout KPI 5: Nombre de bénéficiaires actifs

**Sources de données mises à jour:**
- Ajout: `Beneficiaires`, `Prestations` (en plus des 5 existantes)

---

### 3. Script PowerShell 01 (`scripts/01-Creation-Listes-SharePoint.ps1`)

**Modifications:**
- Version: 1.0 → 2.0
- Description mise à jour: "7 listes" au lieu de "5 listes"
- Ajout section création liste Bénéficiaires (après Documents)
- Ajout section création liste Prestations (après Bénéficiaires)
- Résumé final mis à jour avec les 2 nouvelles listes

**Code ajouté:**
```powershell
# LISTE 5: BÉNÉFICIAIRES (20 colonnes, 4 vues)
# LISTE 6: PRESTATIONS (10 colonnes, 3 vues)
```

---

### 4. Scripts à modifier (pour migration complète)

#### `scripts/02-Export-Access-CSV.ps1`
**À ajouter:**
- Export table BENEFICIAIRE
- Export table RECEVOIR
- Fusion PERSONNE + BENEFICIAIRE → Beneficiaires.csv
- Export RECEVOIR → Prestations.csv

**Transformations:**
```powershell
# Beneficiaires.csv
PERSONNE.PERSONNE_ID, CIVILITE, NOM, PRENOM, ADRESSE1, NPA, VILLE, TELEPHONE, EMAIL, 
BENEFICIAIRE.BNF_BESOINS, BNF_REFERENT, BNF_HORAIRES, BNF_DATEDEBUT, Historique

# Prestations.csv
RECEVOIR.BENEFICIAIRE_ID, ACTIVITE_ID, DateDebut (auto), StatutPrestation = "En cours"
```

#### `scripts/03-Import-SharePoint.ps1`
**À ajouter:**
- Import Beneficiaires.csv → liste Beneficiaires
  - Auto-génération NumeroBeneficiaire (BNF-0001, BNF-0002...)
  - Initialiser RGPDConsentement = Oui par défaut
  - Title = Civilité + Nom + Prénom

- Import Prestations.csv → liste Prestations
  - Résolution lookup BeneficiaireID (PERSONNE_ID Access → ID SharePoint)
  - Résolution lookup MissionID (ACTIVITE_ID Access → ID SharePoint)
  - Initialiser DerniereVisite = DateDebut
  - Title calculé = MissionID + "-" + BeneficiaireID

#### `scripts/04-Verification-Migration.ps1`
**À ajouter:**
- Vérification comptage:
  - Access BENEFICIAIRE vs SharePoint Beneficiaires
  - Access RECEVOIR vs SharePoint Prestations
  
- Vérifications intégrité:
  - Tous les lookups Prestations.BeneficiaireID résolus
  - Tous les lookups Prestations.MissionID résolus
  - RGPD: Bénéficiaires actifs avec consentement

- Rapport HTML:
  - Section Bénéficiaires (comptage, qualité données)
  - Section Prestations (lookups, dernières visites)

---

## 📊 Mapping Access → SharePoint (complet)

| Table Access | Colonnes clés | → | Liste SharePoint | Notes |
|---|---|---|---|---|
| PERSONNE + BENEFICIAIRE | PERSONNE_ID, NOM, PRENOM, ADRESSE, TELEPHONE, BNF_BESOINS | → | **Beneficiaires** (20 cols) | Fusion 2 tables |
| RECEVOIR | BENEFICIAIRE_ID, ACTIVITE_ID | → | **Prestations** (10 cols) | Relation many-to-many |
| PERSONNE + BENEVOLE | (existant) | → | Benevoles | Déjà migré |
| ACTIVITE + EVENEMENT | (existant) | → | Missions | Déjà migré |
| PARTICIPANT + DONNER | (existant) | → | Affectations | Déjà migré |
| *(nouveau)* | - | → | Disponibilites | Nouveau |
| *(nouveau)* | - | → | DocumentsBenevoles | Nouveau |

**Total: 7 listes SharePoint** (au lieu de 5)

---

## 🎯 Prochaines étapes recommandées

### Court terme (pour scripts)
1. **Modifier 02-Export-Access-CSV.ps1**
   - Ajouter export BENEFICIAIRE + RECEVOIR
   - Créer Beneficiaires.csv et Prestations.csv
   
2. **Modifier 03-Import-SharePoint.ps1**
   - Importer les 2 nouveaux CSV
   - Gérer lookups Prestations

3. **Modifier 04-Verification-Migration.ps1**
   - Vérifier comptages et intégrité
   - Mettre à jour rapport HTML

### Moyen terme (pour Power Apps)
4. **Créer les 3 écrans dans Power Apps Studio**
   - scr_ListeBeneficiaires
   - scr_FicheBeneficiaire
   - scr_GestionPrestations

5. **Ajouter au menu navigation**
   - Icône "Bénéficiaires" dans menu latéral
   - Badge si bénéficiaires sans consentement RGPD

6. **Créer Power Automate flows**
   - Alerte si prestation inactive > 60 jours
   - Enrichissement automatique Historique
   - Notification nouveaux bénéficiaires

---

## ⚠️ Points d'attention

### Sécurité
- **Données sensibles:** Les bénéficiaires n'ont PAS accès à l'application
- Seuls les coordinateurs et administrateurs voient les bénéficiaires
- Masquer NotesInternes pour coordinateurs (réservé admins)

### RGPD
- Consentement obligatoire pour statut = Actif
- Même règles de rétention que bénévoles (3 ans après clôture)
- Workflow suppression automatique après 3 ans

### Performance
- Indexer: NumeroBeneficiaire, StatutBnf, VilleBnf
- Indexer: BeneficiaireID et MissionID dans Prestations
- Limiter affichage à 100 bénéficiaires par défaut

### Migration
- Environ **80 bénéficiaires** dans Access (estim.)
- Environ **150 prestations** dans RECEVOIR (estim.)
- Durée ajout: +2-3 minutes aux scripts

---

## 📝 Checklist validation

### Documentation
- [x] Spécifications SharePoint mises à jour
- [x] Architecture Power Apps mise à jour
- [x] Mapping Access→SharePoint documenté
- [ ] Scripts PowerShell modifiés (seulement 01)
- [ ] Guide exécution mis à jour
- [ ] README mis à jour
- [ ] Résumé exécutif mis à jour

### Technique
- [x] Liste Beneficiaires spécifiée (20 colonnes)
- [x] Liste Prestations spécifiée (10 colonnes)
- [x] Script 01 modifié (création listes)
- [ ] Script 02 modifié (export CSV)
- [ ] Script 03 modifié (import SharePoint)
- [ ] Script 04 modifié (vérification)

### Power Apps
- [x] Écran 9: Liste Bénéficiaires (documenté)
- [x] Écran 10: Fiche Bénéficiaire (documenté)
- [x] Écran 11: Gestion Prestations (documenté)
- [x] Dashboard mis à jour (KPI 5)
- [ ] Composants créés dans Power Apps Studio

---

**Note finale:** Cette extension ajoute **~200 lignes** au script 01, **~30 lignes** de documentation Power Apps, et **2 nouvelles listes SharePoint**. Le projet passe de 5 à **7 listes SharePoint**, couvrant maintenant les **bénévoles ET les bénéficiaires** de l'association.

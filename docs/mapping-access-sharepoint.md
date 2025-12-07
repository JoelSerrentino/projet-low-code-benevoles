# Mapping Access → SharePoint - Projet Gestion Bénévoles

**Date:** 18 novembre 2025  
**Base source:** SAS-Benevolat.accdb  
**Cible:** SharePoint Online + Power Apps

---

## Vue d'ensemble

Votre base Access actuelle contient **9 tables**, **6 requêtes**, **6 formulaires** et **6 rapports**. Ce document présente le plan de migration vers SharePoint/Power Apps en alignant avec votre cahier des charges.

### Structure actuelle Access
- **PERSONNE** (table principale avec profil complet)
- **BENEVOLE** (extension de PERSONNE pour bénévoles)
- **BENEFICIAIRE** (extension de PERSONNE pour bénéficiaires)
- **ACTIVITE** (activités récurrentes)
- **EVENEMENT** (événements ponctuels)
- **PARTICIPANT** (lien bénévoles ↔ événements)
- **DONNER** (lien bénévoles ↔ activités)
- **RECEVOIR** (lien bénéficiaires ↔ activités)
- **LOCALITE** (table de référence NPA/Ville)

---

## 📋 Mapping des tables

### 1. PERSONNE + BENEVOLE → Liste SharePoint "Bénévoles"

**Logique de fusion:** La structure Access sépare PERSONNE (données générales) et BENEVOLE (données spécifiques). Dans SharePoint, nous fusionnons ces tables en une seule liste "Bénévoles" pour simplifier.

| Colonne Access | Colonne SharePoint | Type SharePoint | Notes de migration |
| --- | --- | --- | --- |
| PERSONNE.PERSONNE_ID | ID | Auto-increment | ID natif SharePoint |
| PERSONNE.NOM | Title | Texte (255) | Nom complet pour affichage |
| PERSONNE.PRENOM | Prenom | Texte (100) | |
| PERSONNE.TITRE | Civilite | Choix (M./Mme/Autre) | Convertir en liste de choix |
| PERSONNE.EMAIL | Email | Courrier | Validation format email |
| PERSONNE.TELEPHONE | Telephone | Texte (50) | |
| PERSONNE.PORTABLE | TelephoneMobile | Texte (50) | |
| PERSONNE.ADRESSE1 | Adresse1 | Texte (255) | |
| PERSONNE.ADRESSE2 | Adresse2 | Texte (255) | |
| PERSONNE.LOCALITE_ID | NPA | Texte (10) | Fusionner avec table LOCALITE |
| LOCALITE.VILLE | Ville | Texte (100) | Calculé ou saisie |
| PERSONNE.DATENAISSANCE | DateNaissance | Date | |
| PERSONNE.LANGUES | Langues | Choix multi | Convertir en liste normalisée |
| PERSONNE.SITUATIONPERSONNELLE | SituationPersonnelle | Choix | Ex: Étudiant, Retraité, Actif |
| PERSONNE.FORMATION | Formation | Texte multiligne | |
| PERSONNE.DIVERS | NotesGenerales | Texte multiligne enrichi | |
| PERSONNE.SUIVI | NotesInternes | Texte multiligne enrichi | Réservé coordinateurs |
| PERSONNE.DUO | Binome | Texte (100) | |
| BENEVOLE.BNV_STATUT | Statut | Choix (Actif/Inactif/Suspendu) | **Obligatoire** |
| BENEVOLE.BNV_DATEDEBUT | DateEntree | Date et heure | Déclenche onboarding |
| BENEVOLE.BNV_PROVENANCE | Provenance | Choix | Ex: Site web, Bouche-à-oreille |
| BENEVOLE.BNV_PROVENANCEDETAIL | ProvenanceDetail | Texte multiligne | |
| BENEVOLE.BNV_DISPONIBILITE | DisponibilitesPreferees | Texte multiligne | Résumé textuel |
| BENEVOLE.BNV_INTERET | CentresInteret | Texte multiligne | |
| BENEVOLE.BNV_COMPETENCES | Competences | Choix multi | **Liste normalisée** |
| BENEVOLE.BNV_INVITATION | RecevoirInvitations | Oui/Non | Consentement notifications |
| BENEVOLE.BNV_EVENEMENT | ParticiperEvenements | Oui/Non | |
| *(Nouveau)* | RGPDConsentement | Oui/Non | **Obligatoire** - Conformité RGPD |
| *(Nouveau)* | DateDerniereMajProfil | Date et heure | Auto via Power Automate |
| *(Nouveau)* | NumeroBenevole | Numéro auto | Identifiant unique lisible |

**Actions de migration:**
1. Fusionner PERSONNE + BENEVOLE via jointure sur `PERSONNE_ID`
2. Filtrer uniquement les personnes ayant un enregistrement BENEVOLE
3. Exclure les BENEFICIAIRE (migration séparée si nécessaire)
4. Créer colonne calculée `Title = [NOM] & " " & [PRENOM]`
5. Normaliser les choix multiples (Langues, Compétences)

---

### 2. ACTIVITE → Liste SharePoint "Missions" (récurrentes)

Les ACTIVITE Access correspondent aux missions récurrentes dans le cahier des charges.

| Colonne Access | Colonne SharePoint | Type SharePoint | Notes de migration |
| --- | --- | --- | --- |
| ACTIVITE.ACTIVITE_ID | ID | Auto-increment | |
| ACTIVITE.ACT_NOM | Title | Texte (255) | Nom de la mission |
| ACTIVITE.ACT_FREQUENCE | Frequence | Choix | Ex: Hebdomadaire, Mensuelle |
| ACTIVITE.ACT_LIEU | Lieu | Texte (255) | |
| ACTIVITE.ACT_AUTRESDETAIL | Description | Texte multiligne enrichi | Détails complets |
| *(Nouveau)* | CodeMission | Texte (50) | Format: MISS-2025-001 |
| *(Nouveau)* | DateDebut | Date et heure | Pour missions ponctuelles |
| *(Nouveau)* | DateFin | Date et heure | |
| *(Nouveau)* | Responsable | Personne ou groupe | Coordinateur |
| *(Nouveau)* | CompetencesRequises | Choix multi | Liste synchronisée |
| *(Nouveau)* | NombreBenevoles | Nombre | Volume attendu |
| *(Nouveau)* | StatutMission | Choix | Planifiée/En cours/Clôturée |
| *(Nouveau)* | Priorite | Choix | Faible/Moyenne/Haute |

---

### 3. EVENEMENT → Liste SharePoint "Missions" (ponctuelles)

Fusion EVENEMENT Access dans "Missions" SharePoint en ajoutant un champ Type.

| Colonne Access | Colonne SharePoint | Type SharePoint | Notes de migration |
| --- | --- | --- | --- |
| EVENEMENT.EVENEMENT_ID | ID | Auto-increment | |
| EVENEMENT.EVE_NOM | Title | Texte (255) | |
| EVENEMENT.EVE_DATE | DateDebut | Date et heure | |
| *(Calculé)* | DateFin | Date et heure | Même jour si non spécifié |
| EVENEMENT.EVE_LIEU | Lieu | Texte (255) | |
| EVENEMENT.EVE_DESCRIPTION | Description | Texte multiligne enrichi | |
| EVENEMENT.EVE_HORAIRES | HorairesDetail | Texte multiligne | |
| *(Nouveau)* | TypeMission | Choix | **Récurrente / Ponctuelle** |
| *(Nouveau)* | StatutMission | Choix | Planifiée/En cours/Clôturée |

**Stratégie:** Importer ACTIVITE et EVENEMENT dans la même liste "Missions" avec un champ `TypeMission` pour différencier.

---

### 4. PARTICIPANT + DONNER → Liste SharePoint "Affectations"

Tables de liaison Access → Liste unique "Affectations" SharePoint.

| Colonne Access | Colonne SharePoint | Type SharePoint | Notes de migration |
| --- | --- | --- | --- |
| PARTICIPANT.PERSONNE_ID | BenevoleID | Recherche (Bénévoles) | Lookup |
| PARTICIPANT.EVENEMENT_ID | MissionID | Recherche (Missions) | Lookup |
| DONNER.ACTIVITE_ID | MissionID | Recherche (Missions) | Fusionner avec PARTICIPANT |
| PARTICIPANT.PAR_HORAIRE1 | PlageHoraire1 | Texte (100) | |
| PARTICIPANT.PAR_HORAIRE2 | PlageHoraire2 | Texte (100) | |
| PARTICIPANT.PAR_MATERIEL | MaterielFourni | Texte (255) | |
| *(Nouveau)* | Title | Calculé | [MissionID] & "-" & [BenevoleID] |
| *(Nouveau)* | StatutAffectation | Choix | Proposé/Confirmé/Annulé/Terminé |
| *(Nouveau)* | Commentaire | Texte multiligne | |
| *(Nouveau)* | HeuresDeclarees | Nombre (1 déc) | Saisie post-mission |
| *(Nouveau)* | DateProposition | Date et heure | Timestamp |
| *(Nouveau)* | DateConfirmation | Date et heure | |

**Actions de migration:**
1. Union des tables PARTICIPANT et DONNER
2. Mapper EVENEMENT_ID et ACTIVITE_ID vers la liste Missions unifiée
3. Initialiser StatutAffectation = "Confirmé" pour données historiques

---

### 5. RECEVOIR → Liste SharePoint "Bénéficiaires" (optionnel)

**Note:** Votre cahier des charges se concentre sur les **bénévoles**. Si vous gérez aussi des bénéficiaires :

| Colonne Access | Colonne SharePoint | Type SharePoint |
| --- | --- | --- |
| BENEFICIAIRE.PERSONNE_ID | ID | Auto-increment |
| PERSONNE.NOM / PRENOM | Title | Texte |
| BENEFICIAIRE.BNF_BESOINS | Besoins | Texte multiligne |
| BENEFICIAIRE.BNF_REFERENT | Referent | Texte multiligne |
| BENEFICIAIRE.BNF_HORAIRES | Horaires | Texte (255) |
| BENEFICIAIRE.BNF_DATEDEBUT | DateDebut | Date |
| BENEFICIAIRE.Historique | Historique | Texte multiligne enrichi |

**Recommandation:** Créer une liste séparée uniquement si gestion active des bénéficiaires requise.

---

### 6. LOCALITE → Colonne de choix dans "Bénévoles"

**Stratégie simplifiée:** Plutôt qu'une liste séparée, utiliser des colonnes NPA + Ville directement dans "Bénévoles".

**Alternative avancée:** Créer une liste "Localités" de référence avec Lookup depuis "Bénévoles".

---

### 7. Nouvelle liste: "Disponibilités"

**Absence dans Access** → Nouveau dans SharePoint pour planning structuré.

| Colonne SharePoint | Type SharePoint | Description |
| --- | --- | --- |
| Title | Calculé | [BenevoleID] & "-" & [Jour] |
| BenevoleID | Recherche (Bénévoles) | |
| Jour | Date | Ou jour de semaine pour récurrence |
| PlageHoraireDebut | Heure | |
| PlageHoraireFin | Heure | |
| Recurrence | Choix | Aucune/Hebdomadaire/Mensuelle |
| Commentaires | Texte multiligne | |
| DerniereMiseAJour | Date et heure | |

**Migration initiale:** Extraire données de `BENEVOLE.BNV_DISPONIBILITE` (texte libre) et structurer manuellement ou via formulaire Power Apps.

---

### 8. Nouvelle bibliothèque: "Documents Bénévoles"

**Absence dans Access** → Nouveau pour conformité RGPD et gestion documents.

| Colonne SharePoint | Type SharePoint | Description |
| --- | --- | --- |
| Nom (fichier) | Natif | Convention: BEN-####-Type-AAAA |
| BenevoleID | Recherche (Bénévoles) | |
| TypeDocument | Choix | Certificat/Badge/Contrat/Autre |
| DateExpiration | Date | Alertes automatiques |
| Commentaires | Texte multiligne | |
| Confidentialite | Choix | Public interne/Restreint |

---

## 🔄 Migration des requêtes Access

| Requête Access | Équivalent Power Apps |
| --- | --- |
| Activités et bénéficiaires | `Filter(Affectations, MissionID.TypeMission = "Récurrente")` |
| Activités et bénévoles | `Filter(Affectations, !IsBlank(BenevoleID))` |
| Événement vs participants | `Filter(Affectations, MissionID.TypeMission = "Ponctuelle")` |
| Personne trié | `SortByColumns(Bénévoles, "Title", Ascending)` |
| Personne vs événement | Galerie avec Items = `LookUp(Affectations, ...)` |
| Personnes BNV ou BNF | Filtre sur `Statut = "Actif"` |

**Principe:** Toutes les requêtes SQL Access seront remplacées par des formules Power Apps (Filter, LookUp, Sort, etc.).

---

## 📱 Migration des formulaires Access

| Formulaire Access | Écran Power Apps | Fonctionnalités |
| --- | --- | --- |
| PERSONNE | Écran "Fiche Bénévole" | Formulaire d'édition complet |
| BENEVOLE sous-formulaire | Section intégrée dans "Fiche Bénévole" | Onglets ou sections |
| EVENEMENT | Écran "Créer Mission" | Wizard de création |
| PARTICIPANT sous-formulaire | Écran "Affectations" | Galerie + formulaire contextuel |
| BENEFICIAIRE sous-formulaire | *(Optionnel)* Liste Bénéficiaires | Si gestion requise |

**Nouveaux écrans Power Apps:**
- **Accueil/Tableau de bord** : KPI, alertes, missions à pourvoir
- **Onboarding bénévole** : Wizard multi-étapes (voir cahier des charges)
- **Gestion disponibilités** : Calendrier interactif
- **Matching intelligent** : Suggestion bénévoles pour missions

---

## 📊 Migration des rapports Access

| Rapport Access | Solution Power Apps/Power BI |
| --- | --- |
| Activités et bénéficiaires | Export Excel depuis galerie Power Apps |
| Liste des bénéficiaires | Vue SharePoint + export |
| Liste des événements | Vue SharePoint filtrée |
| Activités et bénévoles | Power BI Dashboard (optionnel) |
| Personne vs événement | Rapport Power Apps avec galeries |
| Liste personnes | Export Excel natif |

**Recommandation:** Utiliser Power BI uniquement si reporting avancé nécessaire. Sinon, exports Excel depuis Power Apps suffisent.

---

## 📅 Plan de migration par phases

### Phase 1: Préparation (Semaine 1-2)
- [ ] Nettoyer données Access (doublons, valeurs invalides)
- [ ] Exporter tables en CSV/Excel
- [ ] Créer listes de choix normalisées (Compétences, Statuts, etc.)
- [ ] Définir groupes de sécurité Microsoft 365

### Phase 2: Création structure SharePoint (Semaine 3)
- [ ] Créer liste "Bénévoles" avec toutes colonnes
- [ ] Créer liste "Missions" (fusion Activités + Événements)
- [ ] Créer liste "Affectations"
- [ ] Créer liste "Disponibilités"
- [ ] Créer bibliothèque "Documents Bénévoles"
- [ ] Configurer colonnes calculées et validations

### Phase 3: Import données (Semaine 4)
- [ ] Importer PERSONNE + BENEVOLE → Bénévoles (script PowerShell)
- [ ] Importer ACTIVITE + EVENEMENT → Missions
- [ ] Importer PARTICIPANT + DONNER → Affectations
- [ ] Vérifier intégrité référentielle (lookups)

### Phase 4: Développement Power Apps (Semaine 5-6)
- [ ] Écran Accueil + tableau de bord
- [ ] Écran Liste bénévoles
- [ ] Écran Fiche bénévole (édition)
- [ ] Écran Gestion missions
- [ ] Écran Affectations
- [ ] Écran Onboarding (wizard)
- [ ] Écran Disponibilités

### Phase 5: Automatisations Power Automate (Semaine 7)
- [ ] Flux onboarding nouveau bénévole
- [ ] Flux notifications affectations
- [ ] Flux rappels disponibilités
- [ ] Flux alertes missions non pourvues
- [ ] Flux expiration documents

### Phase 6: Tests et déploiement (Semaine 8)
- [ ] Tests utilisateurs avec coordinateurs
- [ ] Ajustements interface
- [ ] Migration données complètes (production)
- [ ] Formation utilisateurs
- [ ] Mise en production

---

## 🔐 Considérations RGPD

**Champs sensibles à protéger:**
- DateNaissance, TelephoneMobile, Email
- NotesInternes, Suivi
- Documents confidentiels

**Actions:**
- Masquer via permissions SharePoint
- Champs visibles uniquement pour Administrateurs
- Logs d'accès via audit SharePoint
- Politique de rétention 3 ans
- Workflow suppression sur demande (droit à l'oubli)

---

## 📝 Scripts de migration

Des scripts PowerShell seront fournis pour:
1. Exporter Access vers CSV
2. Nettoyer et transformer données
3. Importer dans SharePoint via PnP PowerShell
4. Vérifier intégrité post-migration

Voir fichier `scripts/Migration-Access-SharePoint.ps1` *(à créer)*.

---

## ✅ Checklist de validation

Avant de valider la migration:
- [ ] Toutes les données bénévoles migrées (comptage)
- [ ] Relations préservées (affectations correctes)
- [ ] Aucun doublon créé
- [ ] Lookups fonctionnels
- [ ] Permissions configurées
- [ ] Tests CRUD (Create, Read, Update, Delete) OK
- [ ] Sauvegarde Access conservée

---

**Prochaines étapes:** Créer les spécifications détaillées de chaque liste SharePoint avec colonnes exactes, validations et workflows.

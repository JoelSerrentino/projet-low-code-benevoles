# Spécifications détaillées des listes SharePoint
# Projet Gestion Bénévoles - SAS

**Date:** 18 novembre 2025  
**Version:** 1.0

---

## 📋 Liste 1: Bénévoles

### Informations générales
- **Nom technique:** Benevoles
- **Nom affiché:** Gestion des Bénévoles
- **Description:** Centralise tous les profils de bénévoles avec coordonnées, compétences et historique
- **Versionnage:** Majeur activé (conserver 10 versions)
- **Approbation de contenu:** Activée
- **Pièces jointes:** Désactivées (utiliser bibliothèque Documents)

### Colonnes détaillées

| Nom interne | Nom affiché | Type | Taille/Format | Obligatoire | Valeur par défaut | Validation | Indexé | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Title | Nom complet | Texte | 255 | Oui | - | - | Oui | Nom et prénom pour affichage rapide |
| NumeroBenevole | Numéro bénévole | Numéro auto | - | Oui | Auto | Format: BEN-0001 | Oui | Identifiant unique lisible |
| Prenom | Prénom | Texte | 100 | Oui | - | - | Non | Prénom du bénévole |
| Nom | Nom | Texte | 100 | Oui | - | - | Oui | Nom de famille |
| Civilite | Civilité | Choix | - | Oui | M. | M./Mme/Autre | Non | Titre de civilité |
| Email | Adresse e-mail | Courrier | - | Oui | - | Format email | Oui | Contact principal |
| Telephone | Téléphone fixe | Texte | 50 | Non | - | - | Non | Numéro fixe |
| TelephoneMobile | Téléphone mobile | Texte | 50 | Non | - | - | Non | Numéro portable |
| Adresse1 | Adresse ligne 1 | Texte | 255 | Non | - | - | Non | Rue et numéro |
| Adresse2 | Adresse ligne 2 | Texte | 255 | Non | - | - | Non | Complément adresse |
| NPA | Code postal | Texte | 10 | Non | - | - | Non | NPA suisse ou code postal |
| Ville | Ville | Texte | 100 | Non | - | - | Non | Localité |
| DateNaissance | Date de naissance | Date | Date seule | Non | - | < Aujourd'hui | Non | Pour calcul âge si nécessaire |
| Langues | Langues parlées | Choix multi | - | Non | Français | Français/Allemand/Anglais/Italien/Espagnol/Autre | Non | Compétences linguistiques |
| SituationPersonnelle | Situation | Choix | - | Non | - | Étudiant/Actif/Retraité/En recherche/Autre | Non | Contexte personnel |
| Formation | Formation | Texte multiligne | 6 lignes | Non | - | - | Non | Parcours académique/professionnel |
| NotesGenerales | Notes générales | Texte multiligne enrichi | 10 lignes | Non | - | - | Non | Informations diverses |
| NotesInternes | Notes internes | Texte multiligne enrichi | 10 lignes | Non | - | - | Non | **Réservé coordinateurs** |
| Binome | Binôme préféré | Texte | 100 | Non | - | - | Non | Nom d'un autre bénévole |
| Statut | Statut | Choix | - | Oui | Actif | Actif/Inactif/Suspendu/En attente | Oui | État du bénévole |
| DateEntree | Date d'entrée | Date et heure | Date seule | Oui | =TODAY() | - | Oui | Première adhésion |
| Provenance | Comment nous avez-vous connu ? | Choix | - | Non | - | Site web/Bouche-à-oreille/Réseaux sociaux/Événement/Autre | Non | Canal d'acquisition |
| ProvenanceDetail | Détails provenance | Texte multiligne | 4 lignes | Non | - | - | Non | Précisions |
| DisponibilitesPreferees | Disponibilités (résumé) | Texte multiligne | 6 lignes | Non | - | - | Non | Texte libre, enrichi par liste Disponibilités |
| CentresInteret | Centres d'intérêt | Texte multiligne | 6 lignes | Non | - | - | Non | Motivations et passions |
| Competences | Compétences | Choix multi | - | Oui | - | Voir tableau ci-dessous | Oui | Savoir-faire clés |
| RecevoirInvitations | Recevoir invitations | Oui/Non | - | Oui | Non | - | Non | Consentement mailings |
| ParticiperEvenements | Participer événements | Oui/Non | - | Oui | Non | - | Non | Intérêt événements ponctuels |
| RGPDConsentement | Consentement RGPD | Oui/Non | - | Oui | Non | Doit être Oui pour Statut=Actif | Oui | **Conformité obligatoire** |
| DateDerniereMajProfil | Dernière mise à jour profil | Date et heure | Date et heure | Oui | =TODAY() | - | Non | Auto via Power Automate |
| Photo | Photo de profil | Image | - | Non | - | - | Non | Avatar (optionnel) |

### Liste de choix "Compétences" (Choix multi)
- Accompagnement social
- Animation d'ateliers
- Bricolage / Réparations
- Communication / Rédaction
- Conduite / Transport
- Conseil juridique
- Cuisine / Restauration
- Informatique / Numérique
- Jardinage
- Logistique / Organisation
- Santé / Soins
- Soutien administratif
- Traduction
- Autre (préciser dans Notes)

### Vues SharePoint à créer

**1. Vue par défaut: "Tous les bénévoles actifs"**
- Filtre: Statut = "Actif"
- Colonnes: NumeroBenevole, Title, Email, TelephoneMobile, Competences, DateEntree
- Tri: Title (A→Z)

**2. Vue: "Nouveaux bénévoles (30 jours)"**
- Filtre: DateEntree >= [Aujourd'hui] - 30 jours
- Colonnes: NumeroBenevole, Title, Email, DateEntree, Statut
- Tri: DateEntree (décroissant)

**3. Vue: "Bénévoles inactifs"**
- Filtre: Statut = "Inactif" OU "Suspendu"
- Colonnes: Title, Email, Statut, DateDerniereMajProfil
- Tri: DateDerniereMajProfil (décroissant)

**4. Vue: "Profils incomplets"**
- Filtre: Email vide OU Competences vide OU RGPDConsentement = Non
- Colonnes: Title, Email, Competences, RGPDConsentement
- Alerte visuelle

### Permissions
- **Lecture:** Tous les coordinateurs (groupe M365 "Coordinateurs Bénévoles")
- **Modification:** Administrateurs uniquement
- **Champs masqués pour coordinateurs:** DateNaissance, NotesInternes

### Règles métier
1. Un bénévole avec Statut="Actif" DOIT avoir RGPDConsentement=Oui
2. Title calculé automatiquement = Civilite + Nom + Prenom
3. NumeroBenevole auto-incrémenté (BEN-0001, BEN-0002, etc.)
4. Validation e-mail unique (pas de doublons)

---

## 🎯 Liste 2: Missions

### Informations générales
- **Nom technique:** Missions
- **Nom affiché:** Gestion des Missions et Événements
- **Description:** Regroupe missions récurrentes et événements ponctuels
- **Versionnage:** Majeur et mineur activé
- **Approbation de contenu:** Activée (workflow sur changement StatutMission)
- **Pièces jointes:** Autorisées (documents liés à la mission)

### Colonnes détaillées

| Nom interne | Nom affiché | Type | Taille/Format | Obligatoire | Valeur par défaut | Validation | Indexé | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Title | Titre de la mission | Texte | 255 | Oui | - | - | Oui | Nom court et explicite |
| CodeMission | Code mission | Texte | 50 | Oui | Auto | Format: MISS-AAAA-### | Oui | Identifiant unique |
| TypeMission | Type | Choix | - | Oui | Récurrente | Récurrente/Ponctuelle | Oui | Distingue activités/événements |
| Description | Description complète | Texte multiligne enrichi | - | Oui | - | - | Non | Détails mission |
| DateDebut | Date de début | Date et heure | Date et heure | Oui | - | >= Aujourd'hui | Oui | Début mission |
| DateFin | Date de fin | Date et heure | Date et heure | Oui | - | >= DateDebut | Non | Fin mission |
| Frequence | Fréquence | Choix | - | Non | Unique | Unique/Hebdomadaire/Mensuelle/Trimestrielle | Non | Pour missions récurrentes |
| Lieu | Lieu | Texte | 255 | Non | - | - | Non | Adresse ou site |
| HorairesDetail | Détails horaires | Texte multiligne | 4 lignes | Non | - | - | Non | Plages horaires précises |
| Responsable | Responsable mission | Personne ou groupe | - | Oui | =[Moi] | - | Oui | Coordinateur référent |
| CompetencesRequises | Compétences requises | Choix multi | - | Oui | - | **Même liste que Bénévoles** | Oui | Pour matching |
| NombreBenevoles | Nombre de bénévoles | Nombre | Entier | Oui | 1 | > 0 | Non | Volume attendu |
| StatutMission | Statut | Choix | - | Oui | Brouillon | Brouillon/Planifiée/En cours/Clôturée/Annulée | Oui | Cycle de vie |
| Priorite | Priorité | Choix | - | Non | Moyenne | Faible/Moyenne/Haute/Critique | Oui | Urgence |
| BenevolesCourants | Bénévoles affectés (nb) | Nombre | Calculé | Non | - | COUNT(Affectations) | Non | Nombre actuel |
| PlacesRestantes | Places restantes | Nombre | Calculé | Non | - | =NombreBenevoles - BenevolesCourants | Non | Disponibilité |

### Vues SharePoint à créer

**1. Vue par défaut: "Missions planifiées"**
- Filtre: StatutMission = "Planifiée" OU "En cours"
- Colonnes: CodeMission, Title, TypeMission, DateDebut, Responsable, PlacesRestantes
- Tri: DateDebut (croissant)

**2. Vue: "Missions à pourvoir (urgences)"**
- Filtre: PlacesRestantes > 0 ET Priorite = "Haute" ET DateDebut <= [Aujourd'hui] + 7 jours
- Colonnes: Title, DateDebut, PlacesRestantes, Responsable
- Mise en forme conditionnelle (rouge)

**3. Vue: "Missions récurrentes"**
- Filtre: TypeMission = "Récurrente"
- Colonnes: Title, Frequence, CompetencesRequises, NombreBenevoles
- Tri: Title

**4. Vue: "Historique missions clôturées"**
- Filtre: StatutMission = "Clôturée"
- Colonnes: CodeMission, Title, DateDebut, DateFin, Responsable
- Tri: DateFin (décroissant)

### Permissions
- **Lecture:** Tous les coordinateurs
- **Modification:** Coordinateurs (leurs missions uniquement) + Administrateurs (toutes)
- **Création:** Coordinateurs et Administrateurs

### Règles métier
1. DateFin >= DateDebut (validation SharePoint)
2. CodeMission auto-généré format: MISS-[Année]-[Numéro séquentiel]
3. Impossible de clôturer si PlacesRestantes > 0 ET Priorite="Critique"
4. Workflow d'approbation si changement vers "Clôturée"

---

## 🔗 Liste 3: Affectations

### Informations générales
- **Nom technique:** Affectations
- **Nom affiché:** Affectations Bénévoles ↔ Missions
- **Description:** Table de liaison entre bénévoles et missions
- **Versionnage:** Majeur activé
- **Approbation de contenu:** Désactivée
- **Pièces jointes:** Désactivées

### Colonnes détaillées

| Nom interne | Nom affiché | Type | Taille/Format | Obligatoire | Valeur par défaut | Validation | Indexé | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Title | Identifiant affectation | Calculé | - | Oui | =[MissionID]&"-"&[BenevoleID] | - | Oui | Clé unique |
| MissionID | Mission | Recherche | Missions | Oui | - | - | Oui | Lookup vers Missions.Title |
| BenevoleID | Bénévole | Recherche | Benevoles | Oui | - | Statut=Actif | Oui | Lookup vers Benevoles.Title |
| StatutAffectation | Statut affectation | Choix | - | Oui | Proposé | Proposé/Confirmé/Annulé/Terminé | Oui | État engagement |
| Commentaire | Commentaire coordinateur | Texte multiligne | 6 lignes | Non | - | - | Non | Notes libres |
| PlageHoraire1 | Plage horaire 1 | Texte | 100 | Non | - | - | Non | Ex: 9h-12h |
| PlageHoraire2 | Plage horaire 2 | Texte | 100 | Non | - | - | Non | Ex: 14h-17h |
| MaterielFourni | Matériel fourni | Texte | 255 | Non | - | - | Non | Équipements apportés |
| HeuresDeclarees | Heures réalisées | Nombre | 1 décimale | Non | - | > 0 | Non | Saisie post-mission |
| DateProposition | Date de proposition | Date et heure | Date et heure | Oui | =NOW() | - | Oui | Timestamp création |
| DateConfirmation | Date de confirmation | Date et heure | Date et heure | Non | - | >= DateProposition | Non | Quand bénévole accepte |
| CanalNotification | Canal de notification | Choix | - | Non | Email | Email/Teams/Téléphone/SMS | Non | Moyen de contact |
| EmailEnvoye | Email envoyé | Oui/Non | - | Oui | Non | - | Non | Flag pour Power Automate |

### Vues SharePoint à créer

**1. Vue par défaut: "Affectations en cours"**
- Filtre: StatutAffectation = "Confirmé" ET MissionID.StatutMission <> "Clôturée"
- Colonnes: BenevoleID, MissionID, MissionID.DateDebut, PlageHoraire1
- Tri: MissionID.DateDebut

**2. Vue: "Propositions en attente"**
- Filtre: StatutAffectation = "Proposé"
- Colonnes: BenevoleID, MissionID, DateProposition, CanalNotification
- Tri: DateProposition (décroissant)

**3. Vue: "Affectations par bénévole"**
- Groupement: BenevoleID
- Colonnes: MissionID, StatutAffectation, DateProposition, HeuresDeclarees

**4. Vue: "Heures à valider"**
- Filtre: StatutAffectation = "Terminé" ET HeuresDeclarees vide
- Colonnes: BenevoleID, MissionID, DateConfirmation

### Permissions
- **Lecture:** Coordinateurs (voir toutes)
- **Modification:** Coordinateurs (leurs missions) + Administrateurs
- **Suppression:** Administrateurs uniquement

### Règles métier
1. Validation unicité: un bénévole ne peut pas avoir 2 affectations "Confirmé" sur la même mission
2. Transition StatutAffectation contrôlée par workflow:
   - Proposé → Confirmé (notification auto)
   - Confirmé → Terminé (saisie heures demandée)
   - Annulé = état final
3. Colonne Title calculée empêche doublons
4. Index sur BenevoleID + MissionID pour performances

---

## 📅 Liste 4: Disponibilités

### Informations générales
- **Nom technique:** Disponibilites
- **Nom affiché:** Disponibilités des Bénévoles
- **Description:** Planning détaillé des créneaux disponibles
- **Versionnage:** Majeur activé
- **Approbation de contenu:** Désactivée
- **Pièces jointes:** Désactivées

### Colonnes détaillées

| Nom interne | Nom affiché | Type | Taille/Format | Obligatoire | Valeur par défaut | Validation | Indexé | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Title | Identifiant créneau | Calculé | - | Oui | =[BenevoleID]&"-"&TEXT([Jour],"jj/mm") | - | Oui | Clé lisible |
| BenevoleID | Bénévole | Recherche | Benevoles | Oui | - | Statut=Actif | Oui | Lookup vers Benevoles.Title |
| Jour | Jour / Date | Date | Date seule | Oui | - | - | Oui | Date spécifique ou jour récurrent |
| TypeDisponibilite | Type | Choix | - | Oui | Ponctuelle | Ponctuelle/Récurrente hebdomadaire | Non | Nature du créneau |
| JourSemaine | Jour de la semaine | Choix | - | Non | - | Lundi/Mardi/.../Dimanche | Non | Pour récurrences |
| PlageHoraireDebut | Début | Heure | HH:MM | Oui | - | - | Non | Heure de début |
| PlageHoraireFin | Fin | Heure | HH:MM | Oui | - | > PlageHoraireDebut | Non | Heure de fin |
| Recurrence | Récurrence | Choix | - | Non | Aucune | Aucune/Hebdomadaire/Mensuelle | Non | Type de répétition |
| DateFinRecurrence | Fin de récurrence | Date | Date seule | Non | - | > Jour | Non | Pour limiter récurrence |
| Commentaires | Commentaires | Texte multiligne | 4 lignes | Non | - | - | Non | Précisions ou exceptions |
| DerniereMiseAJour | Dernière modification | Date et heure | Date et heure | Oui | =NOW() | - | Non | Auto via Power Automate |
| Confirme | Confirmé | Oui/Non | - | Oui | Non | - | Non | Bénévole a validé |

### Vues SharePoint à créer

**1. Vue par défaut: "Disponibilités confirmées"**
- Filtre: Confirme = Oui ET (Recurrence <> "Aucune" OU Jour >= Aujourd'hui)
- Colonnes: BenevoleID, TypeDisponibilite, JourSemaine/Jour, PlageHoraireDebut, PlageHoraireFin
- Groupement: BenevoleID

**2. Vue: "Disponibilités à confirmer"**
- Filtre: Confirme = Non
- Colonnes: BenevoleID, Jour, PlageHoraireDebut, DerniereMiseAJour
- Tri: DerniereMiseAJour (décroissant)

**3. Vue calendrier: "Planning hebdomadaire"**
- Type: Calendrier
- Date début: Jour
- Titre: BenevoleID + PlageHoraireDebut-PlageHoraireFin

### Permissions
- **Lecture:** Coordinateurs
- **Modification:** Bénévoles (leurs disponibilités uniquement via Power Apps) + Administrateurs
- **Création:** Bénévoles (via formulaire Power Apps) + Coordinateurs

### Règles métier
1. Validation: PlageHoraireFin > PlageHoraireDebut
2. Pas de chevauchements pour un même bénévole (contrôle Power Apps)
3. Rappel automatique si DerniereMiseAJour > 90 jours (Power Automate)
4. Title empêche doublons jour/bénévole

---

## 📄 Bibliothèque 5: Documents Bénévoles

### Informations générales
- **Nom technique:** DocumentsBenevoles
- **Nom affiché:** Documents des Bénévoles
- **Type:** Bibliothèque de documents
- **Description:** Stockage centralisé certificats, contrats, badges
- **Versionnage:** Majeur et mineur activé (10 versions majeures)
- **Approbation de contenu:** Activée
- **Types de fichiers autorisés:** PDF, JPG, PNG, DOCX, XLSX

### Colonnes de métadonnées

| Nom interne | Nom affiché | Type | Taille/Format | Obligatoire | Valeur par défaut | Validation | Description |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Name | Nom du fichier | Natif | - | Oui | - | Convention: BEN-####-Type-AAAA | Nom fichier uploadé |
| BenevoleID | Bénévole | Recherche | Benevoles | Oui | - | Statut<>Inactif | Propriétaire du document |
| TypeDocument | Type de document | Choix | - | Oui | Autre | Certificat médical/Badge/Contrat/Assurance/Diplôme/Autre | Catégorie |
| DateExpiration | Date d'expiration | Date | Date seule | Non | - | > Aujourd'hui | Pour alertes |
| Commentaires | Commentaires | Texte multiligne | 4 lignes | Non | - | - | Informations complémentaires |
| Confidentialite | Confidentialité | Choix | - | Oui | Public interne | Public interne/Restreint/Confidentiel | Niveau d'accès |
| DateUpload | Date d'ajout | Date et heure | Date et heure | Oui | =NOW() | - | Timestamp création |
| Valide | Document valide | Oui/Non | - | Oui | Oui | - | False si expiré/retiré |

### Vues

**1. Vue par défaut: "Documents actifs"**
- Filtre: Valide = Oui ET (DateExpiration >= Aujourd'hui OU DateExpiration vide)
- Colonnes: Name, BenevoleID, TypeDocument, DateExpiration
- Tri: DateUpload (décroissant)

**2. Vue: "Documents expirés ou à renouveler"**
- Filtre: DateExpiration < Aujourd'hui + 30 jours ET DateExpiration non vide
- Colonnes: BenevoleID, TypeDocument, DateExpiration
- Mise en forme conditionnelle (alerte)

**3. Vue: "Documents par bénévole"**
- Groupement: BenevoleID
- Colonnes: TypeDocument, DateUpload, DateExpiration, Valide

### Permissions
- **Lecture:** Coordinateurs (documents Public interne uniquement)
- **Lecture complète:** Administrateurs (tous niveaux confidentialité)
- **Modification:** Administrateurs uniquement
- **Upload:** Coordinateurs + Bénévoles (leurs docs via Power Apps)

### Règles métier
1. Convention de nommage: BEN-[NumeroBenevole]-[TypeDocument]-[Année]
2. Taille max fichier: 10 MB
3. Workflow d'approbation pour documents Confidentiels
4. Alerte automatique 30 jours avant expiration (Power Automate)
5. Soft delete: Valide=Non au lieu de supprimer (audit trail)

---

## 🔐 Groupes de sécurité Microsoft 365

### Groupes à créer

**1. Administrateurs Bénévoles**
- Membres: Joël (admin projet) + responsables IT
- Permissions: Contrôle total sur toutes les listes
- Accès: Tous les champs, tous les documents

**2. Coordinateurs Bénévoles**
- Membres: Coordinateurs terrain
- Permissions: 
  - Lecture sur Bénévoles (sauf champs sensibles)
  - Modification sur Missions (leurs missions)
  - Modification sur Affectations
  - Lecture sur Disponibilités
  - Lecture Documents (Public interne uniquement)

**3. Bénévoles Actifs**
- Membres: Tous bénévoles avec Statut=Actif
- Permissions:
  - Lecture leur propre fiche Bénévoles
  - Modification leurs Disponibilités
  - Upload leurs Documents
  - Lecture Missions (où ils sont affectés)

### Masquage de colonnes sensibles (RLS)

**Pour groupe "Coordinateurs Bénévoles":**
- Masquer: DateNaissance, NotesInternes, Documents Confidentiels

**Pour groupe "Bénévoles Actifs":**
- Voir uniquement: leur propre profil

---

## 📊 Colonnes calculées à créer

### Liste Bénévoles
```excel
// Title (Nom complet)
=[Civilite]&" "&[Nom]&" "&[Prenom]

// Age (si DateNaissance renseignée)
=IF(ISBLANK([DateNaissance]),"",DATEDIF([DateNaissance],TODAY(),"Y"))
```

### Liste Missions
```excel
// PlacesRestantes
=[NombreBenevoles]-[BenevolesCourants]

// EstComplete (Oui/Non)
=IF([PlacesRestantes]<=0,"Oui","Non")
```

### Liste Affectations
```excel
// Title
=TEXT([MissionID],"0")&"-"&TEXT([BenevoleID],"0")
```

### Liste Disponibilités
```excel
// Title
=TEXT([BenevoleID],"0")&"-"&TEXT([Jour],"dd/mm")
```

---

## 🔔 Alertes SharePoint à configurer

### Alerte 1: Nouveau bénévole
- Liste: Bénévoles
- Déclencheur: Nouvel élément créé
- Destinataires: Administrateurs
- Fréquence: Immédiate

### Alerte 2: Mission urgente non pourvue
- Liste: Missions
- Déclencheur: PlacesRestantes > 0 ET Priorite="Critique"
- Destinataires: Tous coordinateurs
- Fréquence: Quotidienne (résumé)

### Alerte 3: Document expiré
- Bibliothèque: Documents
- Déclencheur: DateExpiration < Aujourd'hui
- Destinataires: Bénévole concerné + Administrateurs
- Fréquence: Hebdomadaire

---

## ✅ Checklist de création

### Phase 1: Création des listes
- [ ] Créer liste Bénévoles avec toutes colonnes
- [ ] Créer liste Missions
- [ ] Créer liste Affectations
- [ ] Créer liste Disponibilités
- [ ] Créer bibliothèque Documents

### Phase 2: Configuration
- [ ] Définir colonnes calculées
- [ ] Activer versionnage
- [ ] Configurer approbation de contenu
- [ ] Créer vues personnalisées
- [ ] Indexer colonnes critiques

### Phase 3: Sécurité
- [ ] Créer groupes M365
- [ ] Configurer permissions par liste
- [ ] Masquer colonnes sensibles
- [ ] Tester accès par profil

### Phase 4: Validation
- [ ] Créer données de test (10 bénévoles, 5 missions)
- [ ] Vérifier lookups fonctionnent
- [ ] Tester validations
- [ ] Vérifier colonnes calculées

---

**Prochaine étape:** Créer les scripts PowerShell d'import des données Access.

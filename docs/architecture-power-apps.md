# Architecture Power Apps - Application Gestion Bénévoles

**Date:** 18 novembre 2025  
**Type d'application:** Power Apps Canvas (desktop & tablette)  
**Version:** 1.0

---

## 🎨 Vue d'ensemble de l'application

### Informations générales
- **Nom:** Gestion Bénévoles SAS
- **Icône:** 👥 (personnalisable)
- **Public cible:** Coordinateurs et administrateurs uniquement
- **Résolution cible:** 
  - Desktop: 1366 x 768 (standard)
  - Tablette: 1024 x 768 (mode paysage)
- **Sources de données:**
  - SharePoint: Benevoles, Missions, Affectations, Disponibilites, DocumentsBenevoles, **Beneficiaires, Prestations**
  - Office 365 Users (pour infos utilisateur connecté)
  - Office 365 Outlook (pour notifications)

### Navigation principale
Structure à 3 niveaux:
1. **Écran d'accueil** (dashboard)
2. **Menu principal** (barre latérale permanente)
3. **Écrans fonctionnels** (contenu central)

---

## 📱 Structure des écrans

### 1. Écran: Accueil / Tableau de bord

**Nom technique:** `scr_Accueil`

**Objectif:** Vue d'ensemble de l'activité et KPIs clés

**Composants:**

| Zone | Contrôle | Source de données | Formule clé |
| --- | --- | --- | --- |
| Header | lbl_Bienvenue | Office365Users | `"Bonjour " & Office365Users.MyProfile().DisplayName` |
| KPI 1 | lbl_TotalBenevoles | Benevoles | `CountRows(Filter(Benevoles, Statut = "Actif"))` |
| KPI 2 | lbl_MissionsEnCours | Missions | `CountRows(Filter(Missions, StatutMission in ["Planifiée","En cours"]))` |
| KPI 3 | lbl_MissionsAPourvoir | Missions | `CountRows(Filter(Missions, PlacesRestantes > 0 And DateDebut <= Today() + 7))` |
| KPI 4 | lbl_NouveauxBenevoles | Benevoles | `CountRows(Filter(Benevoles, DateEntree >= Today() - 30))` |
| KPI 5 | lbl_BeneficiairesActifs | Beneficiaires | `CountRows(Filter(Beneficiaires, Statut = "Actif"))` |
| Graphique | chart_EvolutionBenevoles | Benevoles | Histogramme par mois (DateEntree) |
| Alerte | gal_MissionsUrgentes | Missions | `Filter(Missions, Priorite = "Haute" And PlacesRestantes > 0)` |
| Tableau | gal_ProchainsMissions | Missions | `Sort(Filter(Missions, DateDebut >= Today()), DateDebut, Ascending)` Top 5 |
| Boutons rapides | btn_NouveauBenevole | - | `Navigate(scr_FicheBenevole, ScreenTransition.Fade, {mode: "new"})` |
| | btn_NouvelleMission | - | `Navigate(scr_FicheMission, ScreenTransition.Fade, {mode: "new"})` |

**Layout:**
```
┌─────────────────────────────────────────┐
│ [Logo]  Bienvenue, Joël    [🔔] [⚙️]   │
├─────────────────────────────────────────┤
│ ┌────────┐ ┌────────┐ ┌────────┐ ┌────┐│
│ │ 🧑‍🤝‍🧑 156│ │ 📋 23  │ │ ⚠️ 5   │ │ ✨ │
│ │Bénévoles│ │Missions│ │Urgentes│ │ 12 ││
│ └────────┘ └────────┘ └────────┘ └────┘│
│                                         │
│ 📊 Évolution des bénévoles (graphique) │
│ ┌─────────────────────────────────────┐ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ⚠️ Missions urgentes à pourvoir:       │
│ ┌─────────────────────────────────────┐ │
│ │ • Transport médical - 3 places      │ │
│ │ • Accueil visiteurs - 1 place       │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 📅 Prochaines missions:                │
│ [Galerie missions à venir]              │
│                                         │
│ [+ Nouveau bénévole] [+ Nouvelle mission│
└─────────────────────────────────────────┘
```

---

### 2. Écran: Liste des Bénévoles

**Nom technique:** `scr_ListeBenevoles`

**Objectif:** Rechercher et consulter les profils bénévoles

**Composants:**

| Contrôle | Type | Propriété Items/OnSelect | Description |
| --- | --- | --- | --- |
| txt_RechercheBenevole | TextInput | - | Recherche par nom/email |
| dropdown_FiltreStatut | Dropdown | Items: `["Tous", "Actif", "Inactif", "Suspendu"]` | Filtre statut |
| dropdown_FiltreCompetence | Dropdown | Items: `Choices(Benevoles.Competences)` | Filtre compétence |
| gal_Benevoles | Gallery (vertical) | `Filter(Benevoles, ...)` | Liste principale |
| lbl_NomBenevole | Label | `ThisItem.Title` | Nom affiché |
| lbl_Email | Label | `ThisItem.Email` | Contact |
| lbl_Competences | Label | `Concat(ThisItem.Competences, Value, ", ")` | Compétences |
| icon_Statut | Icon | Icône conditionnelle selon statut | Indicateur visuel |
| btn_VoirDetail | Button | `Navigate(scr_FicheBenevole, ..., {benevole: ThisItem})` | Ouvre fiche |

**Formule de filtre combinée:**
```excel
Filter(
    Benevoles,
    // Recherche textuelle
    (txt_RechercheBenevole.Text = "" Or 
     Title in txt_RechercheBenevole.Text Or 
     Email in txt_RechercheBenevole.Text) 
    And
    // Filtre statut
    (dropdown_FiltreStatut.Selected.Value = "Tous" Or 
     Statut = dropdown_FiltreStatut.Selected.Value)
    And
    // Filtre compétence
    (IsBlank(dropdown_FiltreCompetence.Selected) Or 
     dropdown_FiltreCompetence.Selected.Value in Competences)
)
```

**Boutons d'action:**
- `[+ Nouveau bénévole]` → scr_FicheBenevole (mode création)
- `[📥 Exporter Excel]` → `Export(gal_Benevoles.AllItems, "Benevoles.xlsx")`
- `[🔄 Actualiser]` → `Refresh(Benevoles)`

---

### 3. Écran: Fiche Bénévole (Création/Édition)

**Nom technique:** `scr_FicheBenevole`

**Objectif:** Créer ou modifier un profil bénévole complet

**Variables de contexte:**
- `varBenevole` : Enregistrement bénévole (si édition)
- `varMode` : "new" | "edit" | "view"

**Composants principaux:**

**Formulaire maître:**
- Type: `EditForm`
- DataSource: `Benevoles`
- Item: `varBenevole` (ou Defaults(Benevoles) si nouveau)
- Columns: 2 (layout 2 colonnes)

**Sections (Tabs):**

**Onglet 1: Informations personnelles**
| Champ | Contrôle | Validation |
| --- | --- | --- |
| Civilité | Dropdown | Obligatoire |
| Nom | TextInput | Obligatoire, 100 car max |
| Prénom | TextInput | Obligatoire |
| Email | TextInput | Format email, unique |
| Téléphone fixe | TextInput | Format: +41 XX XXX XX XX |
| Mobile | TextInput | Format: +41 XX XXX XX XX |
| Adresse 1 | TextInput | - |
| Adresse 2 | TextInput | - |
| NPA | TextInput | 4 chiffres |
| Ville | TextInput | - |
| Date de naissance | DatePicker | < Aujourd'hui |

**Onglet 2: Profil bénévole**
| Champ | Contrôle | Validation |
| --- | --- | --- |
| Statut | Dropdown | Obligatoire |
| Numéro bénévole | Label | Auto-généré (lecture seule) |
| Date d'entrée | DatePicker | Obligatoire |
| Provenance | Dropdown | - |
| Détails provenance | TextInput (multiligne) | - |
| Situation personnelle | Dropdown | - |
| Langues | ComboBox (multi) | - |
| Formation | TextInput (multiligne) | - |

**Onglet 3: Compétences & Intérêts**
| Champ | Contrôle | Validation |
| --- | --- | --- |
| Compétences | ComboBox (multi) | Obligatoire, min 1 |
| Centres d'intérêt | TextInput (multiligne) | - |
| Disponibilités (résumé) | TextInput (multiligne) | Lecture seule |
| Binôme préféré | Dropdown | Lookup dans Benevoles |

**Onglet 4: Préférences & RGPD**
| Champ | Contrôle | Validation |
| --- | --- | --- |
| Recevoir invitations | Toggle | - |
| Participer événements | Toggle | - |
| Consentement RGPD | Toggle | **Obligatoire** pour Statut=Actif |
| Notes générales | TextInput (multiligne enrichi) | - |
| Notes internes | TextInput (multiligne enrichi) | Visible admin uniquement |

**Boutons de formulaire:**
```
[Annuler] [Enregistrer] [Enregistrer et fermer]

btn_Annuler.OnSelect = ResetForm(Form_Benevole); Navigate(scr_ListeBenevoles)
btn_Enregistrer.OnSelect = SubmitForm(Form_Benevole)
btn_EnregistrerFermer.OnSelect = SubmitForm(Form_Benevole); Navigate(scr_ListeBenevoles)
```

**Validation avant envoi:**
```excel
Form_Benevole.OnSuccess = 
    If(
        varMode = "new",
        // Nouveau bénévole: déclencher onboarding
        Flow_OnboardingBenevole.Run(Form_Benevole.LastSubmit.ID);
        Notify("Bénévole créé avec succès !", NotificationType.Success),
        // Édition
        Notify("Profil mis à jour", NotificationType.Success)
    )
```

---

### 4. Écran: Gestion des Missions

**Nom technique:** `scr_ListeMissions`

**Composants:**

| Contrôle | Type | Items/OnSelect |
| --- | --- | --- |
| dropdown_FiltreMission | Dropdown | "Toutes" / "Récurrentes" / "Ponctuelles" |
| dropdown_FiltreStatut | Dropdown | Statuts mission |
| toggle_UniquementUrgentes | Toggle | Affiche Priorite="Haute" uniquement |
| gal_Missions | Gallery | `Filter(Missions, ...)` avec filtres combinés |
| lbl_TitreMission | Label | `ThisItem.Title` |
| lbl_DateMission | Label | `Text(ThisItem.DateDebut, "dd/mm/yyyy HH:mm")` |
| lbl_PlacesRestantes | Label | `ThisItem.PlacesRestantes & "/" & ThisItem.NombreBenevoles` |
| icon_Priorite | Icon | Icône selon priorité (⚠️ si Haute) |
| btn_Affecter | Button | `Navigate(scr_Affectation, ..., {mission: ThisItem})` |
| btn_VoirDetail | Button | `Navigate(scr_FicheMission, ..., {mission: ThisItem})` |

**Indicateur visuel de remplissage:**
```excel
// Couleur de fond selon taux de remplissage
clr_IndicateurRemplissage = 
    If(
        ThisItem.PlacesRestantes = 0, RGBA(76, 175, 80, 1),  // Vert: complet
        ThisItem.PlacesRestantes <= 2, RGBA(255, 193, 7, 1), // Orange: presque complet
        RGBA(244, 67, 54, 1)                                 // Rouge: places libres
    )
```

---

### 5. Écran: Affectation Bénévole ↔ Mission

**Nom technique:** `scr_Affectation`

**Objectif:** Interface de matching intelligent

**Variables:**
- `varMissionSelectionnee` : Mission en cours
- `varBenevoleSuggeres` : Liste filtrée de candidats

**Sections:**

**Section 1: Détails mission (haut)**
- Affichage titre, date, lieu, compétences requises
- Indicateur places restantes

**Section 2: Matching intelligent (centre)**

**Algorithme de suggestion:**
```excel
varBenevoleSuggeres = 
    SortByColumns(
        Filter(
            Benevoles,
            // Filtre 1: Statut actif
            Statut = "Actif" 
            And
            // Filtre 2: Compétences correspondent
            CountRows(
                Filter(
                    Competences,
                    Value in varMissionSelectionnee.CompetencesRequises
                )
            ) > 0
            And
            // Filtre 3: Pas déjà affecté à cette mission
            CountRows(
                Filter(
                    Affectations,
                    BenevoleID.ID = ID And 
                    MissionID.ID = varMissionSelectionnee.ID And
                    StatutAffectation in ["Proposé", "Confirmé"]
                )
            ) = 0
            And
            // Filtre 4: Disponible au moment de la mission
            CountRows(
                Filter(
                    Disponibilites,
                    BenevoleID.ID = ID And
                    Jour = varMissionSelectionnee.DateDebut And
                    Confirme = true
                )
            ) > 0
        ),
        "NombreCompetencesCorrespondantes", Descending
    )
```

**Galerie des candidats:**
| Colonne | Affichage |
| --- | --- |
| Avatar | Image (si disponible) ou initiales |
| Nom | Title |
| Compétences match | Icônes avec compteur |
| Disponibilité | ✅ ou ⚠️ |
| Score match | % de correspondance |
| Bouton action | [Proposer] / [Confirmer] |

**Section 3: Affectations existantes (bas)**
- Galerie des bénévoles déjà affectés
- Statut de chaque affectation (Proposé/Confirmé/Annulé)

**Actions:**
```excel
btn_ProposerBenevole.OnSelect = 
    Patch(
        Affectations,
        Defaults(Affectations),
        {
            MissionID: LookUp(Missions, ID = varMissionSelectionnee.ID),
            BenevoleID: LookUp(Benevoles, ID = ThisItem.ID),
            StatutAffectation: "Proposé",
            DateProposition: Now(),
            CanalNotification: "Email"
        }
    );
    // Déclencher notification
    Flow_NotifierPropositionMission.Run(
        ThisItem.Email,
        varMissionSelectionnee.Title,
        varMissionSelectionnee.DateDebut
    );
    Notify("Proposition envoyée à " & ThisItem.Title, NotificationType.Success)
```

---

### 6. Écran: Onboarding Bénévole (Wizard)

**Nom technique:** `scr_OnboardingWizard`

**Objectif:** Parcours guidé pour nouveaux bénévoles

**Structure multi-étapes:**

**Étape 1/5: Bienvenue**
- Message d'accueil
- Présentation du parcours
- [Commencer →]

**Étape 2/5: Informations personnelles**
- Formulaire simplifié (nom, email, téléphone, adresse)
- Validation format email
- [← Précédent] [Suivant →]

**Étape 3/5: Compétences et intérêts**
- Sélection compétences (ComboBox multi)
- Centres d'intérêt (texte libre)
- [← Précédent] [Suivant →]

**Étape 4/5: Disponibilités**
- Sélection jours/heures préférés
- Interface calendrier simplifiée
- [← Précédent] [Suivant →]

**Étape 5/5: Consentement RGPD**
- Affichage charte
- Checkbox consentement (obligatoire)
- [← Précédent] [Terminer et créer profil]

**Variables de progression:**
```excel
varEtapeOnboarding = 1 // 1 à 5
varDonneesOnboarding = { Nom: "", Email: "", ... } // Collecte progressive
```

**Navigation entre étapes:**
```excel
btn_SuivantOnboarding.OnSelect = 
    // Validation étape courante
    If(
        ValidateEtape(varEtapeOnboarding),
        Set(varEtapeOnboarding, varEtapeOnboarding + 1),
        Notify("Veuillez compléter tous les champs obligatoires", NotificationType.Error)
    )

btn_PrecedentOnboarding.OnSelect = 
    Set(varEtapeOnboarding, varEtapeOnboarding - 1)

btn_TerminerOnboarding.OnSelect = 
    Patch(Benevoles, Defaults(Benevoles), varDonneesOnboarding);
    Flow_OnboardingBenevole.Run(Benevoles[@ID]);
    Navigate(scr_OnboardingConfirmation)
```

---

### 7. Écran: Gestion Disponibilités

**Nom technique:** `scr_Disponibilites`

**Objectif:** Interface calendrier pour saisir/modifier disponibilités

**Composants:**

| Contrôle | Type | Description |
| --- | --- | --- |
| cal_Calendrier | Calendar (custom) | Vue mensuelle |
| dropdown_BenevoleSelection | Dropdown | Si coordinateur: sélectionner bénévole<br>Si bénévole: son profil uniquement |
| toggle_ModeRecurrence | Toggle | Basculer ponctuel ↔ récurrent |
| gal_CreneauxJour | Gallery | Créneaux du jour sélectionné |
| btn_AjouterCreneau | Button | Ouvre formulaire création |
| frm_NouveauCreneau | Form | PlageDebut, PlageFin, Commentaires |

**Logique de création créneau:**
```excel
btn_EnregistrerCreneau.OnSelect = 
    Patch(
        Disponibilites,
        Defaults(Disponibilites),
        {
            BenevoleID: LookUp(Benevoles, ID = dropdown_BenevoleSelection.Selected.ID),
            Jour: cal_Calendrier.SelectedDate,
            TypeDisponibilite: If(toggle_ModeRecurrence.Value, "Récurrente hebdomadaire", "Ponctuelle"),
            PlageHoraireDebut: timepicker_Debut.SelectedTime,
            PlageHoraireFin: timepicker_Fin.SelectedTime,
            Confirme: true,
            DerniereMiseAJour: Now()
        }
    );
    Notify("Disponibilité enregistrée", NotificationType.Success);
    Refresh(Disponibilites)
```

**Validation chevauchements:**
```excel
// Avant de créer, vérifier absence de conflit
varCreneauxExistants = 
    Filter(
        Disponibilites,
        BenevoleID.ID = varBenevoleActuel.ID And
        Jour = cal_Calendrier.SelectedDate And
        (
            (PlageHoraireDebut <= timepicker_Debut.SelectedTime And PlageHoraireFin > timepicker_Debut.SelectedTime) Or
            (PlageHoraireDebut < timepicker_Fin.SelectedTime And PlageHoraireFin >= timepicker_Fin.SelectedTime)
        )
    )

If(
    CountRows(varCreneauxExistants) > 0,
    Notify("Conflit d'horaire détecté !", NotificationType.Error),
    // Créer créneau
    ...
)
```

---

### 8. Écran: Gestion Documents

**Nom technique:** `scr_Documents`

**Composants:**

| Contrôle | Type | Description |
| --- | --- | --- |
| dropdown_BenevoleDoc | Dropdown | Sélectionner bénévole |
| gal_Documents | Gallery | Liste documents du bénévole |
| lbl_NomFichier | Label | Name du document |
| lbl_TypeDoc | Label | TypeDocument |
| lbl_Expiration | Label | DateExpiration (avec alerte si < 30j) |
| icon_StatutDoc | Icon | ✅ valide / ⚠️ expire bientôt / ❌ expiré |
| btn_Telecharger | Button | Télécharger fichier |
| btn_Upload | Button | Upload nouveau document |

**Upload de document:**
```excel
btn_UploadDocument.OnSelect = 
    // Utiliser AddMediaButton ou connexion OneDrive
    Set(varFichierAUploader, UploadedImage);
    Patch(
        DocumentsBenevoles,
        Defaults(DocumentsBenevoles),
        {
            Name: "BEN-" & dropdown_BenevoleDoc.Selected.NumeroBenevole & "-" & 
                  dropdown_TypeDocument.Selected.Value & "-" & 
                  Year(Now()),
            FileContent: varFichierAUploader,
            BenevoleID: LookUp(Benevoles, ID = dropdown_BenevoleDoc.Selected.ID),
            TypeDocument: dropdown_TypeDocument.Selected.Value,
            DateExpiration: datepicker_Expiration.SelectedDate,
            Confidentialite: dropdown_Confidentialite.Selected.Value,
            DateUpload: Now(),
            Valide: true
        }
    );
    Notify("Document ajouté", NotificationType.Success)
```

---

## 🎨 Composants réutilisables

### Component: Header (cmp_Header)

**Props:**
- `TitrePage` (Input Text): Titre de la page courante
- `AfficherRetour` (Input Boolean): Afficher bouton retour

**Contenu:**
- Logo SAS (gauche)
- Titre page (centre)
- Bouton notifications (droite)
- Bouton paramètres (droite)
- Bouton retour (si AfficherRetour = true)

### Component: Menu latéral (cmp_MenuLateral)

**Props:**
- `PageActive` (Input Text): Nom de la page courante

**Items de menu:**
```
🏠 Accueil
👥 Bénévoles
📋 Missions
🔗 Affectations
📅 Disponibilités
📄 Documents
⚙️ Paramètres
```

**Navigation:**
```excel
btn_MenuBenevoles.OnSelect = Navigate(scr_ListeBenevoles, ScreenTransition.Fade)
```

### Component: Carte Bénévole (cmp_CarteBenevole)

**Props:**
- `Benevole` (Input Record): Enregistrement bénévole

**Affichage:**
- Avatar/initiales
- Nom complet
- Email
- Téléphone
- Badges compétences
- Statut (indicateur couleur)

### Component: Filtre Recherche (cmp_FiltreRecherche)

**Props:**
- `PlaceholderTexte` (Input Text)
- `ResultatRecherche` (Output Text)

**Contenu:**
- TextInput avec icône loupe
- Bouton clear
- Output: texte saisi

---

## 📊 Collections et variables globales

### Collections (OnStart de l'app)

```excel
App.OnStart = 
    // Charger profil utilisateur connecté
    Set(varUtilisateurConnecte, Office365Users.MyProfile());
    
    // Déterminer rôle
    Set(varEstAdministrateur, Office365Users.IsMemberOf("Administrateurs Bénévoles"));
    Set(varEstCoordinateur, Office365Users.IsMemberOf("Coordinateurs Bénévoles"));
    
    // Charger listes de choix en cache
    ClearCollect(colCompetences, Choices(Benevoles.Competences));
    ClearCollect(colStatutsMission, Choices(Missions.StatutMission));
    
    // Charger KPIs dashboard
    Set(varTotalBenevolesActifs, CountRows(Filter(Benevoles, Statut = "Actif")));
    Set(varMissionsEnCours, CountRows(Filter(Missions, StatutMission in ["Planifiée", "En cours"])));
```

### Variables contextuelles par écran

| Variable | Type | Usage |
| --- | --- | --- |
| varBenevoleActuel | Record | Bénévole en cours d'édition |
| varMissionActuelle | Record | Mission en cours |
| varModeFormulaire | Text | "new" / "edit" / "view" |
| varResultatRecherche | Table | Résultats filtrés |
| varEtapeWizard | Number | Étape courante wizard |

---

## 🔔 Notifications dans l'app

### Types de notifications

```excel
// Succès
Notify("Opération réussie !", NotificationType.Success, 3000)

// Erreur
Notify("Une erreur s'est produite", NotificationType.Error, 5000)

// Avertissement
Notify("Attention: places limitées", NotificationType.Warning, 4000)

// Information
Notify("Chargement en cours...", NotificationType.Information, 2000)
```

### Badge notifications (header)

```excel
icon_Notifications.Badge = 
    CountRows(
        Filter(
            Affectations,
            StatutAffectation = "Proposé" And
            EmailEnvoye = false
        )
    ) + 
    CountRows(
        Filter(
            Missions,
            Priorite = "Critique" And
            PlacesRestantes > 0
        )
    )
```

---

## 📱 Écran 9: Gestion des Bénéficiaires

**Nom technique:** `scr_ListeBeneficiaires`

**Objectif:** Consulter et gérer les personnes recevant les services de l'association

**Composants:**

| Contrôle | Type | Propriété Items/OnSelect | Description |
| --- | --- | --- | --- |
| txt_RechercheBeneficiaire | TextInput | - | Recherche par nom/ville |
| dropdown_FiltreStatutBnf | Dropdown | Items: `["Tous", "Actif", "Inactif", "Clôturé"]` | Filtre statut |
| gal_Beneficiaires | Gallery (vertical) | `Filter(Beneficiaires, ...)` | Liste principale |
| lbl_NomBeneficiaire | Label | `ThisItem.Title` | Nom affiché |
| lbl_Ville | Label | `ThisItem.Ville` | Localité |
| lbl_NombrePrestations | Label | `CountRows(Filter(Prestations, BeneficiaireID.ID = ThisItem.ID))` | Nombre de services actifs |
| btn_VoirFiche | Button | `Navigate(scr_FicheBeneficiaire, ScreenTransition.Fade, {idBenef: ThisItem.ID})` | Détails |
| btn_NouveauBeneficiaire | Button | `Navigate(scr_FicheBeneficiaire, ScreenTransition.Fade, {mode: "new"})` | Création |

**Formule de filtrage:**

```excel
gal_Beneficiaires.Items = 
    Sort(
        Filter(
            Beneficiaires,
            (IsBlank(txt_RechercheBeneficiaire.Text) Or 
             Title in txt_RechercheBeneficiaire.Text Or
             Ville in txt_RechercheBeneficiaire.Text) And
            (dropdown_FiltreStatutBnf.Selected.Value = "Tous" Or
             Statut = dropdown_FiltreStatutBnf.Selected.Value)
        ),
        Nom,
        Ascending
    )
```

---

## 📋 Écran 10: Fiche Bénéficiaire

**Nom technique:** `scr_FicheBeneficiaire`

**Objectif:** Afficher/modifier le profil d'un bénéficiaire

**Composants:**

| Section | Contrôle | Type | Formule/Source |
| --- | --- | --- | --- |
| Identité | datacard_NumeroBeneficiaire | DataCard | Auto-généré |
| | datacard_Civilite | DataCard (Dropdown) | M./Mme/Autre |
| | datacard_Nom | DataCard (TextInput) | Obligatoire |
| | datacard_Prenom | DataCard (TextInput) | Obligatoire |
| Coordonnées | datacard_Adresse1 | DataCard (TextInput) | Obligatoire |
| | datacard_NPA | DataCard (TextInput) | Obligatoire |
| | datacard_Ville | DataCard (TextInput) | Obligatoire |
| | datacard_Telephone | DataCard (TextInput) | - |
| | datacard_Email | DataCard (TextInput) | Format validé |
| Informations | datacard_Besoins | DataCard (TextMultiline) | Services requis |
| | datacard_Referent | DataCard (TextMultiline) | Contact externe |
| | datacard_Horaires | DataCard (TextInput) | Créneaux visite |
| Suivi | datacard_DateDebut | DataCard (DatePicker) | Début prise en charge |
| | datacard_DateFin | DataCard (DatePicker) | Fin (optionnel) |
| | datacard_Statut | DataCard (Dropdown) | Actif/Inactif/Clôturé |
| | datacard_Historique | DataCard (TextMultiline enrichi) | Journal |
| RGPD | datacard_RGPDConsentement | DataCard (Toggle) | Obligatoire si Actif |
| Prestations | gal_PrestationsBeneficiaire | Gallery | `Filter(Prestations, BeneficiaireID.ID = varBeneficiaireActuel.ID)` |

**Boutons d'action:**

```excel
// Sauvegarde
btn_EnregistrerBeneficiaire.OnSelect = 
    Patch(
        Beneficiaires,
        LookUp(Beneficiaires, ID = varBeneficiaireActuel.ID),
        {
            Title: datacard_Nom.Value & " " & datacard_Prenom.Value,
            Nom: datacard_Nom.Value,
            Prenom: datacard_Prenom.Value,
            Statut: datacard_Statut.Selected.Value,
            RGPDConsentement: datacard_RGPDConsentement.Value
        }
    );
    Notify("Bénéficiaire enregistré", NotificationType.Success);
    Navigate(scr_ListeBeneficiaires)

// Validation RGPD
datacard_Statut.OnChange = 
    If(
        datacard_Statut.Selected.Value = "Actif" And !datacard_RGPDConsentement.Value,
        Notify("Le consentement RGPD est obligatoire pour un statut Actif", NotificationType.Error)
    )
```

---

## 🤝 Écran 11: Gestion des Prestations

**Nom technique:** `scr_GestionPrestations`

**Objectif:** Lier bénéficiaires et missions (services rendus)

**Composants:**

| Contrôle | Type | Propriété Items/OnSelect | Description |
| --- | --- | --- | --- |
| dropdown_BeneficiairePrestation | Dropdown | Items: `Beneficiaires` (Statut=Actif) | Sélection bénéficiaire |
| dropdown_MissionPrestation | Dropdown | Items: `Missions` | Sélection mission/service |
| date_DebutPrestation | DatePicker | Default: `Today()` | Début prestation |
| date_FinPrestation | DatePicker | - | Fin prévue (optionnel) |
| dropdown_Frequence | Dropdown | Items: `["Ponctuelle","Hebdomadaire","Bimensuelle","Mensuelle"]` | Récurrence |
| txt_CommentairesPrestation | TextInput multiligne | - | Observations |
| gal_PrestationsActives | Gallery | `Filter(Prestations, StatutPrestation = "En cours")` | Liste des prestations |
| btn_CreerPrestation | Button | `Patch(...)` | Créer lien |

**Formule de création:**

```excel
btn_CreerPrestation.OnSelect = 
    Patch(
        Prestations,
        Defaults(Prestations),
        {
            Title: dropdown_MissionPrestation.Selected.Title & "-" & dropdown_BeneficiairePrestation.Selected.Title,
            BeneficiaireID: {ID: dropdown_BeneficiairePrestation.Selected.ID},
            MissionID: {ID: dropdown_MissionPrestation.Selected.ID},
            DateDebut: date_DebutPrestation.SelectedDate,
            DateFin: date_FinPrestation.SelectedDate,
            Frequence: dropdown_Frequence.Selected.Value,
            StatutPrestation: "En cours",
            Commentaires: txt_CommentairesPrestation.Text,
            DerniereVisite: Now()
        }
    );
    Notify("Prestation créée avec succès", NotificationType.Success);
    Reset(dropdown_BeneficiairePrestation);
    Reset(dropdown_MissionPrestation)
```

**Alerte inactivité:**

```excel
// Badge rouge si dernière visite > 60 jours
icon_AlerteInactivite.Visible = 
    CountRows(
        Filter(
            Prestations,
            DateDiff(DerniereVisite, Now(), Days) > 60 And
            StatutPrestation = "En cours"
        )
    ) > 0
```

---

## 🔐 Gestion des permissions

### Affichage conditionnel selon rôle

```excel
// Masquer bouton suppression si pas admin
btn_SupprimerBenevole.Visible = varEstAdministrateur

// Masquer champs sensibles si pas admin
datacard_NotesInternes.Visible = varEstAdministrateur

// Filtrer liste bénévoles pour coordinateurs
gal_Benevoles.Items = 
    If(
        varEstAdministrateur,
        Benevoles, // Tous
        Filter(Benevoles, Statut = "Actif") // Uniquement actifs
    )
```

### Contrôle d'accès aux écrans

```excel
scr_Parametres.OnVisible = 
    If(
        !varEstAdministrateur,
        Navigate(scr_Accueil);
        Notify("Accès non autorisé", NotificationType.Error)
    )
```

---

## 📱 Responsive design

### Adaptation desktop ↔ tablette

```excel
// Variable de détection
Set(varEstMobile, App.Width < 768)

// Adapter layout
gal_Benevoles.TemplateSize = If(varEstMobile, 200, 120)
gal_Benevoles.Columns = If(varEstMobile, 1, 2)

// Masquer menu latéral sur mobile
cmp_MenuLateral.Visible = !varEstMobile
```

---

## ✅ Checklist développement Power Apps

### Phase 1: Structure de base
- [ ] Créer application Canvas vierge
- [ ] Connecter sources de données SharePoint
- [ ] Créer composants réutilisables (Header, Menu)
- [ ] Définir thème et couleurs

### Phase 2: Écrans principaux
- [ ] Écran Accueil + KPIs
- [ ] Écran Liste Bénévoles
- [ ] Écran Fiche Bénévole
- [ ] Écran Liste Missions
- [ ] Écran Affectation
- [ ] Écran Liste Bénéficiaires
- [ ] Écran Fiche Bénéficiaire

### Phase 3: Écrans avancés
- [ ] Wizard Onboarding
- [ ] Gestion Disponibilités
- [ ] Gestion Documents
- [ ] Gestion Prestations (Bénéficiaires ↔ Missions)

### Phase 4: Logique métier
- [ ] Algorithme matching intelligent
- [ ] Validations formulaires
- [ ] Gestion permissions
- [ ] Notifications

### Phase 5: Tests & optimisation
- [ ] Tests utilisateurs
- [ ] Optimisation performances (délégation)
- [ ] Tests responsive
- [ ] Documentation utilisateur

---

**Prochaine étape:** Définir les workflows Power Automate.

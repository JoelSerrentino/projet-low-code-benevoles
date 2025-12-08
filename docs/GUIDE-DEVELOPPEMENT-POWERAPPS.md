# Guide de Développement Power Apps - Gestion des Bénévoles

**Version:** 1.0  
**Date:** 8 décembre 2025  
**Auteur:** Documentation du projet SAS Bénévolat

---

## Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Prérequis et Configuration](#prérequis-et-configuration)
3. [Architecture de l'Application](#architecture-de-lapplication)
4. [Connexion aux Sources de Données](#connexion-aux-sources-de-données)
5. [Développement Écran par Écran](#développement-écran-par-écran)
6. [Formules Power Fx Essentielles](#formules-power-fx-essentielles)
7. [Design et Composants Réutilisables](#design-et-composants-réutilisables)
8. [Tests et Déploiement](#tests-et-déploiement)
9. [Maintenance et Évolutions](#maintenance-et-évolutions)

---

## Vue d'ensemble

### Objectif de l'Application

Créer une application Canvas Power Apps pour permettre aux coordinateurs de gérer efficacement :
- Les profils de 200+ bénévoles (coordonnées, compétences, disponibilités)
- Les missions (activités récurrentes et événements ponctuels)
- Les affectations bénévoles ↔ missions
- Les bénéficiaires et les prestations qui leur sont dédiées

### Caractéristiques Techniques

- **Type:** Application Canvas (format Tablette)
- **Stockage:** SharePoint Online (7 listes)
- **Authentification:** Microsoft 365 (Azure AD)
- **Utilisateurs cibles:** Coordinateurs et administrateurs uniquement
- **Mode:** En ligne (connexion internet requise)

---

## Prérequis et Configuration

### Accès Requis

1. **Licence Power Apps** : Premium (pour connecteurs SharePoint)
2. **Permissions SharePoint** : Contributeur ou Propriétaire sur le site
3. **URL du site** : `https://serrentino.sharepoint.com/sites/GestionBenevoles`

### Environnement

1. Connectez-vous à [make.powerapps.com](https://make.powerapps.com)
2. Sélectionnez votre environnement (Production ou Développement)
3. Vérifiez l'accès au site SharePoint

---

## Architecture de l'Application

### Structure des Écrans

```
App Gestion Bénévoles
│
├── 📱 Écran_Splash (Chargement initial)
├── 🏠 Écran_Accueil (Tableau de bord)
│
├── 👥 Module Bénévoles
│   ├── Écran_Benevoles_Liste
│   ├── Écran_Benevoles_Detail
│   ├── Écran_Benevoles_Formulaire (Création/Modification)
│   └── Écran_Benevoles_Disponibilites
│
├── 📋 Module Missions
│   ├── Écran_Missions_Liste
│   ├── Écran_Missions_Detail
│   ├── Écran_Missions_Formulaire
│   └── Écran_Missions_Calendrier
│
├── 🔗 Module Affectations
│   ├── Écran_Affectations_Liste
│   └── Écran_Affectations_Nouvelle
│
└── 🎯 Module Bénéficiaires
    ├── Écran_Beneficiaires_Liste
    ├── Écran_Beneficiaires_Detail
    └── Écran_Prestations_Suivi
```

### Navigation

```
Splash → Accueil → [Modules principaux]
                ↓
         Menu latéral persistant
```

### Ordre de Création des Écrans (Recommandé)

Suivez cet ordre pour un développement progressif avec tests à chaque étape :

#### Phase 1 : Fondations (2 écrans)
| # | Écran | Objectif |
|---|-------|----------|
| 1 | `Écran_Splash` | Timer + redirection |
| 2 | `Écran_Accueil` | KPIs + connexion SharePoint |

**✅ Test Phase 1 :** Lancer l'app → le splash redirige vers Accueil → les KPIs affichent des valeurs depuis SharePoint.

---

#### Phase 2 : Module Bénévoles (3 écrans)
| # | Écran | Objectif |
|---|-------|----------|
| 3 | `Écran_Benevoles_Liste` | Galerie + recherche + filtres |
| 4 | `Écran_Benevoles_Detail` | Visualisation complète |
| 5 | `Écran_Benevoles_Formulaire` | Création / Modification |

**✅ Test Phase 2 :** Créer un bénévole → le voir dans la liste → ouvrir le détail → modifier → vérifier les changements.

---

#### Phase 3 : Module Missions (2 écrans minimum)
| # | Écran | Objectif |
|---|-------|----------|
| 6 | `Écran_Missions_Liste` | Galerie avec filtres type/statut |
| 7 | `Écran_Missions_Detail` | Visualisation + bénévoles affectés |

**✅ Test Phase 3 :** Parcourir les missions → filtrer par type → voir le détail d'une mission.

---

#### Phase 4 : Module Affectations (2 écrans)
| # | Écran | Objectif |
|---|-------|----------|
| 8 | `Écran_Affectations_Liste` | Vue des affectations existantes |
| 9 | `Écran_Affectations_Nouvelle` | Lier bénévole ↔ mission |

**✅ Test Phase 4 :** Créer une affectation → vérifier qu'elle apparaît dans le détail du bénévole ET de la mission.

---

#### Phase 5 : Module Bénéficiaires + Prestations (5 écrans)
| # | Écran | Objectif |
|---|-------|----------|
| 10 | `Écran_Beneficiaires_Liste` | Galerie + recherche |
| 11 | `Écran_Beneficiaires_Detail` | Info + prestations actives |
| 12 | `Écran_Beneficiaires_Formulaire` | Création / Modification |
| 13 | `Écran_Prestations_Nouvelle` | Lier bénéficiaire ↔ mission |
| 14 | `Écran_Prestations_Suivi` | Tableau de bord alertes |

**✅ Test Phase 5 :** Créer un bénéficiaire → ajouter une prestation → vérifier les alertes (>30j sans visite).

---

#### Phase 6 : Finalisation Navigation
| # | Écran | Objectif |
|---|-------|----------|
| 15 | `Gallery_Menu` sur `Écran_Accueil` | Navigation complète |

**✅ Test Final :** Depuis l'Accueil, naviguer vers chaque module via le menu → retour fluide.

---

### Checklist Globale

```
[ ] Phase 1 : Splash + Accueil fonctionnels
[ ] Phase 2 : CRUD Bénévoles complet
[ ] Phase 3 : Consultation Missions
[ ] Phase 4 : Affectations Bénévole ↔ Mission
[ ] Phase 5 : Bénéficiaires + Prestations + Alertes
[ ] Phase 6 : Navigation Menu finalisée
[ ] Publication et partage
```

---

## Connexion aux Sources de Données

### Étape 1 : Créer l'Application

1. Dans Power Apps Studio, cliquez sur **+ Créer**
2. Sélectionnez **Application canevas**
3. Choisissez **Format Tablette**
4. Nommez l'application : `App Gestion Bénévoles`

### Étape 2 : Ajouter les Connexions SharePoint

1. Dans le volet gauche, cliquez sur **Données** (icône cylindre)
2. Cliquez sur **+ Ajouter des données**
3. Recherchez et sélectionnez **SharePoint**
4. Choisissez **Se connecter directement**
5. Entrez l'URL : `https://serrentino.sharepoint.com/sites/GestionBenevoles`
6. Sélectionnez TOUTES les listes :
   - ☑️ Benevoles
   - ☑️ Missions
   - ☑️ Affectations
   - ☑️ Disponibilites
   - ☑️ Beneficiaires
   - ☑️ Prestations
   - ☑️ DocumentsBenevoles
7. Cliquez sur **Connecter**

### Étape 3 : Vérifier les Connexions

Les sources de données apparaissent maintenant dans le volet **Données**. Vous pouvez explorer leur structure en cliquant sur chacune.

---

## Développement Écran par Écran

### 1. Écran Splash (Chargement)

**Objectif :** Afficher un logo pendant le chargement des données

#### Composants :
- **Image_Logo** : Logo de l'organisation
- **Label_Chargement** : "Chargement en cours..."
- **Timer_Redirect** : Redirection automatique

#### Propriété OnVisible de l'Écran :
```powerfx
// Initialisation des variables globales
Set(varUtilisateur, User());
Set(varDateDuJour, Today());
```

#### Timer_Redirect (Durée : 2000ms, Auto-start : true) :
```powerfx
// Propriété OnTimerEnd
Navigate(Écran_Accueil, ScreenTransition.Fade);
```

---

### 2. Écran Accueil (Tableau de Bord)

**Objectif :** Vue d'ensemble avec KPIs et navigation rapide

#### Composants Principaux :

##### A. En-tête (Container_Header)
```powerfx
// Rectangle de fond avec couleur principale
Fill: ColorValue("#0078D4")
```

**Label_Titre :**
```powerfx
Text: "Gestion des Bénévoles - SASL"
Font: Open Sans
Size: 24
Color: White
```

**Label_Date :**
```powerfx
Text: Concatenate("Aujourd'hui : "; Text(Today(); "dddd dd mmmm yyyy"; "fr-FR"))
Size: 14
Color: White
```

##### B. Section KPIs (4 Cartes)

**Carte 1 - Bénévoles Actifs :**
```powerfx
// Label_KPI1_Titre
Text: "Bénévoles Actifs"

// Label_KPI1_Valeur
Text: CountRows(Filter(Benevoles; Statut.Value = "Actif"))
Font: Segoe UI (Bold)
Size: 36
Color: ColorValue("#107C10")
```

**Carte 2 - Missions en Cours :**
```powerfx
// Label_KPI2_Valeur
Text: CountRows(Filter(Missions; StatutMission.Value = "En cours"))
Color: ColorValue("#0078d4ff")
```

**Carte 3 - Affectations du Mois :**
```powerfx
// Label_KPI3_Valeur
Text: CountRows(
    Filter(
        Affectations;
        Month(DateProposition) = Month(varDateDuJour) &&
        Year(DateProposition) = Year(varDateDuJour)
    )
)
Color: ColorValue("#8764B8")
```

**Carte 4 - Bénéficiaires Suivis :**
```powerfx
// Label_KPI4_Valeur
Text: CountRows(Filter(Beneficiaires; StatutBnf.Value = "Actif"))
Color: ColorValue("#CA5010")
```

##### C. Menu de Navigation (Gallery_Menu)

```powerfx
// Propriété Items
Table(
    {Icone: "👥"; Titre: "Bénévoles"; Ecran: 'Écran_Benevoles_Liste'; Couleur: "#0078D4"};
    {Icone: "📋"; Titre: "Missions"; Ecran: 'Écran_Missions_Liste'; Couleur: "#107C10"};
    {Icone: "🔗"; Titre: "Affectations"; Ecran: 'Écran_Affectations_Liste'; Couleur: "#8764B8"};
    {Icone: "🎯"; Titre: "Bénéficiaires"; Ecran: 'Écran_Beneficiaires_Liste'; Couleur: "#CA5010"}
)

// Label_Icone (dans la galerie)
Text: ThisItem.Icone
Size: 48

// Label_Titre (dans la galerie)
Text: ThisItem.Titre
Size: 18

// Rectangle de fond (dans la galerie)
Fill: ColorValue(ThisItem.Couleur)
OnSelect: Navigate(ThisItem.Ecran; ScreenTransition.Cover)
```

#### Étapes détaillées d'implémentation (Gallery_Menu)

1. Insérer la galerie de menu
     - Onglet Insérer → Galerie → Horizontal (ou Vertical)
     - Renommez-la `Gallery_Menu`
     - Définissez `TemplateSize` selon votre design (ex. 120)

2. Définir la source `Items`
     - Option statique (recommandée au départ) :
         ```powerfx
         Table(
                 {Icone: "👥"; Titre: "Bénévoles"; Ecran: 'Écran_Benevoles_Liste'; Couleur: "#0078D4"};
                 {Icone: "📋"; Titre: "Missions"; Ecran: 'Écran_Missions_Liste'; Couleur: "#107C10"};
                 {Icone: "🔗"; Titre: "Affectations"; Ecran: 'Écran_Affectations_Liste'; Couleur: "#8764B8"};
                 {Icone: "🎯"; Titre: "Bénéficiaires"; Ecran: 'Écran_Beneficiaires_Liste'; Couleur: "#CA5010"}
         )
         ```
     - Remarques:
         - Locale FR: utilisez des points-virgules `;` entre les arguments et les paires clé/valeur.
         - Écrans: entourez les noms d’écrans avec des quotes si le nom contient des espaces ou des caractères spéciaux (ex. `'Écran_Benevoles_Liste'`).

3. Ajouter les contrôles dans le template de la galerie
     - `Label_Icone`
         ```powerfx
         Text: ThisItem.Icone
         Size: 48
         ```
     - `Label_Titre`
         ```powerfx
         Text: ThisItem.Titre
         Size: 18
         ```
     - `Rectangle_Fond`
         ```powerfx
         Fill: ColorValue(ThisItem.Couleur)
         ```

4. Navigation au clic
     - Sur le `Rectangle_Fond` ou le template de la galerie:
         ```powerfx
         OnSelect: Navigate(ThisItem.Ecran; ScreenTransition.Cover)
         ```

5. États visuels (sélection/survol)
     - Mettre en évidence l’élément sélectionné:
         ```powerfx
         TemplateFill: If(
                 ThisItem.IsSelected;
                 ColorFade(ColorValue(ThisItem.Couleur); 80%);
                 RGBA(243; 242; 241; 1)
         )
         ```

6. Tests rapides
     - Appuyez sur `Alt` et cliquez sur chaque carte du menu → vérifiez la navigation vers l’écran attendu.

7. Dépannage courant
     - « Le nom de l’écran n’existe pas » → ouvrez l’arborescence et copiez le nom exact de votre écran, remplacez dans la table.
     - « Séparateur d’arguments invalide » → vérifiez que vous utilisez des `;` (locale FR) et non des `,`.
     - « Contrôle introuvable » → renommez vos contrôles conforme aux exemples ou adaptez les formules.

8. Variante dynamique (collection)
     - Si vous préférez alimenter la galerie via une collection (modifiable à chaud), initialisez-la au démarrage:
         ```powerfx
         // App.OnStart ou Écran_Accueil.OnVisible
         ClearCollect(
                 colMenu;
                 {Icone: "👥"; Titre: "Bénévoles"; Ecran: 'Écran_Benevoles_Liste'; Couleur: ColorValue("#0078D4")};
                 {Icone: "📋"; Titre: "Missions"; Ecran: 'Écran_Missions_Liste'; Couleur: ColorValue("#107C10")};
                 {Icone: "🔗"; Titre: "Affectations"; Ecran: 'Écran_Affectations_Liste'; Couleur: ColorValue("#8764B8")};
                 {Icone: "🎯"; Titre: "Bénéficiaires"; Ecran: 'Écran_Beneficiaires_Liste'; Couleur: ColorValue("#CA5010")}
         );
         ```
     - Puis définissez `Gallery_Menu.Items` sur:
         ```powerfx
         colMenu
         ```

9. Bonnes pratiques
     - Centralisez les couleurs dans des variables globales (ex. `Set(varColorPrimary; ColorValue("#0078D4"))`).
     - Préférez les noms d’écrans sans accents/espaces pour éviter d’avoir à les entourer de quotes.


---

### 3. Écran Liste Bénévoles

**Objectif :** Afficher, rechercher et filtrer les bénévoles

#### A. Barre de Recherche et Filtres

**TextInput_Recherche :**
```powerfx
HintText: "Rechercher par nom, prénom ou email..."
```

**Dropdown_StatutFiltre :**
```powerfx
Items: Distinct(Benevoles, Statut.Value)
DefaultSelectedItems: Blank()
```

**Dropdown_CompetenceFiltre :**
```powerfx
Items: ["Accueil", "Animation", "Bricolage", "Comptabilité", "Conduite", 
        "Cuisine", "Informatique", "Jardinage", "Langues étrangères", 
        "Musique", "Secrétariat", "Soins", "Sport", "Autre"]
```

#### B. Galerie Bénévoles

```powerfx
// Gallery_Benevoles - Propriété Items
SortByColumns(
    Search(
        Filter(
            colBenevoles,
            // Filtre par statut
            (IsBlank(Dropdown_StatutFiltre.Selected) || 
             Statut.Value = Dropdown_StatutFiltre.Selected.Value) &&
            // Filtre par compétence
            (IsBlank(Dropdown_CompetenceFiltre.Selected) || 
             Dropdown_CompetenceFiltre.Selected.Value in Competences)
        ),
        TextInput_Recherche.Text,
        "Nom", "Prenom", "EmailBenevole", "Telephone"
    ),
    "Nom",
    SortOrder.Ascending
)

// Layout : Vertical, hauteur : 100px
```

#### C. Contenu de la Galerie (Template)

**Label_NomComplet :**
```powerfx
Text: ThisItem.Prenom & " " & ThisItem.Nom
FontWeight: FontWeight.Semibold
Size: 16
```

**Label_Email :**
```powerfx
Text: ThisItem.EmailBenevole
Color: RGBA(0, 0, 0, 0.6)
Size: 12
```

**Label_Telephone :**
```powerfx
Text: If(
    !IsBlank(ThisItem.TelephoneMobile),
    ThisItem.TelephoneMobile,
    ThisItem.Telephone
)
```

**Label_Competences :**
```powerfx
Text: Concat(ThisItem.Competences, Value, ", ")
Color: RGBA(0, 120, 212, 1)
Size: 11
```

**Badge_Statut (Rectangle + Label) :**
```powerfx
// Rectangle
Fill: Switch(
    ThisItem.Statut.Value,
    "Actif", ColorValue("#107C10"),
    "Inactif", ColorValue("#A19F9D"),
    "Suspendu", ColorValue("#D83B01"),
    "En attente", ColorValue("#FFB900"),
    ColorValue("#605E5C")
)

// Label
Text: ThisItem.Statut.Value
Color: White
```

**Icon_Details (Flèche) :**
```powerfx
Icon: Icon.ChevronRight
OnSelect: Navigate(Écran_Benevoles_Detail, ScreenTransition.Cover)
```

#### D. Bouton Nouveau Bénévole

```powerfx
// Button_NouveauBenevole
Text: "+ Nouveau Bénévole"
OnSelect: 
    Set(varBenevoleSelectionne, Defaults(Benevoles));
    Set(varModeFormulaire, "Nouveau");
    Navigate(Écran_Benevoles_Formulaire, ScreenTransition.Cover);
```

---

### 4. Écran Détail Bénévole

**Objectif :** Afficher toutes les informations d'un bénévole

#### A. Formulaire de Visualisation

```powerfx
// Form_BenevoleDetail
DataSource: Benevoles
Item: Gallery_Benevoles.Selected
DefaultMode: FormMode.View

// Cartes à afficher (dans l'ordre) :
- NumeroBenevole
- Prenom, Nom
- Civilite
- EmailBenevole, Telephone, TelephoneMobile
- DateNaissance
- Adresse1, Adresse2, NPA, Ville
- Langues
- Competences
- Statut
- DateEntree
- RGPDConsentement
- NotesGenerales
```

#### B. Onglets (TabList)

**Tab 1 - Informations Générales** : Formulaire ci-dessus

**Tab 2 - Affectations :**
```powerfx
// Gallery_AffectationsBenevole
Items: SortByColumns(
    Filter(
        Affectations,
        BenevoleID.Id = Gallery_Benevoles.Selected.ID
    ),
    "DateProposition",
    SortOrder.Descending
)

// Contenu : Titre mission, dates, statut
```

**Tab 3 - Disponibilités :**
```powerfx
// Gallery_DisponibilitesBenevole
Items: Filter(
    Disponibilites,
    BenevoleID.Id = Gallery_Benevoles.Selected.ID
)
```

#### C. Boutons d'Action

**Button_Modifier :**
```powerfx
Text: "✏️ Modifier"
OnSelect: 
    Set(varBenevoleSelectionne, Gallery_Benevoles.Selected);
    Set(varModeFormulaire, "Modifier");
    Navigate(Écran_Benevoles_Formulaire, ScreenTransition.Cover);
```

**Button_Contacter :**
```powerfx
Text: "✉️ Envoyer Email"
OnSelect: 
    Launch("mailto:" & Gallery_Benevoles.Selected.EmailBenevole & 
           "?subject=Contact SAS Bénévolat");
```

**Button_NouvelleAffectation :**
```powerfx
Text: "➕ Nouvelle Affectation"
OnSelect: 
    Set(varBenevolePreselectionne, Gallery_Benevoles.Selected);
    Navigate(Écran_Affectations_Nouvelle, ScreenTransition.Cover);
```

---

### 5. Écran Formulaire Bénévole

**Objectif :** Créer ou modifier un bénévole

#### Configuration du Formulaire

```powerfx
// Form_BenevoleEdit
DataSource: Benevoles
Item: varBenevoleSelectionne
DefaultMode: If(varModeFormulaire = "Nouveau", FormMode.New, FormMode.Edit)

OnSuccess: 
    Notify("Bénévole enregistré avec succès !", NotificationType.Success);
    Navigate(Écran_Benevoles_Liste, ScreenTransition.UnCover);

OnFailure:
    Notify("Erreur lors de l'enregistrement : " & Form_BenevoleEdit.Error, 
           NotificationType.Error);
```

#### Cartes Personnalisées

**Carte NumeroBenevole :**
```powerfx
// Générer automatiquement si nouveau
Default: If(
    varModeFormulaire = "Nouveau",
    "BEN-" & Text(CountRows(Benevoles) + 1, "00000"),
    Parent.Default
)
DisplayMode: DisplayMode.View  // Lecture seule
```

**Carte Civilite (Dropdown) :**
```powerfx
Items: ["M.", "Mme", "Autre"]
```

**Carte Statut (Dropdown) :**
```powerfx
Items: ["Actif", "Inactif", "Suspendu", "En attente"]
Default: "En attente"
```

**Carte Competences (ComboBox) :**
```powerfx
Items: ["Accompagnement social", "Animation d'ateliers", "Bricolage / Réparations",
        "Communication / Rédaction", "Conduite / Transport", "Conseil juridique",
        "Cuisine / Restauration", "Informatique / Numérique", "Jardinage",
        "Logistique / Organisation", "Santé / Soins", "Soutien administratif",
        "Traduction", "Autre"]
SelectMultiple: true
```

**Carte DateEntree :**
```powerfx
Default: If(varModeFormulaire = "Nouveau", Today(), Parent.Default)
```

**Carte RGPDConsentement (Toggle) :**
```powerfx
Default: false
TrueText: "Oui"
FalseText: "Non"
```

#### Boutons de Contrôle

**Button_Enregistrer :**
```powerfx
Text: "💾 Enregistrer"
OnSelect: SubmitForm(Form_BenevoleEdit)
DisplayMode: If(Form_BenevoleEdit.Valid, DisplayMode.Edit, DisplayMode.Disabled)
```

**Button_Annuler :**
```powerfx
Text: "❌ Annuler"
OnSelect: 
    ResetForm(Form_BenevoleEdit);
    Navigate(Écran_Benevoles_Liste, ScreenTransition.UnCover);
```

---

### 6. Écran Liste Missions

**Objectif :** Gérer les missions (activités et événements)

#### A. Filtres

**Toggle_TypeMission :**
```powerfx
TrueText: "Activités Récurrentes"
FalseText: "Événements Ponctuels"
```

**Dropdown_StatutMission :**
```powerfx
Items: ["Brouillon", "Planifiée", "En cours", "Clôturée", "Annulée"]
```

#### B. Galerie Missions

```powerfx
// Gallery_Missions - Items
SortByColumns(
    Filter(
        colMissions,
        // Filtre par type
        (Toggle_TypeMission.Value && TypeMission.Value = "Récurrente") ||
        (!Toggle_TypeMission.Value && TypeMission.Value = "Ponctuelle") &&
        // Filtre par statut
        (IsBlank(Dropdown_StatutMission.Selected) || 
         StatutMission.Value = Dropdown_StatutMission.Selected.Value)
    ),
    "DateDebut",
    SortOrder.Descending
)
```

#### C. Template Galerie

**Label_TitreMission :**
```powerfx
Text: ThisItem.Title
FontWeight: FontWeight.Bold
Size: 16
```

**Label_TypeMission :**
```powerfx
Text: "🔄 " & ThisItem.TypeMission.Value
Color: If(
    ThisItem.TypeMission.Value = "Récurrente",
    ColorValue("#0078D4"),
    ColorValue("#107C10")
)
```

**Label_Dates :**
```powerfx
Text: If(
    !IsBlank(ThisItem.DateDebut) && !IsBlank(ThisItem.DateFin),
    Text(ThisItem.DateDebut, "dd/mm/yyyy") & " → " & Text(ThisItem.DateFin, "dd/mm/yyyy"),
    If(!IsBlank(ThisItem.DateDebut), Text(ThisItem.DateDebut, "dd/mm/yyyy"), "Date non définie")
)
```

**Label_NombreBenevoles :**
```powerfx
Text: "👥 " & 
      CountRows(Filter(Affectations, MissionID.Id = ThisItem.ID)) & 
      " / " & 
      If(IsBlank(ThisItem.NombreBenevoles), "∞", Text(ThisItem.NombreBenevoles))
```

**Badge_Priorite :**
```powerfx
// Rectangle
Fill: Switch(
    ThisItem.Priorite.Value,
    "Critique", ColorValue("#D83B01"),
    "Haute", ColorValue("#CA5010"),
    "Moyenne", ColorValue("#FFB900"),
    "Faible", ColorValue("#107C10"),
    ColorValue("#605E5C")
)

// Label
Text: ThisItem.Priorite.Value
```

---

### 7. Écran Nouvelle Affectation

**Objectif :** Lier un bénévole à une mission

#### A. Sélection Bénévole

```powerfx
// ComboBox_Benevole
Items: SortByColumns(
    Filter(colBenevoles, Statut.Value = "Actif"),
    "Nom",
    Ascending
)
DisplayFields: ["Nom", "Prenom"]
SearchFields: ["Nom", "Prenom", "EmailBenevole"]
DefaultSelectedItems: If(
    !IsBlank(varBenevolePreselectionne),
    varBenevolePreselectionne,
    Blank()
)
```

#### B. Sélection Mission

```powerfx
// ComboBox_Mission
Items: SortByColumns(
    Filter(
        colMissions,
        StatutMission.Value in ["Planifiée", "En cours"]
    ),
    "DateDebut",
    Descending
)
DisplayFields: ["Title"]
SearchFields: ["Title", "DescriptionMission"]
```

#### C. Informations Complémentaires

**DatePicker_DateProposition :**
```powerfx
DefaultDate: Today()
```

**Dropdown_StatutAffectation :**
```powerfx
Items: ["En attente", "Confirmée", "Refusée", "Annulée"]
Default: "En attente"
```

**TextInput_PlageHoraire1, PlageHoraire2 :**
```powerfx
HintText: "Ex: Lundi 14h-17h"
```

**TextInput_Commentaire :**
```powerfx
Mode: TextMode.MultiLine
HintText: "Informations complémentaires..."
```

#### D. Bouton de Validation

```powerfx
// Button_CreerAffectation
Text: "✅ Créer l'Affectation"
OnSelect:
    // Vérifications
    If(
        IsBlank(ComboBox_Benevole.Selected) || IsBlank(ComboBox_Mission.Selected),
        Notify("Veuillez sélectionner un bénévole et une mission", NotificationType.Warning),
        
        // Vérifier si affectation existe déjà
        If(
            CountRows(
                Filter(
                    Affectations,
                    BenevoleID.Id = ComboBox_Benevole.Selected.ID &&
                    MissionID.Id = ComboBox_Mission.Selected.ID
                )
            ) > 0,
            Notify("Cette affectation existe déjà !", NotificationType.Error),
            
            // Créer l'affectation
            Patch(
                Affectations,
                Defaults(Affectations),
                {
                    Title: "Affectation - " & ComboBox_Benevole.Selected.Nom & " - " & ComboBox_Mission.Selected.Title,
                    BenevoleID: ComboBox_Benevole.Selected,
                    MissionID: ComboBox_Mission.Selected,
                    DateProposition: DatePicker_DateProposition.SelectedDate,
                    StatutAffectation: {Value: Dropdown_StatutAffectation.Selected.Value},
                    PlageHoraire1: TextInput_PlageHoraire1.Text,
                    PlageHoraire2: TextInput_PlageHoraire2.Text,
                    Commentaire: TextInput_Commentaire.Text
                }
            );
            Notify("Affectation créée avec succès !", NotificationType.Success);
            
            // Réinitialiser et retourner
            Reset(ComboBox_Benevole);
            Reset(ComboBox_Mission);
            Reset(DatePicker_DateProposition);
            Reset(TextInput_PlageHoraire1);
            Reset(TextInput_PlageHoraire2);
            Reset(TextInput_Commentaire);
            Navigate(Écran_Affectations_Liste, ScreenTransition.UnCover);
        )
    );

DisplayMode: If(
    IsBlank(ComboBox_Benevole.Selected) || IsBlank(ComboBox_Mission.Selected),
    DisplayMode.Disabled,
    DisplayMode.Edit
)
```

---

### 8. Écran Liste Bénéficiaires

**Objectif :** Gérer les bénéficiaires (personnes recevant des prestations)

#### A. Barre de Recherche et Filtres

**TextInput_RechercheBeneficiaire :**
```powerfx
HintText: "Rechercher par nom, prénom ou NPA..."
```

**Dropdown_StatutBeneficiaire :**
```powerfx
Items: Distinct(Beneficiaires, StatutBnf.Value)
DefaultSelectedItems: Blank()
```

**Dropdown_TypeBesoins :**
```powerfx
Items: ["Accompagnement social", "Aide alimentaire", "Soutien scolaire", 
        "Aide administrative", "Visite de courtoisie", "Transport", "Autre"]
```

#### B. Galerie Bénéficiaires

```powerfx
// Gallery_Beneficiaires - Propriété Items
SortByColumns(
    Search(
        Filter(
            Beneficiaires,
            // Filtre par statut
            (IsBlank(Dropdown_StatutBeneficiaire.Selected) || 
             StatutBnf.Value = Dropdown_StatutBeneficiaire.Selected.Value) &&
            // Filtre par besoin
            (IsBlank(Dropdown_TypeBesoins.Selected) || 
             Dropdown_TypeBesoins.Selected.Value in Split(Besoins, ","))
        ),
        TextInput_RechercheBeneficiaire.Text,
        "NomBnf", "PrenomBnf", "VilleBnf", "NPABnf"
    ),
    "NomBnf",
    SortOrder.Ascending
)

// Layout : Vertical, hauteur : 120px
```

#### C. Contenu de la Galerie (Template)

**Label_NomCompletBnf :**
```powerfx
Text: ThisItem.CiviliteBnf & " " & ThisItem.PrenomBnf & " " & ThisItem.NomBnf
FontWeight: FontWeight.Semibold
Size: 16
```

**Label_AdresseBnf :**
```powerfx
Text: If(
    !IsBlank(ThisItem.Adresse1Bnf),
    ThisItem.Adresse1Bnf & ", " & ThisItem.NPABnf & " " & ThisItem.VilleBnf,
    ThisItem.NPABnf & " " & ThisItem.VilleBnf
)
Color: RGBA(0, 0, 0, 0.6)
Size: 12
```

**Label_ContactBnf :**
```powerfx
Text: If(
    !IsBlank(ThisItem.TelephoneBnf),
    "☎️ " & ThisItem.TelephoneBnf,
    If(!IsBlank(ThisItem.EmailBnf), "✉️ " & ThisItem.EmailBnf, "Pas de contact")
)
Size: 11
```

**Label_Besoins :**
```powerfx
Text: "Besoins : " & Left(ThisItem.Besoins, 50) & If(Len(ThisItem.Besoins) > 50, "...", "")
Color: RGBA(202, 80, 16, 1)
Size: 11
FontWeight: FontWeight.Semibold
```

**Label_NombrePrestations :**
```powerfx
Text: "📊 " & CountRows(
    Filter(Prestations, BeneficiaireID.Id = ThisItem.ID)
) & " prestation(s) active(s)"
Color: RGBA(0, 120, 212, 1)
```

**Badge_StatutBnf (Rectangle + Label) :**
```powerfx
// Rectangle
Fill: Switch(
    ThisItem.StatutBnf.Value,
    "Actif", ColorValue("#107C10"),
    "Inactif", ColorValue("#A19F9D"),
    "En attente", ColorValue("#FFB900"),
    "Clôturé", ColorValue("#605E5C"),
    ColorValue("#D83B01")
)

// Label
Text: ThisItem.StatutBnf.Value
Color: White
Size: 11
```

**Icon_DetailsBnf (Flèche) :**
```powerfx
Icon: Icon.ChevronRight
OnSelect: Navigate(Écran_Beneficiaires_Detail, ScreenTransition.Cover)
```

#### D. Bouton Nouveau Bénéficiaire

```powerfx
// Button_NouveauBeneficiaire
Text: "+ Nouveau Bénéficiaire"
Fill: ColorValue("#CA5010")
OnSelect: 
    Set(varBeneficiaireSelectionne, Defaults(Beneficiaires));
    Set(varModeFormulaireBnf, "Nouveau");
    Navigate(Écran_Beneficiaires_Formulaire, ScreenTransition.Cover);
```

---

### 9. Écran Détail Bénéficiaire

**Objectif :** Visualiser les informations complètes et les prestations d'un bénéficiaire

#### A. En-tête avec Informations Clés

**Container_HeaderBeneficiaire (Rectangle + Labels) :**
```powerfx
// Rectangle de fond
Fill: ColorFade(ColorValue("#CA5010"), 90%)

// Label_NomComplet
Text: Gallery_Beneficiaires.Selected.CiviliteBnf & " " & 
      Gallery_Beneficiaires.Selected.PrenomBnf & " " & 
      Gallery_Beneficiaires.Selected.NomBnf
Size: 22
FontWeight: FontWeight.Bold

// Label_NumeroBeneficiaire
Text: Gallery_Beneficiaires.Selected.NumeroBeneficiaire
Size: 14
Color: RGBA(0, 0, 0, 0.6)
```

#### B. Formulaire de Visualisation

```powerfx
// Form_BeneficiaireDetail
DataSource: Beneficiaires
Item: Gallery_Beneficiaires.Selected
DefaultMode: FormMode.View

// Cartes à afficher :
- NumeroBeneficiaire
- CiviliteBnf, PrenomBnf, NomBnf
- Adresse1Bnf, Adresse2Bnf, NPABnf, VilleBnf
- TelephoneBnf, EmailBnf
- DateDebutBnf (Date de début du suivi)
- Besoins (Zone de texte multi-ligne)
- Referent (Travailleur social référent)
- Horaires (Disponibilités du bénéficiaire)
- StatutBnf
- RGPDConsentementBnf
- HistoriqueBnf
```

#### C. Section Prestations Actives

**Gallery_PrestationsBeneficiaire :**
```powerfx
Items: SortByColumns(
    Filter(
        Prestations,
        BeneficiaireID.Id = Gallery_Beneficiaires.Selected.ID
    ),
    "DateDebutPrestation",
    SortOrder.Descending
)

// Template galerie :

// Label_MissionPrestation
Text: ThisItem.MissionIDPrestation.Title
FontWeight: FontWeight.Semibold
Size: 14

// Label_FrequencePrestation
Text: "🔄 " & ThisItem.FrequencePrestation
Color: RGBA(0, 120, 212, 1)

// Label_DateDebut
Text: "Depuis le " & Text(ThisItem.DateDebutPrestation, "dd/mm/yyyy")
Size: 12

// Label_DerniereVisite
Text: "Dernière visite : " & If(
    !IsBlank(ThisItem.DerniereVisite),
    Text(ThisItem.DerniereVisite, "dd/mm/yyyy"),
    "Aucune"
)
Color: RGBA(0, 0, 0, 0.6)

// Badge_StatutPrestation
Text: ThisItem.StatutPrestation
Fill: Switch(
    ThisItem.StatutPrestation,
    "En_cours", ColorValue("#107C10"),
    "Terminee", ColorValue("#605E5C"),
    "Suspendue", ColorValue("#FFB900"),
    ColorValue("#A19F9D")
)
```

#### D. Boutons d'Action

**Button_ModifierBeneficiaire :**
```powerfx
Text: "✏️ Modifier"
OnSelect: 
    Set(varBeneficiaireSelectionne, Gallery_Beneficiaires.Selected);
    Set(varModeFormulaireBnf, "Modifier");
    Navigate(Écran_Beneficiaires_Formulaire, ScreenTransition.Cover);
```

**Button_NouvellePrestation :**
```powerfx
Text: "➕ Nouvelle Prestation"
Fill: ColorValue("#107C10")
OnSelect: 
    Set(varBeneficiairePreselectionne, Gallery_Beneficiaires.Selected);
    Navigate(Écran_Prestations_Nouvelle, ScreenTransition.Cover);
```

**Button_ContactReferent :**
```powerfx
Text: "👤 Contacter Référent"
Visible: !IsBlank(Gallery_Beneficiaires.Selected.Referent)
OnSelect: 
    Notify("Contact référent : " & Gallery_Beneficiaires.Selected.Referent, 
           NotificationType.Information);
```

---

### 10. Écran Nouvelle Prestation

**Objectif :** Créer une prestation pour un bénéficiaire

#### A. Section Bénéficiaire

**ComboBox_Beneficiaire :**
```powerfx
Items: SortByColumns(
    Filter(Beneficiaires, StatutBnf.Value = "Actif"),
    "NomBnf",
    Ascending
)
DisplayFields: ["NomBnf", "PrenomBnf"]
SearchFields: ["NomBnf", "PrenomBnf", "VilleBnf"]
DefaultSelectedItems: If(
    !IsBlank(varBeneficiairePreselectionne),
    varBeneficiairePreselectionne,
    Blank()
)
```

**Card_InfoBeneficiaire (Visible si sélectionné) :**
```powerfx
// Visible
Visible: !IsBlank(ComboBox_Beneficiaire.Selected)

// Label_AdresseBeneficiaire
Text: "📍 " & ComboBox_Beneficiaire.Selected.Adresse1Bnf & 
      ", " & ComboBox_Beneficiaire.Selected.NPABnf & 
      " " & ComboBox_Beneficiaire.Selected.VilleBnf

// Label_BesoinsActuels
Text: "Besoins : " & ComboBox_Beneficiaire.Selected.Besoins
```

#### B. Sélection Mission/Activité

**ComboBox_MissionPrestation :**
```powerfx
Items: SortByColumns(
    Filter(
        colMissions,
        // Uniquement activités récurrentes adaptées aux prestations
        TypeMission.Value = "Récurrente" &&
        StatutMission.Value in ["Planifiée", "En cours"]
    ),
    "Title",
    Ascending
)
DisplayFields: ["Title"]
SearchFields: ["Title", "DescriptionMission"]
```

**Label_DescriptionMission (Visible si sélectionné) :**
```powerfx
Visible: !IsBlank(ComboBox_MissionPrestation.Selected)
Text: ComboBox_MissionPrestation.Selected.DescriptionMission
Color: RGBA(0, 0, 0, 0.6)
```

#### C. Configuration de la Prestation

**DatePicker_DateDebutPrestation :**
```powerfx
DefaultDate: Today()
```

**Dropdown_FrequencePrestation :**
```powerfx
Items: ["Hebdomadaire", "Bi-hebdomadaire", "Mensuelle", "Ponctuelle", "Sur demande"]
Default: "Hebdomadaire"
```

**Dropdown_StatutPrestation :**
```powerfx
Items: ["En_cours", "Terminee", "Suspendue"]
Default: "En_cours"
```

**DatePicker_DerniereVisite :**
```powerfx
DefaultDate: Today()
```

**TextInput_NotesPrestation :**
```powerfx
Mode: TextMode.MultiLine
HintText: "Notes ou observations sur cette prestation..."
Height: 120
```

#### D. Validation et Création

**Button_CreerPrestation :**
```powerfx
Text: "✅ Créer la Prestation"
Fill: ColorValue("#107C10")

OnSelect:
    // Vérifications
    If(
        IsBlank(ComboBox_Beneficiaire.Selected) || 
        IsBlank(ComboBox_MissionPrestation.Selected),
        Notify("Veuillez sélectionner un bénéficiaire et une mission", 
               NotificationType.Warning),
        
        // Vérifier si prestation existe déjà
        If(
            CountRows(
                Filter(
                    Prestations,
                    BeneficiaireID.Id = ComboBox_Beneficiaire.Selected.ID &&
                    MissionIDPrestation.Id = ComboBox_MissionPrestation.Selected.ID &&
                    StatutPrestation in ["En_cours", "Suspendue"]
                )
            ) > 0,
            Notify("Une prestation active existe déjà pour ce bénéficiaire et cette mission !", 
                   NotificationType.Error),
            
            // Créer la prestation
            Patch(
                Prestations,
                Defaults(Prestations),
                {
                    Title: "Prestation - " & 
                           ComboBox_Beneficiaire.Selected.NomBnf & 
                           " - " & 
                           ComboBox_MissionPrestation.Selected.Title,
                    BeneficiaireID: ComboBox_Beneficiaire.Selected,
                    MissionIDPrestation: ComboBox_MissionPrestation.Selected,
                    DateDebutPrestation: DatePicker_DateDebutPrestation.SelectedDate,
                    FrequencePrestation: Dropdown_FrequencePrestation.Selected.Value,
                    StatutPrestation: Dropdown_StatutPrestation.Selected.Value,
                    DerniereVisite: DatePicker_DerniereVisite.SelectedDate
                }
            );
            Notify("Prestation créée avec succès !", NotificationType.Success);
            
            // Réinitialiser et retourner
            Reset(ComboBox_Beneficiaire);
            Reset(ComboBox_MissionPrestation);
            Reset(DatePicker_DateDebutPrestation);
            Reset(Dropdown_FrequencePrestation);
            Reset(TextInput_NotesPrestation);
            Navigate(Écran_Beneficiaires_Detail, ScreenTransition.UnCover);
        )
    );

DisplayMode: If(
    IsBlank(ComboBox_Beneficiaire.Selected) || 
    IsBlank(ComboBox_MissionPrestation.Selected),
    DisplayMode.Disabled,
    DisplayMode.Edit
)
```

**Button_Annuler :**
```powerfx
Text: "❌ Annuler"
OnSelect: Navigate(Écran_Beneficiaires_Liste, ScreenTransition.UnCover);
```

---

### 11. Écran Suivi Prestations (Tableau de Bord)

**Objectif :** Vue d'ensemble de toutes les prestations actives

#### A. Filtres et Recherche

**Dropdown_FiltreMission :**
```powerfx
Items: SortByColumns(
    Distinct(Prestations, MissionIDPrestation.Title),
    "Value",
    Ascending
)
```

**Dropdown_FiltreStatut :**
```powerfx
Items: ["En_cours", "Terminee", "Suspendue"]
```

**DatePicker_DerniereMiseAJour :**
```powerfx
// Pour filtrer par prestations avec visite avant cette date
DefaultDate: DateAdd(Today(), -30)  // 30 jours
```

#### B. Galerie Prestations avec Indicateurs

```powerfx
// Gallery_ToutesPrestations - Items
SortByColumns(
    Filter(
        Prestations,
        // Filtre par mission
        (IsBlank(Dropdown_FiltreMission.Selected) || 
         MissionIDPrestation.Title = Dropdown_FiltreMission.Selected.Value) &&
        // Filtre par statut
        (IsBlank(Dropdown_FiltreStatut.Selected) || 
         StatutPrestation = Dropdown_FiltreStatut.Selected.Value) &&
        // Prestations nécessitant attention (dernière visite > 30 jours)
        (Toggle_AlertesOnly.Value = false ||
         DateDiff(DerniereVisite, Today()) > 30)
    ),
    "DerniereVisite",
    SortOrder.Ascending
)
```

#### C. Template avec Alertes Visuelles

**Rectangle_Alerte (Fond coloré selon urgence) :**
```powerfx
Fill: If(
    DateDiff(ThisItem.DerniereVisite, Today()) > 60,
    ColorFade(ColorValue("#D83B01"), 80%),  // Rouge si > 60 jours
    If(
        DateDiff(ThisItem.DerniereVisite, Today()) > 30,
        ColorFade(ColorValue("#FFB900"), 80%),  // Jaune si > 30 jours
        ColorValue("#F3F2F1")  // Gris normal
    )
)
```

**Icon_Alerte :**
```powerfx
Icon: If(
    DateDiff(ThisItem.DerniereVisite, Today()) > 60,
    Icon.Warning,
    If(
        DateDiff(ThisItem.DerniereVisite, Today()) > 30,
        Icon.Warning,
        Icon.CheckMark
    )
)
Color: If(
    DateDiff(ThisItem.DerniereVisite, Today()) > 60,
    ColorValue("#D83B01"),
    If(
        DateDiff(ThisItem.DerniereVisite, Today()) > 30,
        ColorValue("#FFB900"),
        ColorValue("#107C10")
    )
)
```

**Label_BeneficiaireNom :**
```powerfx
Text: ThisItem.BeneficiaireID.PrenomBnf & " " & ThisItem.BeneficiaireID.NomBnf
FontWeight: FontWeight.Semibold
```

**Label_MissionTitre :**
```powerfx
Text: ThisItem.MissionIDPrestation.Title
```

**Label_DernierContact :**
```powerfx
Text: "Dernière visite : " & 
      Text(ThisItem.DerniereVisite, "dd/mm/yyyy") & 
      " (" & 
      DateDiff(ThisItem.DerniereVisite, Today()) & 
      " jours)"
Color: If(
    DateDiff(ThisItem.DerniereVisite, Today()) > 30,
    ColorValue("#D83B01"),
    RGBA(0, 0, 0, 0.6)
)
```

**Button_EnregistrerVisite :**
```powerfx
Text: "✓ Enregistrer visite"
OnSelect:
    Patch(
        Prestations,
        ThisItem,
        {DerniereVisite: Today()}
    );
    Notify("Visite enregistrée pour " & 
           ThisItem.BeneficiaireID.NomBnf, 
           NotificationType.Success);
```

#### D. Statistiques en En-tête

**Label_TotalPrestationsActives :**
```powerfx
Text: "Prestations actives : " & 
      CountRows(Filter(Prestations, StatutPrestation = "En_cours"))
```

**Label_AlertesUrgentes :**
```powerfx
Text: "⚠️ Alertes (>60j) : " & 
      CountRows(
          Filter(
              Prestations,
              StatutPrestation = "En_cours" &&
              DateDiff(DerniereVisite, Today()) > 60
          )
      )
Color: ColorValue("#D83B01")
FontWeight: FontWeight.Bold
```

**Label_ARevoir :**
```powerfx
Text: "⚡ À revoir (>30j) : " & 
      CountRows(
          Filter(
              Prestations,
              StatutPrestation = "En_cours" &&
              DateDiff(DerniereVisite, Today()) > 30 &&
              DateDiff(DerniereVisite, Today()) <= 60
          )
      )
Color: ColorValue("#FFB900")
```

---

## Formules Power Fx Essentielles

### Gestion des Dates

**Afficher une date avec format français :**
```powerfx
Text(ThisItem.DateDebut, "dddd dd mmmm yyyy", "fr-FR")
```

**Vérifier si une date est vide :**
```powerfx
If(IsBlank(ThisItem.DateNaissance), "Non renseignée", Text(ThisItem.DateNaissance, "dd/mm/yyyy"))
```

**Calculer l'âge :**
```powerfx
Year(Today()) - Year(ThisItem.DateNaissance)
```

**Filtrer par mois en cours :**
```powerfx
Filter(
    Affectations,
    Month(DateProposition) = Month(Today()) &&
    Year(DateProposition) = Year(Today())
)
```

### Manipulation de Texte

**Concaténer avec gestion des vides :**
```powerfx
Concatenate(
    ThisItem.Adresse1,
    If(!IsBlank(ThisItem.Adresse2), ", " & ThisItem.Adresse2, ""),
    ", ",
    ThisItem.NPA,
    " ",
    ThisItem.Ville
)
```

**Premier mot en majuscule :**
```powerfx
Proper(ThisItem.Nom)
```

**Initiales :**
```powerfx
Upper(Left(ThisItem.Prenom, 1) & Left(ThisItem.Nom, 1))
```

### Choix Multiples (MultiChoice)

**Afficher les choix séparés par des virgules :**
```powerfx
Concat(ThisItem.Competences, Value, ", ")
```

**Vérifier si un choix spécifique existe :**
```powerfx
"Informatique" in ThisItem.Competences
```

**Compter les choix sélectionnés :**
```powerfx
CountRows(ThisItem.Competences)
```

### Lookups

**Afficher le nom depuis une colonne lookup :**
```powerfx
ThisItem.BenevoleID.Nom & " " & ThisItem.BenevoleID.Prenom
```

**Filtrer par ID de lookup :**
```powerfx
Filter(Affectations, BenevoleID.Id = Gallery_Benevoles.Selected.ID)
```

### Couleurs Dynamiques

**Selon une valeur :**
```powerfx
Switch(
    ThisItem.Priorite.Value,
    "Critique", ColorValue("#D83B01"),
    "Haute", ColorValue("#CA5010"),
    "Moyenne", ColorValue("#FFB900"),
    "Faible", ColorValue("#107C10"),
    ColorValue("#605E5C")  // Défaut
)
```

**Avec transparence RGBA :**
```powerfx
RGBA(0, 120, 212, 0.1)  // Bleu avec 10% d'opacité
```

---

## Design et Composants Réutilisables

### Charte Graphique

**Palette de Couleurs :**
```
Primaire:   #0078D4 (Bleu Microsoft)
Succès:     #107C10 (Vert)
Attention:  #FFB900 (Jaune)
Erreur:     #D83B01 (Rouge)
Neutre:     #605E5C (Gris)
Fond:       #F3F2F1 (Gris clair)
Texte:      #323130 (Gris foncé)
```

**Typographie :**
- Titres: Segoe UI Bold, 20-24px
- Corps: Open Sans Regular, 14-16px
- Labels: Segoe UI Semibold, 12-14px

### Créer un Composant d'En-tête

1. Cliquez sur **Composants** dans le volet gauche
2. Créez un nouveau composant : `Header_Standard`
3. Ajoutez :
   - Rectangle (fond bleu)
   - Label Titre (propriété personnalisée)
   - Icon Retour (bouton)

**Propriété Personnalisée `TitreEcran` :**
```powerfx
// Type: Texte
// Valeur par défaut: "Titre"
```

**Utilisation dans un écran :**
```powerfx
// Insérer le composant
Header_Standard.TitreEcran = "Liste des Bénévoles"
```

### Créer un Composant Carte KPI

**Composant `Card_KPI` avec propriétés :**
- `Titre` (Texte)
- `Valeur` (Nombre)
- `Couleur` (Texte couleur hex)
- `Icone` (Texte emoji)

**Rectangle_Fond :**
```powerfx
Fill: ColorFade(ColorValue(Card_KPI.Couleur), 90%)
```

**Label_Valeur :**
```powerfx
Text: Text(Card_KPI.Valeur, "#,##0")
Color: ColorValue(Card_KPI.Couleur)
```

---

## Tests et Déploiement

### Tests à Effectuer

**Tests Fonctionnels :**
1. ✅ Créer un nouveau bénévole
2. ✅ Modifier un bénévole existant
3. ✅ Créer une mission
4. ✅ Créer une affectation
5. ✅ Filtrer et rechercher dans chaque liste
6. ✅ Vérifier les lookups (affichage correct des noms)
7. ✅ Tester les choix multiples
8. ✅ Vérifier la navigation entre écrans

**Tests de Performance :**
```powerfx
// Utiliser des collections pour données fréquemment accédées
OnVisible de Écran_Accueil:
ClearCollect(colBenevoles, Benevoles);
ClearCollect(colMissions, Missions);
```

**Tests de Permissions :**
- Vérifier que seuls les coordinateurs peuvent accéder
- Tester avec différents profils utilisateurs

### Publication

1. Cliquez sur **Fichier** > **Enregistrer**
2. Ajoutez une description des modifications
3. Cliquez sur **Publier**
4. Partagez l'application :
   - **Fichier** > **Partager**
   - Ajoutez les utilisateurs/groupes autorisés
   - Définissez les rôles (Utilisateur / Co-propriétaire)

---

## Maintenance et Évolutions

### Bonnes Pratiques

**Nommage :**
- Écrans : `Écran_Module_Action`
- Galeries : `Gallery_NomListe`
- Formulaires : `Form_Nom`
- Boutons : `Button_Action`
- Variables globales : `varNom`
- Collections : `colNom`

**Performance :**
- Limiter les délégations (max 500 items)
- Utiliser `ClearCollect` pour les données fréquentes
- Éviter les formules complexes dans les galeries

**Documentation :**
- Ajouter des commentaires dans les formules complexes
- Documenter les variables globales utilisées
- Tenir à jour le schéma de navigation

### Évolutions Futures

**Phase 2 - Améliorations :**
1. Tableau de bord avec graphiques (composants Power BI)
2. Vue calendrier des missions
3. Gestion des documents (upload/download)
4. Statistiques d'engagement par bénévole
5. Export PDF des fiches bénévoles

**Phase 3 - Automatisation :**
1. Intégration Power Automate pour notifications
2. Rappels automatiques avant missions
3. Workflow de validation des affectations
4. Rapports mensuels automatisés

---

## Ressources et Support

### Documentation Officielle
- [Power Apps Documentation](https://learn.microsoft.com/fr-fr/power-apps/)
- [Power Fx Reference](https://learn.microsoft.com/fr-fr/power-platform/power-fx/formula-reference)
- [SharePoint Connector](https://learn.microsoft.com/fr-fr/connectors/sharepointonline/)

### Formation Recommandée
- Microsoft Learn: "Create a canvas app in Power Apps"
- Power Apps Community: [powerusers.microsoft.com](https://powerusers.microsoft.com)

---

**Document créé le 8 décembre 2025**  
**Version 1.0 - Guide complet de développement**

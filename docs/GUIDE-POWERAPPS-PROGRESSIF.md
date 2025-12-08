# Guide Power Apps - Développement Progressif

**Version:** 2.0  
**Date:** 8 décembre 2025  
**Projet:** SAS Bénévolat - Gestion des Bénévoles

---

## 📋 Table des Matières

| Phase | Contenu | Durée estimée |
|-------|---------|---------------|
| [Phase 0](#phase-0--préparation) | Préparation et création de l'app | 15 min |
| [Phase 1](#phase-1--fondations) | Splash + Accueil avec KPIs | 30 min |
| [Phase 2](#phase-2--module-bénévoles) | Liste, Détail, Formulaire Bénévoles | 1h30 |
| [Phase 3](#phase-3--module-missions) | Liste et Détail Missions | 45 min |
| [Phase 4](#phase-4--module-affectations) | Liste et Création Affectations | 45 min |
| [Phase 5](#phase-5--module-bénéficiaires) | Bénéficiaires + Prestations | 1h30 |
| [Phase 6](#phase-6--finalisation) | Navigation et publication | 30 min |
| [Annexes](#annexes) | Formules, couleurs, dépannage | Référence |

**⏱️ Temps total estimé : 5-6 heures**

---

## Informations Projet

### Caractéristiques Techniques

| Élément | Valeur |
|---------|--------|
| Type d'application | Canvas App (Tablette) |
| Stockage | SharePoint Online |
| Site SharePoint | `https://serrentino.sharepoint.com/sites/GestionBenevoles` |
| Authentification | Microsoft 365 (Azure AD) |
| Utilisateurs | Coordinateurs et administrateurs |

### Listes SharePoint Disponibles

| Liste | Description | Colonnes principales |
|-------|-------------|---------------------|
| `Benevoles` | Profils des bénévoles | Nom, Prénom, Email, Compétences, Statut |
| `Missions` | Activités et événements | Titre, Type, Dates, Priorité, Statut |
| `Affectations` | Liens bénévole ↔ mission | BenevoleID, MissionID, DateProposition |
| `Disponibilites` | Créneaux des bénévoles | BenevoleID, Jour, Période |
| `Beneficiaires` | Personnes suivies | Nom, Adresse, Besoins, Statut |
| `Prestations` | Services aux bénéficiaires | BeneficiaireID, MissionID, Fréquence |
| `DocumentsBenevoles` | Fichiers associés | BenevoleID, Fichier, Type |

### Charte Graphique

```
Couleurs du projet :
┌─────────────────────────────────────────────────────┐
│  #0078D4  Bleu primaire (Microsoft)                 │
│  #107C10  Vert succès                               │
│  #FFB900  Jaune attention                           │
│  #D83B01  Rouge erreur                              │
│  #8764B8  Violet affectations                       │
│  #CA5010  Orange bénéficiaires                      │
│  #605E5C  Gris neutre                               │
│  #F3F2F1  Gris fond                                 │
└─────────────────────────────────────────────────────┘
```

---

# Phase 0 : Préparation

## 0.1 Créer l'Application

1. Ouvrez [make.powerapps.com](https://make.powerapps.com)
2. Cliquez sur **+ Créer** → **Application canevas**
3. Sélectionnez **Format Tablette**
4. Nommez l'application : `App Gestion Bénévoles`
5. Cliquez sur **Créer**

## 0.2 Connecter les Sources de Données

1. Dans le volet gauche, cliquez sur **Données** (icône cylindre)
2. Cliquez sur **+ Ajouter des données**
3. Recherchez **SharePoint**
4. Choisissez **Se connecter directement**
5. Entrez l'URL : `https://serrentino.sharepoint.com/sites/GestionBenevoles`
6. Cochez **TOUTES** les listes :
   - ☑️ Benevoles
   - ☑️ Missions
   - ☑️ Affectations
   - ☑️ Disponibilites
   - ☑️ Beneficiaires
   - ☑️ Prestations
   - ☑️ DocumentsBenevoles
7. Cliquez sur **Connecter**

## 0.3 Configurer App.OnStart

Sélectionnez **App** dans l'arborescence, puis configurez `OnStart` :

```powerfx
// Initialisation des variables globales
Set(varUtilisateur; User());
Set(varDateDuJour; Today());

// Charger les données en collections (performance)
ClearCollect(colBenevoles; Benevoles);
ClearCollect(colMissions; Missions);
ClearCollect(colBeneficiaires; Beneficiaires);

// Variables de couleurs
Set(varColorPrimary; ColorValue("#0078D4"));
Set(varColorSuccess; ColorValue("#107C10"));
Set(varColorWarning; ColorValue("#FFB900"));
Set(varColorError; ColorValue("#D83B01"));
Set(varColorPurple; ColorValue("#8764B8"));
Set(varColorOrange; ColorValue("#CA5010"));
```

> 💡 **Note locale FR** : Utilisez des points-virgules `;` comme séparateurs (et non des virgules).

## 0.4 Vérification

- [ ] Application créée en format Tablette
- [ ] 7 listes SharePoint connectées (visibles dans le volet Données)
- [ ] App.OnStart configuré sans erreurs

---

# Phase 1 : Fondations

## Objectif

Créer l'écran de chargement et le tableau de bord principal avec les KPIs.

## 1.1 Écran Splash

### Créer l'écran

1. Renommez `Screen1` en `Ecran_Splash`
2. Propriété `Fill` de l'écran : `varColorPrimary`

### Ajouter les composants

**Image_Logo** (optionnel) :
- Insérer → Média → Image
- Centrer au milieu de l'écran

**Label_Chargement** :
```powerfx
Text: "Chargement en cours..."
Color: White
Size: 18
Align: Center
```

**Timer_Redirect** :
- Insérer → Entrée → Minuteur
- Propriétés :

| Propriété | Valeur |
|-----------|--------|
| Duration | 2000 |
| AutoStart | true |
| Visible | false |
| OnTimerEnd | `Navigate('Ecran_Accueil'; ScreenTransition.Fade)` |

### Propriété OnVisible de l'écran

```powerfx
// Rafraîchir les collections si nécessaire
If(
    CountRows(colBenevoles) = 0;
    ClearCollect(colBenevoles; Benevoles)
)
```

---

## 1.2 Écran Accueil

### Créer l'écran

1. Insérer → Nouvel écran → Vide
2. Renommer en `Ecran_Accueil`

### Structure de l'écran

```
┌─────────────────────────────────────────────────────────┐
│  HEADER (bleu) - Titre + Date                           │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  │  KPI 1  │ │  KPI 2  │ │  KPI 3  │ │  KPI 4  │       │
│  │Bénévoles│ │Missions │ │Affectat.│ │Bénéfic. │       │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘       │
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │           GALLERY_MENU                         │     │
│  │  👥 Bénévoles  📋 Missions  🔗 Affectations   │     │
│  │  🎯 Bénéficiaires                              │     │
│  └───────────────────────────────────────────────┘     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### A. Container Header

**Rectangle_Header** :
```powerfx
Fill: varColorPrimary
Height: 80
Width: Parent.Width
X: 0
Y: 0
```

**Label_Titre** :
```powerfx
Text: "Gestion des Bénévoles - SASL"
Color: White
Size: 24
FontWeight: FontWeight.Bold
X: 20
Y: 20
```

**Label_Date** :
```powerfx
Text: "Aujourd'hui : " & Text(Today(); "dddd dd mmmm yyyy"; "fr-FR")
Color: White
Size: 14
X: 20
Y: 50
```

### B. Section KPIs (4 cartes)

Créez 4 rectangles avec leurs labels. Exemple pour la carte 1 :

**Rectangle_KPI1** :
```powerfx
Fill: ColorFade(varColorSuccess; 90%)
Width: 200
Height: 120
X: 40
Y: 100
RadiusTopLeft: 8
RadiusTopRight: 8
RadiusBottomLeft: 8
RadiusBottomRight: 8
```

**Label_KPI1_Titre** :
```powerfx
Text: "Bénévoles Actifs"
Size: 14
Color: RGBA(0; 0; 0; 0.7)
```

**Label_KPI1_Valeur** :
```powerfx
Text: CountRows(Filter(colBenevoles; Statut.Value = "Actif"))
Size: 36
FontWeight: FontWeight.Bold
Color: varColorSuccess
```

**Répétez pour les 3 autres KPIs :**

| Carte | Titre | Formule valeur | Couleur |
|-------|-------|----------------|---------|
| KPI 2 | Missions en cours | `CountRows(Filter(colMissions; StatutMission.Value = "En cours"))` | `varColorPrimary` |
| KPI 3 | Affectations du mois | `CountRows(Filter(Affectations; Month(DateProposition) = Month(Today()) && Year(DateProposition) = Year(Today())))` | `varColorPurple` |
| KPI 4 | Bénéficiaires suivis | `CountRows(Filter(colBeneficiaires; StatutBnf.Value = "Actif"))` | `varColorOrange` |

### C. Gallery_Menu (Navigation)

**Insérer la galerie** :
1. Insérer → Galerie → Vierge horizontale
2. Renommer en `Gallery_Menu`

**Propriété Items** :
```powerfx
Table(
    {Icone: "👥"; Titre: "Bénévoles"; Ecran: 'Ecran_Benevoles_Liste'; Couleur: "#0078D4"};
    {Icone: "📋"; Titre: "Missions"; Ecran: 'Ecran_Missions_Liste'; Couleur: "#107C10"};
    {Icone: "🔗"; Titre: "Affectations"; Ecran: 'Ecran_Affectations_Liste'; Couleur: "#8764B8"};
    {Icone: "🎯"; Titre: "Bénéficiaires"; Ecran: 'Ecran_Beneficiaires_Liste'; Couleur: "#CA5010"}
)
```

> ⚠️ **Important** : Les noms d'écrans entre quotes `'Ecran_...'` ne fonctionneront qu'après avoir créé ces écrans. Laissez temporairement `'Ecran_Accueil'` pour tous pendant la Phase 1.

**Dans le template de la galerie, ajoutez :**

**Label_MenuIcone** :
```powerfx
Text: ThisItem.Icone
Size: 40
```

**Label_MenuTitre** :
```powerfx
Text: ThisItem.Titre
Size: 16
FontWeight: FontWeight.Semibold
```

**Rectangle_MenuFond** :
```powerfx
Fill: ColorFade(ColorValue(ThisItem.Couleur); 80%)
OnSelect: Navigate(ThisItem.Ecran; ScreenTransition.Cover)
```

---

## ✅ Test Phase 1

| Test | Résultat attendu |
|------|------------------|
| Lancer l'application (F5) | Écran Splash affiché |
| Attendre 2 secondes | Redirection automatique vers Accueil |
| Vérifier les KPIs | Valeurs numériques affichées (depuis SharePoint) |
| Cliquer sur une carte menu | Navigation (ou message si écran pas encore créé) |

**Checkpoint :**
- [ ] Splash → Accueil fonctionne
- [ ] KPIs affichent des données
- [ ] Aucune erreur dans les formules

---

# Phase 2 : Module Bénévoles

## Objectif

Créer le cycle complet CRUD (Create, Read, Update, Delete) pour les bénévoles.

## 2.1 Écran Liste Bénévoles

### Créer l'écran

1. Insérer → Nouvel écran → Vide
2. Renommer en `Ecran_Benevoles_Liste`

### Structure

```
┌─────────────────────────────────────────────────────────┐
│  HEADER - "Liste des Bénévoles" + Bouton Retour         │
├─────────────────────────────────────────────────────────┤
│  [🔍 Rechercher...]  [Statut ▼]  [Compétence ▼]        │
├─────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────┐ │
│  │ 👤 Jean Dupont        ✉️ jean@email.com           │ │
│  │    Compétences: Informatique, Animation    [Actif]│ │
│  ├───────────────────────────────────────────────────┤ │
│  │ 👤 Marie Martin       ✉️ marie@email.com          │ │
│  │    Compétences: Cuisine, Accueil          [Actif] │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  [+ Nouveau Bénévole]                                   │
└─────────────────────────────────────────────────────────┘
```

### A. Header avec Retour

**Icon_Retour** :
```powerfx
Icon: Icon.Back
OnSelect: Navigate('Ecran_Accueil'; ScreenTransition.UnCover)
Color: White
X: 10
Y: 25
```

**Label_TitreEcran** :
```powerfx
Text: "Liste des Bénévoles"
Color: White
Size: 22
FontWeight: FontWeight.Bold
X: 50
Y: 20
```

### B. Barre de Recherche et Filtres

**TextInput_Recherche** :
```powerfx
HintText: "Rechercher par nom, prénom ou email..."
Width: 400
X: 20
Y: 90
```

**Dropdown_StatutFiltre** :
```powerfx
Items: ["Tous"; "Actif"; "Inactif"; "Suspendu"; "En attente"]
Default: "Tous"
X: 440
Y: 90
```

**Dropdown_CompetenceFiltre** :
```powerfx
Items: ["Toutes"; "Accompagnement social"; "Animation d'ateliers"; 
        "Bricolage / Réparations"; "Conduite / Transport"; 
        "Cuisine / Restauration"; "Informatique / Numérique"; 
        "Jardinage"; "Soutien administratif"]
Default: "Toutes"
X: 640
Y: 90
```

### C. Galerie des Bénévoles

**Insérer** : Galerie → Vierge verticale  
**Renommer** : `Gallery_Benevoles`

**Propriété Items** :
```powerfx
SortByColumns(
    Search(
        Filter(
            colBenevoles;
            // Filtre par statut
            (Dropdown_StatutFiltre.Selected.Value = "Tous" || 
             Statut.Value = Dropdown_StatutFiltre.Selected.Value) &&
            // Filtre par compétence
            (Dropdown_CompetenceFiltre.Selected.Value = "Toutes" || 
             Dropdown_CompetenceFiltre.Selected.Value in Competences)
        );
        TextInput_Recherche.Text;
        "Nom"; "Prenom"; "EmailBenevole"
    );
    "Nom";
    SortOrder.Ascending
)
```

**Propriétés de la galerie** :

| Propriété | Valeur |
|-----------|--------|
| TemplateHeight | 100 |
| TemplatePadding | 5 |
| Width | Parent.Width - 40 |
| X | 20 |
| Y | 140 |

### D. Contenu du Template (dans la galerie)

**Label_NomComplet** :
```powerfx
Text: ThisItem.Prenom & " " & ThisItem.Nom
FontWeight: FontWeight.Semibold
Size: 16
X: 10
Y: 10
```

**Label_Email** :
```powerfx
Text: "✉️ " & ThisItem.EmailBenevole
Color: RGBA(0; 0; 0; 0.6)
Size: 12
X: 10
Y: 35
```

**Label_Telephone** :
```powerfx
Text: "📞 " & If(!IsBlank(ThisItem.TelephoneMobile); ThisItem.TelephoneMobile; ThisItem.Telephone)
Size: 12
X: 300
Y: 35
```

**Label_Competences** :
```powerfx
Text: "🛠️ " & Concat(ThisItem.Competences; Value; ", ")
Color: varColorPrimary
Size: 11
X: 10
Y: 60
```

**Rectangle_BadgeStatut** :
```powerfx
Fill: Switch(
    ThisItem.Statut.Value;
    "Actif"; varColorSuccess;
    "Inactif"; ColorValue("#A19F9D");
    "Suspendu"; varColorError;
    "En attente"; varColorWarning;
    ColorValue("#605E5C")
)
Width: 80
Height: 24
RadiusTopLeft: 12
RadiusTopRight: 12
RadiusBottomLeft: 12
RadiusBottomRight: 12
```

**Label_Statut** (sur le rectangle) :
```powerfx
Text: ThisItem.Statut.Value
Color: White
Size: 11
Align: Center
```

**Icon_Chevron** :
```powerfx
Icon: Icon.ChevronRight
OnSelect: Navigate('Ecran_Benevoles_Detail'; ScreenTransition.Cover)
X: Parent.TemplateWidth - 40
Y: 35
```

### E. Bouton Nouveau

**Button_NouveauBenevole** :
```powerfx
Text: "+ Nouveau Bénévole"
Fill: varColorPrimary
Color: White
X: Parent.Width - 220
Y: Parent.Height - 60
Width: 200

OnSelect: 
    Set(varBenevoleSelectionne; Defaults(Benevoles));
    Set(varModeFormulaire; "Nouveau");
    Navigate('Ecran_Benevoles_Formulaire'; ScreenTransition.Cover)
```

---

## 2.2 Écran Détail Bénévole

### Créer l'écran

1. Insérer → Nouvel écran → Vide
2. Renommer en `Ecran_Benevoles_Detail`

### Structure

```
┌─────────────────────────────────────────────────────────┐
│  HEADER - "Fiche Bénévole" + Retour                     │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐   │
│  │  👤 Jean DUPONT                          [Actif] │   │
│  │  N° BEN-00001                                    │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  📧 Email: jean.dupont@email.com                        │
│  📞 Tél: 079 123 45 67                                  │
│  🏠 Adresse: Rue du Lac 10, 1000 Lausanne              │
│  🎂 Né(e) le: 15/03/1985                               │
│  📅 Membre depuis: 01/01/2020                          │
│                                                         │
│  🛠️ Compétences: Informatique, Animation               │
│  🌐 Langues: Français, Anglais                         │
│                                                         │
│  [✏️ Modifier]  [✉️ Contacter]  [➕ Affectation]       │
│                                                         │
│  ── Affectations récentes ──────────────────────────   │
│  │ Mission A - 01/12/2025 - Confirmée               │   │
│  │ Mission B - 15/11/2025 - Terminée                │   │
└─────────────────────────────────────────────────────────┘
```

### A. En-tête avec Infos Principales

**Rectangle_HeaderDetail** :
```powerfx
Fill: ColorFade(varColorPrimary; 90%)
Height: 100
Width: Parent.Width
```

**Label_NomCompletDetail** :
```powerfx
Text: Gallery_Benevoles.Selected.Prenom & " " & Upper(Gallery_Benevoles.Selected.Nom)
Size: 24
FontWeight: FontWeight.Bold
```

**Label_NumeroBenevole** :
```powerfx
Text: Gallery_Benevoles.Selected.NumeroBenevole
Size: 14
Color: RGBA(0; 0; 0; 0.6)
```

### B. Formulaire de Visualisation

**Insérer** : Formulaire → Afficher  
**Renommer** : `Form_BenevoleDetail`

```powerfx
DataSource: Benevoles
Item: Gallery_Benevoles.Selected
DefaultMode: FormMode.View
```

**Cartes à afficher** (dans l'ordre) :
1. EmailBenevole
2. Telephone / TelephoneMobile
3. Adresse1, Adresse2, NPA, Ville
4. DateNaissance
5. DateEntree
6. Competences
7. Langues
8. NotesGenerales
9. RGPDConsentement

### C. Galerie Affectations du Bénévole

**Insérer** : Galerie → Vierge verticale  
**Renommer** : `Gallery_AffectationsBenevole`

```powerfx
Items: SortByColumns(
    Filter(
        Affectations;
        BenevoleID.Id = Gallery_Benevoles.Selected.ID
    );
    "DateProposition";
    SortOrder.Descending
)
```

**Template** :
- Label mission : `ThisItem.MissionID.Title`
- Label date : `Text(ThisItem.DateProposition; "dd/mm/yyyy")`
- Label statut : `ThisItem.StatutAffectation.Value`

### D. Boutons d'Action

**Button_Modifier** :
```powerfx
Text: "✏️ Modifier"
OnSelect: 
    Set(varBenevoleSelectionne; Gallery_Benevoles.Selected);
    Set(varModeFormulaire; "Modifier");
    Navigate('Ecran_Benevoles_Formulaire'; ScreenTransition.Cover)
```

**Button_Contacter** :
```powerfx
Text: "✉️ Contacter"
OnSelect: Launch("mailto:" & Gallery_Benevoles.Selected.EmailBenevole & "?subject=Contact SASL")
```

**Button_NouvelleAffectation** :
```powerfx
Text: "➕ Affectation"
OnSelect: 
    Set(varBenevolePreselectionne; Gallery_Benevoles.Selected);
    Navigate('Ecran_Affectations_Nouvelle'; ScreenTransition.Cover)
```

---

## 2.3 Écran Formulaire Bénévole

### Créer l'écran

1. Insérer → Nouvel écran → Vide
2. Renommer en `Ecran_Benevoles_Formulaire`

### Formulaire d'Édition

**Insérer** : Formulaire → Modifier  
**Renommer** : `Form_BenevoleEdit`

```powerfx
DataSource: Benevoles
Item: varBenevoleSelectionne
DefaultMode: If(varModeFormulaire = "Nouveau"; FormMode.New; FormMode.Edit)
```

### Configuration des Cartes

**Carte NumeroBenevole** (lecture seule si modification) :
```powerfx
// DataCard : DisplayMode
If(varModeFormulaire = "Nouveau"; DisplayMode.Edit; DisplayMode.View)

// Default (génération auto)
If(
    varModeFormulaire = "Nouveau";
    "BEN-" & Text(CountRows(Benevoles) + 1; "00000");
    Parent.Default
)
```

**Carte Civilite** (Dropdown) :
```powerfx
Items: ["M."; "Mme"; "Autre"]
```

**Carte Statut** (Dropdown) :
```powerfx
Items: ["Actif"; "Inactif"; "Suspendu"; "En attente"]
Default: If(varModeFormulaire = "Nouveau"; "En attente"; Parent.Default)
```

**Carte Competences** (ComboBox multi-sélection) :
```powerfx
Items: ["Accompagnement social"; "Animation d'ateliers"; "Bricolage / Réparations";
        "Communication / Rédaction"; "Conduite / Transport"; "Conseil juridique";
        "Cuisine / Restauration"; "Informatique / Numérique"; "Jardinage";
        "Logistique / Organisation"; "Santé / Soins"; "Soutien administratif";
        "Traduction"; "Autre"]
SelectMultiple: true
```

**Carte DateEntree** :
```powerfx
Default: If(varModeFormulaire = "Nouveau"; Today(); Parent.Default)
```

**Carte RGPDConsentement** (Toggle) :
```powerfx
TrueText: "Oui"
FalseText: "Non"
```

### Propriétés du Formulaire

```powerfx
OnSuccess: 
    Notify("Bénévole enregistré avec succès !"; NotificationType.Success);
    ClearCollect(colBenevoles; Benevoles);  // Rafraîchir la collection
    Navigate('Ecran_Benevoles_Liste'; ScreenTransition.UnCover)

OnFailure:
    Notify("Erreur : " & Form_BenevoleEdit.Error; NotificationType.Error)
```

### Boutons de Contrôle

**Button_Enregistrer** :
```powerfx
Text: "💾 Enregistrer"
Fill: varColorSuccess
OnSelect: SubmitForm(Form_BenevoleEdit)
DisplayMode: If(Form_BenevoleEdit.Valid; DisplayMode.Edit; DisplayMode.Disabled)
```

**Button_Annuler** :
```powerfx
Text: "❌ Annuler"
Fill: ColorValue("#605E5C")
OnSelect: 
    ResetForm(Form_BenevoleEdit);
    Navigate('Ecran_Benevoles_Liste'; ScreenTransition.UnCover)
```

---

## ✅ Test Phase 2

| Test | Action | Résultat attendu |
|------|--------|------------------|
| Liste | Ouvrir liste bénévoles | Affiche tous les bénévoles |
| Recherche | Taper un nom | Liste filtrée |
| Filtre statut | Sélectionner "Actif" | Uniquement les actifs |
| Détail | Cliquer sur un bénévole | Fiche complète affichée |
| Créer | Cliquer "+ Nouveau" | Formulaire vide |
| Enregistrer | Remplir et sauver | Retour liste + notification |
| Modifier | Depuis détail, cliquer Modifier | Formulaire pré-rempli |
| Mettre à jour | Modifier et sauver | Changements visibles |

**Checkpoint :**
- [ ] CRUD bénévoles complet
- [ ] Recherche et filtres fonctionnels
- [ ] Navigation fluide Liste ↔ Détail ↔ Formulaire

---

# Phase 3 : Module Missions

## Objectif

Afficher et gérer les missions (activités récurrentes et événements).

## 3.1 Écran Liste Missions

### Créer l'écran

1. Insérer → Nouvel écran → Vide
2. Renommer en `Ecran_Missions_Liste`

### Filtres

**Toggle_TypeMission** :
```powerfx
TrueText: "Activités Récurrentes"
FalseText: "Événements Ponctuels"
Default: true
```

**Dropdown_StatutMission** :
```powerfx
Items: ["Tous"; "Brouillon"; "Planifiée"; "En cours"; "Clôturée"; "Annulée"]
Default: "Tous"
```

### Galerie Missions

**Gallery_Missions - Items** :
```powerfx
SortByColumns(
    Filter(
        colMissions;
        // Filtre par type
        (Toggle_TypeMission.Value && TypeMission.Value = "Récurrente") ||
        (!Toggle_TypeMission.Value && TypeMission.Value = "Ponctuelle") &&
        // Filtre par statut
        (Dropdown_StatutMission.Selected.Value = "Tous" || 
         StatutMission.Value = Dropdown_StatutMission.Selected.Value)
    );
    "DateDebut";
    SortOrder.Descending
)
```

### Template Galerie

**Label_TitreMission** :
```powerfx
Text: ThisItem.Title
FontWeight: FontWeight.Bold
Size: 16
```

**Label_TypeMission** :
```powerfx
Text: If(ThisItem.TypeMission.Value = "Récurrente"; "🔄 Récurrente"; "📅 Ponctuelle")
Color: If(ThisItem.TypeMission.Value = "Récurrente"; varColorPrimary; varColorSuccess)
```

**Label_Dates** :
```powerfx
Text: If(
    !IsBlank(ThisItem.DateDebut) && !IsBlank(ThisItem.DateFin);
    Text(ThisItem.DateDebut; "dd/mm/yyyy") & " → " & Text(ThisItem.DateFin; "dd/mm/yyyy");
    If(!IsBlank(ThisItem.DateDebut); Text(ThisItem.DateDebut; "dd/mm/yyyy"); "Date non définie")
)
```

**Label_NombreBenevoles** :
```powerfx
Text: "👥 " & 
      CountRows(Filter(Affectations; MissionID.Id = ThisItem.ID)) & 
      " / " & 
      If(IsBlank(ThisItem.NombreBenevoles); "∞"; Text(ThisItem.NombreBenevoles))
```

**Rectangle_Priorite** :
```powerfx
Fill: Switch(
    ThisItem.Priorite.Value;
    "Critique"; varColorError;
    "Haute"; ColorValue("#CA5010");
    "Moyenne"; varColorWarning;
    "Faible"; varColorSuccess;
    ColorValue("#605E5C")
)
```

---

## 3.2 Écran Détail Mission

### Créer l'écran

1. Insérer → Nouvel écran → Vide
2. Renommer en `Ecran_Missions_Detail`

### Formulaire de Visualisation

```powerfx
// Form_MissionDetail
DataSource: Missions
Item: Gallery_Missions.Selected
DefaultMode: FormMode.View
```

### Galerie Bénévoles Affectés

**Gallery_BenevolesAffectes - Items** :
```powerfx
AddColumns(
    Filter(
        Affectations;
        MissionID.Id = Gallery_Missions.Selected.ID
    );
    "NomBenevole"; BenevoleID.Nom;
    "PrenomBenevole"; BenevoleID.Prenom
)
```

---

## ✅ Test Phase 3

| Test | Résultat attendu |
|------|------------------|
| Basculer toggle type | Liste filtrée Récurrente/Ponctuelle |
| Filtrer par statut | Uniquement le statut choisi |
| Voir détail mission | Informations + bénévoles affectés |

**Checkpoint :**
- [ ] Liste missions avec filtres
- [ ] Détail mission avec affectations
- [ ] Navigation depuis Accueil fonctionne

---

# Phase 4 : Module Affectations

## Objectif

Gérer les liens entre bénévoles et missions.

## 4.1 Écran Liste Affectations

### Créer l'écran

1. Insérer → Nouvel écran → Vide
2. Renommer en `Ecran_Affectations_Liste`

### Galerie Affectations

**Gallery_Affectations - Items** :
```powerfx
SortByColumns(
    Affectations;
    "DateProposition";
    SortOrder.Descending
)
```

### Template

**Label_BenevoleNom** :
```powerfx
Text: ThisItem.BenevoleID.Prenom & " " & ThisItem.BenevoleID.Nom
FontWeight: FontWeight.Semibold
```

**Label_MissionTitre** :
```powerfx
Text: "→ " & ThisItem.MissionID.Title
```

**Label_DateAffectation** :
```powerfx
Text: Text(ThisItem.DateProposition; "dd/mm/yyyy")
```

**Badge_StatutAffectation** :
```powerfx
Fill: Switch(
    ThisItem.StatutAffectation.Value;
    "Confirmée"; varColorSuccess;
    "En attente"; varColorWarning;
    "Refusée"; varColorError;
    "Annulée"; ColorValue("#605E5C");
    ColorValue("#A19F9D")
)
```

---

## 4.2 Écran Nouvelle Affectation

### Créer l'écran

1. Insérer → Nouvel écran → Vide
2. Renommer en `Ecran_Affectations_Nouvelle`

### Sélection Bénévole

**ComboBox_Benevole** :
```powerfx
Items: SortByColumns(
    Filter(colBenevoles; Statut.Value = "Actif");
    "Nom";
    Ascending
)
DisplayFields: ["Nom"; "Prenom"]
SearchFields: ["Nom"; "Prenom"; "EmailBenevole"]
DefaultSelectedItems: If(
    !IsBlank(varBenevolePreselectionne);
    varBenevolePreselectionne;
    Blank()
)
```

### Sélection Mission

**ComboBox_Mission** :
```powerfx
Items: SortByColumns(
    Filter(
        colMissions;
        StatutMission.Value in ["Planifiée"; "En cours"]
    );
    "DateDebut";
    Descending
)
DisplayFields: ["Title"]
SearchFields: ["Title"; "DescriptionMission"]
```

### Champs Complémentaires

**DatePicker_DateProposition** :
```powerfx
DefaultDate: Today()
```

**Dropdown_StatutAffectation** :
```powerfx
Items: ["En attente"; "Confirmée"; "Refusée"; "Annulée"]
Default: "En attente"
```

**TextInput_PlageHoraire** :
```powerfx
HintText: "Ex: Lundi 14h-17h"
```

**TextInput_Commentaire** :
```powerfx
Mode: TextMode.MultiLine
HintText: "Informations complémentaires..."
```

### Bouton Création

**Button_CreerAffectation** :
```powerfx
Text: "✅ Créer l'Affectation"
Fill: varColorSuccess

OnSelect:
    If(
        IsBlank(ComboBox_Benevole.Selected) || IsBlank(ComboBox_Mission.Selected);
        Notify("Veuillez sélectionner un bénévole et une mission"; NotificationType.Warning);
        
        // Vérifier doublon
        If(
            CountRows(
                Filter(
                    Affectations;
                    BenevoleID.Id = ComboBox_Benevole.Selected.ID &&
                    MissionID.Id = ComboBox_Mission.Selected.ID
                )
            ) > 0;
            Notify("Cette affectation existe déjà !"; NotificationType.Error);
            
            // Créer
            Patch(
                Affectations;
                Defaults(Affectations);
                {
                    Title: "Affectation - " & ComboBox_Benevole.Selected.Nom & " - " & ComboBox_Mission.Selected.Title;
                    BenevoleID: ComboBox_Benevole.Selected;
                    MissionID: ComboBox_Mission.Selected;
                    DateProposition: DatePicker_DateProposition.SelectedDate;
                    StatutAffectation: {Value: Dropdown_StatutAffectation.Selected.Value};
                    PlageHoraire1: TextInput_PlageHoraire.Text;
                    Commentaire: TextInput_Commentaire.Text
                }
            );
            Notify("Affectation créée !"; NotificationType.Success);
            Navigate('Ecran_Affectations_Liste'; ScreenTransition.UnCover)
        )
    )

DisplayMode: If(
    IsBlank(ComboBox_Benevole.Selected) || IsBlank(ComboBox_Mission.Selected);
    DisplayMode.Disabled;
    DisplayMode.Edit
)
```

---

## ✅ Test Phase 4

| Test | Résultat attendu |
|------|------------------|
| Liste affectations | Toutes les affectations visibles |
| Nouvelle affectation | Formulaire avec ComboBox |
| Créer affectation | Succès + notification |
| Doublon | Message d'erreur |
| Vérification | Affectation visible dans détail bénévole ET mission |

**Checkpoint :**
- [ ] Liste affectations
- [ ] Création affectation avec validation
- [ ] Lien visible côté bénévole ET mission

---

# Phase 5 : Module Bénéficiaires

## Objectif

Gérer les bénéficiaires et leurs prestations.

## 5.1 Écran Liste Bénéficiaires

### Créer l'écran

1. Insérer → Nouvel écran → Vide
2. Renommer en `Ecran_Beneficiaires_Liste`

### Galerie Bénéficiaires

**Gallery_Beneficiaires - Items** :
```powerfx
SortByColumns(
    Search(
        Filter(
            colBeneficiaires;
            (Dropdown_StatutBeneficiaire.Selected.Value = "Tous" || 
             StatutBnf.Value = Dropdown_StatutBeneficiaire.Selected.Value)
        );
        TextInput_RechercheBnf.Text;
        "NomBnf"; "PrenomBnf"; "VilleBnf"
    );
    "NomBnf";
    SortOrder.Ascending
)
```

### Template

**Label_NomBnf** :
```powerfx
Text: ThisItem.CiviliteBnf & " " & ThisItem.PrenomBnf & " " & ThisItem.NomBnf
FontWeight: FontWeight.Semibold
```

**Label_AdresseBnf** :
```powerfx
Text: "📍 " & ThisItem.NPABnf & " " & ThisItem.VilleBnf
```

**Label_Besoins** :
```powerfx
Text: "Besoins : " & Left(ThisItem.Besoins; 40) & If(Len(ThisItem.Besoins) > 40; "..."; "")
Color: varColorOrange
```

**Label_NombrePrestations** :
```powerfx
Text: "📊 " & CountRows(Filter(Prestations; BeneficiaireID.Id = ThisItem.ID)) & " prestation(s)"
```

---

## 5.2 Écran Détail Bénéficiaire

### Créer l'écran

1. Insérer → Nouvel écran → Vide
2. Renommer en `Ecran_Beneficiaires_Detail`

### Formulaire

```powerfx
DataSource: Beneficiaires
Item: Gallery_Beneficiaires.Selected
DefaultMode: FormMode.View
```

### Galerie Prestations

**Gallery_PrestationsBnf - Items** :
```powerfx
SortByColumns(
    Filter(Prestations; BeneficiaireID.Id = Gallery_Beneficiaires.Selected.ID);
    "DateDebutPrestation";
    SortOrder.Descending
)
```

---

## 5.3 Écran Nouvelle Prestation

### Créer l'écran

1. Insérer → Nouvel écran → Vide
2. Renommer en `Ecran_Prestations_Nouvelle`

### Sélections

**ComboBox_Beneficiaire** :
```powerfx
Items: SortByColumns(Filter(colBeneficiaires; StatutBnf.Value = "Actif"); "NomBnf"; Ascending)
DefaultSelectedItems: If(!IsBlank(varBeneficiairePreselectionne); varBeneficiairePreselectionne; Blank())
```

**ComboBox_MissionPrestation** :
```powerfx
Items: SortByColumns(
    Filter(colMissions; TypeMission.Value = "Récurrente" && StatutMission.Value in ["Planifiée"; "En cours"]);
    "Title";
    Ascending
)
```

**Dropdown_FrequencePrestation** :
```powerfx
Items: ["Hebdomadaire"; "Bi-hebdomadaire"; "Mensuelle"; "Ponctuelle"; "Sur demande"]
Default: "Hebdomadaire"
```

### Bouton Création

```powerfx
// Button_CreerPrestation
OnSelect:
    If(
        IsBlank(ComboBox_Beneficiaire.Selected) || IsBlank(ComboBox_MissionPrestation.Selected);
        Notify("Sélectionnez un bénéficiaire et une mission"; NotificationType.Warning);
        
        Patch(
            Prestations;
            Defaults(Prestations);
            {
                Title: "Prestation - " & ComboBox_Beneficiaire.Selected.NomBnf & " - " & ComboBox_MissionPrestation.Selected.Title;
                BeneficiaireID: ComboBox_Beneficiaire.Selected;
                MissionIDPrestation: ComboBox_MissionPrestation.Selected;
                DateDebutPrestation: DatePicker_DebutPrestation.SelectedDate;
                FrequencePrestation: Dropdown_FrequencePrestation.Selected.Value;
                StatutPrestation: "En_cours";
                DerniereVisite: Today()
            }
        );
        Notify("Prestation créée !"; NotificationType.Success);
        Navigate('Ecran_Beneficiaires_Detail'; ScreenTransition.UnCover)
    )
```

---

## 5.4 Écran Suivi Prestations (Alertes)

### Créer l'écran

1. Insérer → Nouvel écran → Vide
2. Renommer en `Ecran_Prestations_Suivi`

### Statistiques en En-tête

**Label_TotalActives** :
```powerfx
Text: "Prestations actives : " & CountRows(Filter(Prestations; StatutPrestation = "En_cours"))
```

**Label_AlertesUrgentes** :
```powerfx
Text: "⚠️ Alertes (>60j) : " & CountRows(
    Filter(Prestations; StatutPrestation = "En_cours" && DateDiff(DerniereVisite; Today()) > 60)
)
Color: varColorError
FontWeight: FontWeight.Bold
```

**Label_ARevoir** :
```powerfx
Text: "⚡ À revoir (>30j) : " & CountRows(
    Filter(Prestations; 
        StatutPrestation = "En_cours" && 
        DateDiff(DerniereVisite; Today()) > 30 && 
        DateDiff(DerniereVisite; Today()) <= 60
    )
)
Color: varColorWarning
```

### Galerie avec Alertes

**Gallery_SuiviPrestations - Items** :
```powerfx
SortByColumns(
    Filter(Prestations; StatutPrestation = "En_cours");
    "DerniereVisite";
    SortOrder.Ascending
)
```

### Template avec Indicateurs

**Rectangle_AlerteVisuelle** :
```powerfx
Fill: If(
    DateDiff(ThisItem.DerniereVisite; Today()) > 60;
    ColorFade(varColorError; 80%);
    If(
        DateDiff(ThisItem.DerniereVisite; Today()) > 30;
        ColorFade(varColorWarning; 80%);
        ColorValue("#F3F2F1")
    )
)
```

**Label_DernierContact** :
```powerfx
Text: "Dernière visite : " & Text(ThisItem.DerniereVisite; "dd/mm/yyyy") & 
      " (" & DateDiff(ThisItem.DerniereVisite; Today()) & " jours)"
Color: If(DateDiff(ThisItem.DerniereVisite; Today()) > 30; varColorError; RGBA(0; 0; 0; 0.6))
```

**Button_EnregistrerVisite** :
```powerfx
Text: "✓ Visite"
OnSelect:
    Patch(Prestations; ThisItem; {DerniereVisite: Today()});
    Notify("Visite enregistrée !"; NotificationType.Success)
```

---

## ✅ Test Phase 5

| Test | Résultat attendu |
|------|------------------|
| Liste bénéficiaires | Affiche tous les bénéficiaires |
| Détail bénéficiaire | Info + prestations |
| Créer prestation | Succès + visible dans détail |
| Écran suivi | Alertes colorées selon délai |
| Enregistrer visite | Date mise à jour, alerte disparaît |

**Checkpoint :**
- [ ] CRUD bénéficiaires
- [ ] Création prestations
- [ ] Alertes visuelles fonctionnelles
- [ ] Bouton "Enregistrer visite" opérationnel

---

# Phase 6 : Finalisation

## 6.1 Mettre à Jour Gallery_Menu

Maintenant que tous les écrans existent, mettez à jour `Gallery_Menu` sur `Ecran_Accueil` :

```powerfx
Items: Table(
    {Icone: "👥"; Titre: "Bénévoles"; Ecran: 'Ecran_Benevoles_Liste'; Couleur: "#0078D4"};
    {Icone: "📋"; Titre: "Missions"; Ecran: 'Ecran_Missions_Liste'; Couleur: "#107C10"};
    {Icone: "🔗"; Titre: "Affectations"; Ecran: 'Ecran_Affectations_Liste'; Couleur: "#8764B8"};
    {Icone: "🎯"; Titre: "Bénéficiaires"; Ecran: 'Ecran_Beneficiaires_Liste'; Couleur: "#CA5010"};
    {Icone: "📊"; Titre: "Suivi Prestations"; Ecran: 'Ecran_Prestations_Suivi'; Couleur: "#D83B01"}
)
```

## 6.2 Ajouter Navigation Retour sur Chaque Écran

Vérifiez que chaque écran a un bouton/icône retour :

```powerfx
// Icon_Retour (sur chaque écran)
Icon: Icon.Back
OnSelect: Back()
// ou
OnSelect: Navigate('Ecran_Accueil'; ScreenTransition.UnCover)
```

## 6.3 Test Final de Navigation

| Depuis | Vers | Retour |
|--------|------|--------|
| Splash | Accueil | - |
| Accueil | Bénévoles Liste | ✓ |
| Bénévoles Liste | Bénévoles Détail | ✓ |
| Bénévoles Détail | Bénévoles Formulaire | ✓ |
| Accueil | Missions Liste | ✓ |
| Missions Liste | Missions Détail | ✓ |
| Accueil | Affectations Liste | ✓ |
| Affectations Liste | Nouvelle Affectation | ✓ |
| Accueil | Bénéficiaires Liste | ✓ |
| Bénéficiaires Liste | Bénéficiaires Détail | ✓ |
| Bénéficiaires Détail | Nouvelle Prestation | ✓ |
| Accueil | Suivi Prestations | ✓ |

## 6.4 Publication

1. **Enregistrer** : Fichier → Enregistrer
2. **Publier** : Fichier → Publier
3. **Partager** : 
   - Fichier → Partager
   - Ajouter les utilisateurs/groupes
   - Définir les rôles (Utilisateur / Co-propriétaire)

---

## ✅ Checklist Finale

```
[ ] Phase 0 : App créée + connexions SharePoint
[ ] Phase 1 : Splash + Accueil avec KPIs
[ ] Phase 2 : Module Bénévoles complet (CRUD)
[ ] Phase 3 : Module Missions (consultation)
[ ] Phase 4 : Module Affectations (création)
[ ] Phase 5 : Module Bénéficiaires + Prestations + Alertes
[ ] Phase 6 : Navigation complète + Publication
```

---

# Annexes

## A. Palette de Couleurs

| Usage | Code Hex | Variable |
|-------|----------|----------|
| Primaire | #0078D4 | `varColorPrimary` |
| Succès | #107C10 | `varColorSuccess` |
| Attention | #FFB900 | `varColorWarning` |
| Erreur | #D83B01 | `varColorError` |
| Violet | #8764B8 | `varColorPurple` |
| Orange | #CA5010 | `varColorOrange` |
| Gris | #605E5C | - |
| Fond | #F3F2F1 | - |

## B. Formules Fréquentes

### Dates

```powerfx
// Format français
Text(ThisItem.DateDebut; "dddd dd mmmm yyyy"; "fr-FR")

// Âge
Year(Today()) - Year(ThisItem.DateNaissance)

// Jours depuis
DateDiff(ThisItem.DerniereVisite; Today())
```

### Texte

```powerfx
// Concaténation
ThisItem.Prenom & " " & Upper(ThisItem.Nom)

// Initiales
Upper(Left(ThisItem.Prenom; 1) & Left(ThisItem.Nom; 1))

// Troncature
Left(ThisItem.Description; 50) & If(Len(ThisItem.Description) > 50; "..."; "")
```

### Choix Multiples

```powerfx
// Afficher
Concat(ThisItem.Competences; Value; ", ")

// Vérifier présence
"Informatique" in ThisItem.Competences

// Compter
CountRows(ThisItem.Competences)
```

### Lookups

```powerfx
// Accéder aux champs
ThisItem.BenevoleID.Nom

// Filtrer par ID
Filter(Affectations; BenevoleID.Id = Gallery_Benevoles.Selected.ID)
```

## C. Dépannage

| Erreur | Cause | Solution |
|--------|-------|----------|
| "Séparateur d'arguments invalide" | Virgule au lieu de point-virgule | Remplacer `,` par `;` |
| "Nom d'écran introuvable" | Écran pas encore créé | Créer l'écran ou mettre temporairement `'Ecran_Accueil'` |
| "Délégation warning" | >500 éléments | Utiliser collections ou Filter côté client |
| "Colonne non trouvée" | Nom incorrect | Vérifier le nom exact dans SharePoint |

## D. Ressources

- [Documentation Power Apps](https://learn.microsoft.com/fr-fr/power-apps/)
- [Référence Power Fx](https://learn.microsoft.com/fr-fr/power-platform/power-fx/formula-reference)
- [Connecteur SharePoint](https://learn.microsoft.com/fr-fr/connectors/sharepointonline/)

---

**Document créé le 8 décembre 2025**  
**Version 2.0 - Guide Progressif**

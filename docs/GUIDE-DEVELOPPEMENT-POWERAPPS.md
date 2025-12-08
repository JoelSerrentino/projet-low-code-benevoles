# Guide de Développement Power Apps - Gestion des Bénévoles

Ce guide détaille les étapes pour construire l'application Power Apps "Gestion des Bénévoles" connectée à votre site SharePoint.

## 1. Architecture de l'Application

### Sources de Données
Connectez l'application aux listes SharePoint suivantes :
- `Benevoles`
- `Missions`
- `Affectations`
- `Beneficiaires`
- `Prestations`
- `Disponibilites`

### Structure des Écrans
L'application sera composée des écrans principaux suivants :

1.  **Ecran_Accueil (Home Screen)**
    -   Tableau de bord avec KPIs (Nombre de bénévoles actifs, Missions en cours).
    -   Menu de navigation principal.
2.  **Ecran_Benevoles_Liste**
    -   Galerie filtrable des bénévoles.
    -   Recherche par nom, compétence, statut.
3.  **Ecran_Benevoles_Detail**
    -   Fiche complète du bénévole.
    -   Onglets pour voir ses affectations et disponibilités.
    -   Boutons d'action (Modifier, Contacter).
4.  **Ecran_Benevoles_Edit**
    -   Formulaire de création/modification de bénévole.
5.  **Ecran_Missions_Liste**
    -   Galerie des missions (activités et événements).
    -   Filtre par date et type.
6.  **Ecran_Missions_Detail**
    -   Détails de la mission.
    -   Liste des bénévoles affectés.
    -   Bouton pour affecter un bénévole.
7.  **Ecran_Affectation**
    -   Interface pour lier un bénévole à une mission.

---

## 2. Mise en Place Initiale

1.  Allez sur [make.powerapps.com](https://make.powerapps.com).
2.  Créez une **Application Canevas (Canvas App)** à partir de zéro.
3.  Format : **Tablette** (recommandé pour l'administration) ou Téléphone.
4.  Nommez-la : `App Gestion Bénévoles`.
5.  Ajoutez les données : `Données` > `Ajouter des données` > `SharePoint` > Sélectionnez votre site > Cochez toutes les listes.

---

## 3. Développement Écran par Écran

### A. Écran d'Accueil (Ecran_Accueil)

**Design :**
-   En-tête avec le logo et le titre.
-   Une galerie horizontale ou des "Cartes" pour les statistiques.
-   Un menu de navigation (Boutons ou Galerie).

**Formules KPIs (Exemples) :**
```powerfx
// Nombre de bénévoles actifs
CountRows(Filter(Benevoles, Statut.Value = "Actif"))

// Missions planifiées
CountRows(Filter(Missions, StatutMission.Value = "Planifiée"))
```

### B. Écran Liste Bénévoles (Ecran_Benevoles_Liste)

**Composants :**
-   **TextSearchBox** : Pour chercher par nom.
-   **DropdownFilter** : Pour filtrer par Compétence ou Statut.
-   **GalleryBenevoles** : Affiche les résultats.

**Formule `Items` de la Galerie :**
```powerfx
SortByColumns(
    Search(
        Filter(
            Benevoles,
            (IsBlank(DropdownStatut.Selected.Value) || Statut.Value = DropdownStatut.Selected.Value)
        ),
        TextSearchBox.Text,
        "Title", "Nom", "Prenom", "EmailBenevole"
    ),
    "Nom",
    SortOrder.Ascending
)
```

**Champs dans la Galerie :**
-   Image (si disponible) ou Initiales.
-   Nom Complet : `ThisItem.Nom & " " & ThisItem.Prenom`
-   Compétences : `Concat(ThisItem.Competences, Value, ", ")`
-   Statut : Badge de couleur selon le statut.

### C. Écran Détail Bénévole (Ecran_Benevoles_Detail)

**Design :**
-   Utilisez un **Formulaire en mode Affichage (ViewForm)** connecté à `GalleryBenevoles.Selected`.
-   Ajoutez une **Galerie secondaire** en dessous pour afficher l'historique des affectations.

**Formule `Items` de la Galerie Affectations :**
```powerfx
Filter(Affectations, BenevoleID.Id = GalleryBenevoles.Selected.ID)
```

### D. Écran Affectation (Ecran_Affectation)

**Objectif :** Créer un lien entre une Mission et un Bénévole.

**Composants :**
-   **ComboBoxBenevole** : Liste des bénévoles actifs.
-   **ComboBoxMission** : Liste des missions planifiées/en cours.
-   **DatePicker** : Date de début/fin.
-   **Bouton Valider**.

**Formule du Bouton Valider (`OnSelect`) :**
```powerfx
Patch(
    Affectations,
    Defaults(Affectations),
    {
        Title: "Affectation - " & ComboBoxBenevole.Selected.Title,
        BenevoleID: ComboBoxBenevole.Selected,
        MissionID: ComboBoxMission.Selected,
        StatutAffectation: { Value: "En attente" },
        DateProposition: Now()
    }
);
Notify("Affectation créée avec succès", NotificationType.Success);
Navigate(Ecran_Missions_Liste);
```

---

## 4. Design et UX (Expérience Utilisateur)

### Charte Graphique
-   **Couleurs** : Utilisez une palette cohérente (ex: Bleu pour les actions principales, Gris pour le fond).
-   **Composants** : Créez un "Composant d'En-tête" réutilisable sur chaque écran pour faciliter la navigation.

### Feedback Utilisateur
-   Utilisez `Notify()` après chaque action (enregistrement, suppression).
-   Affichez des indicateurs de chargement (spinners) lors des opérations longues.

---

## 5. Prochaines Étapes (Power Automate)

Une fois l'application en place, nous créerons les flux suivants :
1.  **Notification d'Affectation** : Envoi d'un email au bénévole quand une affectation est créée.
2.  **Rappel de Mission** : Envoi d'un rappel 2 jours avant le début d'une mission.

---

## Annexe : Astuces Power Fx

**Gérer les dates vides :**
```powerfx
If(IsBlank(ThisItem.DateNaissance), "Non renseignée", Text(ThisItem.DateNaissance, "dd/mm/yyyy"))
```

**Concaténer l'adresse complète :**
```powerfx
Concatenate(ThisItem.Adresse1, " ", ThisItem.NPA, " ", ThisItem.Ville)
```

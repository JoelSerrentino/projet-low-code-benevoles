# 📝 Notes de session - 7 décembre 2025 (Session 2)

## Phase 2: Export et transformation des données Access

**Durée:** 14:55 - 15:03 (8 minutes)  
**Statut:** ✅ Export et fusion complétés avec succès

---

## ✅ Réalisations

### 1. Export des tables Access brutes (Script 02-Export-Simple.ps1)

**Problèmes rencontrés:**
- ❌ Script original `02-Export-Access-CSV.ps1` avec erreurs d'encodage et syntaxe PowerShell
- ❌ Méthode `TransferText` bloquée par conflit séparateurs régionaux (français)

**Solution implémentée:**
- ✅ Création script simplifié `02-Export-Simple.ps1`
- ✅ Utilisation d'ADO/OLEDB au lieu de TransferText
- ✅ Génération manuelle des CSV (évite les problèmes de séparateurs)

**Résultats:**
```
PERSONNE.csv      : 1,808 enregistrements (937 KB)
BENEVOLE.csv      : 1,121 enregistrements (219 KB)
BENEFICIAIRE.csv  : 737 enregistrements (142 KB)
ACTIVITE.csv      : 28 enregistrements (1 KB)
EVENEMENT.csv     : 69 enregistrements (5 KB)
DONNER.csv        : 363 enregistrements (3 KB)
PARTICIPANT.csv   : 826 enregistrements (10 KB)
RECEVOIR.csv      : 781 enregistrements (6 KB)
LOCALITE.csv      : 67 enregistrements (1 KB)
```

**Total:** 5,800 enregistrements exportés en 9 tables

---

### 2. Fusion et transformation (Script 02bis-Fusion-Donnees.ps1)

**Problèmes rencontrés:**
- ❌ Erreurs "NullArrayIndex" lors des lookups dans hash tables

**Solution implémentée:**
- ✅ Ajout de vérifications `if ($value)` avant indexation
- ✅ Gestion des valeurs nulles dans LOCALITE_ID

**Transformations effectuées:**

| Fichier SharePoint | Source | Enregistrements | Colonnes | Opérations |
|-------------------|---------|-----------------|----------|------------|
| **Benevoles.csv** | PERSONNE + BENEVOLE + LOCALITE | 1,122 | 32 | INNER JOIN + enrichissement |
| **Beneficiaires.csv** | PERSONNE + BENEFICIAIRE + LOCALITE | 737 | 20 | INNER JOIN + enrichissement |
| **Missions.csv** | ACTIVITE + EVENEMENT | 97 | 17 | UNION + codes |
| **Affectations.csv** | PARTICIPANT + DONNER | 1,189 | 10 | UNION + mapping |
| **Prestations.csv** | RECEVOIR | 781 | 6 | Transformation |

**Total:** 3,926 enregistrements transformés pour SharePoint

---

## 📊 Statistiques de migration

### Vue d'ensemble des données

**Personnes:**
- 1,808 personnes dans la base Access
- 1,122 bénévoles actifs (62%)
- 737 bénéficiaires (41%)
- Note: Une personne peut être à la fois bénévole ET bénéficiaire

**Activités:**
- 28 activités récurrentes
- 69 événements ponctuels
- **97 missions** au total à migrer

**Affectations:**
- 363 affectations activités (DONNER)
- 826 participations événements (PARTICIPANT)
- **1,189 affectations** au total

**Prestations:**
- 781 prestations (bénéficiaires → activités)

---

## 🔧 Améliorations techniques

### 1. Export ADO vs TransferText

**Ancien code (TransferText):**
```powershell
$access.DoCmd.TransferText(2, $null, $TableName, $outputPath, $true)
```
**Problème:** Conflit séparateurs (`,` vs `;`) avec paramètres régionaux français

**Nouveau code (ADO):**
```powershell
$conn = New-Object -ComObject ADODB.Connection
$rs = New-Object -ComObject ADODB.Recordset
$conn.Open("Provider=Microsoft.ACE.OLEDB.12.0;Data Source=$AccessDbPath;")
$rs.Open("SELECT * FROM [$TableName]", $conn)
# Génération manuelle CSV avec échappement guillemets
```
**Avantages:**
- ✅ Contrôle total du format CSV
- ✅ Échappement correct des guillemets et virgules
- ✅ Indépendant des paramètres régionaux
- ✅ Encodage UTF-8 garanti

### 2. Gestion des lookups dans hash tables

**Problème:** Valeurs nulles causent "NullArrayIndex"

**Solution:**
```powershell
# Avant (erreur)
$benevolesHash[$b.PERSONNE_ID] = $b

# Après (sécurisé)
if ($b.PERSONNE_ID) {
    $benevolesHash[$b.PERSONNE_ID] = $b
}

# Utilisation sécurisée
$loc = $null
if ($p.LOCALITE_ID) {
    $loc = $localitesHash[$p.LOCALITE_ID]
}
```

---

## 📁 Structure des fichiers

### Répertoire des exports

```
exports/
├── PERSONNE.csv           (brut Access)
├── BENEVOLE.csv           (brut Access)
├── BENEFICIAIRE.csv       (brut Access)
├── ACTIVITE.csv           (brut Access)
├── EVENEMENT.csv          (brut Access)
├── DONNER.csv             (brut Access)
├── PARTICIPANT.csv        (brut Access)
├── RECEVOIR.csv           (brut Access)
├── LOCALITE.csv           (brut Access)
└── sharepoint/            (transformés pour SharePoint)
    ├── Benevoles.csv      ✅ Prêt
    ├── Beneficiaires.csv  ✅ Prêt
    ├── Missions.csv       ⚠️ À compléter manuellement
    ├── Affectations.csv   ✅ Prêt (lookups à résoudre après import)
    └── Prestations.csv    ✅ Prêt (lookups à résoudre après import)
```

---

## ⚠️ Actions manuelles requises

### Avant l'import SharePoint

1. **Validation RGPD** (URGENT)
   - [ ] Ouvrir `Benevoles.csv`
   - [ ] Vérifier colonne `RGPDConsentement` (actuellement "A_VERIFIER")
   - [ ] Remplacer par "Oui" ou "Non" selon les consentements réels
   - [ ] Répéter pour `Beneficiaires.csv`

2. **Compléter Missions.csv** (RECOMMANDÉ)
   - [ ] Ouvrir `Missions.csv`
   - [ ] Compléter colonne `ResponsableMission`
   - [ ] Compléter colonne `CompetencesRequises`
   - [ ] Ajuster `Priorite` si nécessaire (actuellement "Moyenne" partout)

3. **Vérification générale**
   - [ ] Ouvrir chaque fichier CSV dans Excel
   - [ ] Vérifier l'intégrité des données
   - [ ] Contrôler les accents et caractères spéciaux

---

## 🎯 Prochaine étape

### Étape 7: Import CSV → SharePoint

**Script:** `03-Import-SharePoint.ps1`  
**Pré-requis:**
- ✅ Listes SharePoint créées (Phase 1 complétée)
- ✅ Fichiers CSV transformés (Phase 2 complétée)
- ⏳ Validation RGPD à faire
- ⏳ Complétion Missions.csv (optionnel)

**Commande:**
```powershell
cd "c:\Users\joels\OneDrive - Serrentino\Documents\5 - Informatique\Mes projets developpement\2_Projets Office\2025 - projet-low-code-benevoles\scripts"

.\03-Import-SharePoint.ps1 `
    -SiteUrl "https://serrentino.sharepoint.com/sites/GestionBenevoles" `
    -CSVFolder "..\exports\sharepoint"
```

**Ordre d'import:**
1. Bénévoles (aucune dépendance)
2. Bénéficiaires (aucune dépendance)
3. Missions (aucune dépendance)
4. Affectations (dépend de: Bénévoles, Missions)
5. Prestations (dépend de: Bénéficiaires, Missions)

**Estimation:** ~15-20 minutes pour 3,926 enregistrements

---

## 📝 Leçons apprises

1. **Encodage PowerShell**
   - Les scripts avec caractères accentués peuvent causer des erreurs de parsing
   - Toujours utiliser UTF-8 BOM pour les scripts PowerShell
   - Préférer les caractères ASCII dans les commentaires techniques

2. **Export Access**
   - TransferText est fragile avec les paramètres régionaux
   - ADO/OLEDB offre un meilleur contrôle
   - Toujours tester avec des données réelles avant production

3. **PowerShell hash tables**
   - Toujours vérifier les clés nulles avant indexation
   - Utiliser `if ($key)` ou `$hash.ContainsKey($key)`
   - Préférer `$null` explicite aux valeurs non initialisées

4. **Migration de données**
   - Séparer export brut et transformation
   - Conserver les fichiers bruts pour traçabilité
   - Documenter toutes les transformations appliquées

---

## 📈 Progression globale

**Phase 1:** ✅ Infrastructure SharePoint (7 listes + 111 colonnes)  
**Phase 2:** ✅ Export Access (9 tables → 5,800 enregistrements)  
**Phase 2:** ✅ Transformation (5 fichiers SharePoint → 3,926 enregistrements)  
**Phase 2:** ⏳ Import SharePoint (en attente)  
**Phase 3:** ⏳ Power Apps (non démarrée)  
**Phase 4:** ⏳ Power Automate (non démarrée)

**Avancement:** ~55% (2 phases sur 4 complétées)

---

**Session terminée:** 7 décembre 2025, 15:03  
**Prochaine session:** Import SharePoint (Étape 7)

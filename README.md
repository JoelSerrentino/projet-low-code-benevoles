# Projet Low-Code Gestion Bénévoles SAS

> Application Power Apps pour moderniser la gestion de plus de 200 bénévoles avec centralisation des profils, automatisation des affectations et suivi des missions.

## 📋 Vue d'ensemble

Ce projet vise à remplacer la base de données Microsoft Access actuelle par une solution moderne basée sur **Microsoft Power Platform** :
- **Power Apps Canvas** pour l'interface utilisateur (coordinateurs uniquement)
- **SharePoint Online** pour le stockage des données
- **Power Automate** pour les automatisations
- **Microsoft 365** pour l'authentification et les notifications

### Objectifs principaux
1. ✅ Centraliser les données bénévoles et bénéficiaires (coordonnées, compétences, besoins)
2. ⚡ Automatiser l'affectation et les notifications liées aux missions
3. 📊 Tableau de bord temps réel pour la planification
4. 🤝 Suivre les prestations aux bénéficiaires
5. 🔒 Garantir la conformité RGPD

---

## 📁 Structure du projet

```
projet-low-code-benevoles/
├── README.md                           # Ce fichier
├── projet-low-code-benevoles.md        # Cahier des charges complet
│
├── docs/
│   ├── analyse-access-structure.md     # Analyse de la base Access existante
│   ├── mapping-access-sharepoint.md    # Plan de migration Access → SharePoint
│   ├── specifications-sharepoint.md    # Spécifications détaillées des listes
│   ├── architecture-power-apps.md      # Structure et écrans Power Apps
│   ├── workflows-power-automate.md     # Flux d'automatisation
│   ├── guide-execution-scripts.md      # ✅ Guide complet d'exécution des scripts
│   └── resume-executif.md              # Résumé exécutif du projet
│
├── scripts/
│   ├── Analyser-BaseAccess.ps1                # Script d'analyse Access
│   ├── 01-Creation-Listes-SharePoint.ps1      # ✅ Création automatique listes SharePoint
│   ├── 02-Export-Access-CSV.ps1               # ✅ Export Access → CSV
│   ├── 03-Import-SharePoint.ps1               # ✅ Import CSV → SharePoint
│   └── 04-Verification-Migration.ps1          # ✅ Vérification et rapport HTML
│
└── templates/
    ├── Email-Bienvenue.html            # Templates d'emails (à créer)
    └── Checklist-Onboarding.pdf        # Documents support (à créer)
```

---

## 🚀 Démarrage rapide

### Prérequis

- [ ] Tenant Microsoft 365 actif
- [ ] Licences Power Apps (per-app ou per-user)
- [ ] Accès administrateur SharePoint Online
- [ ] Power Automate inclus dans licence M365
- [ ] Microsoft Access (pour analyse base existante)

### Étapes de mise en œuvre

#### Phase 1: Préparation (Semaine 1-2)

1. **Analyser la base Access existante**
   ```powershell
   cd "D:\_Projets\bd_SAS-Benevolat\scripts"
   .\Analyser-BaseAccess.ps1
   ```

2. **Lire la documentation**
   - 📖 [Cahier des charges](projet-low-code-benevoles.md)
   - 🗺️ [Mapping Access → SharePoint](docs/mapping-access-sharepoint.md)
   - 📋 [Spécifications SharePoint](docs/specifications-sharepoint.md)

3. **Créer les groupes de sécurité M365**
   - Administrateurs Bénévoles
   - Coordinateurs Bénévoles

#### Phase 2: Création structure SharePoint (Semaine 3)

4. **Créer le site SharePoint**
   - Nom: "Gestion Bénévoles SAS"
   - Template: Site d'équipe
   - URL: https://[tenant].sharepoint.com/sites/GestionBenevoles

5. **Créer les listes SharePoint automatiquement** ✅
   ```powershell
   cd "D:\_Projets\bd_SAS-Benevolat\scripts"
   .\01-Creation-Listes-SharePoint.ps1 -SiteUrl "https://[tenant].sharepoint.com/sites/GestionBenevoles"
   ```
   - ✅ Crée automatiquement 7 listes (Bénévoles, Missions, Affectations, Disponibilités, Bénéficiaires, Prestations, Documents)
   - ✅ Configure colonnes avec types, validations, vues
   - ✅ Durée: 4-6 minutes

#### Phase 3: Import données (Semaine 4)

6. **Exporter données Access** ✅
   ```powershell
   .\02-Export-Access-CSV.ps1
   ```
   - ✅ Fusionne PERSONNE+BENEVOLE, ACTIVITE+EVENEMENT, PARTICIPANT+DONNER, PERSONNE+BENEFICIAIRE, RECEVOIR
   - ✅ Génère fichiers CSV avec nettoyage automatique
   - ✅ Durée: 2-4 minutes

7. **Importer dans SharePoint** ✅
   ```powershell
   .\03-Import-SharePoint.ps1 -SiteUrl "https://[tenant].sharepoint.com/sites/GestionBenevoles"
   ```
   - ✅ Import par lots (100 items), gestion automatique des lookups
   - ✅ Logging complet avec rapport d'erreurs
   - ✅ Durée: 5-10 minutes

8. **Vérifier l'intégrité** ✅
   ```powershell
   .\04-Verification-Migration.ps1 -SiteUrl "https://[tenant].sharepoint.com/sites/GestionBenevoles"
   ```
   - ✅ Compare Access vs SharePoint (comptages, lookups, qualité)
   - ✅ Génère rapport HTML interactif avec problèmes détectés
   - ✅ Durée: 3-5 minutes

📖 **Guide complet** : [docs/guide-execution-scripts.md](docs/guide-execution-scripts.md)

#### Phase 4: Développement Power Apps (Semaine 5-6)

9. **Créer l'application Power Apps**
    - Type: Canvas app (desktop/tablette)
    - Connecter aux listes SharePoint
    - Suivre [architecture-power-apps.md](docs/architecture-power-apps.md)

10. **Développer les écrans**
    - ✅ Accueil / Dashboard
    - ✅ Liste bénévoles + Fiche bénévole
    - ✅ Liste bénéficiaires + Fiche bénéficiaire
    - ✅ Gestion missions
    - ✅ Affectations
    - ✅ Prestations (services aux bénéficiaires)
    - ✅ Onboarding
    - ✅ Disponibilités

#### Phase 5: Automatisations (Semaine 7)

11. **Créer les flux Power Automate**
    - Suivre [workflows-power-automate.md](docs/workflows-power-automate.md)
    - Priorité 1: Onboarding, Notifications, Alertes urgentes
    - Priorité 2: Rappels, Expirations
    - Priorité 3: Approbations, Rapports

#### Phase 6: Tests et déploiement (Semaine 8)

12. **Tests utilisateurs**
    - Groupe pilote: 5 coordinateurs
    - Tests scénarios complets
    - Collecter retours

13. **Ajustements et formation**
    - Corriger bugs identifiés
    - Former utilisateurs finaux
    - Créer documentation utilisateur

14. **Mise en production**
    - Partager app Power Apps
    - Activer tous les flux
    - Communiquer auprès des bénévoles

---

## 📊 Architecture technique

### Stack technologique

| Composant | Technologie | Rôle |
| --- | --- | --- |
| **Interface utilisateur** | Power Apps Canvas | Application desktop/tablette |
| **Base de données** | SharePoint Online (listes) | Stockage structuré |
| **Documents** | SharePoint (bibliothèque) | Fichiers bénévoles |
| **Automatisation** | Power Automate | Workflows et notifications |
| **Authentification** | Azure AD | SSO Microsoft 365 |
| **Notifications** | Office 365 Outlook + Teams | Emails et messages |
| **Reporting** | Power Apps (export Excel) | Tableaux de bord et KPIs |

### Modèle de données

```
Bénévoles (1) ──────< Affectations >────── (N) Missions
    │                                            │
    │                                            ├──< Types: Récurrentes / Ponctuelles
    └──< Disponibilités                          │
    │                                            │
    └──< Documents Bénévoles                     │
                                                 │
Bénéficiaires (1) ──< Prestations >─────────────┘
```

**Listes SharePoint:**
- `Benevoles` : 200+ enregistrements (profils complets)
- `Missions` : ~80/an (récurrentes + ponctuelles)
- `Affectations` : ~1000/an (bénévoles → missions)
- `Beneficiaires` : Personnes aidées (profils, besoins)
- `Prestations` : Services rendus (bénéficiaires ↔ missions)
- `Disponibilites` : Planning individuel
- `DocumentsBenevoles` : Bibliothèque (certificats, contrats)

---

## 🔐 Sécurité et conformité RGPD

### Permissions

| Rôle | Accès Bénévoles | Accès Missions | Accès Documents |
| --- | --- | --- | --- |
| **Administrateur** | Contrôle total | Contrôle total | Tous documents |
| **Coordinateur** | Lecture/Écriture | Création/Modification | Documents internes |

### Conformité RGPD

✅ **Consentement explicite** : Champ obligatoire `RGPDConsentement`  
✅ **Minimisation des données** : Uniquement champs nécessaires  
✅ **Droit à l'oubli** : Workflow de suppression sur demande  
✅ **Portabilité** : Export Excel intégré  
✅ **Conservation limitée** : Politique 3 ans  
✅ **Logs d'accès** : Audit SharePoint activé  

---

## 📈 Indicateurs de succès

| KPI | Cible | Mesure |
| --- | --- | --- |
| **Profils à jour** | 90% des bénévoles actifs | Disponibilités < 90 jours |
| **Temps d'affectation** | < 2 jours | Date proposition → confirmation |
| **Missions pourvues** | 100% des critiques | 48h avant événement |
| **Satisfaction coordinateurs** | ≥ 4/5 | Enquête trimestrielle |
| **Utilisation app** | 80% adoption | Connexions mensuelles |

---

## 📚 Documentation

### Pour les développeurs
- [Spécifications détaillées SharePoint](docs/specifications-sharepoint.md)
- [Architecture Power Apps](docs/architecture-power-apps.md)
- [Workflows Power Automate](docs/workflows-power-automate.md)
- [Mapping migration Access](docs/mapping-access-sharepoint.md)

### Pour les administrateurs
- **[Guide d'exécution des scripts PowerShell](docs/guide-execution-scripts.md)** ✅
- [Résumé exécutif](docs/resume-executif.md)
- Procédures d'exploitation *(à créer)*
- Backup et restauration *(à créer)*

### Pour les utilisateurs
- Guide de démarrage rapide *(à créer)*
- Tutoriels vidéo *(à créer)*
- FAQ *(à créer)*

---

## 🛠️ Maintenance et support

### Responsabilités

| Rôle | Responsable | Tâches |
| --- | --- | --- |
| **Admin projet** | Joël | Développement, évolutions, support N3 |
| **Coordinateurs** | Équipe terrain | Support utilisateur, gestion quotidienne |
| **DSI/IT** | Service informatique | Licences, sauvegardes, sécurité tenant |

### Processus de support

1. **Niveau 1** : Coordinateurs (questions utilisateurs)
2. **Niveau 2** : Administrateur projet (bugs, évolutions mineures)
3. **Niveau 3** : DSI/Microsoft Support (problèmes infrastructure)

### Backlog et améliorations

Voir fichier `BACKLOG.md` *(à créer)* pour:
- Fonctionnalités en développement
- Bugs connus
- Demandes d'évolution

---

## 📞 Contacts

| Fonction | Personne | Contact |
| --- | --- | --- |
| **Chef de projet** | Joël Serrentino | [Email] |
| **Validation métier** | [Responsable bénévoles] | [Email] |
| **Support technique** | [DSI] | [Email] |

---

## 📄 Licence et confidentialité

Ce projet est la propriété de **SAS (Service d'Aide et de Soins)**. Toutes les données sont confidentielles et protégées par les réglementations RGPD.

---

## 🎯 Statut du projet

**Phase actuelle :** Scripts d'automatisation prêts ✅  
**Prochaine étape :** Exécution migration Access → SharePoint  
**Date de mise en production prévue :** [À définir]

### Progression globale

- [x] Analyse base Access existante
- [x] Mapping Access → SharePoint
- [x] Spécifications techniques complètes (100+ pages)
- [x] **Scripts PowerShell automatisés (4 scripts, ~2800 lignes)** ✅
- [ ] Création listes SharePoint (script prêt)
- [ ] Import données (script prêt)
- [ ] Développement Power Apps
- [ ] Création workflows Power Automate
- [ ] Tests utilisateurs
- [ ] Déploiement production

### ⚡ Migration automatisée en 4 étapes

```powershell
# 1. Créer listes SharePoint (3-5 min)
.\01-Creation-Listes-SharePoint.ps1 -SiteUrl "https://[tenant].sharepoint.com/sites/GestionBenevoles"

# 2. Exporter Access vers CSV (2-3 min)
.\02-Export-Access-CSV.ps1

# 3. Importer CSV vers SharePoint (5-10 min)
.\03-Import-SharePoint.ps1 -SiteUrl "https://[tenant].sharepoint.com/sites/GestionBenevoles"

# 4. Vérifier migration + Rapport HTML (3-5 min)
.\04-Verification-Migration.ps1 -SiteUrl "https://[tenant].sharepoint.com/sites/GestionBenevoles"
```

📖 **[Guide complet d'exécution](docs/guide-execution-scripts.md)** avec prérequis, dépannage, FAQ

---

**Dernière mise à jour :** 18 novembre 2025  
**Version documentation :** 1.0
Projet Low-code Gestion Bénévoles

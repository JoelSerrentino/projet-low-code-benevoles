# Cahier des charges – Projet Low-code Gestion Bénévoles

## 1. Contexte et enjeux
- Moderniser la gestion de plus de 200 bénévoles en centralisant profils, disponibilités et documents.
- Réduire le temps d'affectation aux missions récurrentes/ponctuelles.
- Offrir une visibilité temps réel aux coordinateurs et faciliter l'onboarding.

## 2. Objectifs
1. Centraliser les données bénévoles (coordonnées, compétences, certificats) dans Microsoft 365.
2. Automatiser l'affectation et les notifications liées aux missions.
3. Mettre à disposition un tableau de bord fiable pour la planification.
4. Garantir la conformité RGPD (droit à l'oubli, minimisation des données).

## 3. Périmètre fonctionnel
- Application Power Apps Canvas (desktop/tablette) pour coordinateurs et administrateurs.
- Formulaires onboarding bénévoles + mise à jour des disponibilités.
- Automatisations Power Automate pour notifications, rappels, workflows d'approbation.
- Stockage SharePoint Online : listes "Bénévoles", "Missions", "Affectations", "Disponibilités", "Documents".
- Tableau de bord intégré (galeries, graphiques, export Excel).

## 4. Acteurs & rôles
| Acteur | Responsabilités |
| --- | --- |
| Administrateur projet (Joël) | Paramétrage Power Apps/Automate, gouvernance, support. |
| Coordinateurs bénévoles | Création des missions, affectations, validations d'heures. |
| Bénévoles | Mise à jour profil et disponibilités via formulaires sécurisés. |
| DSI / Sécurité | Gestion tenant M365, licences, conformité, sauvegardes. |

## 5. Fonctionnalités détaillées
1. **Gestion des bénévoles** : fiches complètes, statut actif/inactif, upload de documents (PDF, images), historique missions.
2. **Disponibilités** : planning récurrent, validation des chevauchements, rappels automatiques pour mise à jour.
3. **Missions & matching** : saisie mission (compétences requises, slots), filtrage intelligent (compétences + disponibilité), proposition puis confirmation.
4. **Onboarding** : wizard multi-étapes (données perso, charte, documents), checklist automatisée (Power Automate) pour chaque nouveau bénévole.
5. **Notifications & reporting** : e-mails / Teams aux bénévoles affectés, alertes missions non pourvues, KPI en page d'accueil.
6. **Sécurité & conformité** : rôles via groupes Microsoft 365, masquage champs sensibles, politique de conservation 3 ans, consentement explicite.

## 6. Architecture technique
- Power Apps Canvas + Power Automate + SharePoint Online (listes + bibliothèques).
- Authentification Azure AD, MFA recommandé.
- Connecteurs standard Microsoft 365 (pas de connecteur premium requis).
- Versioning SharePoint activé + sauvegardes quotidiennes Infomaniak/M365.

## 7. Modèle de données (extrait)
- **Bénévoles** : ID, Nom, Email, Téléphone, Compétences (multi), Disponibilités préférées, Statut, Date d'entrée, Documents (lookup), Notes.
- **Missions** : ID, Titre, Description, Date début/fin, Lieu, Responsable, Compétences requises, Nombre de bénévoles, Statut.
- **Affectations** : MissionID, BénévoleID, Statut (proposé/confirmé/annulé), Commentaire.
- **Disponibilités** : BénévoleID, Jour, Plage horaire, Récurrence, Dernière mise à jour.
- **Documents** : BénévoleID, Type (certificat, badge, contrat), Date d'expiration, URL fichier.

## 8. Contraintes & hypothèses
- Données hébergées dans le tenant M365 existant (licences Power Apps per-app ou per-user).
- Volume cible : 200 bénévoles, 80 missions/an, 1 000 affectations.
- Support mobile : lecture/écriture via Power Apps (connexion internet obligatoire).
- Respect RGPD (données minimales, suppression sur demande, logs d'accès).
- Pas d'intégration paie/comptabilité dans cette phase.

## 9. Planification indicative
1. Recueil détaillé des besoins & maquettes (S1-S2).
2. Prototype Power Apps + listes SharePoint (S3-S4).
3. Automatisations Power Automate + sécurité (S5-S6).
4. Tests utilisateurs & ajustements (S7).
5. Déploiement pilote + généralisation (S8).

## 10. Indicateurs de succès
- 90 % des bénévoles actifs ayant leurs disponibilités à jour.
- Temps moyen d'affectation < 2 jours.
- Zéro mission critique sans bénévole assigné 48 h avant l'événement.
- Satisfaction coordinateurs ≥ 4/5.

## 11. Livrables
- Application Power Apps empaquetée + procédure d'installation.
- Documentation utilisateur (PDF/OneNote) + tutoriels courts.
- Procédures d'exploitation (ajout utilisateur, gestion incidents, backup).
- Registre d'amélioration continue (backlog).

# 🔐 Guide Express - Créer une Application Entra ID pour PnP

**Durée:** 3 minutes  
**Prérequis:** Accès administrateur au portail Azure

---

## Étape 1: Créer l'application (2 minutes)

1. **Ouvrir le portail Azure**
   ```
   https://portal.azure.com
   ```

2. **Navigation**
   - Recherchez "Entra ID" dans la barre de recherche en haut
   - Cliquez sur **Microsoft Entra ID**
   - Dans le menu de gauche, cliquez sur **Inscriptions d'applications**
   - Cliquez sur **+ Nouvelle inscription**

3. **Remplir le formulaire**
   - **Nom:** `PnP PowerShell - Gestion Benevoles`
   - **Types de comptes pris en charge:** Comptes dans cet annuaire d'organisation uniquement (Serrentino uniquement - Locataire unique)
   - **URI de redirection:** 
     - Type: **Application cliente publique/native (mobile et bureau)**
     - URI: `http://localhost`
   - Cliquez sur **Inscrire**

4. **Copier l'ID d'application**
   - Une fois créée, vous verrez la page de vue d'ensemble
   - **COPIEZ** l'**ID d'application (client)** 
   - Format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - **GARDEZ-LE** pour l'étape 3 !

---

## Étape 2: Configurer les permissions (1 minute)

5. **Ajouter les permissions SharePoint**
   - Dans le menu de gauche, cliquez sur **Autorisations de l'API**
   - Cliquez sur **+ Ajouter une autorisation**
   - Sélectionnez **SharePoint**
   - Sélectionnez **Autorisations déléguées**
   - Cochez **AllSites.FullControl**
   - Cliquez sur **Ajouter des autorisations**

6. **Accorder le consentement administrateur**
   - Cliquez sur **✓ Accorder le consentement de l'administrateur pour Serrentino**
   - Confirmez en cliquant sur **Oui**
   - Attendez que le statut passe à ✓ vert

---

## Étape 3: Tester la connexion

7. **Retourner dans PowerShell et exécuter:**

```powershell
# REMPLACEZ [VOTRE-APP-ID] par l'ID copié à l'étape 4
$appId = "[VOTRE-APP-ID]"

# Tester la connexion
Connect-PnPOnline -Url "https://serrentino.sharepoint.com/sites/GestionBenevoles" -Interactive -ClientId $appId

# Si connecté avec succès, vous verrez:
Get-PnPWeb | Select-Object Title, Url
```

**Résultat attendu:**
```
Title                    Url
-----                    ---
Gestion Bénévoles SAS    https://serrentino.sharepoint.com/sites/GestionBenevoles
```

---

## Étape 4: Mettre à jour le script

8. **Modifier le script 01-Creation-Listes-SharePoint.ps1**

Remplacez la ligne de connexion par:

```powershell
Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId "[VOTRE-APP-ID]"
```

---

## ✅ C'est terminé !

Vous pouvez maintenant exécuter:

```powershell
.\01-Creation-Listes-SharePoint.ps1 -SiteUrl "https://serrentino.sharepoint.com/sites/GestionBenevoles"
```

---

## 📸 Capture d'écran des étapes clés

### À l'étape 3 - Nouvelle inscription:
![image](https://learn.microsoft.com/fr-fr/entra/identity-platform/media/quickstart-register-app/portal-02-app-reg-01.png)

### À l'étape 5 - Permissions SharePoint:
![image](https://learn.microsoft.com/fr-fr/sharepoint/dev/images/sharepoint-api-permissions.png)

---

## 🆘 En cas de problème

**Erreur "Vous n'avez pas les autorisations":**
- Vous devez être Administrateur global ou Administrateur d'application dans Entra ID

**L'option SharePoint n'apparaît pas dans les API:**
- Tapez "SharePoint" dans la barre de recherche
- Ou cherchez "Office 365 SharePoint Online"

**Le consentement administrateur échoue:**
- Vérifiez que vous êtes bien administrateur global
- Ou demandez à votre administrateur global de donner le consentement

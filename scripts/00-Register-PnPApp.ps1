# ============================================================================================================
# Script: Enregistrement Application PnP pour SharePoint
# Description: Enregistre une application Entra ID pour permettre l'authentification PnP.PowerShell
# ============================================================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ENREGISTREMENT APPLICATION PNP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Cette application permettra aux scripts PowerShell de se connecter à SharePoint." -ForegroundColor Yellow
Write-Host ""

# Demander le tenant
$tenant = Read-Host "Entrez votre nom de tenant (ex: serrentino)"
$siteUrl = "https://$tenant.sharepoint.com/sites/GestionBenevoles"

Write-Host ""
Write-Host "Enregistrement de l'application PnP Management Shell..." -ForegroundColor Cyan

try {
    # Enregistrer l'application avec permissions SharePoint
    Register-PnPEntraIDAppForInteractiveLogin `
        -ApplicationName "PnP PowerShell - Gestion Benevoles" `
        -Tenant "$tenant.onmicrosoft.com" `
        -Interactive
    
    Write-Host ""
    Write-Host "✓ Application enregistrée avec succès !" -ForegroundColor Green
    Write-Host ""
    Write-Host "Vous pouvez maintenant exécuter les scripts de migration." -ForegroundColor Green
    Write-Host ""
    
    # Sauvegarder les informations
    $appInfo = @"
Application PnP enregistrée le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Tenant: $tenant
Site: $siteUrl

Pour vous connecter, utilisez:
Connect-PnPOnline -Url "$siteUrl" -Interactive

L'application est visible dans:
https://portal.azure.com → Entra ID → Inscriptions d'applications → "PnP PowerShell - Gestion Benevoles"
"@
    
    $appInfo | Out-File ".\PnP-App-Info.txt"
    Write-Host "Informations sauvegardées dans: PnP-App-Info.txt" -ForegroundColor Cyan
}
catch {
    Write-Host ""
    Write-Host "✗ Erreur lors de l'enregistrement: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "SOLUTION ALTERNATIVE:" -ForegroundColor Yellow
    Write-Host "1. Ouvrez https://portal.azure.com" -ForegroundColor White
    Write-Host "2. Allez dans Entra ID → Inscriptions d'applications → + Nouvelle inscription" -ForegroundColor White
    Write-Host "3. Nom: PnP PowerShell - Gestion Benevoles" -ForegroundColor White
    Write-Host "4. Types de comptes: Comptes dans cet annuaire uniquement" -ForegroundColor White
    Write-Host "5. URI de redirection: http://localhost" -ForegroundColor White
    Write-Host "6. Cliquez sur Inscrire" -ForegroundColor White
    Write-Host "7. Notez l'ID d'application (client)" -ForegroundColor White
    Write-Host "8. Allez dans Autorisations API → + Ajouter une autorisation" -ForegroundColor White
    Write-Host "9. SharePoint → Autorisations déléguées → Cochez AllSites.FullControl" -ForegroundColor White
    Write-Host "10. Cliquez sur Accorder le consentement de l'administrateur" -ForegroundColor White
    exit 1
}

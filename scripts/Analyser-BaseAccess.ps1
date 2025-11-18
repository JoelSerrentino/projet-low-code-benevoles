# Script PowerShell pour analyser la structure de la base Access
# Fichier: D:\_Projets\bd_SAS-Benevolat\SAS-Benevolat.accdb

$accessFile = "D:\_Projets\bd_SAS-Benevolat\SAS-Benevolat.accdb"
$outputFile = "D:\_Projets\bd_SAS-Benevolat\analyse-access-structure.md"

Write-Host "Analyse de la base Access: $accessFile" -ForegroundColor Green

try {
    # Créer une instance de l'objet Access COM
    $access = New-Object -ComObject Access.Application
    $access.Visible = $false
    
    # Ouvrir la base de données
    $access.OpenCurrentDatabase($accessFile, $false)
    
    $output = @()
    $output += "# Analyse de la structure - SAS-Benevolat.accdb"
    $output += "`nDate d'analyse: $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
    $output += "`n---`n"
    
    # Analyser les tables
    $output += "## Tables de la base de données`n"
    
    $tableCount = 0
    foreach ($obj in $access.CurrentDb().TableDefs) {
        # Ignorer les tables système (commencent par MSys ou ~)
        if (-not ($obj.Name.StartsWith("MSys") -or $obj.Name.StartsWith("~"))) {
            $tableCount++
            $output += "### $($tableCount). Table: **$($obj.Name)**`n"
            $output += "| Nom de colonne | Type | Taille | Obligatoire | Description |"
            $output += "| --- | --- | --- | --- | --- |"
            
            foreach ($field in $obj.Fields) {
                $typeName = switch ($field.Type) {
                    1 { "Oui/Non" }
                    2 { "Byte" }
                    3 { "Integer" }
                    4 { "Long" }
                    5 { "Currency" }
                    6 { "Single" }
                    7 { "Double" }
                    8 { "Date/Time" }
                    10 { "Text" }
                    11 { "OLE Object" }
                    12 { "Memo" }
                    15 { "ReplicationID" }
                    16 { "BigInt" }
                    default { "Type $($field.Type)" }
                }
                
                $required = if ($field.Required) { "Oui" } else { "Non" }
                $size = if ($field.Size -gt 0) { $field.Size } else { "N/A" }
                
                $output += "| $($field.Name) | $typeName | $size | $required | |"
            }
            
            $output += "`n**Nombre d'enregistrements:** À compter"
            $output += "`n"
        }
    }
    
    # Analyser les requêtes
    $output += "`n## Requêtes sauvegardées`n"
    
    $queryCount = 0
    foreach ($obj in $access.CurrentDb().QueryDefs) {
        if (-not $obj.Name.StartsWith("~")) {
            $queryCount++
            $output += "### Requête $($queryCount): **$($obj.Name)**"
            $output += "- Type: Requête SQL"
            $output += "- À reproduire dans Power Apps via formules Filter/LookUp`n"
        }
    }
    
    # Analyser les formulaires
    $output += "`n## Formulaires Access`n"
    
    $formCount = 0
    try {
        foreach ($obj in $access.CurrentProject.AllForms) {
            $formCount++
            $output += "### Formulaire $($formCount): **$($obj.Name)**"
            $output += "- À recréer comme écran Power Apps`n"
        }
    } catch {
        $output += "- Impossible de lister les formulaires automatiquement`n"
    }
    
    # Analyser les états (rapports)
    $output += "`n## États/Rapports`n"
    
    $reportCount = 0
    try {
        foreach ($obj in $access.CurrentProject.AllReports) {
            $reportCount++
            $output += "### Rapport $($reportCount): **$($obj.Name)**"
            $output += "- À reproduire via Power BI ou export Excel depuis Power Apps`n"
        }
    } catch {
        $output += "- Impossible de lister les rapports automatiquement`n"
    }
    
    # Résumé
    $output += "`n---`n"
    $output += "## Résumé de l'analyse`n"
    $output += "- **Tables:** $tableCount"
    $output += "- **Requêtes:** $queryCount"
    $output += "- **Formulaires:** $formCount"
    $output += "- **Rapports:** $reportCount"
    
    # Fermer Access
    $access.CloseCurrentDatabase()
    $access.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($access) | Out-Null
    
    # Sauvegarder le résultat
    $output -join "`n" | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "`nAnalyse terminée !" -ForegroundColor Green
    Write-Host "Fichier créé: $outputFile" -ForegroundColor Cyan
    
    # Afficher un aperçu
    Write-Host "`n--- APERÇU ---" -ForegroundColor Yellow
    $output | Select-Object -First 50 | ForEach-Object { Write-Host $_ }
    
} catch {
    Write-Host "Erreur lors de l'analyse: $_" -ForegroundColor Red
    Write-Host "Assurez-vous que Microsoft Access est installé sur cet ordinateur." -ForegroundColor Yellow
} finally {
    if ($access) {
        try { $access.Quit() } catch {}
    }
}

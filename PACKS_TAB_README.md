# 📦 Onglet Packs - Dashboard Administrateur

## Vue d'ensemble

Un nouvel onglet "Packs" a été ajouté au dashboard administrateur pour visualiser les statistiques détaillées des achats de packs par type, mois et année.

## 🎯 Fonctionnalités

### Onglet Packs

L'onglet affiche deux tableaux récapitulatifs :

1. **Statistiques Mensuelles (Année en cours)**
   - Affichage mois par mois de l'année en cours
   - Pour chaque mois : nombre d'achats et montant total par type de pack
   - Total annuel en bas du tableau

2. **Statistiques Annuelles**
   - Affichage année par année (historique complet)
   - Pour chaque année : nombre d'achats et montant total par type de pack
   - Total général tous temps confondus

3. **KPIs**
   - CA total de l'année en cours
   - CA total tous temps
   - Pack le plus populaire

### Types de packs suivis

- **Crédits** : Packs de crédits pour les sessions
- **Licence** : Licences annuelles
- **Stage** : Packs pour les stages

## 📂 Fichiers créés/modifiés

### Service
- **`app/services/reporting/packs_stats.rb`**
  - Service pour générer les statistiques des packs
  - Méthodes :
    - `monthly_stats_for_current_year` : stats mensuelles pour l'année en cours
    - `yearly_stats` : stats annuelles historiques
    - `pack_details_for_period` : détails par pack pour une période donnée

### Controller
- **`app/controllers/admin/dashboard_controller.rb`**
  - Ajout du case `when 'packs'`
  - Méthode `render_packs_tab` pour préparer les données

### Component
- **`app/components/admin/dashboard_tabs_component.rb`**
  - Ajout de l'onglet "Packs" dans la liste des tabs

### Vue
- **`app/views/admin/dashboard/_packs_tab.html.erb`**
  - Vue partielle pour l'onglet packs
  - Deux tableaux : statistiques mensuelles et annuelles
  - Section KPIs avec 3 cartes

### Tests
- **`spec/services/reporting/packs_stats_spec.rb`**
  - Tests complets du service PacksStats
  - Couvre tous les scénarios : achats mensuels, annuels, par type, etc.
  
- **`spec/components/admin/dashboard_tabs_component_spec.rb`**
  - Test mis à jour pour vérifier la présence de l'onglet "Packs"

## 🚀 Utilisation

### Accès
1. Se connecter en tant qu'administrateur
2. Aller sur `/admin` (Dashboard)
3. Cliquer sur l'onglet "Packs" 📦

### Navigation
- L'onglet affiche automatiquement les statistiques à jour
- Les données sont basées sur les `CreditPurchase` avec le statut `paid`
- Seuls les achats payés (`paid_at` non null) sont comptabilisés

## 📊 Données affichées

### Pour chaque période (mois ou année)
- **Quantité** : Nombre d'achats par type de pack
- **Montant** : Montant total en euros par type de pack
- **Total** : Somme de tous les montants

### Exemple de tableau mensuel

| Période      | Crédits (Qté/€) | Licence (Qté/€) | Stage (Qté/€) | Total |
|--------------|-----------------|-----------------|---------------|-------|
| Janvier 2024 | 15 / 150€       | 5 / 250€        | 0 / 0€        | 400€  |
| Février 2024 | 20 / 200€       | 3 / 150€        | 2 / 100€      | 450€  |
| Mars 2024    | 12 / 120€       | 4 / 200€        | 1 / 50€       | 370€  |

## 🧪 Tests

Pour exécuter les tests :

```bash
# Tests du service PacksStats
bundle exec rspec spec/services/reporting/packs_stats_spec.rb

# Tests du composant DashboardTabs
bundle exec rspec spec/components/admin/dashboard_tabs_component_spec.rb

# Tous les tests liés aux packs
bundle exec rspec spec/services/reporting/packs_stats_spec.rb spec/components/admin/dashboard_tabs_component_spec.rb
```

## 🎨 Design

- Design cohérent avec le reste du dashboard
- Utilisation de Tailwind CSS
- Responsive (adaptatif mobile/tablette/desktop)
- Couleurs :
  - `bg-asmbv-red` pour les totaux importants
  - Vert (`bg-green-600`) pour les KPIs positifs
  - Bleu (`bg-blue-600`) pour l'année en cours

## 🔄 Évolutions futures possibles

- Graphiques d'évolution des ventes
- Export CSV/Excel des statistiques
- Filtres par période personnalisée
- Comparaison d'une période à l'autre
- Détail par pack individuel (drilldown)
- Statistiques par utilisateur

## 📝 Notes techniques

- Les stats sont calculées à la volée (pas de cache pour l'instant)
- Le service utilise des requêtes SQL groupées pour optimiser les performances
- Les montants sont stockés en centimes dans la DB et convertis en euros pour l'affichage
- Le fuseau horaire utilisé est `Europe/Paris`

## 🐛 Dépannage

Si l'onglet n'apparaît pas :
1. Vérifier que l'utilisateur a les droits admin
2. Vérifier que le serveur est redémarré
3. Vérifier les logs pour d'éventuelles erreurs

Si les données ne s'affichent pas :
1. Vérifier qu'il y a des `CreditPurchase` avec `status: :paid`
2. Vérifier que les packs sont bien associés aux purchases (`pack_id` non null)
3. Vérifier les dates de `paid_at`


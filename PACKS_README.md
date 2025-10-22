# 📦 Système de Packs

## Vue d'ensemble

Le système de packs permet aux administrateurs de créer et gérer des offres de crédits, et aux utilisateurs de les acheter via le système de paiement LCL Sherlock.

## 🎯 Fonctionnalités

### Pour les administrateurs

1. **Gestion des packs** (`/admin/packs`)
   - Créer, modifier, supprimer des packs
   - Types de packs : crédits, licence, stage (extensible)
   - Définir le prix, nombre de crédits, description
   - Activer/désactiver les packs
   - Ordonner les packs (position)

2. **Historique des achats** (`/admin/purchase_history`)
   - Voir tous les achats avec détails
   - Stats : CA total, nombre d'achats, achats en attente
   - Filtrer par statut, utilisateur, pack
   - Suivi des références de transaction

### Pour les utilisateurs

1. **Page des packs** (`/packs`)
   - Voir tous les packs actifs de crédits
   - Affichage du solde actuel
   - Détails : prix, crédits, taux de conversion
   - Bouton d'achat direct

2. **Processus d'achat**
   - Clic sur "Acheter"
   - Création automatique du CreditPurchase
   - Redirection vers gateway de paiement
   - Retour success/cancel
   - Crédits ajoutés automatiquement

## 📊 Modèle de données

### Pack

```ruby
Pack
  - name: string              # Ex: "Pack Premium"
  - description: text         # Description du pack
  - pack_type: enum           # credits, licence, stage
  - amount_cents: integer     # Montant en centimes (1000 = 10€)
  - credits: integer          # Nombre de crédits (pour type credits)
  - active: boolean           # Pack disponible à l'achat
  - position: integer         # Ordre d'affichage
```

### Relation avec CreditPurchase

```ruby
CreditPurchase belongs_to :pack, optional: true
Pack has_many :credit_purchases
```

## 🎨 Interface

### Admin - Liste des packs

```
┌─────────────────────────────────────────────────┐
│ Gestion des Packs          [Nouveau pack]       │
├─────────────────────────────────────────────────┤
│ Nom          │ Type     │ Montant │ Crédits    │
│ Pack Standard│ credits  │ 10 €    │ 1000       │
│ Pack Premium │ credits  │ 20 €    │ 2200       │
└─────────────────────────────────────────────────┘
```

### Utilisateur - Achat de packs

```
┌──────────────────┐ ┌──────────────────┐
│ Pack Standard    │ │ Pack Premium     │
│                  │ │                  │
│ 10 €             │ │ 20 €             │
│ 1000 crédits     │ │ 2200 crédits     │
│ [Acheter]        │ │ [Acheter]        │
└──────────────────┘ └──────────────────┘
```

## 🔧 Configuration

### Seeds par défaut

4 packs sont créés automatiquement :

```ruby
bin/rails db:seed

# Pack Découverte: 5€ = 500 crédits
# Pack Standard: 10€ = 1000 crédits
# Pack Premium: 20€ = 2200 crédits (+10% bonus)
# Pack VIP: 50€ = 6000 crédits (+20% bonus)
```

### Créer un nouveau pack

```ruby
Pack.create!(
  name: "Pack Étudiant",
  description: "Tarif réduit pour les étudiants",
  pack_type: :credits,
  amount_cents: 800,  # 8 EUR
  credits: 900,       # +100 crédits bonus
  active: true,
  position: 5
)
```

## 🚀 Utilisation

### En tant qu'admin

1. Aller sur `/admin/packs`
2. Cliquer sur "Nouveau pack"
3. Remplir le formulaire :
   - Nom : "Pack Spécial Noël"
   - Description : "Offre de fin d'année"
   - Type : credits
   - Montant (centimes) : 1500 (15 EUR)
   - Crédits : 1800
   - Position : 3
   - ✓ Pack actif
4. Enregistrer

### En tant qu'utilisateur

1. Aller sur `/packs`
2. Voir son solde actuel
3. Choisir un pack
4. Cliquer sur "Acheter"
5. Payer via LCL Sherlock
6. Redirection vers success
7. Crédits ajoutés automatiquement

## 📈 Évolutions futures

### Court terme
- [ ] Filtres sur l'historique des achats
- [ ] Export CSV des achats
- [ ] Statistiques par pack
- [ ] Codes promo

### Moyen terme
- [ ] Packs de licences (type: licence)
- [ ] Packs de stages (type: stage)
- [ ] Packs personnalisés par utilisateur
- [ ] Abonnements récurrents

### Long terme
- [ ] Système de fidélité
- [ ] Packs familiaux
- [ ] Packs saisonniers automatiques
- [ ] A/B testing des prix

## 🔗 Routes

### Admin

```ruby
GET    /admin/packs                  # Liste des packs
GET    /admin/packs/new              # Formulaire nouveau pack
POST   /admin/packs                  # Créer un pack
GET    /admin/packs/:id/edit         # Formulaire édition
PATCH  /admin/packs/:id              # Mettre à jour
DELETE /admin/packs/:id              # Supprimer

GET    /admin/purchase_history       # Historique des achats
```

### Utilisateurs

```ruby
GET    /packs                        # Liste des packs actifs
POST   /packs/:id/buy                # Acheter un pack
```

## 🧪 Tests

```ruby
# Console Rails
rails console

# Créer un pack
pack = Pack.create!(name: "Test", pack_type: :credits, amount_cents: 1000, credits: 1000, active: true)

# Acheter un pack (simulation)
user = User.first
purchase = user.credit_purchases.create!(
  pack: pack,
  amount_cents: pack.amount_cents,
  currency: 'EUR',
  credits: pack.credits,
  status: :pending
)

# Simuler le paiement
purchase.credit!
user.balance.reload.amount # Devrait avoir augmenté de 1000
```

## 📊 Statistiques

```ruby
# CA total
CreditPurchase.paid_status.sum(:amount_cents) / 100.0

# Pack le plus vendu
Pack.joins(:credit_purchases)
    .where(credit_purchases: { status: :paid })
    .group(:id)
    .order('COUNT(*) DESC')
    .first

# Achats par mois
CreditPurchase.paid_status
              .where('created_at > ?', 1.month.ago)
              .group_by_day(:created_at)
              .count
```

## 🎁 Stratégies de prix

### Bonus progressifs

```ruby
# 5€ = 500 crédits (100 crédits/€)
# 10€ = 1000 crédits (100 crédits/€)
# 20€ = 2200 crédits (110 crédits/€) +10%
# 50€ = 6000 crédits (120 crédits/€) +20%
```

### Formule recommandée

```ruby
def calculate_credits(amount_eur)
  base = amount_eur * 100
  bonus = case amount_eur
          when 0..9 then 0
          when 10..19 then 0.05  # +5%
          when 20..49 then 0.10  # +10%
          else 0.20              # +20%
          end
  (base * (1 + bonus)).to_i
end
```

## 📝 Notes

- Les packs inactifs ne sont pas visibles par les utilisateurs
- Un pack peut être modifié même s'il a des achats associés
- La suppression d'un pack ne supprime pas les achats associés (nullify)
- Les prix sont en centimes pour éviter les problèmes de précision
- Position permet de contrôler l'ordre d'affichage

---

**Statut** : ✅ Système complet et opérationnel  
**Version** : 1.0  
**Date** : 22 octobre 2025


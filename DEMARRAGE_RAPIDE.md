# 🚀 Démarrage Rapide - AS Monaco Beach Volley App

## ✅ Ce qui a été fait

### 1. Migration Sidekiq (Terminé)
- ✅ Sidekiq + Redis configuré
- ✅ Interface web `/admin/sidekiq`
- ✅ Prêt pour Scalingo

### 2. Système de Paiement (Terminé)
- ✅ Modèle CreditPurchase
- ✅ Gateway Fake/Real pour LCL Sherlock
- ✅ Webhook avec Sidekiq
- ✅ Boutique `/packs` et pages de résultat `/checkout`
- ✅ Tests RSpec

## 🎯 Pour tester en local

### 1. Configuration initiale

```bash
# 1. Installer les dépendances
bundle install

# 2. Installer et démarrer Redis
brew install redis
brew services start redis

# 3. Créer le fichier .env
cat > .env << 'EOF'
REDIS_URL=redis://localhost:6379/1
SHERLOCK_GATEWAY=fake
APP_HOST=http://localhost:3000
CURRENCY=EUR
EOF

# 4. Appliquer les migrations
bin/rails db:migrate

# 5. Démarrer l'application
bin/dev
```

### 2. Tester le paiement

1. **Créer un utilisateur admin** (si pas déjà fait) :
   ```bash
   bin/rails console
   User.create!(
     email: 'admin@test.com',
     password: 'password123',
     password_confirmation: 'password123',
     admin: true,
     first_name: 'Admin',
     last_name: 'Test'
   )
   ```

2. **Se connecter** :
   - Aller sur http://localhost:3000
   - Se connecter avec `admin@test.com` / `password123`

3. **Acheter un pack** :
   - Aller sur http://localhost:3000/packs
   - Cliquer sur "Acheter" sur un pack de crédits
   - La passerelle simulée renvoie une réponse signée : vous arrivez sur la
     page de résultat, solde à jour
   - Pour rejouer un refus : `SHERLOCK_FAKE_RESPONSE_CODE=05`

4. **Vérifier Sidekiq** :
   - Interface : http://localhost:3000/admin/sidekiq
   - Voir les jobs traités

## 📦 Déploiement sur Scalingo

### 1. Ajouter Redis

```bash
scalingo --app votre-app addons-add redis redis-starter-256
```

### 2. Activer le worker Sidekiq

```bash
scalingo --app votre-app scale worker:1
```

### 3. Configurer les variables (mode fake pour tester)

```bash
scalingo --app votre-app env-set SHERLOCK_GATEWAY=fake
scalingo --app votre-app env-set APP_HOST=https://votre-app.osc-fr1.scalingo.io
scalingo --app votre-app env-set CURRENCY=EUR
```

### 4. Déployer

```bash
git push scalingo Implem-paiement:master
```

### 5. Passer en mode production (plus tard)

Voir `PAIEMENT_README.md` pour la configuration complète de LCL Sherlock.

## 📚 Documentation détaillée

| Fichier | Description |
|---------|-------------|
| **PAIEMENT_README.md** | Guide complet du système de paiement |
| **MIGRATION_SIDEKIQ.md** | Documentation Sidekiq complète |
| **SCALINGO_DEPLOYMENT.md** | Guide déploiement Scalingo |
| **ENV_VARIABLES.md** | Variables d'environnement |
| **setup_real_sherlock.md** | Plan d'implémentation original |

## 🧪 Lancer les tests

```bash
# Tous les tests
bundle exec rspec

# Tests du modèle CreditPurchase
bundle exec rspec spec/models/credit_purchase_spec.rb
```

## 📊 Structure des commits

```
a1f893a docs: comprehensive payment system documentation
12d61df test: comprehensive specs for CreditPurchase
70a74ec feat(views): payment and checkout views
1ba64e4 feat(admin): payments page with 10€ pack
eedde86 feat(webhook): webhook endpoint + jobs
0870fe8 feat(payments): Sherlock gateway abstraction
b2cb9cb feat(credits): CreditPurchase model
befe3fd docs: variables d'environnement
[... migrations Sidekiq précédentes ...]
```

## ✨ Fonctionnalités clés

### Système de crédits
- **1 EUR = 100 crédits**
- Pack prédéfini : 10 EUR = 1000 crédits
- Système idempotent (pas de double crédit)

### Gateway de paiement
- **Mode fake** : Développement (auto-success)
- **Mode real** : Production LCL Sherlock

### Webhook
- Traitement asynchrone via Sidekiq
- Vérification signature HMAC
- Gestion success/failed/cancelled

## 🔧 Commandes utiles

```bash
# Console Rails
bin/rails console

# Voir les jobs Sidekiq
bundle exec sidekiq -C config/sidekiq.yml

# Créer un paiement test
bin/rails console
> pack = Pack.credits_packs.active.first
> purchase = User.first.credit_purchases.create!(pack:, amount_cents: pack.amount_cents,
>                                                currency: "EUR", credits: pack.credits, status: :pending)
> purchase.credit!
> User.first.balance.amount

# Voir les logs
tail -f log/development.log
```

## 🆘 Problèmes courants

### Redis ne démarre pas
```bash
brew services restart redis
redis-cli ping  # Devrait répondre PONG
```

### Sidekiq ne traite pas les jobs
```bash
# Vérifier que Sidekiq tourne
ps aux | grep sidekiq

# Redémarrer avec bin/dev
```

### Les crédits ne s'ajoutent pas
- Vérifier les logs de Sidekiq
- Vérifier que le job `SherlockCallbackJob` s'est exécuté
- Vérifier l'interface Sidekiq `/admin/sidekiq`

---

**Branche actuelle** : `Implem-paiement`  
**Statut** : ✅ Prêt pour tests en local et déploiement


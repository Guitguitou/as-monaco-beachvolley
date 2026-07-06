# 🚀 Démarrage Rapide - AS Monaco Beach Volley App

## ✅ Ce qui a été fait

### 1. Jobs & Cache (Terminé)
- ✅ SolidQueue + SolidCache configurés (Postgres, sans Redis)
- ✅ Interface web `/admin/jobs`
- ✅ Prêt pour Scalingo

### 2. Système de Paiement (Terminé)
- ✅ Modèle CreditPurchase
- ✅ Gateway Fake/Real pour LCL Sherlock
- ✅ Webhook avec Sidekiq
- ✅ Interface admin `/admin/payments`
- ✅ Tests RSpec

## 🎯 Pour tester en local

### 1. Configuration initiale

```bash
# 1. Installer les dépendances
bundle install

# 2. Créer le fichier .env
cat > .env << 'EOF'
SHERLOCK_GATEWAY=fake
APP_HOST=http://localhost:3000
CURRENCY=EUR
EOF

# 3. Appliquer les migrations
bin/rails db:migrate

# 4. Démarrer l'application
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

3. **Acheter des crédits** :
   - Aller sur http://localhost:3000/admin/payments
   - Cliquer sur "Acheter 10 € (1000 crédits)"
   - Vous serez redirigé vers `/checkout/success` (FakeGateway)
   - Vérifier que le solde a augmenté de 1000 crédits

4. **Vérifier les jobs** :
   - Interface : http://localhost:3000/admin/jobs
   - Voir les jobs traités

## 📦 Déploiement sur Scalingo

### 1. Activer le worker SolidQueue

```bash
scalingo --app votre-app scale worker:1
```

### 2. Configurer les variables (mode fake pour tester)

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
- Traitement asynchrone via SolidQueue
- Vérification signature HMAC
- Gestion success/failed/cancelled

## 🔧 Commandes utiles

```bash
# Console Rails
bin/rails console

# Voir les jobs SolidQueue
bin/jobs

# Créer un paiement test
rails console
> purchase = CreditPurchase.create_pack_10_eur(user: User.first)
> purchase.credit!
> User.first.balance.amount

# Voir les logs
tail -f log/development.log
```

## 🆘 Problèmes courants

### Les jobs ne se traitent pas
```bash
# Vérifier que bin/jobs tourne
ps aux | grep "bin/jobs"

# Redémarrer avec bin/dev
```

### Les crédits ne s'ajoutent pas
- Vérifier les logs de `bin/jobs`
- Vérifier que le job `SherlockCallbackJob` s'est exécuté
- Vérifier l'interface `/admin/jobs`

---

**Branche actuelle** : `Implem-paiement`  
**Statut** : ✅ Prêt pour tests en local et déploiement


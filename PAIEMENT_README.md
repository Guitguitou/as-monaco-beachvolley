# 💳 Système de Paiement LCL Sherlock

## 🎯 Vue d'ensemble

Système complet de paiement en ligne permettant aux utilisateurs d'acheter des crédits via LCL Sherlock.

**Conversion** : 100 crédits = 1 EUR

## ✅ Fonctionnalités implémentées

### 1. Modèle CreditPurchase
- ✅ Statuts : pending, paid, failed, cancelled
- ✅ Méthode `credit!` idempotente
- ✅ Pack prédéfini 10 EUR = 1000 crédits
- ✅ Génération automatique de référence unique

### 2. Gateway de paiement
- ✅ **FakeGateway** : Pour développement (redirige auto vers success)
- ✅ **RealGateway** : Pour production avec signature HMAC
- ✅ Factory pattern pour sélection selon `ENV['SHERLOCK_GATEWAY']`

### 3. Webhook Sidekiq
- ✅ Endpoint `/webhooks/sherlock`
- ✅ Vérification signature HMAC
- ✅ Traitement asynchrone via `SherlockCallbackJob`
- ✅ Service `HandleCallback` pour normaliser les statuts
- ✅ `PostPaymentFulfillmentJob` pour actions post-paiement

### 4. Interface Admin
- ✅ Page `/admin/payments`
- ✅ Bouton "Acheter 10 € (1000 crédits)"
- ✅ Historique des achats avec statuts
- ✅ Affichage du solde actuel

### 5. Pages Checkout
- ✅ `/checkout/success` : Confirmation de paiement
- ✅ `/checkout/cancel` : Annulation de paiement
- ✅ Design moderne avec Tailwind CSS

### 6. Tests RSpec
- ✅ Tests modèle CreditPurchase
- ✅ Tests d'idempotence
- ✅ Factory avec traits

## 🚀 Utilisation

### En développement (FakeGateway)

1. **Configurer les variables d'environnement** :
   ```bash
   # Dans .env
   REDIS_URL=redis://localhost:6379/1
   SHERLOCK_GATEWAY=fake
   APP_HOST=http://localhost:3000
   CURRENCY=EUR
   ```

2. **Démarrer les services** :
   ```bash
   # Terminal 1 : Redis
   redis-server
   
   # Terminal 2 : Rails + Sidekiq
   bin/dev
   ```

3. **Tester le flux** :
   - Aller sur `/admin/payments`
   - Cliquer sur "Acheter 10 € (1000 crédits)"
   - Redirection automatique vers `/checkout/success`
   - Vérifier le solde mis à jour

### En production (RealGateway)

1. **Configurer les variables Scalingo** :
   ```bash
   scalingo --app votre-app env-set SHERLOCK_GATEWAY=real
   scalingo --app votre-app env-set SHERLOCK_MERCHANT_ID=votre_merchant_id
   scalingo --app votre-app env-set SHERLOCK_TERMINAL_ID=votre_terminal_id
   scalingo --app votre-app env-set SHERLOCK_API_KEY=votre_api_key
   scalingo --app votre-app env-set SHERLOCK_RETURN_URL_SUCCESS=https://votre-app.osc-fr1.scalingo.io/checkout/success
   scalingo --app votre-app env-set SHERLOCK_RETURN_URL_CANCEL=https://votre-app.osc-fr1.scalingo.io/checkout/cancel
   scalingo --app votre-app env-set SHERLOCK_WEBHOOK_TOKEN=votre_token_secret
   scalingo --app votre-app env-set APP_HOST=https://votre-app.osc-fr1.scalingo.io
   ```

2. **Configurer le webhook chez LCL** :
   - URL : `https://votre-app.osc-fr1.scalingo.io/webhooks/sherlock`
   - Méthode : POST
   - Header : `X-Sherlock-Signature` (signature HMAC)

3. **Déployer** :
   ```bash
   git push scalingo Implem-paiement:master
   ```

## 📊 Flux de paiement

```
1. User → Clique "Acheter 10 €"
   ↓
2. CreditPurchase créé (status: pending)
   ↓
3. Redirection vers gateway (Fake ou Real)
   ↓
4. User → Paiement sur plateforme LCL
   ↓
5. LCL → Callback webhook
   ↓
6. SherlockCallbackJob → HandleCallback
   ↓
7. CreditPurchase.credit! (idempotent)
   ↓
8. Balance mise à jour
   ↓
9. CreditTransaction créée
   ↓
10. PostPaymentFulfillmentJob (email, analytics)
```

## 🔐 Sécurité

### En développement
- Vérification signature désactivée
- FakeGateway sans vraie transaction

### En production
- ✅ Vérification HMAC SHA-256 du webhook
- ✅ Signature des paramètres vers LCL
- ✅ Protection CSRF (sauf webhook)
- ✅ Protection admin uniquement

## 🧪 Tests

```bash
# Lancer les tests
bundle exec rspec spec/models/credit_purchase_spec.rb

# Créer un paiement en console
rails console
purchase = CreditPurchase.create_pack_10_eur(user: User.first)
purchase.credit!
User.first.balance.amount # Devrait avoir augmenté de 1000
```

## 📁 Structure du code

```
app/
├── models/
│   └── credit_purchase.rb          # Modèle principal
├── services/
│   └── sherlock/
│       ├── gateway.rb               # Interface abstraite
│       ├── fake_gateway.rb          # Gateway dev
│       ├── real_gateway.rb          # Gateway prod
│       ├── create_payment.rb        # Service création paiement
│       └── handle_callback.rb       # Service traitement callback
├── jobs/
│   ├── sherlock_callback_job.rb    # Job traitement webhook
│   └── post_payment_fulfillment_job.rb  # Job post-paiement
├── controllers/
│   ├── admin/
│   │   └── payments_controller.rb  # Interface admin
│   ├── checkout_controller.rb      # Success/Cancel
│   └── webhooks/
│       └── sherlock_controller.rb  # Webhook endpoint
└── views/
    ├── admin/payments/
    │   └── show.html.erb           # Page achat crédits
    └── checkout/
        ├── success.html.erb        # Page succès
        └── cancel.html.erb         # Page annulation
```

## 🎯 Prochaines évolutions

### Court terme
- [ ] Emails de confirmation (via PostPaymentFulfillmentJob)
- [ ] Analytics/Sentry sur les paiements
- [ ] Page admin pour voir tous les paiements

### Moyen terme
- [ ] Imports journaliers CSV (cron jobs)
- [ ] Gestion des impayés/chargebacks
- [ ] Remboursements partiels
- [ ] Badge 3DS garanti/non garanti

### Long terme
- [ ] Rapprochement bancaire
- [ ] Monitoring des paiements > 30min
- [ ] Alertes impayés
- [ ] Dashboard analytics paiements

## 📚 Documentation

- **Variables d'environnement** : Voir `ENV_VARIABLES.md`
- **Guide détaillé** : Voir `setup_real_sherlock.md`
- **Migration Sidekiq** : Voir `MIGRATION_SIDEKIQ.md`
- **Déploiement Scalingo** : Voir `SCALINGO_DEPLOYMENT.md`

## 🆘 Troubleshooting

### Le paiement ne se crédite pas
1. Vérifier que Sidekiq tourne : `bundle exec sidekiq -C config/sidekiq.yml`
2. Vérifier les logs du worker
3. Vérifier que le webhook a bien été reçu

### Erreur "CreditPurchase not found"
- La référence dans le callback ne correspond pas
- Vérifier les logs du webhook

### Signature invalide
- Vérifier `SHERLOCK_WEBHOOK_TOKEN`
- Vérifier le header `X-Sherlock-Signature`

---

**Statut** : ✅ Prêt pour développement (FakeGateway)  
**Prochaine étape** : Configuration LCL Sherlock pour production


# 💳 Implémentation Paiement LCL Sherlock + Crédits + Sidekiq

> ⚠️ **Document historique.** C'est le plan de l'implémentation initiale : il
> décrit un achat admin de 1000 crédits via `/admin/payments`, page depuis
> supprimée, et des variables d'environnement qui n'existent plus
> (`SHERLOCK_TERMINAL_ID`, `SHERLOCK_WEBHOOK_TOKEN`). Pour l'état réel du
> système, voir **PAIEMENT_README.md** et **ENV_VARIABLES.md**.


> Projet : Application Rails 8 (Hotwire/Tailwind)  
> Objectif : permettre à un **admin** d’acheter **1000 crédits (10 €)** via **LCL Sherlock**  
> Stack : Rails + Sidekiq + Redis + PostgreSQL  
> Conversion : **100 crédits = 1 €**

---

## 🔹 1. Installer & configurer Sidekiq

- Ajouter les gems :
  ```ruby
  gem "sidekiq"
  gem "sidekiq-cron"
  # gem "sidekiq-unique-jobs" # (optionnel)
  ```
- `config.active_job.queue_adapter = :sidekiq`
- Créer `config/initializers/sidekiq.rb`
- Créer `config/sidekiq.yml`
- Monter l’UI protégée `/admin/sidekiq` (BasicAuth + admin only)
- Commit :
  ```
  chore(sidekiq): add Sidekiq + cron, adapter ActiveJob, config & UI route
  ```

---

## 🔹 2. Variables d’environnement & Procfile

Créer `.env.template` :

```bash
REDIS_URL=redis://localhost:6379/1
SIDEKIQ_USER=admin
SIDEKIQ_PASSWORD=change-me

SHERLOCK_GATEWAY=fake
SHERLOCK_MERCHANT_ID=
SHERLOCK_TERMINAL_ID=
SHERLOCK_API_KEY=
SHERLOCK_RETURN_URL_SUCCESS=http://localhost:3000/checkout/success
SHERLOCK_RETURN_URL_CANCEL=http://localhost:3000/checkout/cancel
SHERLOCK_WEBHOOK_TOKEN=

APP_HOST=http://localhost:3000
CURRENCY=EUR
```

Créer un `Procfile` :

```bash
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
```

Commit :
```
chore(env): add .env.template and Procfile (web + worker)
```

---

## 🔹 3. Modèle `CreditPurchase`

- Générer le modèle :
  ```bash
  rails g model CreditPurchase user:references amount_cents:integer currency:string credits:integer status:string sherlock_transaction_reference:string sherlock_fields:jsonb paid_at:datetime failed_at:datetime
  rails db:migrate
  ```

- Implémenter `CreditPurchase#credit!` :
  - Ajoute `credits` à `user.balance.amount`
  - Crée une `CreditTransaction` (type `purchase`)
  - Marque `paid_at`

- Enum dans `CreditTransaction` :
  ```ruby
  enum :transaction_type, { purchase: 0, debit_session: 1, refund: 2 }, _default: :purchase
  ```

- Commit :
  ```
  feat(credits): add CreditPurchase model + idempotent credit! using balances & credit_transactions
  ```

---

## 🔹 4. Sherlock Gateway (Fake en dev)

- Créer :
  - `Sherlock::Gateway` (interface)
  - `Sherlock::FakeGateway` (redirige auto vers success)
  - `Sherlock::CreatePayment` (sélectionne la gateway)

- Commit :
  ```
  feat(payments): add Sherlock gateway abstraction + FakeGateway for dev + CreatePayment service
  ```

---

## 🔹 5. Webhook & Jobs Sidekiq

- Route : `POST /webhooks/sherlock`
- Contrôleur `Webhooks::SherlockController`
- Job `SherlockCallbackJob` → appelle `Sherlock::HandleCallback`
- Job `PostPaymentFulfillmentJob` (emails plus tard)
- Service `Sherlock::HandleCallback` :
  - Normalise le statut
  - Met à jour `sherlock_fields`
  - Appelle `credit!` si payé
- Commit :
  ```
  feat(webhook): add webhook endpoint + callback job/service + post-payment job (Sidekiq)
  ```

---

## 🔹 6. Page Admin (achat 10 € → 1000 crédits)

- Routes :
  ```ruby
  namespace :admin do
    resource :payments, only: [:show] do
      post :buy_10_eur, on: :collection
    end
  end

  resource :checkout, only: [] do
    get :success
    get :cancel
  end
  ```
- Contrôleur `Admin::PaymentsController`
- Vue `/admin/payments` avec bouton “Acheter 10 € (1000 crédits)”
- Contrôleur `CheckoutController` (success/cancel)
- Commit :
  ```
  feat(admin): payments page with 10€ (1000 credits) pack + checkout success/cancel
  ```

---

## 🔹 7. Cron (optionnel pour plus tard)

- Créer `config/sidekiq_schedule.yml` et `config/initializers/sidekiq_cron.rb`
- Commit :
  ```
  chore(cron): add cron bootstrap (disabled jobs placeholder)
  ```

---

## 🔹 8. Test minimal RSpec

```ruby
RSpec.describe CreditPurchase, type: :model do
  let(:user){ create(:user) }
  it "credits once (idempotent)" do
    purchase = CreditPurchase.create!(user:, amount_cents: 1000, currency: "EUR", credits: 1000, status: :pending)
    expect { purchase.credit! }.to change { user.reload.balance&.amount.to_i }.by(1000)
    expect { purchase.credit! }.not_to change { user.reload.balance&.amount.to_i }
  end
end
```

Commit :
```
test: minimal idempotence spec for CreditPurchase#credit!
```

---

## 🔹 9. Lancer en local

```bash
redis-server
bin/rails s
bundle exec sidekiq -C config/sidekiq.yml
```

Puis aller sur `/admin/payments` :
- Cliquer **Acheter 10 € (1000 crédits)**  
- Redirection → `/checkout/success` (FakeGateway)  
- Vérifier :
  - `balances.amount` +1000  
  - `credit_transactions` créé  
  - `CreditPurchase.status == "paid"`

---

## 🔹 10. Passage à la vraie passerelle LCL Sherlock

### 10.1 Implémenter `Sherlock::RealGateway`

- `SHERLOCK_GATEWAY=real`
- Créer `app/services/sherlock/real_gateway.rb`
- Produire un **form POST** ou une **URL GET signée**
- Ex :
  ```ruby
  class Sherlock::RealGateway < Gateway
    HOSTED_URL = "https://paiement-sherlock.lcl.fr/hosted"

    def create_payment(reference:, amount_cents:, currency:, return_urls:, customer:)
      params = {
        merchantId: ENV["SHERLOCK_MERCHANT_ID"],
        terminalId: ENV["SHERLOCK_TERMINAL_ID"],
        orderId: reference,
        amount: amount_cents,
        currency: currency,
        returnUrlSuccess: return_urls[:success],
        returnUrlCancel:  return_urls[:cancel],
        customerEmail: customer[:email]
      }
      # signature = HMAC(params, ENV["SHERLOCK_API_KEY"])
      "#{HOSTED_URL}?#{params.to_query}"
    end
  end
  ```
- Commit :
  ```
  feat(payments): add RealGateway implementation for LCL Sherlock
  ```

---

### 10.2 Sécuriser le webhook

- Vérifier la **signature HMAC** ou **IP allowlist** (selon doc LCL)
- Exemple :

```ruby
def verify_signature!
  return if Rails.env.development?
  provided = request.headers["X-Sherlock-Signature"].to_s
  body     = request.raw_post
  secret   = ENV["SHERLOCK_WEBHOOK_TOKEN"]
  computed = OpenSSL::HMAC.hexdigest("SHA256", secret, body)
  head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(provided, computed)
end
```

---

### 10.3 Historique & badge 3DS

- Dans `sherlock_fields` : stocker `responseCode`, `transactionStatus`, `threed_ls_code`
- `threed_ls_code == "1"` → **garanti 3DS**
- Ajouter badge “3DS garanti / non garanti” dans la vue admin
- Option : ajouter colonne `threeds_guaranteed:boolean`

---

### 10.4 Imports journaux (cron)

Créer des jobs :
- `ImportSherlockTransactionsJob` → transactions acceptées/refusées  
- `ImportSherlockOperationsJob` → opérations (captures, annulations)  
- `ImportSherlockReconciliationJob` → rapprochement bancaire  
- `ImportSherlockUnpaidJob` → impayés / chargebacks  

Chacun :
- Parse CSV (`col_sep: ';'`)
- Match sur `sherlock_transaction_reference`
- Met à jour `CreditPurchase` + `sherlock_fields`

---

### 10.5 Gestion impayés / remboursements

- Si **impayé** :
  - Créer `CreditTransaction` négatif
  - Décrémenter `balance.amount`
  - Notifier admin
- Si **remboursement partiel** :
  - Décréditer proportionnellement
  - Journaliser dans `sherlock_fields`

---

### 10.6 Évolutions de schéma (optionnelles)

Ajouter dans `CreditPurchase` :
```ruby
add_column :credit_purchases, :paid_settled, :boolean, default: false
add_column :credit_purchases, :reconciled_at, :datetime
add_column :credit_purchases, :threeds_guaranteed, :boolean
add_index :credit_purchases, :sherlock_transaction_reference, unique: true
```

---

### 10.7 Monitoring & alertes

- Sentry tags : `component=payments`, `reference=CP-xxx`
- Alertes :
  - `pending > 30min`
  - `paid sans paid_settled > 72h`
  - impayés détectés

---

### 10.8 Checklist déploiement prod

1. Renseigner toutes les variables ENV sur Scalingo :
   - `SHERLOCK_GATEWAY=real`
   - `SHERLOCK_MERCHANT_ID`
   - `SHERLOCK_TERMINAL_ID`
   - `SHERLOCK_API_KEY`
   - `SHERLOCK_RETURN_URL_SUCCESS`
   - `SHERLOCK_RETURN_URL_CANCEL`
   - `APP_HOST`
   - `CURRENCY`
2. Redéployer ton code
3. Faire un test réel à 10 €
4. Vérifier :
   - `CreditPurchase.status == paid`
   - `Balance.amount +1000`
   - Webhook reçu (`200 OK`)
   - Aucune erreur Sentry
5. Activer cron d’import
6. Mettre en place alertes & monitoring

---

### 10.9 Tests à ajouter

- Tests unitaires `RealGateway`
- Tests webhook (signature ok / invalide)
- Tests import CSV
- Tests refund / impayé
- Tests badge 3DS garanti / non garanti

---

✅ **Et voilà :**
- FakeGateway pour dev  
- RealGateway pour prod  
- Zéro certificat à gérer  
- Tout se pilote via variables ENV + URLs déclarées chez LCL  
- Et le webhook synchronise tes paiements automatiquement 🚀

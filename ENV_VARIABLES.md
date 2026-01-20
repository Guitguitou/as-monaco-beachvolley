# Variables d'environnement requises

## Redis & Sidekiq

```bash
REDIS_URL=redis://localhost:6379/1
```

## Sherlock Payment Gateway

```bash
# Mode de la gateway (fake pour dev, real pour prod)
SHERLOCK_GATEWAY=fake

# Identifiants LCL Sherlock (fournis par LCL)
SHERLOCK_MERCHANT_ID=
SHERLOCK_TERMINAL_ID=
SHERLOCK_API_KEY=

# URLs de retour après paiement
SHERLOCK_RETURN_URL_SUCCESS=http://localhost:3000/checkout/success
SHERLOCK_RETURN_URL_CANCEL=http://localhost:3000/checkout/cancel

# Token de sécurité pour le webhook
SHERLOCK_WEBHOOK_TOKEN=
```

## Brevo (emails transactionnels)

```bash
# Clé API Brevo
BREVO_API_KEY=

# Expéditeur par défaut des emails transactionnels
BREVO_SENDER_EMAIL=
BREVO_SENDER_NAME="AS Monaco Beach Volley"

# ID du template Brevo pour la confirmation de paiement
BREVO_TEMPLATE_PAYMENT_SUCCESS=
```

## Application

```bash
# Host de l'application
APP_HOST=http://localhost:3000

# Devise (EUR pour euros)
CURRENCY=EUR
```

## Configuration locale (.env)

Créez un fichier `.env` à la racine avec ces variables :

```bash
# Copier-coller ce template dans votre .env local
REDIS_URL=redis://localhost:6379/1
SHERLOCK_GATEWAY=fake
SHERLOCK_RETURN_URL_SUCCESS=http://localhost:3000/checkout/success
SHERLOCK_RETURN_URL_CANCEL=http://localhost:3000/checkout/cancel
BREVO_API_KEY=your_brevo_api_key
BREVO_SENDER_EMAIL=notifications@example.com
BREVO_SENDER_NAME="AS Monaco Beach Volley"
BREVO_TEMPLATE_PAYMENT_SUCCESS=1
APP_HOST=http://localhost:3000
CURRENCY=EUR
```

## Configuration Scalingo (production)

```bash
# Ajouter les variables via CLI
scalingo --app votre-app env-set SHERLOCK_GATEWAY=real
scalingo --app votre-app env-set SHERLOCK_MERCHANT_ID=votre_merchant_id
scalingo --app votre-app env-set SHERLOCK_TERMINAL_ID=votre_terminal_id
scalingo --app votre-app env-set SHERLOCK_API_KEY=votre_api_key
scalingo --app votre-app env-set SHERLOCK_RETURN_URL_SUCCESS=https://votre-app.osc-fr1.scalingo.io/checkout/success
scalingo --app votre-app env-set SHERLOCK_RETURN_URL_CANCEL=https://votre-app.osc-fr1.scalingo.io/checkout/cancel
scalingo --app votre-app env-set SHERLOCK_WEBHOOK_TOKEN=votre_token_secret
scalingo --app votre-app env-set APP_HOST=https://votre-app.osc-fr1.scalingo.io
scalingo --app votre-app env-set CURRENCY=EUR
scalingo --app votre-app env-set BREVO_API_KEY=votre_cle_api
scalingo --app votre-app env-set BREVO_SENDER_EMAIL=notifications@votre-domaine
scalingo --app votre-app env-set BREVO_SENDER_NAME="AS Monaco Beach Volley"
scalingo --app votre-app env-set BREVO_TEMPLATE_PAYMENT_SUCCESS=123

# Notifications Push (générer les clés avec: bin/rails vapid:generate)
scalingo --app votre-app env-set VAPID_PUBLIC_KEY="votre_cle_publique"
scalingo --app votre-app env-set VAPID_PRIVATE_KEY="votre_cle_privee"
scalingo --app votre-app env-set VAPID_SUBJECT="mailto:votre-email@example.com"
```

Note : 
- `REDIS_URL` est automatiquement configurée par l'addon Redis de Scalingo.
- Voir `SCALINGO_PUSH_NOTIFICATIONS.md` pour la configuration complète des notifications push.


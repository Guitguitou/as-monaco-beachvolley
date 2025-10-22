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
```

Note : `REDIS_URL` est automatiquement configurée par l'addon Redis de Scalingo.


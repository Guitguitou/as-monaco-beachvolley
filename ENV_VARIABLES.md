# Variables d'environnement requises

## Redis & Sidekiq

```bash
REDIS_URL=redis://localhost:6379/1
```

## Sherlock's (LCL)

```bash
# Mode de la passerelle : fake pour le dev, real pour la prod
SHERLOCK_GATEWAY=fake

# Identifiants du contrat, fournis par LCL
SHERLOCK_MERCHANT_ID=
SHERLOCK_API_KEY=            # clé secrète ; obligatoire hors développement
SHERLOCK_KEY_VERSION=1
```

### Facultatif

```bash
# Moyens de paiement affichés sur la page LCL.
# APPLEPAY et GOOGLEPAY n'apparaissent qu'une fois les options actives sur le
# contrat : envoyer une marque inactive fait échouer l'initialisation.
SHERLOCK_PAYMENT_MEAN_BRAND_LIST=CB,VISA,MASTERCARD,APPLEPAY,GOOGLEPAY

# Feuille de style de la page de paiement (nom du zip déposé chez Sherlock's)
SHERLOCK_TEMPLATE_NAME=

# Algorithme du sceau : sha256 (défaut) ou HMAC-SHA-256
SHERLOCK_SEAL_ALGO=sha256

# Langue de la page de paiement (fr par défaut)
SHERLOCK_CUSTOMER_LANGUAGE=fr

# URL d'init (recette LCL, par exemple)
SHERLOCK_PAYMENT_INIT_URL=
SHERLOCK_INTERFACE_VERSION=HP_3.4

# Référence marchande envoyée en orderId au lieu de transactionReference
SHERLOCK_USE_ORDER_ID=false

# Force l'URL de retour. Sans elle : #{APP_HOST}/checkout/return
SHERLOCK_RETURN_URL_SUCCESS=

# Dev uniquement : code de réponse simulé par la passerelle fake
# 00 accepté · 05 refusé · 17 annulé par le client · 97 session expirée
SHERLOCK_FAKE_RESPONSE_CODE=00
```

Sherlock's transmet `normalReturnUrl` et `automaticResponseUrl` à chaque
requête : il n'y a **aucune URL à déclarer côté LCL**. Il n'y a pas non plus
d'URL d'annulation — le résultat est porté par le `responseCode`.

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
scalingo --app votre-app env-set SHERLOCK_API_KEY=votre_cle_secrete
scalingo --app votre-app env-set SHERLOCK_KEY_VERSION=1
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


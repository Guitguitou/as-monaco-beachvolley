# Système de Paiement LCL/Sherlock

Ce document explique comment configurer et utiliser le système de paiement intégré avec LCL/Sherlock.

## Fonctionnalités

- ✅ Gestion des forfaits de crédits par l'admin
- ✅ Interface d'achat de crédits pour les joueurs
- ✅ Intégration avec l'API LCL/Sherlock
- ✅ Gestion des callbacks de paiement
- ✅ Historique des paiements
- ✅ Mise à jour automatique du solde de crédits

## Configuration

### 1. Variables d'environnement

Créez un fichier `.env` à la racine du projet (utilisez `.env.example` comme modèle) :

```bash
# LCL/Sherlock Payment Gateway
LCL_MERCHANT_ID=votre_merchant_id
LCL_CERTIFICATE_PATH=config/certificates/lcl.crt
LCL_PRIVATE_KEY_PATH=config/certificates/lcl.key

# URL de base de votre application (pour les callbacks)
BASE_URL=https://votre-domaine.com
```

**Note**: Le fichier `.env` ne doit **jamais** être commité dans Git. Il est déjà dans `.gitignore`.

### 2. Certificats

Placez vos certificats LCL dans le dossier `config/certificates/` :
- `lcl.crt` : Certificat LCL
- `lcl.key` : Clé privée

**Important**: Ajoutez `config/certificates/` à votre `.gitignore` pour ne pas exposer vos clés privées.

### 3. URLs selon l'environnement

- **Développement/Recette**: `https://recette.secure.lcl.fr` (automatique)
- **Production**: `https://secure.lcl.fr` (automatique)

Vous pouvez forcer une URL spécifique avec la variable `LCL_BASE_URL` dans `.env`.

## Utilisation

### Pour les Administrateurs

1. **Créer des forfaits** : Allez dans Admin > Forfaits de Crédits
2. **Gérer les forfaits** : Activez/désactivez, modifiez les prix
3. **Suivre les paiements** : Consultez l'historique des transactions

### Pour les Joueurs

1. **Acheter des crédits** : Menu "Acheter des crédits"
2. **Choisir un forfait** : Sélectionnez le forfait souhaité
3. **Payer** : Redirection vers LCL/Sherlock
4. **Confirmation** : Retour automatique avec les crédits ajoutés

## Flux de Paiement

1. **Initiation** : Le joueur choisit un forfait
2. **Redirection** : Redirection vers LCL/Sherlock
3. **Paiement** : Le joueur effectue le paiement
4. **Callback** : LCL renvoie le résultat
5. **Mise à jour** : Les crédits sont ajoutés au solde

## Modèles

### CreditPackage
- `name` : Nom du forfait
- `description` : Description
- `credits` : Nombre de crédits
- `price_cents` : Prix en centimes
- `active` : Statut actif/inactif

### Payment
- `user_id` : Utilisateur
- `credit_package_id` : Forfait acheté
- `status` : Statut du paiement
- `amount_cents` : Montant en centimes
- `sherlock_transaction_id` : ID transaction LCL
- `sherlock_response` : Réponse LCL

## Architecture

### Structure du code

Le système de paiement est organisé en trois couches :

#### 1. Couche API (`lib/lcl/`)
Gère toutes les interactions avec l'API LCL/Sherlock :

- **`Lcl::Client`** : Client principal, gère la configuration
- **`Lcl::Signature`** : Gestion des signatures cryptographiques
- **`Lcl::Api::Payment`** : Méthodes API (create, capture, refund, cancel)

```ruby
# Utilisation directe de l'API
client = Lcl.client
result = client.payment.create(payment_record)
```

#### 2. Couche Service (`app/services/`)
Logique métier pour les paiements :

- **`LclPaymentService`** : Service métier qui orchestre les paiements
  - `initiate_payment` : Crée et initie un paiement
  - `handle_callback` : Traite les callbacks LCL
  - `refund` : Rembourse un paiement

```ruby
# Utilisation dans les controllers
service = LclPaymentService.new(payment)
result = service.initiate_payment
```

#### 3. Couche Controller (`app/controllers/`)
Logique d'interface utilisateur :

- **`PaymentsController`** : Gère les actions utilisateur
  - Affichage des formulaires
  - Création de paiements
  - Gestion des redirections
  - Traitement des webhooks

## Routes

```ruby
# Paiements
resources :payments, only: [:index, :show, :new, :create] do
  member do
    get :callback    # Retour après paiement
    get :cancel      # Annulation
    post :notify     # Webhook LCL
  end
end

# Admin
namespace :admin do
  resources :credit_packages
end
```

## Tests

Pour tester le système :

1. **Développement** : Utilisez l'environnement de recette LCL
2. **Production** : Utilisez l'environnement de production LCL

## Sécurité

- ✅ Signatures cryptographiques
- ✅ Validation des callbacks
- ✅ Protection CSRF
- ✅ Authentification requise
- ✅ Logs des transactions

## API LCL - Méthodes disponibles

### Créer un paiement
```ruby
client = Lcl.client
result = client.payment.create(payment_record)
# => { success: true, payment_url: "https://...", transaction_id: "PAY_123..." }
```

### Rembourser un paiement
```ruby
result = client.payment.refund(payment_record, amount_cents: 1000)
# => { success: true, refund_id: "REFUND_123...", amount_refunded: 1000 }
```

### Capturer un paiement pré-autorisé
```ruby
result = client.payment.capture(payment_record, amount_cents: 1000)
# => { success: true, capture_id: "CAPTURE_123...", amount_captured: 1000 }
```

### Annuler un paiement pré-autorisé
```ruby
result = client.payment.cancel(payment_record)
# => { success: true, cancellation_id: "CANCEL_123..." }
```

## Dépannage

### Erreurs courantes

1. **"Configuration LCL manquante"** 
   - Vérifiez votre fichier `.env`
   - Assurez-vous que toutes les variables sont définies

2. **"Signature invalide"** 
   - Vérifiez que les certificats sont bien présents
   - Vérifiez les permissions des fichiers de certificats

3. **"Paiement échoué"** 
   - Consultez les logs Rails
   - Vérifiez la configuration LCL (merchant_id)

### Logs

Les erreurs sont loggées dans `log/development.log` ou `log/production.log` avec le préfixe `LCL`.

## Support

Pour toute question sur l'intégration LCL/Sherlock :
- Documentation : https://sherlocks-documentation.secure.lcl.fr/
- Support : ecommerce_lcl@avem-groupe.com
- Téléphone : 09 80 98 07 91

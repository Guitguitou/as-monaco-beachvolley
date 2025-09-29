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

### 1. Credentials LCL

Ajoutez vos credentials LCL dans les credentials Rails :

```bash
rails credentials:edit
```

Ajoutez la section suivante :

```yaml
lcl:
  merchant_id: "VOTRE_MERCHANT_ID"
  certificate_path: "config/certificates/lcl.crt"
  private_key_path: "config/certificates/lcl.key"
```

### 2. Certificats

Placez vos certificats LCL dans le dossier `config/certificates/` :
- `lcl.crt` : Certificat LCL
- `lcl.key` : Clé privée

### 3. Variables d'environnement

Pour la production, configurez les URLs de callback :

```bash
# URLs de base de votre application
BASE_URL=https://votre-domaine.com
```

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

## Services

### LclPaymentService
Service principal pour gérer l'intégration LCL :
- `initiate_payment` : Initie un paiement
- `handle_callback` : Traite les callbacks
- `generate_signature` : Génère les signatures
- `valid_signature?` : Valide les signatures

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

## Dépannage

### Erreurs courantes

1. **"Configuration LCL manquante"** : Vérifiez les credentials
2. **"Signature invalide"** : Vérifiez les certificats
3. **"Paiement échoué"** : Vérifiez les logs LCL

### Logs

Les erreurs sont loggées dans `log/development.log` ou `log/production.log`.

## Support

Pour toute question sur l'intégration LCL/Sherlock :
- Documentation : https://sherlocks-documentation.secure.lcl.fr/
- Support : ecommerce_lcl@avem-groupe.com
- Téléphone : 09 80 98 07 91

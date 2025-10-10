# Guide de test en console Rails

Ce guide vous montre comment tester le système de paiement LCL en console Rails locale.

## Préparation

J'ai créé pour vous :
- ✅ Un fichier `.env` avec des valeurs de test
- ✅ Des certificats de test dans `config/certificates/`

**Note**: Ce sont des certificats de test ! Vous devrez les remplacer par vos vrais certificats LCL pour les paiements réels.

## Lancer la console Rails

```bash
rails console
# ou
rails c
```

## Tests à effectuer

### 1. Vérifier que le module LCL est chargé

```ruby
Lcl
# => Lcl (module)
```

### 2. Vérifier la configuration du client

```ruby
# Obtenir le client
client = Lcl.client

# Vérifier qu'il est configuré
client.configured?
# => true

# Voir le merchant_id
client.merchant_id
# => "test_merchant_id_123"

# Voir l'URL de base
client.base_url
# => "https://recette.secure.lcl.fr" (en développement)
```

### 3. Tester les certificats

```ruby
# Charger la clé privée
client.private_key
# => #<OpenSSL::PKey::RSA:0x...>

# Charger le certificat
client.certificate
# => #<OpenSSL::X509::Certificate:0x...>

# Vérifier la validité du certificat
cert = client.certificate
cert.subject
# => /C=FR/ST=Monaco/L=Monaco/O=Test/CN=test.lcl.fr

cert.not_before
# => Date de début

cert.not_after
# => Date d'expiration
```

### 4. Tester la génération de signature

```ruby
# Générer une signature pour des paramètres de test
test_params = {
  merchant_id: 'test_123',
  amount: 5000,
  currency: 'EUR'
}

signature = client.signature.generate(test_params)
# => "Base64EncodedSignature..."

# Afficher la signature
puts signature
```

### 5. Tester la vérification de signature

```ruby
# Vérifier que la signature est correcte
test_params = { amount: 1000, merchant_id: 'test' }
signature = client.signature.generate(test_params)

# Vérifier
client.signature.verify(test_params, signature)
# => true (la signature est valide)

# Tester avec une mauvaise signature
client.signature.verify(test_params, 'mauvaise_signature')
# => false
```

### 6. Tester l'API Payment (sans vraie requête)

```ruby
# Créer un utilisateur de test
user = User.first || User.create!(
  email: 'test@example.com',
  password: 'password123',
  first_name: 'Test',
  last_name: 'User'
)

# Créer un package de crédits
package = CreditPackage.first || CreditPackage.create!(
  name: 'Pack Test',
  description: 'Package de test',
  credits: 10,
  price_cents: 5000,
  active: true
)

# Créer un paiement
payment = Payment.create!(
  user: user,
  credit_package: package,
  status: 'pending'
)

# Tester la création d'un paiement (génère une URL)
result = Lcl.client.payment.create(payment)

# Voir le résultat
result
# => { success: true, payment_url: "https://...", transaction_id: "PAY_..." }

# Afficher l'URL de paiement
puts result[:payment_url]
```

### 7. Tester le service LclPaymentService

```ruby
# Utiliser le service métier
service = LclPaymentService.new(payment)

# Initier un paiement
result = service.initiate_payment

# Voir le résultat
result
# => { success: true, payment_url: "...", transaction_id: "..." }

# Vérifier que le paiement a été mis à jour
payment.reload
payment.status
# => "processing"

payment.sherlock_transaction_id
# => "PAY_123_..."
```

### 8. Tester les autres méthodes API

```ruby
# Remboursement
result = Lcl.client.payment.refund(payment, amount_cents: 1000)
result
# => { success: true, refund_id: "REFUND_...", amount_refunded: 1000 }

# Capture
result = Lcl.client.payment.capture(payment, amount_cents: 2000)
result
# => { success: true, capture_id: "CAPTURE_...", amount_captured: 2000 }

# Annulation
result = Lcl.client.payment.cancel(payment)
result
# => { success: true, cancellation_id: "CANCEL_..." }
```

### 9. Tester les callbacks (simulation)

```ruby
# Simuler un callback de succès
callback_params = {
  order_id: payment.id,
  transaction_id: 'TRANS_123',
  external_id: 'EXT_456',
  status: 'SUCCESS',
  amount: 5000
}

# Générer une signature pour ces paramètres
signature = Lcl.client.signature.generate(callback_params)
callback_params[:signature] = signature

# Traiter le callback
result = Lcl.client.payment.handle_callback(callback_params)
result
# => { success: true, status: "completed", ... }

# Utiliser le service
service = LclPaymentService.new(payment)
result = service.handle_callback(callback_params)
```

### 10. Utiliser le script de vérification

Sortez de la console et lancez :

```bash
exit  # Sortir de la console

# Lancer le script de vérification
bin/check_lcl_config
```

Ce script vous donnera un rapport complet sur votre configuration.

## Commandes utiles

### Réinitialiser le client (après changement de config)

```ruby
Lcl.reset!
Lcl.client  # Nouveau client avec la nouvelle config
```

### Voir toutes les méthodes disponibles

```ruby
# Méthodes du client
Lcl.client.methods.grep(/^[^_]/).sort

# Méthodes de l'API Payment
Lcl.client.payment.methods.grep(/^[^_]/).sort

# Méthodes de Signature
Lcl.client.signature.methods.grep(/^[^_]/).sort
```

### Activer les logs détaillés

```ruby
# Voir les logs en temps réel
tail -f log/development.log | grep LCL

# Ou dans la console
Rails.logger.level = :debug
```

## Dépannage

### Erreur "Configuration LCL manquante"

```ruby
# Vérifier les variables d'environnement
ENV['LCL_MERCHANT_ID']
ENV['LCL_CERTIFICATE_PATH']
ENV['LCL_PRIVATE_KEY_PATH']

# Si vide, relancez Rails après avoir créé/modifié .env
```

### Erreur "Certificat introuvable"

```ruby
# Vérifier que le fichier existe
File.exist?(ENV['LCL_CERTIFICATE_PATH'])
# => true

# Voir le chemin absolu
Rails.root.join(ENV['LCL_CERTIFICATE_PATH'])
```

### Recharger le code après modifications

```ruby
reload!
# Recharge tout le code de l'application
```

## Prochaines étapes

Une fois que tout fonctionne en console :

1. **Remplacez les certificats de test** par vos vrais certificats LCL
2. **Mettez à jour le `LCL_MERCHANT_ID`** dans `.env`
3. **Testez un paiement complet** via l'interface web
4. **Configurez la production** avec les variables d'environnement appropriées

## Exemple de session complète

```ruby
# Lancer la console
rails console

# 1. Vérifier la configuration
Lcl.client.configured?  # => true

# 2. Créer un paiement de test
user = User.first
package = CreditPackage.first
payment = Payment.create!(user: user, credit_package: package, status: 'pending')

# 3. Tester l'initiation
service = LclPaymentService.new(payment)
result = service.initiate_payment
puts result[:payment_url]

# 4. Vérifier le statut
payment.reload.status  # => "processing"

# 5. Nettoyer
payment.destroy

# 6. Sortir
exit
```

Bon test ! 🚀


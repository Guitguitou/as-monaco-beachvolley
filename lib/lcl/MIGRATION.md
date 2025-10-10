# Migration vers la nouvelle structure LCL

Ce guide vous aide à migrer de l'ancienne configuration (credentials Rails) vers la nouvelle structure (.env).

## Changements principaux

### Avant

```ruby
# Configuration dans Rails credentials
rails credentials:edit
# lcl:
#   merchant_id: "..."
#   certificate_path: "..."
#   private_key_path: "..."

# Service avec logique API mélangée
class LclPaymentService
  def initialize(payment)
    @merchant_id = Rails.application.credentials.lcl&.merchant_id
    # ...
  end
  
  def generate_signature(params)
    # Logique cryptographique ici
  end
end
```

### Après

```ruby
# Configuration dans .env
LCL_MERCHANT_ID=votre_merchant_id
LCL_CERTIFICATE_PATH=config/certificates/lcl.crt
LCL_PRIVATE_KEY_PATH=config/certificates/lcl.key

# API séparée dans lib/lcl/
client = Lcl.client
result = client.payment.create(payment)

# Service simplifié avec logique métier
class LclPaymentService
  def initiate_payment
    result = Lcl.client.payment.create(payment)
    # Gestion métier uniquement
  end
end
```

## Étapes de migration

### 1. Récupérer vos credentials actuels

```bash
rails credentials:show
```

Notez vos valeurs `lcl:merchant_id`, `certificate_path` et `private_key_path`.

### 2. Créer le fichier .env

```bash
# Copier le template
cp .env.example .env

# Éditer avec vos valeurs
vim .env
```

Remplacez les valeurs par défaut par vos vraies credentials.

### 3. Vérifier que les certificats sont au bon endroit

```bash
ls -la config/certificates/
# Devrait afficher lcl.crt et lcl.key
```

Si vos certificats sont ailleurs, déplacez-les ou mettez à jour `LCL_CERTIFICATE_PATH` et `LCL_PRIVATE_KEY_PATH`.

### 4. Tester la configuration

Lancez un console Rails et testez :

```ruby
rails c

# Vérifier la configuration
Lcl.client.configured?
# => true

# Vérifier le merchant_id
Lcl.client.merchant_id
# => "votre_merchant_id"

# Tester la signature
Lcl.client.signature.generate({ test: "data" })
# => "base64_encoded_signature"
```

### 5. Nettoyer l'ancienne configuration

Une fois que tout fonctionne, vous pouvez supprimer l'ancienne configuration des credentials :

```bash
rails credentials:edit
# Supprimez la section lcl:
```

### 6. Mettre à jour votre déploiement

#### Avec Kamal

```yaml
# config/deploy.yml
env:
  secret:
    - LCL_MERCHANT_ID
    - LCL_CERTIFICATE_PATH
    - LCL_PRIVATE_KEY_PATH
```

Puis définissez ces variables dans `.env.production` sur votre serveur.

#### Avec Heroku

```bash
heroku config:set LCL_MERCHANT_ID=votre_merchant_id
heroku config:set LCL_CERTIFICATE_PATH=config/certificates/lcl.crt
heroku config:set LCL_PRIVATE_KEY_PATH=config/certificates/lcl.key
heroku config:set BASE_URL=https://votre-app.herokuapp.com
```

## Avantages de la nouvelle structure

✅ **Séparation des responsabilités**
- API dans `lib/lcl/` (réutilisable, testable)
- Logique métier dans `app/services/`
- Logique UI dans `app/controllers/`

✅ **Configuration plus claire**
- Variables d'environnement dans `.env`
- Pas besoin de `rails credentials:edit`
- Compatible avec tous les systèmes de déploiement

✅ **Code plus maintenable**
- Chaque classe a une responsabilité unique
- Facile à tester unitairement
- Documentation claire

✅ **Extensibilité**
- Facile d'ajouter de nouvelles méthodes API
- Structure modulaire
- Réutilisable dans d'autres projets

## Rollback

Si vous devez revenir en arrière :

1. Restaurer l'ancienne configuration dans credentials
2. Restaurer l'ancien fichier `app/services/lcl_payment_service.rb` depuis Git
3. Supprimer `lib/lcl/` et `config/initializers/lcl.rb`

```bash
git checkout HEAD~1 -- app/services/lcl_payment_service.rb
rm -rf lib/lcl/
rm config/initializers/lcl.rb
```

## Support

En cas de problème :
1. Vérifiez les logs : `tail -f log/development.log | grep LCL`
2. Testez dans la console Rails
3. Vérifiez que .env est bien chargé : `ENV['LCL_MERCHANT_ID']`


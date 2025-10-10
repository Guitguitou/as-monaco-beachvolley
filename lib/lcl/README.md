# LCL/Sherlock API Client

Cette bibliothèque gère toutes les interactions avec l'API de paiement LCL/Sherlock.

## Architecture

```
lib/lcl/
├── lcl.rb                  # Module principal et point d'entrée
├── client.rb               # Client de base avec configuration
├── signature.rb            # Gestion des signatures cryptographiques
└── api/
    └── payment.rb          # API de paiement (create, capture, refund, cancel)
```

## Utilisation

### Configuration

Les variables d'environnement suivantes doivent être définies dans `.env` :

```bash
LCL_MERCHANT_ID=votre_merchant_id
LCL_CERTIFICATE_PATH=config/certificates/lcl.crt
LCL_PRIVATE_KEY_PATH=config/certificates/lcl.key
LCL_BASE_URL=https://recette.secure.lcl.fr  # Optionnel
```

### Exemples d'utilisation

#### Initialiser le client

```ruby
client = Lcl.client
```

#### Créer un paiement

```ruby
payment = Payment.create!(user: current_user, amount_cents: 5000)
result = Lcl.client.payment.create(payment)

if result[:success]
  redirect_to result[:payment_url]
else
  flash[:error] = result[:error]
end
```

#### Traiter un callback

```ruby
result = Lcl.client.payment.handle_callback(params)

if result[:success] && result[:status] == 'completed'
  payment.complete!
end
```

#### Rembourser un paiement

```ruby
# Remboursement total
result = Lcl.client.payment.refund(payment)

# Remboursement partiel
result = Lcl.client.payment.refund(payment, amount_cents: 1000)
```

#### Capturer un paiement pré-autorisé

```ruby
result = Lcl.client.payment.capture(payment)
```

#### Annuler un paiement pré-autorisé

```ruby
result = Lcl.client.payment.cancel(payment)
```

## Structure des réponses

Toutes les méthodes retournent un Hash avec la structure suivante :

### Succès

```ruby
{
  success: true,
  # ... données spécifiques à la méthode
}
```

### Erreur

```ruby
{
  success: false,
  error: "Message d'erreur"
}
```

## Sécurité

- ✅ Signatures cryptographiques SHA256 avec RSA
- ✅ Validation des certificats
- ✅ Comparaison sécurisée des signatures (protection contre les attaques de timing)
- ✅ Logs détaillés pour l'audit

## Développement

### Tests

```ruby
# Dans vos specs, réinitialisez le client entre chaque test
RSpec.configure do |config|
  config.before(:each) do
    Lcl.reset!
  end
end
```

### Mocking

```ruby
# Mocker le client dans les tests
allow(Lcl).to receive(:client).and_return(double_lcl_client)
```

## Gestion des erreurs

La bibliothèque définit deux exceptions personnalisées :

- `Lcl::Client::ConfigurationError` : Erreur de configuration (variables manquantes, certificats invalides)
- `Lcl::Client::ApiError` : Erreur lors d'un appel API

```ruby
begin
  result = Lcl.client.payment.create(payment)
rescue Lcl::Client::ConfigurationError => e
  Rails.logger.error "Configuration LCL invalide: #{e.message}"
rescue Lcl::Client::ApiError => e
  Rails.logger.error "Erreur API LCL: #{e.message}"
end
```

## Contributions

Pour ajouter une nouvelle fonctionnalité API :

1. Créer une nouvelle classe dans `lib/lcl/api/`
2. Ajouter une méthode au client dans `lib/lcl/client.rb`
3. Documenter dans ce README
4. Ajouter des tests

Exemple :

```ruby
# lib/lcl/api/subscription.rb
module Lcl
  module Api
    class Subscription
      attr_reader :client

      def initialize(client)
        @client = client
      end

      def create(params)
        # Implémentation
      end
    end
  end
end

# lib/lcl/client.rb
def subscription
  @subscription ||= Lcl::Api::Subscription.new(self)
end
```


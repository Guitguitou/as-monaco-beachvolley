# Fichiers de traduction

Cette application utilise une organisation modulaire des fichiers de traduction pour une meilleure maintenabilité.

## Structure des fichiers

### Fichiers par modèle
- `session.yml` - Traductions pour le modèle Session
- `user.yml` - Traductions pour le modèle User
- `registration.yml` - Traductions pour le modèle Registration
- `level.yml` - Traductions pour le modèle Level
- `balance.yml` - Traductions pour le modèle Balance
- `credit_transaction.yml` - Traductions pour le modèle CreditTransaction
- `session_level.yml` - Traductions pour le modèle SessionLevel

### Fichiers généraux
- `common.yml` - Messages et actions communs
- `fr.yml` - Configuration des formats de date/heure

## Utilisation

### Dans les vues
```erb
<%= t('activerecord.models.session.one') %> <!-- "Session" -->
<%= t('activerecord.attributes.session.title') %> <!-- "Titre" -->
<%= t('sessions.types.entrainement') %> <!-- "Entraînement" -->
```

### Dans les modèles
```ruby
# Dans le modèle Session
validates :title, presence: { message: :blank }
# Rails utilisera automatiquement la traduction appropriée
```

### Dans les contrôleurs
```ruby
# Dans un contrôleur
redirect_to sessions_path, notice: t('sessions.messages.created')
```

### Messages d'erreur personnalisés
```ruby
# Dans un modèle
validate :custom_validation

private

def custom_validation
  errors.add(:base, :custom_error)
end
```

## Organisation des clés

### Structure standard pour chaque modèle
```yaml
fr:
  activerecord:
    models:
      model_name:
        one: "Nom singulier"
        other: "Nom pluriel"
    attributes:
      model_name:
        attribute_name: "Nom de l'attribut"
    errors:
      models:
        model_name:
          attributes:
            attribute_name:
              error_type: "Message d'erreur"
  model_names:
    types:
      type_name: "Nom du type"
    messages:
      action: "Message de succès"
    actions:
      action_name: "Nom de l'action"
```

### Messages d'erreur courants
- `blank` - Champ obligatoire
- `invalid` - Format invalide
- `taken` - Valeur déjà utilisée
- `too_short` - Trop court
- `too_long` - Trop long
- `not_a_number` - Doit être un nombre
- `greater_than` - Doit être supérieur à
- `less_than` - Doit être inférieur à

## Ajout de nouvelles traductions

1. Identifiez le modèle concerné
2. Ajoutez les nouvelles clés dans le fichier correspondant
3. Utilisez la structure standard pour maintenir la cohérence
4. Testez les traductions dans l'application

## Bonnes pratiques

- Utilisez des clés descriptives et cohérentes
- Groupez les traductions par contexte (types, messages, actions)
- Évitez les clés dupliquées
- Utilisez les interpolations `%{variable}` pour les messages dynamiques
- Testez les traductions avec différents contextes 

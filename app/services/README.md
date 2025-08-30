# Services

## DuplicateSessionService

Ce service permet de dupliquer une session existante sur plusieurs semaines.

### Utilisation

```ruby
# Dupliquer une session sur 3 semaines
result = DuplicateSessionService.new(session, 3).call

if result[:success]
  puts "Créé #{result[:created_count]} sessions"
  result[:created_sessions].each do |dup_session|
    puts "Session dupliquée: #{dup_session.title}"
  end
else
  puts "Erreurs: #{result[:errors].join(', ')}"
end
```

### Paramètres

- `session`: La session à dupliquer (doit être persistée)
- `weeks`: Nombre de semaines à dupliquer (1-20, défaut: 1)

### Retour

Le service retourne un hash avec les clés suivantes :

- `success`: Boolean indiquant si la duplication a réussi
- `created_count`: Nombre de sessions créées
- `created_sessions`: Array des sessions créées
- `errors`: Array des erreurs (vide si succès)

### Fonctionnalités

- Duplique tous les attributs de la session originale
- Décale automatiquement les dates (start_at, end_at, cancellation_deadline_at, registration_opens_at)
- Copie les associations de niveaux (level_ids)
- Ne copie PAS les inscriptions (registrations)
- Gère les erreurs de validation (chevauchement de créneaux, etc.)
- Valide les paramètres d'entrée

### Exemple dans un contrôleur

```ruby
def duplicate
  authorize! :manage, Session
  
  result = DuplicateSessionService.new(@session, params[:weeks]).call
  
  if result[:success]
    redirect_to admin_sessions_path, notice: "#{result[:created_count]} session(s) créée(s) ✅"
  else
    alert_message = result[:errors].any? ? 
      ["Certaines duplications ont échoué:", *result[:errors]].join("\n") :
      "Erreur lors de la duplication"
    redirect_to admin_session_path(@session), alert: alert_message
  end
end
```

# Serveur MCP intégré à l'app Rails, OAuth via Doorkeeper, tools métier uniquement

Le Staff doit pouvoir piloter le club depuis son Claude (claude.ai web/mobile ou Desktop), ce qui impose un connecteur MCP distant authentifié en OAuth 2.1. Nous exposons le MCP directement depuis l'app Rails (`POST /mcp`), avec Doorkeeper par-dessus Devise, des scopes `read` / `write` distincts, et uniquement des tools métier ciblés qui passent par `Ability` et les mêmes services que les contrôleurs.

## Considered Options

- **Service MCP séparé appelant une API** : rejeté — une API à maintenir en plus, et une seconde source de vérité pour les autorisations.
- **Jeton API statique** : rejeté — non supporté par les connecteurs distants claude.ai/Desktop, et pas de révocation par utilisateur.
- **Tool générique « requête sur modèle X »** : rejeté — impossible de garantir ce qui sort (données personnelles des joueurs) et contournerait les services métier.

## Consequences

- Une action faite via Claude a exactement les mêmes effets de bord que dans l'UI (notifications, remboursements, annulations tardives).
- La perte du statut Staff coupe l'accès immédiatement, même avec un jeton encore valide.
- Le passage en écriture exige un nouveau consentement OAuth (scope `write`).
- Via Claude, seuls les rôles d'Encadrant (Coach, Responsable) sont modifiables, jamais les siens ; les rôles Staff restent réservés à l'UI.

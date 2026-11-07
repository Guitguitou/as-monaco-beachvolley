# Écriture MCP ouverte aux sessions publiées et aux inscriptions, admins uniquement

Remplace la conséquence « aucun tool MCP ne modifie de joueur, de solde de crédits ni de séance publiée » de l'ADR 0003. Le manager de section gère depuis son Claude des séances et des inscriptions que le Staff aurait sinon à ressaisir. Un admin peut donc, via MCP, créer, modifier et supprimer des sessions, mais aussi inscrire un joueur à une session ou le désinscrire. Ces actions passent par les mêmes services que l'UI : crédits débités ou remboursés, priorités, liste d'attente, désinscriptions tardives. Elles exigent le scope `write`.

## Considered Options

- **Rester aux brouillons (ADR 0003)** : rejeté. Les séances et les inscriptions sont le travail quotidien du manager, et les ressaisir coûte plus cher que le risque d'erreur, qui reste rattrapable dans l'UI.
- **Ouvrir aussi au coach de la session, comme dans l'app** : rejeté. Les tools d'écriture restent réservés aux admins (`:manage, :admin_sessions`).

## Consequences

- Via MCP, l'inscription refuse un joueur qui ne « Peut pas réserver ». L'admin qui veut forcer passe par l'UI.
- Une désinscription via MCP peut être excusée, auquel cas le joueur est remboursé (cf. GLOSSARY.md).
- Les soldes de crédits ne bougent que par l'effet d'une inscription ou d'une désinscription, jamais directement.

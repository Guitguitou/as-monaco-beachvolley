# Écriture MCP limitée aux brouillons, scope séparé, journal des modifications

Le connecteur MCP (ADR 0001) est aujourd'hui en lecture seule. L'assistant du manager de section propose d'écrire sur le site pour éviter les ressaisies. Nous n'ouvrirons l'écriture que pour créer des **brouillons non publiés** (fiche de tournoi, de stage), que le Staff publie après relecture. Ces écritures exigent un scope `write` distinct du scope `read`, et chacune est inscrite dans un journal qui indique qui a écrit, quoi et quand, via Claude.

## Considered Options

- **Écriture complète au niveau du Staff** : rejetée. Une erreur sur un joueur, un crédit ou une séance publiée touche directement des licenciés, et ces cas sont trop rares pour justifier le risque.
- **Aucune écriture** : rejetée. Les tournois sont ressaisis à la main alors qu'un brouillon ne présente aucun risque pour les inscriptions en cours.

## Consequences

- Aucun tool MCP ne modifie de joueur, de solde de crédits ni de séance publiée.
- Retirer le scope `write` coupe l'écriture sans toucher à la lecture.
- Toute écriture via Claude peut être retracée et annulée à partir du journal.

# Fusion de séances : la séance absorbée devient une séance annulée

Quand deux entraînements au même créneau ont trop peu d'inscrits (par exemple G1m et G2m avec deux joueurs chacun), le Staff les fusionne pour qu'un seul coach les encadre. Une séance porte déjà plusieurs groupes avec un rang de priorité : la fusion transfère donc les groupes et les inscriptions (confirmées et en attente) de la **séance absorbée** vers la **séance conservée**, qui reçoit le coach choisi et la capacité saisie lors de la fusion. La séance absorbée devient une Séance annulée au motif « fusionnée », sans remboursement puisque ses inscrits sont transférés. Un joueur inscrit aux deux séances garde une seule inscription ; l'autre est remboursée.

## Considered Options

- **Lier les deux séances sans les réunir** (deux séances visibles, coach commun) : rejeté. Deux rosters, deux capacités et deux listes d'attente à garder cohérents pour une seule séance réelle.
- **Supprimer la séance absorbée** : rejeté. La Suppression de séance est réservée aux erreurs de saisie et ne laisse aucune trace ; le club veut savoir qu'une séance a été fusionnée.

## Consequences

- La fusion est irréversible : une erreur se corrige à la main.
- Elle porte sur une seule occurrence d'une série, jamais sur toute la série.
- Conditions : deux entraînements non annulés, même début, même fin, même prix ; la capacité saisie ne peut pas être inférieure aux inscrits confirmés cumulés.
- Disponible depuis la fiche admin d'un entraînement et via le connecteur MCP, réservée au Staff.
- Les inscrits transférés et le coach écarté sont prévenus.

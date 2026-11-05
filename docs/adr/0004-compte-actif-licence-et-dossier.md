# Compte actif : licence payée et dossier complet, dossier refait chaque saison

Jusqu'ici, le paiement de la licence suffisait à ouvrir toute l'app ; seule l'inscription à une session exigeait en plus le Dossier complet. Des membres accédaient donc au club sans que le Staff ait vérifié leurs pièces d'adhésion. Désormais, un **Compte actif** exige la Licence payée **et** le Dossier complet. Tant que le dossier n'est pas coché, le membre qui a payé garde l'accès restreint d'un membre sans licence, avec un message indiquant que sa licence est reçue. Le Dossier complet est décoché pour tous à la remise à zéro de la saison, renouvellements compris : les pièces valent pour une saison.

## Considered Options

- **Paiement seul, inscription bloquée sans dossier** (comportement précédent) : rejeté. Le membre voit le club comme actif, le Staff et l'assistant MCP aussi, et le dossier n'est jamais réclamé.
- **Conserver le Dossier complet d'une saison à l'autre** : rejeté. Un membre qui rachète sa licence redeviendrait actif sans que ses pièces soient revues.

## Consequences

- Au déploiement, les membres qui ont payé mais dont le dossier n'est pas coché perdent l'accès complet jusqu'à ce que le Staff le coche.
- Le paiement pose toujours la date de Licence payée ; seule l'activation du compte dépend en plus du Staff.
- Admins et Responsables financiers restent exemptés de cette règle.
- À chaque nouvelle saison, le Staff doit recocher le Dossier complet de chaque membre, même de ceux qui ont déjà renouvelé.

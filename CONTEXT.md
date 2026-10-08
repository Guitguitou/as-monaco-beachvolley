# AS Monaco Beach Volley

## Language

**Tournoi**:
Compétition homologuée par la fédération et organisée par le club. Elle est datée, a une affiche, un niveau (ex. Série 3) et un prix par équipe.
_Avoid_: Session tournoi, événement

**Inscription BVS**:
Inscription officielle d'une équipe à un **Tournoi**, faite sur la plateforme de la fédération (BVS). C'est la seule source de vérité pour savoir qui participe.
_Avoid_: Registration (réservé aux sessions de l'app)

**Pack tournoi**:
**Pack** qui sert à payer, dans l'app, les frais d'un **Tournoi**. Payer ce pack ne vaut pas inscription.

**Stage**:
Période de plusieurs jours d'entraînement encadrée par des coachs. Elle se paie avec un pack de stage.

## Relationships

- Un **Tournoi** a un **Pack tournoi** pour le paiement
- Un **Tournoi** occupe des terrains dans l'agenda : ce sont des Sessions de type tournoi, qui sont des occupations et non des fermetures
- Les **Inscriptions BVS** restent hors de l'app : l'app ne compte pas les équipes
- Le **Pack tournoi** est créé avec le **Tournoi**, fermé par défaut ; l'admin ouvre le paiement manuellement
- Un joueur paie au plus une fois par **Tournoi** ; le paiement couvre une équipe
- Un **Tournoi** se tient sur nos terrains (il occupe alors un ou plusieurs terrains) ou ailleurs (il n'en occupe aucun)

- Un **Tournoi** peut durer plusieurs jours, avec les mêmes horaires chaque jour
- Un **Tournoi** a un niveau (S3, S2, S1, Elite) et, en option, des points (ex. 150)
- Un **Tournoi** a plusieurs images ordonnées ; la première est la couverture

## Flagged ambiguities

- « Inscription » : il faut distinguer l'**Inscription BVS** (externe, officielle) de la Registration à une session de l'app.

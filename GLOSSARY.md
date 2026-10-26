# AS Monaco Beach Volley

Gestion des sessions, inscriptions, crédits et licences du club de beach volley de l'AS Monaco.

## Rôles

**Admin** :
Membre du bureau qui gère l'ensemble du club dans l'application.
_Avoid_: Manager, gérant

**Responsable financier** :
Membre du bureau chargé des crédits, paiements et transactions.
_Avoid_: Trésorier, financial manager

**Staff** :
Tout Admin ou Responsable financier, c'est-à-dire toute personne ayant accès à l'espace d'administration.
_Avoid_: Bureau, management

**Encadrant** :
Coach ou Responsable de réservation qui encadre une session.
_Avoid_: Supervisor, animateur

**Coach** :
Entraîneur qui anime un entraînement, un coaching privé ou un stage.
_Avoid_: Responsable

**Responsable de réservation** :
Encadrant qui tient le terrain d'un jeu libre ; il n'entraîne pas.
_Avoid_: Coach (pour un jeu libre), responsable de terrain

**Joueur** :
Membre du club sans rôle particulier.
_Avoid_: Adhérent, user

## Licences

**Licence payée** :
Le joueur a réglé la licence de la saison (achat en ligne ou validation par le Staff).
_Avoid_: Compte activé

**Dossier complet** :
Le Staff a vérifié toutes les pièces d'adhésion, qui restent sur le Drive ; il le coche dans la fiche joueur.

**Peut réserver** :
Licence payée et Dossier complet : seule condition pour s'inscrire à une session.
_Avoid_: Compte activé

## Inscriptions

**Désinscription tardive** :
Désinscription d'un entraînement payant après sa date limite d'annulation (ou une fois la session commencée) : non remboursée et comptée dans les alertes du joueur.
_Avoid_: Annulation tardive, late cancel

**Désinscription excusée** :
Désinscription tardive dont le Staff lève la pénalité au moment de retirer le joueur : remboursée et non comptée, mais tracée comme toute désinscription tardive.
_Avoid_: Annulation justifiée, dérogation

## Séances

**Séance annulée** :
Séance prévue qui n'aura pas lieu ; elle disparaît du calendrier mais reste connue du club avec son motif d'annulation. Les inscrits sont remboursés et prévenus. Ses désinscriptions tardives deviennent des désinscriptions excusées.
_Avoid_: Séance supprimée

**Motif d'annulation** :
Raison d'une séance annulée : météo, moins de 2 inscrits, absence d'encadrant ou autre.

**Suppression de séance** :
Effacement d'une séance qui n'aurait jamais dû exister (erreur de saisie) ; ne laisse aucune trace.
_Avoid_: Annulation

## Saison

**Saison** :
Période d'un an qui commence au mois de début de saison du club (septembre par défaut). La remise à zéro des licences en marque le passage sans la définir.
_Avoid_: Année, exercice

**Alerte** :
Situation calculée qui demande l'attention du Staff (joueur à risque, séance sans encadrant…). Elle n'a pas d'état : elle disparaît quand la situation est résolue.

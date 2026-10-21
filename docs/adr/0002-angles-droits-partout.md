# Angles droits partout, rond réservé aux marqueurs

L'UI vise un registre sportif et affirmé (Nike, adidas, IBM Carbon, Volleyball World). Pour cela, elle n'utilise que deux rayons :

- `rounded-none` pour **tous** les contrôles et toutes les surfaces : boutons, inputs, flash, cards, modales, dropdowns, calendrier (toolbar, événements, légende) ;
- `rounded-full` pour les **marqueurs** : avatars, badges, barres de progression, compteurs, pastilles de statut.

Toute autre valeur (`rounded`, `-sm`, `-md`, `-lg`, `-xl`) est interdite.

## Considered Options

- **Cards à 4px** : écarté. Ça ajoutait une troisième valeur pour un gain négligeable.
- **Cards arrondies (8 à 12px) avec boutons carrés** : c'était l'état précédent. Écarté, parce qu'un contrôle carré dans une surface arrondie viole la règle du rayon concentrique (rayon intérieur = rayon extérieur − padding) et donne l'impression que le contrôle « flotte ».
- **Neutraliser `rounded-lg`/`xl` dans le thème Tailwind pour qu'ils valent 0** : écarté. Une classe qui ne fait pas ce que son nom annonce trompe le lecteur. On préfère interdire ces classes par un lint.

## Consequences

Les modales se distinguent des cards par l'ombre et l'élévation, pas par l'arrondi. Le markup ad hoc des vues est migré vers `ButtonComponent`, `FormFieldComponent` et `CardComponent`, plutôt que corrigé classe par classe.

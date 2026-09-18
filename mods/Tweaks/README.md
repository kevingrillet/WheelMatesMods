# Tweaks

Tweaks est activé dans `mods/mods.txt`, avec SkipStartup et AutoDucks. Les POC et
leurs diagnostics sont désactivés. Après les corrections des touches, des voyages,
du HUD survivant et des scans, l'utilisateur indique que le fonctionnement semble
bon et autorise les commits. Ce retour valide les scénarios essayés, pas toutes les
situations moteur possibles. WallHack reste reporté à une version ultérieure.

## Commandes

La même touche de fonction désigne la même action : `Ctrl+Fn` pour le joueur 1,
`Ctrl+Shift+Fn` pour le joueur 2. Les affichages, le tri et le mode de ciblage sont
indépendants pour chaque joueur. Tout affichage démarre masqué après un reload.

| Action | Joueur 1 | Joueur 2 |
| --- | --- | --- |
| Coordonnées | `Ctrl+F1` | `Ctrl+Shift+F1` |
| Tableau des objets manquants chargés | `Ctrl+F2` | `Ctrl+Shift+F2` |
| Compas | `Ctrl+F3` | `Ctrl+Shift+F3` |
| Tri type puis distance / distance seule | `Ctrl+F4` | `Ctrl+Shift+F4` |
| TP vers la cible | `Ctrl+F5` | `Ctrl+Shift+F5` |
| Retour avant le dernier TP réussi | `Ctrl+F6` | `Ctrl+Shift+F6` |
| Rafraîchir les candidats | `Ctrl+F8` | `Ctrl+Shift+F8` |
| Cible suivante, passage en manuel | `Ctrl+F10` | `Ctrl+Shift+F10` |
| Revenir au mode automatique « plus proche » | `Ctrl+F12` | `Ctrl+Shift+F12` |

Le numéro correspond à LocalPlayers et au libellé du HUD : joueur 1 = indice 1
(écran droit observé), joueur 2 = indice 2 (écran gauche observé).
Le retour remplace l'ancien F7 ; F7 est utilisé par AutoDucks dans le manifeste actuel ; F9 et F11 restent libres.

## Affichages et sélection

- Coordonnées sur une ligne : `P1 XYZ 123 / 456 / 789 cm`.
- Compas sur une ligne : joueur, mode AUTO/MANUAL, type et libellé de cible,
  direction relative au véhicule, distance 3D et différence de hauteur signée.
  La bande LEVEL inclut ±2 mètres.
- Tableau trié par type puis distance, ou distance seule. Le marqueur `>` indique
  la cible commune au tableau, au compas et au TP. Dix lignes maximum sont montrées
  à la fois ; la page suit la cible. F10 permet de parcourir tous les candidats.
- AUTO choisit l'objet manquant chargé le plus proche de chaque joueur.
- MANUAL parcourt un ordre stable par type et identité de session, boucle à la fin,
  et conserve la cible pendant les déplacements et les rafraîchissements.
  Si la cible disparaît, la sélection avance vers la suivante encore valide.
- Les TP, retours et changements de cible fonctionnent aussi quand le HUD est masqué.

Les coordonnées et le compas sont compacts ; les POC gardent leur présentation
détaillée pour les diagnostics. Le tableau est rendu en texte dans le conteneur
UMG partagé, pas dans une fenêtre interactive.

## Catalogue et cycle de vie

Un scan ciblé alimente les deux joueurs au plus toutes les cinq secondes lorsque
le tableau ou le compas est affiché. Aucun scan de collecte ne tourne avec tous les
éléments masqués ou avec les seules coordonnées. Le rendu et les distances sont
actualisés toutes les 200 ms à partir de positions copiées en Lua ; aucun acteur
cible n'est conservé ni relu pour chaque ligne. Un objet collecté peut donc rester
affiché jusqu'au prochain scan. Le texte du widget n'est réécrit que s'il change.

Les touches mettent une commande en attente, traitée par cette même boucle (jusqu'à
200 ms de latence hors voyage). F8 effectue un scan large explicite, qui peut être
plus coûteux ; il préserve les modes de sélection. F5 effectue un scan ciblé et
résout à nouveau la cible par son chemin et son adresse avant le déplacement.

Les scans automatiques interrogent les classes narratives observées dans les dumps,
`BP_NarrativeItem_C` et `BP_Collectable_Microchip_C`, au lieu de tous les Actors.
F8 conserve la recherche large du POC pour les investigations. Un type narratif
supplémentaire trouvé uniquement par F8 n'est pas garanti dans les scans suivants.
Les widgets sont retrouvés par chemin/adresse ; ils ne sont plus conservés sous
forme de wrappers natifs. Le monde vient du GameInstance, ce qui évite le scan de
PlayerControllers effectué par `UEHelpers.GetWorld()` à chaque appel.

Un hook de chargement de map et une vérification de l'identité du monde vident les
candidats, sélections et points de retour. Les anciennes références scalaires aux
widgets sont abandonnées sans toucher les objets de la map détruite. La reprise
attend trois passages de boucle (environ 600 ms) ; les commandes reçues pendant
cette phase sont ignorées. Les préférences d'affichage et de tri
sont conservées pendant le voyage ; les sélections repartent en AUTO. Les overlays
se rattachent aux nouveaux HUD lorsque monde et joueurs sont disponibles.
Un reload réinitialise toutes les préférences et supprime les anciens textes.

Tweaks reprend le nettoyage de ModKit, y compris la restauration des états de rendu
laissés par POCWallHack. Cette restauration de migration n'active pas WallHack.
ModKit sait aussi retirer les overlays Tweaks lors du retour au profil POC.

## Objets couverts

`WMCollectibles` expose les Gears chargés et les objets narratifs absents de la
sauvegarde active. Les mini-jeux chargés sont affichés dans une section dédiée :

- `Recorded` : un résultat existe pour le `MinigameId` dans la sauvegarde active ;
- `No result` : la table de résultats est disponible, l'identifiant est valide,
  mais aucun résultat correspondant n'est enregistré ; le mini-jeu est aussi une
  cible du tableau principal, du compas et du TP ;
- `Unknown` : sauvegarde, table de résultats ou identifiant indisponible. Le
  mini-jeu reste visible mais n'est pas une cible automatique.

La correspondance utilise le vrai `MinigameId` du composant et les clés de
`LastMinigameResultById`, sans déduire un identifiant du nom d'entrée Guest.
Un résultat enregistré n'est pas une preuve de victoire, de médaille ou de
complétion de toutes les variantes ; l'interprétation doit être vérifiée en jeu.
Une sauvegarde indisponible affiche aussi `Narrative: Unknown` ; les Gears restent utilisables.

Il ne s'agit pas d'un catalogue complet de la map : les zones non chargées ne sont
pas couvertes. Les Gears conservent l'hypothèse validée par le POC (chargé = manquant).
Leurs libellés numérotés ne sont pas des identifiants persistants. Aucun filtre de
visibilité ou de monde par acteur n'est réintroduit : ils avaient éliminé des
cibles valides. Les identités de sélection sont limitées à la session et à la map.

## TP et retour

Le point d'approche initial est situé à 6 mètres horizontalement de la cible, du
côté du véhicule, et 1 mètre au-dessus. Si les positions horizontales coïncident,
le décalage se fait en +X. Les paramètres `Approach` au début du script sont
séparés par type (Gear, Narrative, Mini-game), avec les mêmes valeurs initiales.

Ce placement reprend les amplitudes du POC, sans vérification du sol ni balayage
de collision. Un décalage peut tomber dans un obstacle ou dans le vide : le
comportement du véhicule doit être validé en jeu pour les nouveaux emplacements.
La cible est revalidée avant le déplacement ; aucune cible signifie aucun TP.

Chaque TP réussi remplace le retour de ce joueur par sa position juste avant le
mouvement. Ce n'est ni le spawn ni le début d'une série de TP. Un échec conserve le
retour précédent ; un retour réussi le consomme. Changement de map et reload
suppriment tous les retours. Les sauvegardes ne sont jamais modifiées.

## Validation en jeu

Faire un reload complet avec `Ctrl+R` pour charger le nouveau manifeste. Tweaks,
SkipStartup et AutoDucks sont actifs ; garder POC et diagnostics désactivés pour
éviter les conflits de raccourcis. Pour revenir aux prototypes, désactiver Tweaks et activer ModKit
avec les POC souhaités, puis recharger.

1. Afficher coordonnées, tableau et compas séparément sur chaque joueur. Vérifier
   qu'ajouter Shift ne déclenche pas aussi l'action du joueur 1 et que chaque HUD
   reste lisible ; masquer chaque élément indépendamment.
2. Comparer le tri type/distance au tri par distance, puis parcourir les cibles
   avec F10 jusqu'à la boucle. Se déplacer : la cible manuelle doit rester stable.
   F12 doit revenir au plus proche uniquement pour le joueur concerné.
3. Collecter une cible et vérifier sa disparition, automatiquement puis avec F8.
   Tester une liste vide et une sauvegarde indisponible.
4. Tester F5/F6 pour chaque joueur, HUD visible puis masqué. Vérifier les points
   d'approche, les déplacements successifs et les retours indépendants.
5. Changer de map, tester l'absence d'ancien retour et la reconstruction des HUD.
   Recharger avec `Ctrl+R` : aucun texte résiduel, affichages masqués, retours vides.

Les tests Lua couvrent ces transitions dans un modèle UE4SS, mais pas le rendu
natif, les collisions, la physique ni l'autorité réseau.
Voir les [contrats shared](../shared/README.md) et les [tests](../../tests/README.md).

## Historique des corrections et limites

Le scénario F1/F2/F3, déplacement, puis F1 a provoqué une violation d'accès native
UE4SS. La capture du crash confirme les trois affichages actifs. La pile disponible
ne fournit pas la ligne Lua responsable ; la cause exacte reste à confirmer.

La première correction supprime les callbacks temporaires `ExecuteInGameThread`
créés à chaque touche : les actions, scans et mises à jour HUD passent désormais
par la même boucle persistante. Le hook de map marque une invalidation et abandonne
les commandes en attente ; le nettoyage effectif est fait dans cette boucle.
Le log indique le début et la fin de chaque commande pour localiser un éventuel
nouveau crash. Les tests reproduisent la séquence de touches, mais ne simulent pas
la durée de vie native des wrappers UE4SS. Ce scénario a ensuite été confirmé
sans crash par l’utilisateur.

## Voyage et fluidité

Après validation du correctif des touches, un crash a été signalé après deux
changements de map, avec une autre adresse fautive native. La nouvelle version
remplace les wrappers conservés des widgets et cibles par des références scalaires,
ne touche plus les anciens widgets lors de l'invalidation du monde, puis les
récupère après la courte phase de reprise. La cause native exacte reste non
symbolisée ; les tests Lua ne constituent pas une validation du crash en jeu.

Le test de performance vérifie l'absence de scans Actor automatiques, l'absence de
scans avec le HUD masqué ou les seules coordonnées, et l'absence de lecture des
acteurs cibles entre les scans. Les scans dépassant 20 ms de temps CPU sont notés
`Slow target scan` dans le log ; ce n'est pas une mesure complète des temps de frame.

## HUD survivant et protection du chargement

Les captures suivantes ont montré un ancien bloc Kitchen figé au-dessus du nouveau
HUD Garage. `forget()` abandonnait la référence Lua mais laissait le texte attaché
si le HUD survivait au voyage. Après stabilisation, `recover()` retire désormais les
anciens textes par leur préfixe de propriété, à partir d'une énumération fraîche.
Le conteneur et le texte nommés sont réutilisés s'ils existent : aucun appel à
`StaticConstructObject` pour reconstruire un widget encore vivant.

Un [hook avant LoadMap](https://docs.ue4ss.com/dev/lua-api.html) suspend la boucle
avant ses lectures Unreal ; le hook après chargement déclenche la reprise. Les
raccourcis en attente pendant le chargement sont abandonnés. La boucle arrête aussi
le traitement si une action déclenche un voyage synchrone.

Après un voyage, le catalogue reste masqué sous `Updating loaded targets...` pendant
une courte phase de scans ciblés rapprochés (environ deux secondes après la pause
initiale). Après TP ou retour réussi, cette phase dure environ une seconde. Les
coordonnées restent affichables ; les actions TP/cible suivante attendent la fin de
la phase de synchronisation. La cadence normale revient ensuite à cinq secondes.
Cela évite de présenter immédiatement les acteurs transitoires comme une liste
stabilisée ; ce délai ne garantit pas la fin de tout chargement asynchrone du moteur.

Le test `test_tweaks_surviving_hud.lua` simule un HUD survivant, un doublon figé,
plusieurs bascules et un TP. Le modèle refuse la reconstruction d'un widget nommé
vivant. Après cette correction, l’utilisateur indique que le fonctionnement semble
bon et demande les commits. Les piles natives sans symboles ne permettent pas
de démontrer une cause unique ni de garantir l’absence de tout crash futur.

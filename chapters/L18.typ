#import "../template.typ": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

== Indice di Katz (Centralità) <katz>

*Idea di partenza:* Generalizzare il concetto di elezione per maggioranza su un grafo/rete.

Partiamo da una matrice d'adiacenza $bold(A)$, dove l'arco orientato $x arrow.r y$ indica che $x$ vota per $y$. Il punteggio base di maggioranza equivale al numero di voti entranti per ciascun vertice, che si ottiene moltiplicando il vettore riga di tutti uni per $bold(A)$: $bold(1) bold(A)$.

*Problema:* La sola maggioranza diretta non considera l'importanza di *chi* esprime il voto. Vorremmo contare anche i voti ottenuti dalle persone che ci votano: $bold(1) bold(A)^2$ (che rappresenta il numero di cammini di lunghezza 2 entranti in ogni vertice).

#informally[
  Un voto vale di più se arriva da qualcuno che è a sua volta molto votato. Per catturarlo si contano non solo i voti diretti, ma tutti i cammini che arrivano al vertice, dando meno peso a quelli più lunghi.
]

#example[
  Nel grafo $a -> c$, $b -> c$, $c -> d$ i voti diretti sono $bold(1) bold(A) = (0, 0, mb(2), 1)$, quindi vince $c$. Contando i cammini di lunghezza 2 ($a -> c -> d$ e $b -> c -> d$) si ha $bold(1) bold(A)^2 = (0, 0, 0, mo(2))$: $d$ riceve peso proprio dai voti di chi ha votato $c$.

  #figure(
    diagram(
      node-stroke: 0.6pt,
      node-inset: 6pt,
      spacing: (22mm, 14mm),
      node((0, -0.5), $a$, shape: circle, name: <a>),
      node((0, 0.5), $b$, shape: circle, name: <b>),
      node((1, 0), $c$, shape: circle, name: <c>),
      node((2, 0), $d$, shape: circle, name: <d>, fill: luma(225)),
      edge(<a>, <c>, "->"),
      edge(<b>, <c>, "->"),
      edge(<c>, <d>, "->"),
    ),
    caption: [Voti diretti contro cammini di lunghezza 2.],
  )
]

Possiamo iterare il processo sommando i cammini di lunghezza $k$ per $k -> infinity$. Tuttavia, i cammini crescono esponenzialmente con $k$. Per ovviare a ciò, introduciamo un fattore numerico di attenuazione $alpha$ in modo tale che la serie converga:

$ bold(x) = alpha bold(1) bold(A) + alpha^2 bold(1) bold(A)^2 + dots.c = sum_(k >= 1) bold(1) (alpha bold(A))^k $

La serie converge a patto che $alpha < 1 / rho(bold(A))$, dove $rho(bold(A))$ è il raggio spettrale di $bold(A)$. L'attenuazione serve proprio a contrastare il tasso di crescita della matrice dato dal suo autovalore principale.

Includendo anche il termine di lunghezza $k=0$ (che aggiunge soltanto la costante $bold(1)$ a ogni vertice e non cambia la classifica), consideriamo la serie matriciale:
$ sum_(k >= 0) (alpha bold(A))^k $

#note[
  Invece di calcolare il limite delle potenze della matrice (come nei metodi di tipo Markov/Perron-Frobenius), consideriamo una sommatoria attenuata dal fattore $alpha$. Possiamo usare $alpha$ per calibrare l'importanza delle connessioni vicine rispetto a quelle lontane:
  - *$alpha$ piccolo:* l'attenuazione è forte, prevalgono le *connessioni vicine* (locali).
  - *$alpha$ grande:* l'attenuazione è debole, si attribuisce maggior peso alle *connessioni lontane* (globali).
]

=== Formulazione tramite Sistema Lineare

È noto che per la serie geometrica scalare vale $sum_(k >= 0) q^k = 1 / (1 - q)$ per $abs(q) < 1$. Analogamente, in ambito matriciale:

#theorem(title: "Serie di Neumann")[
  Se $rho(alpha bold(A)) < 1$, ovvero $alpha < 1 / rho(bold(A))$, la matrice $bold(I) - alpha bold(A)$ è invertibile e
  $ sum_(k >= 0) (alpha bold(A))^k = (bold(I) - alpha bold(A))^(-1) $
]

#proof[
  Poniamo $bold(X) = alpha bold(A)$ e moltiplichiamo la somma parziale per $(bold(I) - bold(X))$. I termini intermedi si cancellano a coppie (somma telescopica):
  $ (sum_(k = 0)^N bold(X)^k) (bold(I) - bold(X)) = (bold(I) + bold(X) + dots.c + bold(X)^N) - (bold(X) + bold(X)^2 + dots.c + bold(X)^(N+1)) = bold(I) - bold(X)^(N+1) $
  Poiché $rho(bold(X)) < 1$, si ha $bold(X)^(N+1) -> bold(0)$ per $N -> infinity$. Passando al limite il prodotto restituisce l'identità $bold(I)$, quindi la serie coincide con la matrice inversa.
]

Calcolare l'Indice di Katz vettoriale $bold(x) = bold(1) (bold(I) - alpha bold(A))^(-1)$ equivale quindi a risolvere il seguente sistema lineare:

$ bold(x) (bold(I) - alpha bold(A)) = bold(1) quad <==> quad bold(x) = bold(1) (bold(I) - alpha bold(A))^(-1) $


== PageRank

L'indice di PageRank è concettualmente più recente.

*Idea base:* Consideriamo la matrice d'adiacenza $bold(A)$ normalizzata per riga (o per colonna a seconda della convenzione) in modo che le righe sommino ad $1$ (matrice stocastica $overline(bold(A))$). Modelliamo il comportamento di un *random surfer* che naviga tra le pagine seguendo i link, ma con una probabilità di "teletrasportarsi" casualmente su una qualsiasi pagina tramite il lancio di una moneta.

La matrice di transizione risultante è:
$ bold(P) = mb(alpha overline(bold(A))) + mo((1 - alpha) bold(1)^T bold(v)) $

dove il termine #text(fill: blue)[blu] è il *seguire un link* (probabilità $alpha$) e il termine #text(fill: orange)[arancione] è il *teletrasporto* (probabilità $1 - alpha$).

#figure(
  diagram(
    node-stroke: 0.6pt,
    node-inset: 6pt,
    spacing: (28mm, 18mm),
    node((0, 0), $1$, shape: circle, name: <n1>),
    node((1, -0.5), $2$, shape: circle, name: <n2>),
    node((1, 0.5), $3$, shape: circle, name: <n3>),
    node((0.5, 2), [teletrasporto], shape: rect, stroke: (dash: "dashed"), name: <tp>),

    edge(<n1>, <n2>, "->", $alpha / 2$, label-side: left),
    edge(<n1>, <n3>, "->", $alpha / 2$, label-side: right),
    edge(<n2>, <n3>, "->", $alpha$, label-side: left),
    edge(<n3>, <n1>, "->", bend: 35deg, $alpha$, label-side: right),

    edge(<tp>, <n1>, "-->", $(1 - alpha) v_1$, label-side: right),
    edge(<tp>, <n2>, "-->", $(1 - alpha) v_2$, label-side: left),
    edge(<tp>, <n3>, "-->", $(1 - alpha) v_3$, label-side: right),
  ),
  caption: [
    Random surfer: archi continui = link seguiti (probabilità $alpha / "outdegree"$),
    archi tratteggiati = salto casuale con probabilità $1 - alpha$ distribuita secondo $bold(v)$.
  ],
)

#note[
  Una combinazione convessa di matrici di Markov/stocastiche, con $0 <= alpha <= 1$, produce ancora una catena di Markov valida. È la formalizzazione rigorosa del random surfer che naviga con probabilità $alpha$ e salta a caso con probabilità $1-alpha$.
]

#note(title: "Personalized PageRank")[
  Invece della distribuzione uniforme $1/n bold(1)$, si impiega un generico vettore di probabilità $bold(v)$. Questo permette di sbilanciare (*bias*) il PageRank verso un particolare sito o insieme di nodi di interesse. Se facciamo ripartire sempre il surfer da un insieme specifico, le pagine vicine a quell'insieme otterranno un punteggio più alto. Spesso si usa per prevenire spam o personalizzare la ricerca.
]

=== Calcolo dello Stato Stazionario

Il PageRank corrisponde alla distribuzione limite/stazionaria $bold(p)$ della catena di Markov, definita dall'equazione agli autovalori:
$ bold(p) = bold(p) bold(P) $

Sostituendo la definizione di $bold(P)$:
$ bold(p) = bold(p) (alpha overline(bold(A)) + (1 - alpha) bold(1)^T bold(v)) = alpha bold(p) overline(bold(A)) + (1 - alpha) (bold(p) bold(1)^T) bold(v) $

Poiché $bold(p)$ è un vettore di probabilità, la somma dei suoi elementi è pari a $1$, ovvero $bold(p) bold(1)^T = 1$. L'equazione si semplifica in un'equazione lineare:

$ bold(p) - alpha bold(p) overline(bold(A)) = (1 - alpha) bold(v) $

Raccogliendo $bold(p)$:
$ bold(p) (bold(I) - alpha overline(bold(A))) = (1 - alpha) bold(v) quad -> quad bold(p) = (1 - alpha) bold(v) (bold(I) - alpha overline(bold(A)))^(-1) $

Sviluppando nuovamente come serie geometrica (si applica il teorema di Neumann a $alpha overline(bold(A))$, con $rho(overline(bold(A))) = 1$ e $alpha < 1$):
$ bold(p) = (1 - alpha) bold(v) sum_(k >= 0) (alpha overline(bold(A)))^k $

#informally[
  A meno del fattore scalare di peso $(1 - alpha)$, dell'uso della matrice normalizzata $overline(bold(A))$ e del vettore di salto $bold(v)$, il PageRank ha la *stessa forma algebrica dell'Indice di Katz* (vedi #link-section(<katz>)).
]

=== Interpretazione Combinatoria sui Cammini

Possiamo interpretare il PageRank anche senza ricorrere alla teoria delle catene di Markov, vedendolo come una somma pesata su tutti i possibili cammini del grafo.

Poiché le potenze della matrice rappresentano i cammini, la serie $bold(v) sum_(k >= 0) (alpha overline(bold(A)))^k$ si spezza considerando tutti i cammini orientati di lunghezza $k$:
1. Il vertice iniziale del cammino ha un peso iniziale $v_i$ fornito dal vettore di personalizzazione $bold(v)$.
2. Ogni arco attraversato dal nodo $u$ al nodo $w$ contribuisce con un fattore pari a $alpha / "outdegree"(u)$.

Quindi, il PageRank di un nodo $y$ è la somma sui cammini infiniti entranti in $y$, dove ciascun cammino è pesato dal prodotto del peso iniziale $v_i$ e dei fattori di attenuazione/outdegree lungo ciascun arco. Questa è la terza interpretazione formale (e la più intuitiva dal punto di vista combinatorio) per il calcolo del PageRank.

== Quadro Riassuntivo delle Centralità

I quattro metodi principali di centralità basati su matrici si possono schematizzare e confrontare secondo due assi: *normalizzazione della matrice* e *tipo di operazione* (limite delle potenze vs. somma geometrica attenuata).

#table(
  columns: (1.3fr, 2fr, 2fr),
  align: center + horizon,
  [*Matrice*], [*Limite ($k arrow.r infinity$)*], [*Somma attenuata ($k >= 0$)*],
  [*Non normalizzata ($bold(A)$)*],
  [*Landau* (centralità da autovettore) \ $lim_(k arrow.r infinity) bold(1) bold(A)^k$ (a meno di normalizzazione)],
  [*Katz* \ $bold(1) sum_(k >= 0) (alpha bold(A))^k$],

  [*Normalizzata ($overline(bold(A))$)*],
  [*Seeley* \ $lim_(k arrow.r infinity) bold(v) overline(bold(A))^k$],
  [*PageRank* \ $(1 - alpha) bold(v) sum_(k >= 0) (alpha overline(bold(A)))^k$],
)

#note[
  I quattro metodi sono strettamente interconnessi da relazioni di limite e di perturbazione:
  - *Dalla somma al limite (verticale):* facendo tendere $alpha$ al valore critico (legato al raggio spettrale), la somma attenuata converge verso i metodi al limite: da PageRank si passa a Seeley, e da Katz si passa a Landau.
  - *Dalla versione pura a quella perturbata (orizzontale):* aggiungere il fattore di smorzamento o il teletrasporto ($alpha$) equivale a perturbare le matrici di partenza, trasformando Seeley in PageRank e Landau in Katz, garantendo così sempre esistenza e unicità della soluzione anche su grafi non fortemente connessi.
]
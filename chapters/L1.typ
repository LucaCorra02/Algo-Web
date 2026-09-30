#import "../template.typ": *

= Nozioni di base

Nel corso vedremo due tipi di strutture dati: *compresse* e *succinte*:
- *Strutture Succinte*: struttura dati che utilizza lo spazio minimo possibile per rappresentare un insieme di dati, senza perdere la capacità di eseguire operazioni efficienti su di essi. Lo spazio occupato di avvicina al limite inferiore dell'informazione (Shannon). Esse si basano sulla *combinatoria*: Contano quante configurazioni possibili esistono per una determinata struttura dati e usano il numero minimo di bit per distinguere quelle configurazioni.

#example()[
  Per distinguere tutti gli alberi binari con $n$ nodi servono circa $O(n log n)$ puntatori. Tuttavia, il numero di alberi binari con $n$ nodi è dato dal numero di Catalan:
  $
    C_n = 4^n / (n^(3/2))
  $
  servono quindi circa $log_2(C_n) approx 2n "bit"$ per distinguere tutti gli alberi binari con $n$ nodi. Una struttura succinta usa $2n + o(n)$ bit permettendo di trovare il figlio sinistro, il figlio destro e sinistro in tempo costante.
]

- *Strutture Compresse*: La *distribuzione dei dati è nota* a priori. Esse fanno un passo in più rispetto alle strutture succinte: comprimono i dati in base alla loro distribuzione, riducendo ulteriormente lo spazio occupato. Lo spazio viene ridotto non solo rispetto al numero di configurazioni strutturali ma avvicinandosi all'*entropia empirica* dei dati $H_k$

Le strutture che vedremo hanno delle operazioni in tempo costante: il tempo non dipende da quanti dati inseriamo, ma da altri parametri, come la probabilità di errore.

#note()[
  Il compromesso è *l'immutabilità delle strutture* (strutture statiche). Non è possibile la modifica dei dati: se voglio aggiungere un elemento, devo ricostruire la struttura da zero.
]

== Grafi

Andiamo a definire un grafo orienato $G$ come una tupla $G = <N, A, s, t>$, dove:
- $N$ è l'insieme dei nodi. (L'ordine del grafo è il numero totale dei suoi vertici $|N|$).
- $A$ è l'insieme degli archi
- $s, t: A -> N$ sono due funzioni che collegano un arco a un nodo. Dove $s$ è la funzione di sorgente e $t$ è la funzione di destinazione (target). In questo modo possiamo rappresentare *archi paralleli* (stesso nodo di partenza e arrivo) ovvero se esistono due archi $a$ e $b$ t.c:
  $
    s(a) = s(b) "e" t(a) = t(b)
  $
  Così da rappresentare pagine collegate più volte tra di loro.

#note()[
  Stando alla formulazione standard, un grafo definito come sopra è un *multigrafo*, ovvero un grafo che può avere archi multipli tra due nodi. 
  Un grafo che non presenta archi paralleli è detto *grafo separato*. Se inoltre è presente un arco che ha lo stesso nodo come inizio e fine ($s(a)=t(a)$), questo prende il nome di *Cappio (Loop)*.
]

Al fine di unificare i concetti di grafo orientato e non orientato, definiamo la *funzione di inversione degli archi* $sigma: A -> A$ che associa ad ogni arco $a$ il suo arco inverso $sigma(a)$, tale che:
$
  sigma^2 = 1 "identità" \
  s compose sigma = t "se prendo un arco, lo giro e ne considero la sorgente, ottengo il target dell'arco originale"
$
Senza la funzione $sigma$, i grafi orientati e non orientati richiederebbero due definizioni matematiche diverse: coppie ordinate per i primi, insiemi di due nodi per i secondi. Introducendo $sigma$ un grafo orientato diventa un grafo in cui l'insieme degli archi $A$ è _chiuso_ rispetto a $sigma$. Ovvero: $forall a in A$ che va da $x$ a $y$, è garantita l'esistenza di un arco gemello $sigma(a)$ che va da $y$ a $x$.

#note(title: "(Grafi non orientati)")[
  In un grafo non orientato è utile definire due concetti contrapposti:
  - *Cricca (Clique):* Un insieme di vertici mutualmente tutti adiacenti tra loro.
  - *Insieme indipendente:* Un insieme di vertici mutualmente _non_ adiacenti.
]

Definiamo con:
- *indegree* = numero di vertici che entrano in un nodo
$
  d^-(x) = |{a in A: t(a) = x}| = |t^(-1)(x)| \
$
#note()[
  È una misura più difficile da manipolare: dobbiamo farci seguire da molte persone.
]
- *outdegree* = numero di vertici che escono da un nodo
$
  d^+(x) = |{a in A: s(a) = x}| = |s^(-1)(x)|\
$

#note()[
  Se il grafo non è orientato questi due valori coincidono grazie alla funzione di inversione degli archi.
]

=== Raggiungibilità e componenti connesse

Definiamo come *successori* i nodi raggiungibili da un nodo $x$ tramite un arco $a$ in un solo passo. I *predecessori* sono i nodi dai quali si raggiunge $x$ tramite un arco $a$ in un solo passo.

Definiamo con *path (cammino)* una sequenza alternata di nodi e archi che collega due nodi $x$ e $y$ in un grafo:
$
  a_1, a_2, ..., a_k "t.c" t(a_i) = s(a_(i+1)) space forall i = 1, ..., k - 1
$
La lunghezza del path è il numero di archi che lo compongono (i vertici del cammino possono ripetersi). 
- Un *Ciclo Semplice* è un cammino chiuso in cui i nodi interni non si ripetono mai.
- Il *Grafo Trasposto* si ottiene scambiando la funzione $s$ con la funzione $t$ (si "gira" il verso di ogni arco).

#note()[
  Gli archi in entrata e gli archi in uscita nel Web sono molto diversi. Conoscere i successori (seguire i link) è molto facile, mentre conoscere i predecessori è molto difficile: bisogna fare crawling di tutto il Web per sapere chi collega chi, ottenendo man mano le liste di adiacenza ed infine invertirle.

  Il processo non può sempre convengere, le liste di adiacenza ottenute riguardano solo una piccola parte del Web.
]

*Raggiungibilità*: se esiste un path da $x$ a $y$, diciamo che $y$ è raggiungibile da $x$.

*Componenti fortemente connesse*: Due (o più) nodi sono fortemente connessi se esiste una *relazione di equivalenza* tra di loro, ovvero i vertici sono co-raggiungibili, cioè se ciascuno dei due è raggiungibile dall'altro. La relazione di equivalenza $x tilde y$ è definita come:
$
  x tilde y <-> x -> y "and" y -> x
$
Deve inoltre avere le seguenti proprietà:
- _riflessiva_: $x tilde x$ (per il cammino vuoto)
- _simmetrica_: $x tilde y -> y tilde x$: se esiste un path da $x$ a $y$, deve esistere anche un path da $y$ a $x$;
- _transitiva_: $x tilde y, y tilde z -> x tilde z$: se esiste un path da $x$ a $y$ e da $y$ a $z$, allora esiste un path da $x$ a $z$.

Le classi di equivalenza di $tilde$ sono le componenti fortemente connesse del grafo. $G$ è *fortemente connesso* se ha una sola componente fortemente connessa, ovvero se tutti i nodi sono co-raggiungibili.

#informally(title: "Struttura delle Componenti (CFC)")[
  Le CFC sono a tutti gli effetti dei *"blocchi di co-raggiungibilità"*. All'interno della classe, da ogni nodo posso arrivare a qualsiasi altro nodo della stessa classe e tornare indietro.
  
  Se guardiamo al grafo dove ogni componente diventa un super-nodo, potremmo avere un cammino che permette di arrivare da una CFC $A$ a una CFC $B$, ma una volta in $B$ *non è più possibile tornare indietro* ad $A$ (altrimenti $A$ e $B$ si unirebbero nella stessa unica classe di equivalenza).
]

#figure(
  fletcher.diagram(
    fletcher.node((0, 0), [x], fill: orange.lighten(70%), stroke: orange.darken(20%)),
    fletcher.node((1.4, 0), [y], fill: orange.lighten(70%), stroke: orange.darken(20%)),
    fletcher.node((0.7, 1.1), [z], fill: orange.lighten(70%), stroke: orange.darken(20%)),
    fletcher.edge((0, 0), (1.4, 0), "->"),
    fletcher.edge((1.4, 0), (0.7, 1.1), "->"),
    fletcher.edge((0.7, 1.1), (0, 0), "->"),
    fletcher.node((3.8, 0), [u], fill: blue.lighten(70%), stroke: blue.darken(20%)),
    fletcher.node((5.2, 0), [v], fill: blue.lighten(70%), stroke: blue.darken(20%)),
    fletcher.node((4.5, 1.1), [w], fill: blue.lighten(70%), stroke: blue.darken(20%)),
    fletcher.edge((3.8, 0), (5.2, 0), "->"),
    fletcher.edge((5.2, 0), (4.5, 1.1), "->"),
    fletcher.edge((4.5, 1.1), (3.8, 0), "->"),
    fletcher.edge((1.4, 0), (3.8, 0), "->", bend: 20deg),
  ),
  caption: [Componenti fortemente connesse: all'interno di ogni classe ogni nodo raggiunge gli altri; tra classi diverse il passaggio può essere a senso unico.],
)
Una componente *debolmente connessa* è una componente connessa del *grafo orientato* ottenuta considerando anche la funzione di inversione degli archi: gli archi possono essere girati in modo da ignorarne l'orientamento. Si tratta di una relazione di equivalenza più debole (basta un arco tra due nodi in una qualsiasi direzione).

#example(title: "Il crawling e la Scelta del Seme")[
  Il problema del crawling non dipende solo dal "dove partiamo" per raggiungere una buona parte del Web, ma è anche una questione di *tempo* e di topologia.
  Dato che il Web è composto da queste componenti (CFC centrali, componenti solo in entrata e componenti solo in uscita), la *scelta del seme (seed)* è fondamentale. Se scegliamo un seme in un blocco isolato o in una componente senza vie d'uscita (come la CFC blu nell'immagine sopra, da cui non si può tornare indietro), il crawler si bloccherà presto non trovando più nuovi nodi da visitare.
]

*Distanza in un grafo*: lunghezza del path più corto (c'è ne può essere più di uno) tra due nodi $x$ e $y$. Se non esiste un path tra i due nodi, la distanza è $infinity$. Per essere una distanza, la funzione $d: N times N -> R$ deve soddisfare le seguenti proprietà:
- _non negatività_: $d(x,y) >= 0$ (la distanza non può essere negativa)
- _identità_: $d(x,y) = 0 <-> x = y$ (la distanza tra due nodi è nulla se e solo se i due nodi coincidono)
- _simmetria_: $d(x,y) = d(y,x)$ (la distanza tra due nodi non dipende dall'ordine in cui li consideriamo. Nel caso di grafi orientati questo vale solo se il grafo è perfettamente simmetrico).
- _triangolarità_: $d(x,y) <= d(x,z) + d(z,y)$
  #proof()[
    #figure(
    fletcher.diagram(
      fletcher.node((0, 0), [x], fill: orange.lighten(70%), stroke: orange.darken(20%)),
      fletcher.node((2.5, 1.4), [z], fill: orange.lighten(70%), stroke: orange.darken(20%)),
      fletcher.node((5, 0), [y], fill: orange.lighten(70%), stroke: orange.darken(20%)),
      fletcher.edge((0, 0), (2.5, 1.4), "->"),
      fletcher.edge((2.5, 1.4), (5, 0), "->"),
      fletcher.edge((0, 0), (5, 0), "->", bend: -18deg),
    ),
    caption: [$d(x,y) <= d(x,z) + d(z,y)$.],
    )
    1. Per definizione di distanza, $d(x,y)$ è la lunghezza del path più corto tra $x$ e $y$.
    2. Se esiste un path da $x$ a $y$ che passa per un nodo intermedio $z$, allora la lunghezza di quel path è data dalla somma delle lunghezze dei due path più corti:
      $
        x->z->y = d(x,z) + d(z,y)
      $
    3. Poiché il path più corto tra due nodi è il minimo tra tutti i possibili path, la lunghezza del path più corto tra $x$ e $y$ non può essere maggiore della somma dei due path più corti che passano per un nodo intermedio.

    #note()[
      L'uguale nel $<=$ è dovuto al fatto che se il nodo $z$ fa già parte del cammino minimo che va da $x$ a $y$, allora fermarsi in $z$ e ripartire non aggiunge alcun costo extra. Si usa $<$ nel caso in cui $z$ è una deviazione dal cammino minimo.
    ]
  ]
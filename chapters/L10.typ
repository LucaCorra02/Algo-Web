#import "../template.typ": *

= Codifiche entropiche

Le tecniche di codifica entropica cercano di rappresentare una stringa usando un numero di bit vicino all'entropia del sorgente.
In pratica, i simboli più frequenti costano meno, quelli rari costano di più.

Ci sono due modi principali per farlo:

- *codifica aritmetica*: si costruisce un intervallo continuo;
- *codifica asimmetrica*: si aggiorna uno stato numerico intero.

L'idea di fondo è sempre la stessa: ogni nuovo simbolo fa crescere il costo in modo proporzionale alla sua rarità.

= Codifica aritmetica

Il problema classico della codifica di sorgente (come il codice di Huffman) assegna a ciascun simbolo un *numero intero di bit*. Questo approccio impedisce di rappresentare un singolo simbolo con meno di un bit (ad esempio, un simbolo con probabilità $p > 0.5$ richiederebbe teoricamente $log_2 p < 1$ bit, ma Huffman è costretto ad assegnargli almeno $1$ bit).

La *codifica aritmetica* supera questo limite fondamentale associando un'*intera sequenza di simboli a un unico intervallo* sui numeri reali all'interno di $[0, 1)$, la cui ampiezza è proporzionale alla probabilità con cui la sequenza stessa si verifica.

Sia:
- $Sigma = [0 .. k)$ l'alfabeto dei simboli
- $p_s$ la probabilità del simbolo $s in Sigma$
- $C_s = sum_(t < s) p_t$ la *probabilità cumulativa* dei simboli che precedono strettamente $s$.

L'algoritmo di codifica procede come segue:
1. Si parte dall'intervallo iniziale $[l, l+w) = [0, 1)$, che ha estremo inferiore $l = 0$ e ampiezza $w=1$.
2. Per codificare un simbolo $s$, si suddivide l'intervallo corrente $[l, l+w)$ in $k$ sottointervalli consecutivi di ampiezza proporzionale alle probabilità dei simboli e si seleziona quello corrispondente a $s$:
  $
    [l + w C_s space , space l + w (C_s + p_s))
  $
  Il nuovo estremo inferiore diventa quindi *$l' = l + w C_s$* e la nuova ampiezza diventa *$w' = w p_s$*. L'operazione si ripete per tutti i simboli della sequenza.

== Lunghezza dell'intervallo e contenuto informativo

Poiché a ogni passo l'ampiezza dell'intervallo viene moltiplicata per la probabilità $p_s$ del simbolo letto, dopo aver codificato una sequenza di $n$ simboli $s_0, s_1, dots, s_(n-1)$ l'ampiezza dell'intervallo finale è:
$
  P = product_(i=0)^(n-1) p_(s_i)
$
che corrisponde esattamente alla probabilità dell'intera sequenza (assumendo simboli indipendenti).

Prendendo il logaritmo in base $2$ dell'inverso di $P$, otteniamo:
$
  log_2 frac(1, P) = sum_(i=0)^(n-1) log_2 frac(1, p_(s_i))
$
Il termine a destra è la *somma esatta dei contenuti informativi* dei singoli simboli: non c'è alcun arrotondamento all'intero superiore simbolo per simbolo.

#example(title: "Secondo esempio passo-passo: sequenza AAB")[
  Dati due simboli $A$ e $B$ con probabilità $p(A) = 3/4$ e $p(B) = 1/4$, l'intervallo unitario iniziale è diviso in $[0, 3/4)$ per $A$ e $[3/4, 1)$ per $B$:

  #figure()[
    #cetz.canvas({
      import cetz.draw: *

      line((0, 0), (12, 0), stroke: black)
      rect((0, 0), (9, 1), fill: blue.lighten(80%), stroke: black)
      rect((9, 0), (12, 1), fill: red.lighten(80%), stroke: black)

      content((4.5, 0.5), [$A$])
      content((10.5, 0.5), [$B$])
      content((4.5, 1.5), [$p(A)=3/4$])
      content((10.5, 1.5), [$p(B)=1/4$])
      content((0, -0.6), [$0$])
      content((9, -0.6), [$3/4$])
      content((12, -0.6), [$1$])
    })
  ]

  Codifichiamo la sequenza `AAB`:
  1. La prima `A` seleziona $[0, 3/4)$. Suddividendolo nelle proporzioni $3/4$ e $1/4$, `A` occupa:
  $
    [0, 9/16) = [l + w C_s , w p_s] = [0 + 3/4 * 0, 3/4 * 3/4]
  $
  e `B` occupa $[9/16, 3/4)$:

  #figure()[
    #cetz.canvas({
      import cetz.draw: *

      line((0, 0), (12, 0), stroke: black)
      rect((0, 0), (6.75, 1), fill: blue.lighten(80%), stroke: black)
      rect((6.75, 0), (9, 1), fill: red.lighten(80%), stroke: black)
      rect((9, 0), (12, 1), fill: gray.lighten(85%), stroke: black)

      content((3.375, 0.5), [$A$])
      content((7.875, 0.5), [$B$])
      content((10.5, 0.5), [resto])
      content((0, -0.6), [$0$])
      content((6.75, -0.6), [$9/16$])
      content((9, -0.6), [$3/4$])
      content((12, -0.6), [$1$])
    })
  ]

  2. La seconda `A` seleziona $[0, 9/16)$, che viene diviso in $[0, 27/64)$ per `A` e $[27/64, 9/16)$ per `B`:

  #figure()[
    #cetz.canvas({
      import cetz.draw: *

      line((0, 0), (12, 0), stroke: black)
      rect((0, 0), (5.0625, 1), fill: blue.lighten(80%), stroke: black)
      rect((5.0625, 0), (6.75, 1), fill: red.lighten(80%), stroke: black)
      rect((6.75, 0), (12, 1), fill: gray.lighten(85%), stroke: black)

      content((2.53125, 0.5), [$A$])
      content((5.90625, 0.5), [$B$])
      content((9.375, 0.5), [resto])
      content((0, -0.6), [$0$])
      content((5.0625, -0.6), [$27/64$])
      content((6.75, -0.6), [$9/16$])
      content((12, -0.6), [$1$])
    })
  ]

  3. L'ultimo simbolo `B` seleziona $[27/64, 9/16) = [27/64, 36/64)$. L'ampiezza è $9/64$, proprio la probabilità della sequenza:
  $
    p(A A B) = 3/4 dot 3/4 dot 1/4 = 9/64
  $
  Il numero diadico $7/16 = 28/64 = 0.0111_2$ cade nell'intervallo finale:

  #figure()[
    #cetz.canvas({
      import cetz.draw: *

      line((0, 0), (12, 0), stroke: black)
      rect((0, 0), (5.0625, 1), fill: gray.lighten(85%), stroke: black)
      rect((5.0625, 0), (6.75, 1), fill: red.lighten(75%), stroke: black)
      rect((6.75, 0), (12, 1), fill: gray.lighten(85%), stroke: black)

      line((5.25, -0.2), (5.25, 1.5), stroke: blue, mark: (end: "stealth"))
      content((5.90625, 0.5), [$A A B$])
      content((5.25, 1.8), [$7/16$])
      content((0, -0.6), [$0$])
      content((5.0625, -0.6), [$27/64$])
      content((6.75, -0.6), [$9/16$])
      content((12, -0.6), [$1$])
    })
  ]
]


Dopo aver letto una sequenza $s_1, s_2, dots, s_n$, il nuovo intervallo è il risultato del restringimento progressivo della
partizione iniziale. Le formule e l'esempio assumono un modello con probabilità dei simboli fissate,

Se la sequenza è $x_1, x_2, dots, x_n$, allora l'ampiezza del suo *intervallo finale* è:
$
  P(x_1, dots, x_n) = product_(i=1)^n p(x_i)
$

Quindi il numero di bit necessari per rappresentare l'intervallo è circa:
$
  -log_2 P(x_1, dots, x_n) = -sum_(i=1)^n log_2 p(x_i)
$

Questo è il costo informativo ideale della sequenza, espresso in bit: una codifica effettiva usa un numero intero di bit
e può richiedere qualche bit aggiuntivo per terminazione e sincronizzazione.

== Trasmissione e limite superiore alla lunghezza del codice

Per trasmettere la sequenza codificata non serve inviare entrambi gli estremi dell'intervallo finale: basta trasmettere
un *numero diadico* $j 2^(-h)$ *contenuto al suo interno*.

#note()[
  Un numero diadico $j 2^(-h) in [0, 1)$ è completamente descritto dalla parola di $h$ bit che rappresenta l'intero $j$ in
  binario, ovvero dalle sue prime $h$ cifre binarie dopo la virgola.
]

Quanti bit $h$ servono al massimo?
- Se il passo della griglia diadica non supera l'ampiezza dell'intervallo, cioè se $2^(-h) <= P$, allora un intervallo di lunghezza $P$ contiene *sempre* almeno un multiplo di $2^(-h)$. Basta quindi scegliere:
  $
    h = ceil(log_2(1/P)) < log_2(1/P) + 1 = sum_(i=0)^(n-1) log_2 frac(1, p_(s_i)) + 1
  $

In conclusione, la codifica aritmetica spende *al più $1$ bit in più rispetto al contenuto informativo dell'intera sequenza*.

#note()[
  Ripartendo questo singolo bit di sovraccosto su tutti gli $n$ simboli della sequenza, per $n$ grande il costo aggiuntivo per simbolo ($1/n$) diventa nullo e il costo medio per simbolo tende all'entropia.
]
== Costo medio e distribuzione empirica

Supponiamo di avere una sequenza $S$ di lunghezza $n$ in cui ciascun simbolo distinto $s in Sigma$ compare un numero di
volte pari a $"#s"$ (con $sum_s "#s" = n$).
Possiamo raggruppare i termini del costo informativo totale della sequenza raccogliendo le occorrenze dello stesso simbolo:
$
  log_2 frac(1, P) = sum_(i=0)^(n-1) log_2 frac(1, p_(s_i)) = sum_(s in Sigma) "#s" dot log_2 frac(1, p_s)
$
Dividendo per il numero totale di simboli $n$, otteniamo il *costo informativo medio per simbolo*:
$
  frac(1, n) log_2 frac(1, P) = sum_(s in Sigma) frac("#s", n) log_2 frac(1, p_s)
$
Osserviamo che il rapporto $"#s" / n$ (numero di occorrenze di $s$ diviso la lunghezza della sequenza) è esattamente la
*probabilità (o frequenza) empirica* del simbolo $s$ nella sequenza.
Se la distribuzione di probabilità $p_s$ usata dal codificatore coincide con la distribuzione empirica della sequenza ($p_s = "#s" / n$),
allora il costo medio per simbolo diventa uguale all'entropia:
$
  sum_(s in Sigma) p_s log_2 frac(1, p_s) = H
$

== Decodifica della codifica aritmetica

Il decoder parte dal valore trasmesso e applica la stessa logica usata dal codificatore.

#example()[
  Il decodificatore riceve la parola binaria (ad esempio `0111`) e la interpreta come il numero reale diadico $x = 0.0111_2 = 7/16$, assumendo che tutte le cifre binarie successive siano uguali a zero.

  A questo punto ripete esattamente le stesse suddivisioni dell'intervallo fatte dal codificatore:
  1. Guarda in quale sottointervallo cade $x$ ed emette il simbolo corrispondente;
  2. Restringe l'intervallo corrente al sottointervallo scelto e ripete il procedimento.

  #figure(
    caption: [Decodifica di `0111` ($x = 7/16$) per `abaa` *senza riscalare* ($p_a=5/8, p_b=1/4, p_c=1/8$). La linea verticale rossa individua ad ogni riga il sottointervallo in cui cade $x$.],
  )[
    #cetz.canvas({
      import cetz.draw: *

      // Scala: [0, 1] -> [0, 12]
      // x = 7/16 -> 7/16 * 12 = 5.25
      let x_pos = 5.25

      // Riga 1: [0, 1) -> a:[0, 7.5), b:[7.5, 10.5), c:[10.5, 12)
      rect((0, 4.5), (7.5, 5.1), fill: white, stroke: (paint: black, thickness: 1.5pt))
      rect((7.5, 4.5), (10.5, 5.1), fill: gray.lighten(60%), stroke: black)
      rect((10.5, 4.5), (12, 5.1), fill: gray.lighten(30%), stroke: black)
      content((3.75, 4.8), [`a`])
      content((9.0, 4.8), [`b`])
      content((11.25, 4.8), [`c`])
      content((0, 4.2), [$0$])
      content((12, 4.2), [$1$])
      content((12.8, 4.8), [*`a`*])

      // Riga 2: [0, 5/8) -> [0, 7.5): a:[0, 4.6875), b:[4.6875, 6.5625), c:[6.5625, 7.5)
      line((0, 3.3), (12, 3.3), stroke: gray.lighten(50%))
      rect((0, 3.0), (4.6875, 3.6), fill: white, stroke: black)
      rect((4.6875, 3.0), (6.5625, 3.6), fill: gray.lighten(60%), stroke: (paint: black, thickness: 1.5pt))
      rect((6.5625, 3.0), (7.5, 3.6), fill: gray.lighten(30%), stroke: black)
      content((2.34, 3.3), [`a`])
      content((5.625, 3.3), [`b`])
      content((7.03, 3.3), [`c`])
      content((12.8, 3.3), [*`b`*])

      // Riga 3: [25/64, 35/64) -> [4.6875, 6.5625): a:[4.6875, 5.859375), b:[5.859375, 6.328125), c:[6.328125, 6.5625)
      line((0, 1.8), (12, 1.8), stroke: gray.lighten(50%))
      rect((4.6875, 1.5), (5.859375, 2.1), fill: white, stroke: (paint: black, thickness: 1.5pt))
      rect((5.859375, 1.5), (6.328125, 2.1), fill: gray.lighten(60%), stroke: black)
      rect((6.328125, 1.5), (6.5625, 2.1), fill: gray.lighten(30%), stroke: black)
      content((12.8, 1.8), [*`a`*])

      // Riga 4: [25/64, 125/256) -> [4.6875, 5.859375): a:[4.6875, 5.41992), b:[5.41992, 5.71289), c:[5.71289, 5.859375)
      line((0, 0.3), (12, 0.3), stroke: gray.lighten(50%))
      rect((4.6875, 0.0), (5.41992, 0.6), fill: white, stroke: (paint: black, thickness: 1.5pt))
      rect((5.41992, 0.0), (5.71289, 0.6), fill: gray.lighten(60%), stroke: black)
      rect((5.71289, 0.0), (5.859375, 0.6), fill: gray.lighten(30%), stroke: black)
      content((12.8, 0.3), [*`a`*])

      // Linea rossa per x = 7/16
      line((x_pos, -0.4), (x_pos, 5.5), stroke: (paint: red, thickness: 1.5pt))
      content((x_pos, 5.85), text(fill: red)[$x = 0.0111_2 = 7/16$])
    })
  ]


  Il decoder ricostruisce così `AAB`. Ma il valore $7/16$ da solo non dice che il messaggio è finito: dopo aver decodificato B si arresta perché in questo esempio conosce già la lunghezza, pari a tre simboli.
  Se la lunghezza non è nota in anticipo, il messaggio deve invece includere un simbolo speciale di fine sequenza (EOF).
]

#note(title: "Il problema della precisione finita")[
  Su un calcolatore non si può lavorare con numeri reali a precisione arbitraria: gli estremi dell'intervallo sono rappresentati mediante *interi di dimensione fissa* (es. registri a 32 o 64 bit), ma per intervalli molto piccoli i bit potrebbero non essere sufficienti.

  Non appena i bit più significativi dei due estremi dell'intervallo coincidono (entrambi `0` se l'intervallo è tutto nella metà inferiore $[0, 1/2)$, oppure entrambi `1` se è tutto nella metà superiore $[1/2, 1)$), quei bit non potranno più cambiare.

  Questo consente quindi che tali bit "definitivi" vengano subito emessi in output e l'intervallo viene raddoppiato (shift a sinistra `<< 1`), ripristinando la precisione disponibile.

  *Problema dell'underflow a cavallo di $1/2$*: occorre prestare particolare cura quando l'intervallo diventa molto piccolo restando però a cavallo di $1/2$ (ad esempio gli estremi iniziano con `0111...` e `1000...`). In questo caso il primo bit non è ancora deciso, ma i bit successivi sono già bloccati: si espande allora la regione centrale tenendo un contatore dei "bit in sospeso", che verranno scaricati (invertiti) non appena il primo bit si deciderà.
]

#warning(title: "Limiti pratici della codifica aritmetica")[
  - *Lentezza in decodifica*: per individuare a quale sottointervallo appartiene $x$, il decodificatore deve eseguire *una divisione per ogni simbolo*, risultando sensibilmente più lento rispetto a un codice istantaneo (come Huffman).
  - *Bit di scarico (flush)*: al termine della codifica occorre emettere alcuni bit di scarico per disambiguare l'intervallo finale; per questo motivo un flusso compresso con codifica aritmetica non si presta facilmente a essere interrotto e inframmezzato con altri dati non compressi.
]

#note(title: "Modello adattivo")[
  La codifica aritmetica si presta molto bene a essere usata in modo *adattivo*: se *non si conosce a priori la distribuzione dei simboli*, codificatore e decodificatore possono partire da una distribuzione uniforme (equiprobabile) e aggiornare i conteggi delle frequenze man mano che codificano e decodificano i simboli in ordine. Poiché procedono nella stessa direzione, rimangono perfettamente sincronizzati senza bisogno di trasmettere in anticipo la distribuzione di probabilità.
]

= Sistemi di numerazione asimmetrica (ANS)

I *Sistemi di Numerazione Asimmetrica (ANS)* :
- garantiscono una *velocità di decodifica confrontabile o superiore a un codice di Huffman*;
- raggiungono un *rapporto di compressione confrontabile con la codifica aritmetica*, e quindi vicinissimo all'entropia.

Per queste ragioni sono oggi utilizzati in alcuni dei importanti compressori e formati moderni (zstd, JPEG XL, ...)

Invece di rappresentare la sequenza con un intervallo reale sempre più piccolo, codifichiamo l'intera sequenza con un singolo *intero naturale molto grande $x$*, il quale richiede circa $log_2 x$ bit per essere scritto in binario.

Quando aggiungiamo alla sequenza un simbolo $s$ di probabilità $p_s$, vogliamo aggiornare lo stato intero $x$ in un nuovo intero $x'$ tale che:
$
  x' approx frac(x, p_s)
$
Ovvero il nuovo intero $x'$ deve essere circa $1/p_s$ volte più grande di $x$, in modo da avere lo stesso effetto della codifica aritmetica: restringere l'intervallo di un fattore $p_s$.

Considerando la dimensione della rappresentazione binaria si ottiene:
$
  log_2 x' approx log_2 x + log_2 frac(1, p_s)
$

Aggiungere il simbolo $s$ fa quindi crescere il numero di bit di $x$ esattamente del *contenuto informativo* $log_2(1/p_s)$ del simbolo. Di conseguenza, sull'intera sequenza, il costo medio per simbolo coinciderà con l'*entropia*.

== Il caso banale (sorgente binaria equiprobabile) e la struttura a pila

Consideriamo la sorgente più semplice possibile: due simboli $0$ e $1$ equiprobabili
($p_0 = p_1 = 1/2$).
Se $x$ è l'intero che codifica i simboli visti finora, per aggiungere il nuovo simbolo
$s in {0, 1}$ dividiamo per $p_s = 1/2$ (cioè moltiplichiamo per $2$) e sommiamo $s$:
$x' = 2x + s$
In binario, moltiplicare per $2$ sposta tutti i bit di $x$ a sinistra di una posizione
(aggiungendo uno `0` in fondo) e sommare $s$ scrive il nuovo bit nel posto appena liberato. In pratica, ogni passo *appende
il bit $s$ a destra della rappresentazione binaria di $x$*.

Per decodificare $x'$ basta fare l'operazione opposta:
- l'*ultimo simbolo inserito* è l'ultimo bit a destra, cioè il resto $s = x' mod 2$;
- lo *stato precedente* si ottiene eliminando l'ultimo bit a destra, cioè calcolando il quoziente $x = floor(x' / 2)$.

#example(title: "Codifica e decodifica passo-passo di 011")[
  Partiamo dallo stato iniziale $x_0 = 1$ (in binario `1`, usato come stato di partenza per non perdere eventuali zeri iniziali) e codifichiamo la sequenza `0`, `1`, `1`:

  1. *Stato iniziale*: $x_0 = 1$ (binario: `1`)
  2. *Codifica `0`*: $x_1 = 2 dot 1 + 0 = 2$ (binario: `10`)
  3. *Codifica `1`*: $x_2 = 2 dot 2 + 1 = 5$ (binario: `101`)
  4. *Codifica `1`*: $x_3 = 2 dot 5 + 1 = 11$ (binario: `1011`)

  Lo stato finale è $11$. Ora decodifichiamo partendo da $x_3 = 11$:
  1. Da $11$ (`1011`): simbolo $s = 11 mod 2 = bold(1)$, nuovo stato $x_2 = floor(11/2) = 5$ (`101`);
  2. Da $5$ (`101`): simbolo $s = 5 mod 2 = bold(1)$, nuovo stato $x_1 = floor(5/2) = 2$ (`10`);
  3. Da $2$ (`10`): simbolo $s = 2 mod 2 = bold(0)$, nuovo stato $x_0 = floor(2/2) = 1$ (`1`, stato iniziale).

  I simboli estratti sono `1, 1, 0`, ovvero la sequenza codificata `0, 1, 1` ma *in ordine inverso*.
]

Questa è una caratteristica strutturale di tutti i sistemi ANS: *si codifica in una direzione e si decodifica nella direzione
opposta, esattamente come in una pila (LIFO)*

== La numerazione come colorazione

Possiamo reinterpretare la numerazione binaria standard in termini di *colori* e *ranghi* sui numeri naturali:
- *Colore*: coloriamo ogni numero naturale $y$ con la sua ultima cifra binaria $s = y mod 2$ (i numeri pari hanno colore $mb(0)$, i dispari hanno colore $mr(1)$).

- *Rango*: definiamo il *rango* di un naturale $y$ come il numero di naturali *dello stesso colore* che lo precedono strettamente (cioè minori di $y$).

#figure(
  caption: [Ogni naturale $y$ è colorato in base a $y mod 2$ (azzurro per i pari `0`, rosso per i dispari `1`).],
)[
  #table(
    columns: 19,
    align: center + horizon,
    fill: (col, row) => if row == 0 and col > 0 {
      if calc.even(col - 1) { blue.lighten(75%) } else { red.lighten(75%) }
    },
    [*$y$*], ..range(18).map(str),
    [*rango*], ..range(18).map(y => str(calc.quo(y, 2))),
  )
]
In questa vista:
- *Codificare (`push`)*: $2x + s$ è esattamente l'unico naturale di *colore $s$* e *rango $x$* (ad esempio, per $x = 8$ e $s = 1$, il naturale di colore $1$ e rango $8$ è $2 dot 8 + 1 = 17$).
- *Decodificare (`pop`)*: dato $y$, significa determinare il suo *colore* (l'ultimo simbolo) e il suo *rango* (lo stato precedente $x$).

Nel sistema binario standard ogni colore occupa esattamente metà dei naturali: il sistema è *simmetrico* (tutti i simboli hanno lo stesso peso, proprio come in base $k$ con $k$ simboli equiprobabili), quindi *il naturale di colore $s$ e rango $x$ vale sempre circa $2x$ e ogni simbolo costa $1$ bit*.

== Dal caso base alla colorazione assimetrica

Per passare dal caso base del sistema binario ad un qualsiasi scenario reale, si colorano i numeri naturali in modo *asimmetrico*,
facendo sì che il colore $s$ occupi una *frazione dei naturali pari alla sua probabilità $p_s$*.
In questo modo, poiché solo una frazione $p_s$ dei naturali ha colore $s$, per incontrare $x$ naturali di colore $s$ bisognerà
scorrere circa $x / p_s$ numeri naturali. Il naturale di colore $s$ e rango $x$ varrà quindi circa $x / p_s$, che è esattamente la crescita desiderata.

Definiamo quindi per qualsiasi colorazione:
- $"push"(x, s)$: restituisce il naturale $y$ di colore $s$ e rango $x$;
- $"pop"(y)$: restituisce la coppia $< "rango"(y), "colore"(y) >$, cioè lo stato precedente e l'ultimo simbolo codificato.

Per realizzare in modo efficiente la colorazione asimmetrica:
1. Fissiamo un parametro di *precisione* intero $d > 0$ e approssimiamo la probabilità di ciascun simbolo con una frazione di denominatore $2^d$:
$p_s approx frac(f_s, 2^d)$
dove $f_s$ è un intero positivo (la frequenza scalata di $s$) e $sum_(s in Sigma) f_s = 2^d$. Più grande è $d$, migliore è l'approssimazione delle probabilità e quindi la compressione.
2. Dividiamo il blocco dei primi $2^d$ naturali $[0 .. 2^d)$ in $k$ segmenti contigui di lunghezza $f_s$. Ponendo la cumulativa delle frequenze:
$
  c_s = sum_(t < s) f_t quad "per " s in [0 .. k]
$
il segmento associato al simbolo $s$ all'interno del blocco base è $[c_s .. c_(s+1))$, dove $c_(s+1) = c_s + f_s$.
3. Per ogni $z in [0 .. 2^d)$, definiamo la tabella $"sym"(z)$ come l'unico simbolo $s$ tale che $c_s <= z < c_(s+1)$.
4. Coloriamo infine ogni numero naturale $y >= 0$ periodicamente a blocchi di $2^d$numeri, assegnandogli il colore:$ "colore"(y) = "sym"(y mod 2^d) $
In ogni blocco di $2^d$ naturali ci sono esattamente $f_s$ naturali consecutivi di colore $s$: la densità del colore $s$ è quindi esattamente $f_s / 2^d approx p_s$.

#example(title: "Colorazione con d = 3 (blocchi di 8 naturali)")[
  Con $d = 3$ abbiamo blocchi di $2^3 = 8$ naturali. Scegliamo le frequenze $f_a = 5$, $f_b = 2$, $f_c = 1$ (cioè $p_a = 5/8$, $p_b = 2/8$, $p_c = 1/8$), con cumulative $c_a = 0$, $c_b = 5$, $c_c = 7$.
  Ogni blocco di $8$ naturali è colorato con 5 *`a`* (azzurro), 2 *`b`* (verde) e 1 *`c`* (arancione):

  #figure(
    caption: [Ogni naturale $y$ è colorato secondo $y mod 8$: primi 5 in azzurro (`a`), poi 2 in verde (`b`) e 1 in arancione (`c`).],
  )[
    #let sym(y) = {
      let r = calc.rem(y, 8)
      if r < 5 { "a" } else if r < 7 { "b" } else { "c" }
    }
    #let rank(y) = {
      let q = calc.quo(y, 8)
      let r = calc.rem(y, 8)
      if r < 5 { q * 5 + r } else if r < 7 { q * 2 + (r - 5) } else { q * 1 + (r - 7) }
    }
    #table(
      columns: 19,
      align: center + horizon,
      fill: (col, row) => if row == 0 and col > 0 {
        let s = sym(col - 1)
        if s == "a" { blue.lighten(75%) } else if s == "b" { green.lighten(75%) } else { orange.lighten(75%) }
      },
      [*$y$*], ..range(18).map(str),
      [*rango*], ..range(18).map(y => str(rank(y))),
    )
  ]

  *Codifica e decodifica passo-passo di `aa` partendo da $x_0 = 5$ (visibile tutta nella tabella):*
  1. *Stato iniziale*: $x_0 = 5$.
  2. *Codifica `a`*: cerchiamo nella tabella la cella *azzurra* (`a`) con *rango $5$* $arrow.r$ troviamo *$y = 8$* ($"push"(5, a) = 8$).
  3. *Codifica `a`*: ora lo stato è $8$; cerchiamo la cella *azzurra* (`a`) con *rango $8$* $arrow.r$ troviamo *$y = 11$* ($"push"(8, a) = 11$, moltiplicando lo stato per circa $8/5 = 1.6$ invece che per $2$).
  4. *Se ora codificassimo `b`*: dallo stato $11$, cercheremmo la cella *verde* (`b`) con *rango $11$*. Poiché ci sono solo $2$ celle verdi ogni $8$ numeri, il rango $11$ cade nel $5°$ blocco ($floor(11/2) = 5$), precisamente in *$y = 46$* ($"push"(11, b) = 46$, moltiplicando lo stato per circa $8/2 = 4$).

  *Decodifica (`pop`) da $y = 11$*:
  1. guardiamo $y = 11$: la cella è *azzurra* (simbolo *`a`*) e sotto leggiamo *rango $8$* (nuovo stato $x = 8$);
  2. guardiamo $y = 8$: la cella è *azzurra* (simbolo *`a`*) e sotto leggiamo *rango $5$* (tornati allo stato iniziale $x_0 = 5$).

  Notiamo l'effetto sulla compressione: il simbolo frequente `a` compare $5$ volte per blocco e fa crescere $y$ molto lentamente
  ($approx times 8/5$, costo $log_2(8/5) approx 0.68$ bit), mentre il simbolo raro `c` (arancione) compare solo una volta
  ogni $8$ numeri e fa crescere $y$ molto velocemente ($approx times 8$, costo $log_2(8/1) = 3$ bit).
]

=== Formula di `push` (Codifica)

Dato lo stato corrente $x$ e il simbolo $s$, dove si trova il naturale di colore $s$ e rango $x$?
- Poiché ogni blocco di $2^d$ numeri contiene esattamente $f_s$ elementi di colore $s$, per accumulare $x$ elementi di colore $s$ dobbiamo superare $floor(x / f_s)$ blocchi completi: il numero cercato si trova quindi nel *blocco di indice $floor(x / f_s)$*, che inizia all'intero $floor(x / f_s) dot 2^d = (floor(x / f_s) << d)$.
- All'interno di quel blocco, è l'elemento di colore $s$ di indice locale $x mod f_s$.
- Poiché i numeri di colore $s$ nel blocco partono dall'offset $c_s$, la sua posizione all'interno del blocco è $c_s + (x mod f_s)$.

Sommando l'inizio del blocco e l'offset interno otteniamo:
$
  "push"(x, s) = (floor(x / f_s) << d) + c_s + (x mod f_s)
$
*(Ad esempio, con $d=3, f_a=5, c_a=0$: $"push"(8, a) = (floor(8/5) << 3) + 0 + (8 mod 5) = 8 + 0 + 3 = 11$).*
In pratica, poiché le frequenze $f_s$ dei simboli sono fisse per tutto il blocco di testo, anche la divisione intera per $f_s$ in fase di codifica può essere velocizzata tramite costanti moltiplicative precomputate.

=== Formula di `pop` (Decodifica)

Dato lo stato intero $x$, dobbiamo risalire all'ultimo simbolo $s$ (il colore di $x$) e allo stato precedente (il rango di $x$):
- L'indice del blocco in cui si trova $x$ è $floor(x / 2^d) = (x >> d)$, mentre la posizione di $x$ all'interno del suo blocco è $r = x mod 2^d$ (calcolabile istantaneamente con la maschera di bit $x and (2^d - 1)$).
- Il colore di $x$si ottiene subito accedendo alla tabella:$ s = "sym"(x mod 2^d) $
- Quanti naturali di colore $s$ precedono $x$ (cioè qual è il suo rango)?
  - Ci sono esattamente $f_s$ naturali di colore $s$ in ciascuno dei $(x >> d)$ blocchi completi che precedono il blocco di $x$;
  - più gli $(x mod 2^d) - c_s$ naturali di colore $s$ che precedono $x$ all'interno del suo stesso blocco.

Otteniamo quindi la formula di decodifica:
$
  "pop"(x) = < (x >> d) dot f_s + (x mod 2^d) - c_s, \; s >
$
(Ad esempio, per $x = 46$ con $d=3$: abbiamo $46 mod 8 = 6$, da cui $s = "sym"(6) = b$ con $f_b = 2, c_b = 5$; il rango è $(46 >> 3) dot 2 + 6 - 5 = 5 dot 2 + 1 = 11$, quindi $"pop"(46) = < 11, b >$).

=== Proprietà di `push` e `pop`

1. *Invertibilità*: per costruzione, `push` e `pop` sono esattamente una l'inversa dell'altra.
2. *Crescita proporzionale a $1/p_s$*: vale$ "push"(x, s) approx frac(x, f_s) dot 2^d = frac(x, f_s / 2^d) approx frac(x, p_s) $
Più precisamente, l'errore rispetto a $(x / f_s) dot 2^d$ è inferiore a $2^d$, ed è quindi del tutto trascurabile quando lo stato $x$ è mantenuto molto più grande di $2^d$.
3. *Estrema velocità di decodifica*: a differenza della codifica aritmetica, *`pop(x)` non richiede alcuna divisione*, ma soltanto shift/maschere di bit, un accesso alla tabella `sym` e una singola moltiplicazione!

#example(title: "Visualizzazione grafica e tabellare di ANS")[
  Disponendo i numeri naturali in colonne di altezza $2^d = 8$ (i blocchi), il colore dipende solo dalla riga ($0..4 -> a$, $5..6 -> b$, $7 -> c$). Partendo dallo stato iniziale $x_0 = 8$:
  - Codifica di `abaa`: $8 arrow.r^a 11 arrow.r^b 46 arrow.r^a 73 arrow.r^a 115$. Lo stato cresce di $log_2(115/8) approx 3.85$ bit (contro $4.03$ bit di contenuto informativo). Decodificando da $115$ si percorre la catena a ritroso ($115 arrow.r^a 73 arrow.r^a 46 arrow.r^b 11 arrow.r^a 8$) ottenendo i simboli invertiti `aaba`.

  Vediamo anche la tabella completa dei lucidi per la codifica e decodifica della sequenza più lunga `abacaaba` partendo da $x = 8$:

  #figure(caption: [Codifica (`push`) di `abacaaba`])[
    #table(
      columns: 6,
      align: center,
      [*$x$*], [*$s$*], [*$floor(x/f_s) << 3$*], [*$c_s$*], [*$x mod f_s$*], [*$"push"(x,s)$*],
      [8], [a], [8], [0], [3], [11],
      [11], [b], [40], [5], [1], [46],
      [46], [a], [72], [0], [1], [73],
      [73], [c], [584], [7], [0], [591],
      [591], [a], [944], [0], [1], [945],
      [945], [a], [1512], [0], [0], [1512],
      [1512], [b], [6048], [5], [0], [6053],
      [6053], [a], [9680], [0], [3], [*9683*],
    )
  ]

  #figure(caption: [Decodifica (`pop`) da $x = 9683$])[
    #table(
      columns: 5,
      align: center,
      [*$x$*], [*$x >> 3$*], [*$x mod 8$*], [*$s$*], [*rango*],
      [9683], [1210], [3], [a], [6053],
      [6053], [756], [5], [b], [1512],
      [1512], [189], [0], [a], [945],
      [945], [118], [1], [a], [591],
      [591], [73], [7], [c], [73],
      [73], [9], [1], [a], [46],
      [46], [5], [6], [b], [11],
      [11], [1], [3], [a], [*8*],
    )
  ]
  L'intero è cresciuto di $log_2(9683/8) approx 10.24$ bit, a fronte di un contenuto informativo totale di circa $10.39$ bit ($6 dot log_2(8/5) + 2 dot 2 + 1 dot 3$). La decodifica emette `abaacaba`, ovvero la sequenza originale al contrario.
]

#warning(title: "Perché non conviene partire dallo stato x = 0?")[
  Per il primo simbolo dell'alfabeto (`a`) si ha sempre $c_a = 0$. Di conseguenza:
  $
    "push"(0, a) = (floor(0 / f_a) << d) + 0 + (0 mod f_a) = 0
  $
  Se partissimo da $x = 0$, codificare una o più `a` all'inizio lascerebbe lo stato fermo a $0$, perdendo completamente
  l'informazione sul numero di `a` iniziali! Per questo motivo si parte sempre da uno stato iniziale positivo fissato
  (come $x = 2^d = 8$, oppure la soglia inferiore $L$ di rinormalizzazione).
]

== Rinormalizzazione e dettagli implementativi

Se applicassimo solo `push`, lo stato intero $x$ crescerebbe indefinitamente con la lunghezza del messaggio. Nelle implementazioni
pratiche (note come *rANS* o *tANS*), lo stato $x$ viene mantenuto sempre all'interno di un intervallo fissato:
$x in [L .. 2^b L)$
dove $L$ è un multiplo di $2^d$ e $b$ è il numero di bit trasferiti a ogni operazione di I/O (ad esempio $b = 8$ per scrivere
un byte alla volta).

- *Rinormalizzazione in codifica (`push`)*: prima di eseguire $"push"(x, s)$, si controlla se il nuovo stato supererebbe
il limite superiore $2^b L$. Precisamente, *finché $x >= 2^b L f_s / 2^d$*, i *$b$ bit meno significativi* di $x$ vengono
scritti nel buffer di output ed eliminati dallo stato ($x <- x >> b$). Quando $x$ è tornato abbastanza piccolo, si esegue
$"push"(x, s)$, che cadrà garantitamente in $[L .. 2^b L)$.
- *Rinormalizzazione in decodifica (`pop`)*: simmetricamente, dopo aver eseguito $"pop"(x)$, lo stato può scendere sotto
$L$. *Finché $x < L$*, si rileggono blocchi di $b$ bit dal buffer di input e si inseriscono come bit meno significativi di $x$
($x <- (x << b) + "bits"$), riportando $x$ nell'intervallo $[L .. 2^b L)$.

Si dimostra che in questo modo la decodifica rilegge esattamente gli stessi blocchi di $b$ bit emessi dalla codifica. L'emissione
dei bit meno significativi comporta una piccola perdita di precisione (e quindi di compressione), che però è del tutto trascurabile
se si sceglie $L$ molto più grande di $2^d$.
In compenso, l'intero algoritmo opera esclusivamente su *interi di dimensione fissa*: ad esempio, scegliendo $L = 2^23$ e
$b = 8$, lo stato resta in $[2^23 .. 2^31)$ e bastano normali registri a *32 bit*.

#warning(title: "Distribuzione statica a blocchi e memorizzazione delle frequenze")[
  Poiché ANS codifica in una direzione e decodifica nella direzione opposta (dalla fine del blocco verso l'inizio), non è
  possibile apprendere e aggiornare la distribuzione in modo adattivo simbolo per simbolo.
  In ANS occorre quindi dividere l'input in blocchi, calcolare le frequenze $f_s$ del blocco e *salvarle come dati ancillari (metadati)*
  nell'intestazione del blocco compresso affinché il decodificatore le conosca prima di iniziare le `pop`.
  Se il vettore delle frequenze $f_s$ occupasse troppo spazio, ridurrebbe il guadagno della compressione: per questo nei
  compressori reali si utilizzano apposite tecniche di *packing* (compressione compatta delle tabelle delle frequenze) per memorizzare gli $f_s$ con il minimo numero possibile di bit.
]

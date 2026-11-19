#import "../template.typ": *

= HyperBall: Distanze e centralità su grafi con miliardi di nodi

Per analizzare grafi di dimensioni enormi (con miliardi di nodi e archi) non è possibile calcolare le distanze esatte tra tutte le coppie in tempi ragionevoli. Si ricorre quindi a strutture dati probabilistiche molto compatte chiamate *schizzi probabilistici* (_probabilistic sketches_), che permettono di stimare la cardinalità degli insiemi con un consumo di memoria minimo.

== Centralità geometriche e distribuzione delle distanze

Le *centralità geometriche* di un nodo $x$ dipendono esclusivamente dalle distanze dei cammini minimi $d(x, y)$ verso gli altri nodi del grafo:

- *Vicinanza (_Closeness centrality_)*: misura l'inverso della somma delle distanze da $x$ a tutti gli altri nodi raggiungibili:
  $ C(x) = frac(1, sum_(y != x, d(x,y) < infinity) d(x, y)) $

- *Centralità armonica (_Harmonic centrality_)*: risolve il problema dei nodi non raggiungibili ($d(x, y) = infinity$, per cui $1 / infinity = 0$) sommando i reciproci delle distanze:
  $ H(x) = sum_(y != x) frac(1, d(x, y)) $

- *Distribuzione delle distanze (_Neighborhood function_)*: la funzione $N(t)$ indica il numero di coppie di nodi $(x, y)$ a distanza al più $t$. La variante puntuale $s(t) = N(t) - N(t-1)$ indica il numero di coppie esattamente a distanza $t$.

#note[
  Dalla distribuzione delle distanze $N(t)$ è possibile ricavare immediatamente proprietà globali fondamentali del grafo, tra cui la *distanza media*, il *diametro* (il minimo $t$ per cui $N(t)$ raggiunge il valore massimo), il *diametro effettivo* (90° percentile delle distanze) e la *frazione di coppie collegate* (grado di connessione del grafo).
]

=== Il limite dell'approccio classico
Il metodo classico ed esatto consiste nell'eseguire una visita in ampiezza (*BFS*) partendo da ogni singolo nodo del grafo. In questo modo si ottengono tutte le distanze esatte, ma con una complessità temporale pari a $O(n m)$ (dove $n = |V|$ e $m = |E|$), totalmente impraticabile su grafi con miliardi di nodi. Una prima approssimazione consiste nell'eseguire la BFS solo da un campione casuale di nodi, ma ciò non fornisce stime puntuali per tutti i vertici del grafo.

== Sfere e Bolle

Un'intuizione chiave per evitare di memorizzare tutte le coppie $(x, y)$ consiste nel ragionare per *sfere* e *bolle* centrate in un nodo $x$:

- *Sfera di raggio $t$*, denotata con $S_t (x)$: l'insieme dei nodi a distanza *esattamente* $t$ da $x$:
  $ S_t (x) = { y in V mid(|) d(x, y) = t } = B_t (x) without B_(t-1) (x) $

- *Bolla di raggio $t$*, denotata con $B_t (x)$: l'insieme dei nodi a distanza *al più* $t$ da $x$:
  $ B_t (x) = { y in V mid(|) d(x, y) <= t } $

Poiché $B_(t-1)(x) subset.eq B_t (x)$, la cardinalità della sfera si ottiene semplicemente per differenza tra le cardinalità delle bolle:
$ |S_t (x)| = |B_t (x)| - |B_(t-1) (x)| $

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    // Bolle concentriche
    circle((0, 0), radius: 3.3, fill: blue.lighten(92%), stroke: (
      paint: blue.darken(20%),
      thickness: 1pt,
      dash: "dashed",
    ))
    circle((0, 0), radius: 2.2, fill: green.lighten(88%), stroke: (paint: green.darken(20%), thickness: 1pt))
    circle((0, 0), radius: 1.1, fill: orange.lighten(85%), stroke: (paint: orange.darken(20%), thickness: 1pt))

    // Nodo centrale x
    circle((0, 0), radius: 0.28, fill: red.lighten(60%), stroke: red.darken(30%))
    content((0, 0), [$x$])

    // Nodi a distanza 1
    circle((0.6, 0.55), radius: 0.14, fill: white, stroke: black)
    circle((-0.65, 0.45), radius: 0.14, fill: white, stroke: black)
    circle((0.1, -0.75), radius: 0.14, fill: white, stroke: black)

    // Nodi a distanza 2
    circle((1.4, 0.8), radius: 0.14, fill: white, stroke: black)
    circle((-1.45, -0.6), radius: 0.14, fill: white, stroke: black)
    circle((0.7, -1.5), radius: 0.14, fill: white, stroke: black)

    // Nodi a distanza 3
    circle((2.3, 1.2), radius: 0.14, fill: white, stroke: black)
    circle((-2.4, 0.9), radius: 0.14, fill: white, stroke: black)
    circle((-1.2, -2.4), radius: 0.14, fill: white, stroke: black)

    // Archi esemplificativi
    line((0.22, 0.18), (0.5, 0.45), stroke: 0.7pt + gray.darken(30%))
    line((0.72, 0.6), (1.28, 0.76), stroke: 0.7pt + gray.darken(30%))
    line((1.52, 0.86), (2.18, 1.15), stroke: 0.7pt + gray.darken(30%))

    // Etichette
    content((0, 0.82), text(size: 8.5pt, fill: orange.darken(40%))[*$B_1(x)$*])
    content((0, 1.88), text(size: 8.5pt, fill: green.darken(40%))[*$B_2(x)$*])
    content((0, 2.95), text(size: 8.5pt, fill: blue.darken(40%))[*$B_3(x)$*])

    // Indicatore sfera S_3(x)
    line((2.2, 0), (3.3, 0), mark: (start: ">", end: ">"), stroke: blue.darken(30%))
    content((2.75, -0.35), text(size: 8pt, fill: blue.darken(40%))[$S_3(x)$])
  }),
  caption: [Rappresentazione delle bolle concentriche $B_t (x)$ attorno al nodo $x$. La corona circolare tra $B_2 (x)$ e $B_3 (x)$ costituisce la sfera $S_3 (x)$, la cui cardinalità è $|B_3 (x)| - |B_2 (x)|$.],
)

Una volta nota la dimensione delle sfere $|S_t (x)|$ ad ogni passo $t$, è sufficiente mantenere un *accumulatore* per ciascun nodo $x$ per calcolare al volo le centralità e la distribuzione delle distanze:
- *Centralità armonica*:
  $ H(x) = sum_(t >= 1) frac(|S_t (x)|, t) = sum_(t >= 1) frac(|B_t (x)| - |B_(t-1) (x)|, t) $
- *Vicinanza*:
  $ C(x) = frac(1, sum_(t >= 1) t dot |S_t (x)|) = frac(1, sum_(t >= 1) t dot (|B_t (x)| - |B_(t-1) (x)|)) $
- *Distribuzione delle distanze*:
  $ N(t) = sum_(x in V) |B_t (x)| $

=== Crescita iterativa delle bolle per unione
Le bolle godono di una proprietà ricorsiva fondamentale: la bolla di raggio $t+1$ centrata in $x$ si ottiene unendo a $\{x\}$ le bolle di raggio $t$ di tutti i suoi vicini uscenti:

$ mb(B_0 (x)) = {x}, quad mb(B_(t+1) (x)) = {x} union union_(x -> y) mg(B_t (y)) $

#informally[
  Invece di esplorare il grafo in profondità o ampiezza un nodo alla volta, facciamo crescere le bolle di tutti i nodi contemporaneamente (*programmazione dinamica sincrona*).
  Al passo $0$ ogni nodo contiene solo se stesso; al passo $1$ include i propri vicini immediati; al passo $t+1$ unisce le bolle di raggio $t$ dei suoi successori. Quando nessuna bolla cambia più dimensione per nessun nodo, tutte le distanze finite sono state scoperte e il numero di iterazioni effettuate corrisponde al *diametro* del grafo.
]

Questo schema ha un enorme vantaggio architetturale: *le bolle (molto compatte) risiedono in memoria RAM*, mentre *il grafo non deve necessariamente stare in memoria*, ma può essere letto sequenzialmente da disco (in _streaming_) ad ogni iterazione, scandendo la lista di adiacenza.

#warning[
  Rappresentare ciascuna bolla $B_t (x)$ in modo esatto con un vettore di bit (_bitmap_) di lunghezza $n$ richiederebbe $n^2$ bit complessivi in RAM, il che è impensabile per miliardi di nodi.
  Tuttavia, per le nostre formule non ci serve il metodo `contains(y)` (sapere quali specifici nodi appartengono a $B_t (x)$), ma ci basta una stima di `size()` ($|B_t (x)|$).
]

Ci serve dunque una struttura dati probabilistica (*contatore HyperLogLog*) che supporti in modo efficiente tre sole operazioni:
1. `add(v)`: aggiunta di un elemento;
2. `union(C1, C2)`: fusione di due contatori per rappresentare l'unione degli insiemi;
3. `size()`: stima del numero di elementi distinti inseriti fino a quel momento.

== HyperLogLog

*HyperLogLog* (Flajolet et al.) è un contatore probabilistico progettato per risolvere il problema del _Count-Distinct_ (stimare la cardinalità di un insieme) utilizzando una quantità irrisoria di memoria.

=== L'intuizione probabilistica: lancio della moneta e prefissi di zeri
Immaginiamo di lanciare una moneta equa fino a quando non esce *testa* (`1`), contando quante *croci* (`0`) consecutive abbiamo ottenuto prima della testa, e di ripetere questo esperimento molte volte:
- Una sequenza che inizia subito con `1` (0 croci) capita con probabilità $1/2$ (in media ogni $2^1$ lanci).
- Una sequenza che inizia con `01` (1 croce) capita con probabilità $1/4$ (in media ogni $2^2$ lanci).
- In generale, una sequenza con $h$ zeri iniziali (`00...01`) ha probabilità $2^(-(h+1))$.

Se applichiamo una funzione di hash uniforme $hash: V -> {0, 1}^L$ a ciascun elemento dell'insieme, le stringhe binarie ottenute si comportano come sequenze casuali di lanci di moneta.
Osservando una sequenza massima di $h$ zeri iniziali (oppure la posizione $rho = h + 1$ del primo `1` da sinistra) tra tutti gli hash visti finora, possiamo stimare che il numero di elementi distinti $s$ sia proporzionale a:
$ s approx 2^h $

=== Occupazione di memoria e registri multipli (_Stochastic Averaging_)
Se un insieme contiene $s$ elementi distinti, il numero massimo di zeri consecutivi osservato sarà circa $log_2 s$. Per memorizzare il valore numerico $log_2 s$ bastano appena $log_2 log_2 s$ bit!

#example[
  Con soli *6 bit* per registro possiamo rappresentare numeri fino a $2^6 - 1 = 63$, sufficienti per contare insiemi di cardinalità fino a $2^63 approx 9 dot 10^18$ elementi.
]

Tuttavia, usare un singolo valore massimo comporta una *varianza elevatissima* (basta un singolo elemento "fortunato" il cui hash inizia con molti zeri per falsare completamente la stima). Per ridurre la varianza si applica la tecnica dello *stochastic averaging*, suddividendo il flusso in $k = 2^b$ sotto-esperimenti indipendenti (detti *registri* o _bucket_) in un unico passaggio:

1. I primi $b$ bit (bit alti) dell'hash $hash(v)$ determinano l'indice del registro $j in [0, k-1]$ a cui appartiene l'elemento.
2. Sui restanti $L - b$ bit dell'hash si conta la posizione $rho$ del primo bit uguale a `1` (ovvero il numero di zeri iniziali più 1).
3. Si aggiorna il registro $M[j]$ mantenendo il massimo valore osservato fino a quel momento:
  $ M[j] <- max(M[j], rho) $

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    // Titolo hash
    content((-1.8, 3.0), text(weight: "bold")[$hash(v) =$])

    // Bit alti (b = 3 bit)
    let b-bits = ("0", "1", "0")
    for (i, bit) in b-bits.enumerate() {
      rect((i * 0.7, 2.7), ((i + 1) * 0.7, 3.3), fill: blue.lighten(80%), stroke: blue.darken(20%))
      content(((i + 0.5) * 0.7, 3.0), text(fill: blue.darken(40%), weight: "bold")[#bit])
    }

    // Bit restanti (prefisso di zeri + primo 1)
    let r-bits = ("0", "0", "0", "1", "1", "0", "...")
    for (i, bit) in r-bits.enumerate() {
      let x0 = (i + 3) * 0.7
      let is-prefix = i <= 3
      let bg = if is-prefix { orange.lighten(82%) } else { gray.lighten(88%) }
      let st = if is-prefix { orange.darken(20%) } else { gray.darken(20%) }
      rect((x0, 2.7), (x0 + 0.7, 3.3), fill: bg, stroke: st)
      content((x0 + 0.35, 3.0), text(weight: if is-prefix { "bold" } else { "regular" })[#bit])
    }

    // Annotazioni sopra i bit
    line((0, 3.55), (2.1, 3.55), mark: (start: "|", end: "|"), stroke: blue.darken(30%))
    content((0.5, 3.9), text(size: 8.5pt, fill: blue.darken(30%))[$b = 3$ bit $->$ registro $j = 2$])

    line((2.1, 3.55), (4.9, 3.55), mark: (start: "|", end: "|"), stroke: orange.darken(30%))
    content((3.5, 3.9), text(size: 8.5pt, fill: orange.darken(30%))[3 zeri + `1` $-> rho = 4$])

    // Array di registri M[0..7]
    content((-1.8, 0.6), text(weight: "bold")[Registri $M$: ])
    let reg-vals = ("2", "5", "4", "1", "3", "6", "2", "3")
    for (j, val) in reg-vals.enumerate() {
      let x0 = j * 0.85
      let is-target = j == 2
      let bg = if is-target { green.lighten(75%) } else { white }
      let st = if is-target { (paint: green.darken(30%), thickness: 1.4pt) } else { black }
      rect((x0, 0.25), (x0 + 0.85, 0.95), fill: bg, stroke: st)
      content((x0 + 0.425, 0.6), text(weight: if is-target { "bold" } else { "regular" })[#val])
      content((x0 + 0.425, -0.05), text(size: 7.5pt, fill: gray.darken(40%))[$M[#j]$])
    }

    // Frecce di collegamento
    line((1.05, 2.7), (2.125, 0.95), mark: (end: ">"), stroke: (paint: blue.darken(20%), thickness: 1pt))
    line(
      (3.5, 2.7),
      (2.125, 0.95),
      mark: (end: ">"),
      stroke: (paint: orange.darken(20%), thickness: 1pt, dash: "dashed"),
    )
    content((4.3, 1.75), text(size: 8.5pt, fill: green.darken(40%))[$M[2] <- max(M[2], 4)$])
  }),
  caption: [Funzionamento di un contatore HyperLogLog con $b = 3$ bit di indirizzamento ($k = 2^3 = 8$ registri). I primi $b$ bit selezionano il registro $M[2]$, mentre la lunghezza del prefisso nella coda aggiorna il massimo locale.],
)

Ogni registro vede in media $s / k$ elementi distinti. Per stimare la cardinalità totale $s$, HyperLogLog calcola la *media armonica* di $2^(M[j])$ su tutti i $k$ registri (moltiplicata per una costante di correzione del bias $alpha_k$):
$ hat(s) = alpha_k dot k^2 dot (sum_(j=0)^(k-1) 2^(-M[j]))^(-1) $

L'uso della media armonica attenua fortemente l'effetto degli _outlier_ (code insolitamente lunghe di zeri). L'errore standard relativo scende proporzionalmente alla radice quadrata del numero di registri:
$ "Errore relativo" approx frac(1.04, sqrt(k)) $

=== Operazione di Unione e Massimo parallelo in _Broadword Programming_
Dati due contatori $M_A$ e $M_B$ (con lo stesso numero di registri $k$ e la stessa funzione di hash), il contatore dell'insieme unione $A union B$ si ottiene calcolando il *massimo componente per componente* (registro per registro) tra i due vettori di numeri a 6 bit:

$ forall j in [0, k-1], quad mb(M_(A union B)[j]) = max(mg(M_A [j]), mo(M_B [j])) $

Poiché durante ogni iterazione di HyperBall questa unione viene eseguita per ogni singolo arco del grafo, *il calcolo del massimo tra i registri rappresenta il costo computazionale dominante in tempo*.
Se estraessimo un registro da 6 bit alla volta tramite shift, maschere e cicli con `if/else`, il programma sarebbe troppo lento. Si ricorre quindi alla *Broadword Programming* (o *SWAR*, _SIMD Within A Register_): si impacchettano più registri dentro un'unica parola di memoria da 64 bit (_word_) e si calcola il massimo di tutti i registri *in parallelo* usando solo operazioni logiche e aritmetiche a bit.

==== L'algoritmo del bit di guardia
Supponiamo che ogni registro occupi $r$ bit (es. 6 bit) e sia preceduto a sinistra da un *bit di guardia* (il bit più significativo del blocco, inizialmente a `0`). Definiamo la maschera $H$ che ha `1` esattamente in corrispondenza di tutti i bit di guardia e `0` altrove:
$ H = "1000000 1000000 ... 1000000"_2 $

Dati due vettori di registri $x$ e $y$ impacchettati in due parole da 64 bit, per calcolare $max(x, y)$ in parallelo procediamo in quattro passi:

1. *Impostazione dei bit di guardia e sottrazione*: mettiamo in `OR` il primo vettore $x$ con la maschera $H$ (forzando a `1` tutti i bit di guardia di $x$) e sottraiamo il secondo vettore $y$:
  $ d = (x mid(|) H) - y $
  Grazie al bit di guardia posto a `1`, la sottrazione $x_j - y_j$ nel blocco $j$-esimo *non può mai generare un prestito* (_borrow_) dal blocco adiacente $(j+1)$-esimo. Alla fine della sottrazione:
  - se $x_j >= y_j$, il bit di guardia non viene intaccato e rimane *`1`*;
  - se $x_j < y_j$, la sottrazione consuma il bit di guardia portandolo a *`0`*.

2. *Estrazione dei bit di guardia*: isoliamo l'esito del confronto filtrando con un `AND` sulla maschera $H$:
  $ g = d and H $
  Nel vettore $g$, ogni blocco ha il bit di guardia a `1` se e solo se $x_j >= y_j$, e `0` altrimenti.

3. *Costruzione della maschera di selezione a blocchi*: trasformiamo ciascun bit di guardia in una sequenza di tutti `1` (se $x_j >= y_j$) o tutti `0` (se $x_j < y_j$) lunga quanto l'intero registro. Basta traslare il bit di guardia a destra fino al bit meno significativo del blocco ($(g >> r)$) e sottrarlo da $g$:
  $
    m = g - (g >> r) = cases(
      "0111111"_2 & "se " x_j >= y_j,
      "0000000"_2 & "se " x_j < y_j
    )
  $
  _(Se si vuole includere anche la posizione del bit di guardia nella maschera basta porre $m = (g - (g >> r)) mid(|) g$)._

4. *Selezione finale del massimo*: usiamo la maschera $m$ per prelevare i bit da $x$ dove $m$ vale `1` e da $y$ dove $m$ vale `0`:
  $ max(x, y) = (x and m) mid(|) (y and not m) $

#figure(
  cetz.canvas(length: 0.92cm, {
    import cetz.draw: *

    let draw-block(x0, y0, gbit, valbits, label-left, label-right, g-color: orange) = {
      if label-left != none {
        content((x0 - 0.3, y0 + 0.35), anchor: "east", text(size: 8.5pt, weight: "bold")[#label-left])
      }
      // Guard bit cell
      rect((x0, y0), (x0 + 0.7, y0 + 0.7), fill: g-color.lighten(78%), stroke: g-color.darken(30%))
      content((x0 + 0.35, y0 + 0.35), text(weight: "bold", fill: g-color.darken(40%))[#gbit])
      // 6 value bits
      for (i, b) in valbits.enumerate() {
        let bx = x0 + (i + 1) * 0.65
        rect((bx, y0), (bx + 0.65, y0 + 0.7), fill: gray.lighten(92%), stroke: gray.darken(25%))
        content((bx + 0.325, y0 + 0.35), text(size: 8.5pt)[#b])
      }
      if label-right != none {
        content((x0 + 4.8, y0 + 0.35), anchor: "west", text(size: 8pt, fill: gray.darken(40%))[#label-right])
      }
    }

    // Esempio su due blocchi affiancati: Blocco 1 (x >= y: 5 >= 3), Blocco 0 (x < y: 2 < 6)
    content((2.3, 5.1), text(weight: "bold", size: 9pt, fill: blue.darken(30%))[Blocco $j=1$: $x_1 = 5 >= y_1 = 3$])
    content((8.2, 5.1), text(weight: "bold", size: 9pt, fill: red.darken(30%))[Blocco $j=0$: $x_0 = 2 < y_0 = 6$])

    // Riga 1: x | H
    draw-block(0, 4.0, "1", ("0", "0", "0", "1", "0", "1"), [$x mid(|) H =$], none)
    draw-block(5.8, 4.0, "1", ("0", "0", "0", "0", "1", "0"), none, [(guardia = 1)])

    // Riga 2: y
    draw-block(0, 3.0, "0", ("0", "0", "0", "0", "1", "1"), [$y =$], none, g-color: gray)
    draw-block(5.8, 3.0, "0", ("0", "0", "0", "1", "1", "0"), none, [(guardia = 0)], g-color: gray)

    // Riga 3: d = (x | H) - y
    draw-block(0, 1.8, "1", ("0", "0", "0", "0", "1", "0"), [$d = (x mid(|) H) - y =$], none, g-color: green)
    draw-block(5.8, 1.8, "0", ("1", "1", "1", "1", "0", "0"), none, [(prestito dal bit di guardia!)], g-color: red)

    // Riga 4: maschera m
    draw-block(0, 0.6, "0", ("1", "1", "1", "1", "1", "1"), [$m = g - (g >> 6) =$], none, g-color: blue)
    draw-block(
      5.8,
      0.6,
      "0",
      ("0", "0", "0", "0", "0", "0"),
      none,
      [(tutti 1 se $x>=y$, tutti 0 se $x<y$)],
      g-color: blue,
    )

    // Riga 5: risultato max(x, y)
    draw-block(0, -0.6, "0", ("0", "0", "0", "1", "0", "1"), [$max(x, y) =$], none, g-color: purple)
    draw-block(5.8, -0.6, "0", ("0", "0", "0", "1", "1", "0"), none, [($max(5, 3)=5$, $max(2, 6)=6$)], g-color: purple)
  }),
  caption: [Esempio di calcolo parallelo di $max(x, y)$ su due registri da 6 bit con bit di guardia (evidenziato nella prima cella a sinistra di ogni blocco). Nel blocco $j=1$ ($5 >= 3$) il bit di guardia resta `1` e genera una maschera di tutti `1`; nel blocco $j=0$ ($2 < 6$) la sottrazione intacca il bit di guardia portandolo a `0` e generando una maschera di tutti `0`.],
)

#note(title: "Come ricavare i bit di guardia senza sprecare spazio")[
  Se i registri da 6 bit sono memorizzati in modo contiguo (senza bit di guardia fisici tra un registro e l'altro), basta dividere il calcolo in due passaggi usando due maschere complementari: prima si estraggono e confrontano tutti i *registri di indice pari* (usando i bit dei registri dispari adiacenti come spazio per i bit di guardia), poi si fa lo stesso per i *registri di indice dispari*, combinando infine i due risultati.
]

#note(title: "Ipotesi di piccolo mondo e complessità")[
  L'efficienza di HyperBall si basa sull'assunzione che il grafo abbia un *diametro basso* $D$ (proprietà _small-world_, tipica delle reti reali e del web dove $D approx O(log n)$)[cite: 1]. Poiché ogni iterazione scandisce tutti gli $m$ archi e aggiorna i contatori, l'algoritmo richiede esattamente $D$ passaggi complessivi: il costo temporale è quindi proporzionale a $O(D dot m)$, che risulta quasi lineare nel numero di archi solo se $D$ è piccolo[cite: 1]. Su grafi con diametro molto elevato (es. una lunga catena o una griglia), il numero di iterazioni crescerebbe troppo, rendendo l'approccio inefficiente[cite: 1].
]

#warning(title: "Propagazione dell'errore nella differenza (Cancellazione numerica)")[
  I contatori HyperLogLog garantiscono un *errore relativo* limitato (circa $1.04 / sqrt(k)$) sulla stima della bolla $|B_t (x)|$[cite: 1].
  - Quando *sommiamo* le stime (ad esempio per calcolare $N(t) = sum_x |B_t (x)|$), l'errore relativo si mantiene basso (e anzi si riduce grazie alla compensazione statistica tra stime indipendenti)[cite: 1].
  - Quando invece *sottraiamo* due stime per calcolare la sfera $|S_t (x)| = |B_t (x)| - |B_(t-1) (x)|$, gli errori *assoluti* delle due bolle si sommano[cite: 1]. Se la sfera $|S_t (x)|$ è piccola rispetto alla bolla $|B_t (x)|$ (cosa che accade regolarmente nella coda della distribuzione, per $t$ grandi), si verifica il fenomeno della *cancellazione numerica*: la differenza tra due quantità grandi e quasi uguali produce un *errore relativo enorme* su $|S_t (x)|$ (che può persino risultare negativa)[cite: 1]. Tuttavia, nelle centralità geometriche come quella armonica, questo rumore sulle code viene attenuato dal fattore $1/t$[cite: 1].
]

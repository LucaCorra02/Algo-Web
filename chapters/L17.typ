#import "../template.typ": *

== Meccanismi di centralità e ranking basati su autovalori e autovettori

Finora abbiamo analizzato misure di centralità basate su proprietà locali (come il grado) o sulle distanze (come _closeness_ e _betweenness_). Introduciamo ora una famiglia di misure di centralità *spettrali* (o ricorsive), il cui principio fondamentale è:
#informally[
  Un nodo è importante se è puntato da altri nodi a loro volta importanti.
]

=== Prodotto vettore-matrice e cammini su grafi

Sia $G = (V, E)$ un grafo diretto con $n = |V|$ vertici e sia $A in RR^(n times n)$ la sua *matrice di adiacenza*, definita come:
$
  A_(i j) = cases(
    1 & "se" (i, j) in E " (esiste un arco da " i " a " j ")",
    0 & "altrimenti"
  )
$

Vediamo cosa significa moltiplicare un vettore di punteggi (pesi) per la matrice $A$:

- *Moltiplicazione a sinistra (vettore riga per matrice):* dato un vettore riga $v in RR^(1 times n)$, il prodotto $v' = v A$ ha come componente $j$-esima:
  $
    v'_j = (v A)_j = sum_(i=1)^n v_i A_(i j) = sum_(i in N^-(j)) v_i
  $
  Ogni vertice $j$ *sostituisce il proprio peso con la somma dei pesi dei suoi predecessori* (nodi che hanno un arco entrante in $j$).
  In particolare, se partiamo dal vettore uniforme $bold(1) = (1, 1, dots, 1)$, otteniamo il vettore degli *in-degree*:
  $
    (bold(1) dot A)_j = sum_(i=1)^n 1 dot A_(i j) = d^-(j)
  $

- *Moltiplicazione a destra (matrice per vettore colonna):* dato un vettore colonna $u in RR^(n times 1)$, il prodotto $u' = A u$ ha come componente $i$-esima:
  $
    u'_i = (A u)_i = sum_(j=1)^n A_(i j) u_j = sum_(j in N^+(i)) u_j
  $
  Ogni vertice $i$ *sostituisce il proprio peso con la somma dei pesi dei suoi successori* (nodi raggiunti da un arco uscente da $i$). In particolare, $(A dot bold(1)^T)_i = d^+(i)$ restituisce il vettore degli *out-degree*.

==== Interpretazione delle potenze della matrice di adiacenza $A^k$

Cosa succede quando moltiplichiamo la matrice $A$ per se stessa? Consideriamo il prodotto $A^2 = A dot A$:
$
  (A^2)_(i j) = sum_(l=1)^n A_(i l) A_(l j)
$
Poiché $A_(i l)$ e $A_(l j)$ valgono $1$ solo se esistono rispettivamente gli archi $i -> l$ e $l -> j$, il prodotto $A_(i l) A_(l j)$ vale $1$ se e solo se esiste un *cammino diretto di lunghezza 2* da $i$ a $j$ che passa per il nodo intermedio $l$. Sommando su tutti i possibili nodi intermedi $l$, otteniamo il numero totale di cammini di lunghezza $2$ da $i$ a $j$.

Per induzione, vale la proprietà generale:
#note(title: "Significato combinatorio di " + $A^k$)[
  L'elemento $(A^k)_(i j)$ della potenza $k$-esima della matrice di adiacenza rappresenta esattamente il *numero di cammini diretti di lunghezza $k$* dal nodo $i$ al nodo $j$.
]

#example(title: "Calcolo dei cammini tramite potenze di matrice")[
  Consideriamo il grafo diretto a $4$ nodi rappresentato dalla seguente matrice di adiacenza $A$:
  $
    A = mat(
      0, 1, 0, 1;
      0, 0, 1, 1;
      0, 1, 0, 1;
      1, 1, 0, 0
    ), quad
    A^2 = A dot A = mat(
      1, 1, 1, 1;
      1, 2, 0, 1;
      1, 1, 1, 1;
      0, 1, 1, 2
    )
  $
  Osserviamo ad esempio l'entrata $(A^2)_(2, 2) = 2$: ciò significa che esistono esattamente $2$ cammini di lunghezza $2$ che partono dal nodo $2$ e tornano nel nodo $2$, ovvero $2 -> 3 -> 2$ e $2 -> 4 -> 2$.

  #figure(
    cetz.canvas(length: 1cm, {
      import cetz.draw: *

      let r = 0.45
      let pos = (
        "1": (0, 2.5),
        "2": (3.5, 2.5),
        "3": (3.5, 0),
        "4": (0, 0),
      )

      // Disegno nodi
      for (name, p) in pos {
        circle(p, radius: r, fill: blue.lighten(85%), stroke: blue.darken(20%) + 1.2pt, name: "n" + name)
        content(p, text(weight: "bold")[#name])
      }

      let arrow-style = (mark: (end: "stealth", fill: black, scale: 0.7), stroke: 1pt)
      let highlight-style = (mark: (end: "stealth", fill: red.darken(10%), scale: 0.7), stroke: (paint: red.darken(10%), thickness: 1.3pt))

      // Archi standard
      line("n1.east", "n2.west", ..arrow-style)
      line("n1.south", "n4.north", ..arrow-style)
      line("n3.north-west", "n4.north-east", ..arrow-style)
      line("n4.north-east", "n1.south-east", ..arrow-style)

      // Archi evidenziati (cicli di lunghezza 2 da/per il nodo 2)
      bezier("n2.south-east", "n3.north-east", (4.3, 1.25), ..highlight-style)
      bezier("n3.north-west", "n2.south-west", (2.7, 1.25), ..highlight-style)
      bezier("n2.south-west", "n4.north-east", (1.4, 1.6), ..highlight-style)
      bezier("n4.east", "n2.south", (2.1, 0.9), ..highlight-style)
    }),
    caption: [Grafo associato alla matrice $A$. In rosso sono evidenziati i due cicli di lunghezza $2$ centrati sul nodo $2$, corrispondenti a $(A^2)_(2,2) = 2$.]
  )
]

Di conseguenza, la definizione di *connessione forte* di un grafo (ovvero l'esistenza di un cammino diretto da ogni nodo $i$ a ogni nodo $j$) può essere espressa algebricamente tramite le potenze di $A$ (in algebra lineare, una matrice con questa proprietà si dice *irriducibile*):
$
  G "è fortemente connesso" quad <==> quad forall i, j in V, space exists k >= 1 " tale che " (A^k)_(i j) > 0
$

---

=== Teorema di Perron-Frobenius e Centralità di Autovettore

Per costruire un punteggio di centralità ricorsivo possiamo procedere iterativamente:
1. Partiamo da un vettore di punteggi uniforme $v^{(0)} = bold(1) = (1, 1, dots, 1)$.
2. Al primo passo calcoliamo $v^{(1)} = bold(1) dot A$, ottenendo per ogni nodo il suo grado entrante (_in-degree_): contiamo cioè quanti siti puntano a ciascun nodo.
3. Al secondo passo calcoliamo $v^{(2)} = v^{(1)} dot A = bold(1) dot A^2$: il punteggio di un nodo diventa la *somma degli in-degree dei suoi predecessori* (contiamo i cammini entranti di lunghezza $2$).
4. Iterando $k$ volte, otteniamo $v^{(k)} = bold(1) dot A^k$. Per evitare che i valori divergano all'infinito al crescere di $k$, normalizziamo il vettore a ogni passo dividendolo per la sua norma:
   $
     v^{(k)} = frac(bold(1) dot A^k, norm(bold(1) dot A^k))
   $

Se questa successione converge a un vettore limite $v^*$, allora tale vettore deve essere stabile rispetto a un'ulteriore moltiplicazione per $A$ (a meno di un fattore di scala $lambda$), ovvero deve soddisfare l'*equazione agli autovalori*:
$
  v^* A = lambda v^*
$
dove $v^*$ è un *autovettore sinistro* di $A$ e $lambda$ è il corrispondente *autovalore*.

Affinché $v^*$ possa essere usato come misura di centralità sensata, deve avere tutte componenti *non negative* (non avrebbe senso avere importanze negative che si cancellano con quelle positive) e deve essere *unico* (a meno di un fattore di scala). L'esistenza e l'unicità di tale vettore sono garantite dal celebre *Teorema di Perron-Frobenius*.

#theorem(title: "Teorema di Perron-Frobenius (per grafi fortemente connessi)")[
  Sia $A in RR^(n times n)$ una matrice non negativa ($A_(i j) >= 0$) che rappresenta un grafo *fortemente connesso* (ossia $A$ è *irriducibile*: $forall i, j space exists k >= 1 " t.c. " (A^k)_(i j) > 0$). Allora valgono le seguenti proprietà:
  1. Esiste un autovalore reale e strettamente positivo $lambda_0 > 0$, detto *autovalore dominante* (o radice di Perron), tale che per ogni altro autovalore $lambda_i$ di $A$ si ha $|lambda_i| <= lambda_0$.
  2. L'autovalore dominante $lambda_0$ ha molteplicità algebrica e geometrica semplice (pari a $1$).
  3. A $lambda_0$ è associato un *unico autovettore* (a meno di moltiplicazione per uno scalare) avente tutte le componenti *strettamente positive* ($v_i > 0, forall i$).
  4. Nessun altro autovalore ammette un autovettore con componenti tutte positive (o tutte non negative).
]

#informally(title: "Perché esiste un solo autovettore tutto positivo?")[
  Nel caso di una matrice simmetrica (o più in generale considerando la dualità tra autovettori destri e sinistri relativi ad autovalori distinti), gli autovettori associati ad autovalori diversi sono *ortogonali* tra loro, ovvero il loro prodotto scalare deve essere nullo ($⟨e_0, e_i⟩ = 0$ per $i != 0$).
  
  Se l'autovettore dominante $e_0$ ha tutte le componenti strettamente positive ($e_(0, j) > 0$), qualsiasi altro vettore $e_i$ ortogonale ad esso deve necessariamente avere *alcune componenti positive e altre negative* affinché la somma dei prodotti componente per componente possa annullarsi dando $0$. Inoltre, essendo tutti i pesi in $e_0$ positivi, nel calcolo di $v A$ non si verificano mai cancellazioni tra contributi positivi e negativi.
]

#note(title: "Definizione: Centralità di Autovettore (Eigenvector Centrality)")[
  La *centralità di autovettore* (_dominant eigenvector centrality_) consiste nell'assegnare a ciascun vertice del grafo il punteggio corrispondente alla sua componente nell'autovettore positivo associato all'autovalore dominante $lambda_0$:
  $
    v A = lambda_0 v, quad v_j = frac(1, lambda_0) sum_(i in N^-(j)) v_i
  $
]

=== Convergenza del Metodo delle Potenze e Grafi Periodici

Mostriamo matematicamente sotto quali condizioni la procedura iterativa $v^{(k)} = v^{(0)} A^k$ converge all'autovettore dominante (questo algoritmo numerico è noto come *Metodo delle Potenze* o _Power Iteration_).

#proof(title: "Analisi di convergenza del Metodo delle Potenze")[
  Supponiamo che la matrice $A$ sia diagonalizzabile e abbia autovalori $lambda_0, lambda_1, dots, lambda_(n-1)$ ordinati per modulo decrescente:
  $
    lambda_0 > |lambda_1| >= |lambda_2| >= dots >= |lambda_(n-1)|
  $
  dove $mb(lambda_0)$ è *strettamente maggiore* in modulo rispetto a tutti gli altri autovalori. Siano $e_0, e_1, dots, e_(n-1)$ i corrispondenti autovettori sinistri ($e_i A = lambda_i e_i$), che formano una base di $RR^n$.

  Qualsiasi vettore iniziale $v^{(0)}$ può essere scritto come combinazione lineare della base di autovettori:
  $
    v^{(0)} = sum_(i=0)^(n-1) alpha_i e_i
  $
  Moltiplicando a destra per $A^k$ e sfruttando la linearità e la proprietà $e_i A^k = lambda_i^k e_i$, otteniamo:
  $
    v^{(0)} A^k = (sum_(i=0)^(n-1) alpha_i e_i) A^k = sum_(i=0)^(n-1) alpha_i (e_i A^k) = sum_(i=0)^(n-1) alpha_i lambda_i^k e_i
  $
  Separiamo ora il termine $i = 0$ (relativo all'autovalore dominante) dal resto della sommatoria e raccogliamo a fattor comune $mb(lambda_0^k)$:
  $
    v^{(0)} A^k &= alpha_0 lambda_0^k e_0 + sum_(i=1)^(n-1) alpha_i lambda_i^k e_i \
                &= mb(lambda_0^k) ( mr(alpha_0 e_0) + sum_(i=1)^(n-1) alpha_i underbrace((frac(lambda_i, lambda_0))^k, -> 0 " per " k -> infinity) e_i )
  $
  Poiché per ipotesi $|lambda_i| < lambda_0$ per ogni $i >= 1$, si ha che $|lambda_i / lambda_0| < 1$, e dunque per $k -> infinity$ tutti i termini $(lambda_i / lambda_0)^k$ tendono a $0$. Di conseguenza, per $k$ grande:
  $
    v^{(0)} A^k approx lambda_0^k alpha_0 e_0
  $
  Normalizzando il vettore, il fattore scalare $lambda_0^k alpha_0$ si semplifica e la successione converge esattamente nella direzione dell'autovettore dominante $e_0$:
  $
    lim_(k -> infinity) frac(v^{(0)} A^k, norm(v^{(0)} A^k)) = frac(e_0, norm(e_0))
  $
]

Affinché il metodo converga sono quindi necessarie *due condizioni fondamentali*:
1. *$alpha_0 != 0$*: il vettore iniziale $v^{(0)}$ deve avere una componente non nulla lungo l'autovettore dominante $e_0$. Scegliendo un vettore iniziale $v^{(0)}$ *strettamente positivo* (come $bold(1)$), poiché anche $e_0$ è strettamente positivo, siamo certi che $alpha_0 > 0$.
2. *$lambda_0 > |lambda_1|$ (Primitività / Aperiodicità)*: l'autovalore dominante deve essere *strettamente* maggiore in modulo di tutti gli altri. Il solo teorema di Perron-Frobenius per grafi fortemente connessi garantisce $|lambda_i| <= lambda_0$, ma non esclude che ci possano essere altri autovalori (negativi o complessi) con lo stesso modulo $|lambda_i| = lambda_0$. Ciò accade nei grafi *periodici* (o ciclici).

#example(title: "Controesempio: Grafo periodico (Flip-Flop)")[
  Consideriamo un grafo formato da due soli nodi che si puntano a vicenda (ciclo di lunghezza $2$), la cui matrice di adiacenza è:
  $
    A = mat(0, 1; 1, 0)
  $
  Questo grafo è fortemente connesso, ma se partiamo da un vettore generico $v^{(0)} = (a, b)$ con $a != b$ e moltiplichiamo ripetutamente per $A$, otteniamo:
  $
    (a, b) mat(0, 1; 1, 0) = (b, a), quad (b, a) mat(0, 1; 1, 0) = (a, b)
  $
  La successione oscilla indefinitamente tra $(a, b)$ e $(b, a)$ come un *flip-flop* e *non converge*!

  #figure(
    cetz.canvas(length: 1cm, {
      import cetz.draw: *

      circle((0, 0), radius: 0.5, fill: orange.lighten(85%), stroke: orange.darken(20%) + 1.2pt, name: "A")
      content("A", [$1$])
      content((0, -0.9), text(size: 9pt, fill: orange.darken(30%))[peso: $a <-> b$])

      circle((3.5, 0), radius: 0.5, fill: purple.lighten(85%), stroke: purple.darken(20%) + 1.2pt, name: "B")
      content("B", [$2$])
      content((3.5, -0.9), text(size: 9pt, fill: purple.darken(30%))[peso: $b <-> a$])

      let arr = (mark: (end: "stealth", fill: black, scale: 0.8), stroke: 1.1pt)
      bezier("A.north-east", "B.north-west", (1.75, 0.9), ..arr)
      bezier("B.south-west", "A.south-east", (1.75, -0.9), ..arr)
    }),
    caption: [Grafo periodico di periodo $2$ ("flip-flop"): ad ogni iterazione i pesi $a$ e $b$ si scambiano senza mai convergere.]
  )

  *Perché non converge?* Calcoliamo gli autovalori di $A$ tramite il polinomio caratteristico:
  $
    det(A - lambda I) = det mat(-lambda, 1; 1, -lambda) = lambda^2 - 1 = 0 quad ==> quad lambda_0 = 1, space lambda_1 = -1
  $
  Abbiamo due autovalori distinti ma con lo *stesso modulo massimo*: $|lambda_0| = |lambda_1| = 1$. Nella formula del metodo delle potenze il rapporto $(lambda_1 / lambda_0)^k = (-1)^k$ oscilla tra $+1$ e $-1$ anziché tendere a zero!

  #warning(title: "Come forzare la convergenza (Matrice Primitiva)")[
    Per eliminare la periodicità e garantire che $lambda_0 > |lambda_i|$ per ogni $i >= 1$ (rendendo la matrice *primitiva*), è sufficiente aggiungere dei *cappi* (_self-loops_) o perturbare leggermente la diagonale, ad esempio considerando $A' = A + alpha I$ (con $alpha > 0$). Dal punto di vista dei cammini, aggiungere un cappio rompe la parità dei cicli e fa sì che esista un intero $k$ tale che $A^k$ abbia *tutte le entrate strettamente positive* ($(A^k)_(i j) > 0$ simultaneamente per lo stesso $k$).
  ]
]

== Indice di Seeley (PageRank semplificato)

Nel 1949 il sociologo John R. Seeley propose un indice per misurare il *prestigio sociale* (popolarità) all'interno di un gruppo di bambini. Dopo aver chiesto a ciascun bambino di indicare quali compagni gli piacessero, Seeley costruì il grafo diretto delle preferenze (con matrice di adiacenza $A$).

L'idea iniziale della centralità di autovettore somma semplicemente il prestigio di chi ci vota: $s_i = sum_(j in N^-(i)) s_j$. Tuttavia, Seeley osservò un difetto:
#informally[
  Se un bambino dice che gli piacciono *tutti*, il suo voto vale meno rispetto al voto di un bambino molto *selettivo* che indica solo uno o due compagni.
]

Per tenere conto della selettività, il prestigio $s_j$ trasferito dal nodo $j$ a ciascuno dei suoi successori viene *diviso equamente per il numero totale di preferenze espresse da $j$*, ovvero per il suo *out-degree* $d^+(j)$ (assumendo $d^+(j) >= 1$ per ogni nodo):
$
  s_i = sum_(j in N^-(i)) frac(s_j, d^+(j)) = sum_(j=1)^n s_j frac(A_(j i), d^+(j))
$

=== Normalizzazione in norma $L_1$ e formulazione matriciale

Definiamo la matrice di adiacenza *normalizzata per righe in norma $L_1$*, indicata con $overline(A)$ (detta anche *matrice di transizione* o matrice stocastica per righe), dividendo ogni riga $j$ di $A$ per la somma dei moduli dei suoi elementi (che coincide con l'out-degree $d^+(j)$):
$
  overline(A)_(j i) = frac(A_(j i), d^+(j)) = frac(A_(j i), sum_(k=1)^n A_(j k))
$
Con questa definizione, l'equazione dell'indice di Seeley per l'intero vettore riga dei punteggi $s = (s_1, s_2, dots, s_n)$ si scrive semplicemente come:
$
  s = s dot overline(A) quad <==> quad 1 dot s = s dot overline(A)
$
Pertanto, *l'indice di Seeley corrisponde all'autovettore sinistro di $overline(A)$ associato all'autovalore $lambda = 1$*.

#note(title: "Perché " + $lambda = 1$ + " è sempre l'autovalore dominante di " + $overline(A)$ + "?")[
  Poiché ogni riga di $overline(A)$ è stata divisa per la somma dei suoi elementi, la somma di ciascuna riga di $overline(A)$ vale esattamente $1$.
  Se moltiplichiamo $overline(A)$ *a destra* per il vettore colonna formato da tutti uni $bold(1)^T = (1, 1, dots, 1)^T$, otteniamo:
  $
    (overline(A) dot bold(1)^T)_j = sum_(i=1)^n overline(A)_(j i) dot 1 = 1 quad ==> quad overline(A) dot bold(1)^T = 1 dot bold(1)^T
  $
  Quindi il vettore colonna $bold(1)^T$ è sempre un *autovettore destro* di $overline(A)$ relativo all'autovalore $lambda = 1$. Poiché gli autovalori destri e sinistri coincidono (e per il teorema di Gershgorin / Perron-Frobenius il raggio spettrale di una matrice stocastica è esattamente $1$), esiste sempre anche un *autovettore sinistro* $s$ associato a $lambda_0 = 1$, che è unico e strettamente positivo se il grafo è fortemente connesso.
]


== Catene di Markov e il modello del Random Surfer

L'indice di Seeley (e più in generale PageRank) ha una naturale interpretazione probabilistica attraverso le *Catene di Markov a tempo discreto*.

Una catena di Markov è un processo stocastico definito su un insieme finito di stati $V = {1, 2, dots, n}$ che ad ogni passo temporale si sposta da uno stato $i$ a uno stato $j$ con una *probabilità di transizione* $P_(i j) >= 0$ che dipende solo dallo stato corrente.
Affinché le probabilità di uscita da ogni stato formino una distribuzione valida, la somma delle probabilità sugli archi uscenti da ogni nodo deve essere $1$:
$
  sum_(j=1)^n P_(i j) = 1 quad forall i in V
$
La matrice $P = overline(A)$ costruita nell'indice di Seeley è esattamente la matrice di transizione di una catena di Markov in cui, da ogni nodo, si sceglie uno qualsiasi degli archi uscenti con *probabilità uniforme* $1 / d^+(i)$.

=== Evoluzione della distribuzione di probabilità e stato stazionario

Supponiamo che al tempo $t$ il sistema si trovi nei vari stati secondo una distribuzione di probabilità descritta dal vettore riga $pi^{(t)} = (pi_1^{(t)}, dots, pi_n^{(t)})$, con $sum_i pi_i^{(t)} = 1$.
Qual è la probabilità $pi_j^{(t+1)}$ di trovarsi nello stato $j$ al passo successivo? Per la legge delle probabilità totali, sommiamo su tutti i possibili stati di provenienza $i$ la probabilità di trovarsi in $i$ moltiplicata per la probabilità di transitare da $i$ a $j$:
$
  pi_j^{(t+1)} = sum_(i=1)^n pi_i^{(t)} P_(i j) quad <==> quad pi^{(t+1)} = pi^{(t)} P
$

#example(title: "Passo di transizione")[
  Se al tempo $t$ mi trovo nel nodo $a$ con probabilità $pi_a^{(t)} = 1/4$ e dal nodo $a$ escono $2$ archi (quindi l'arco $a -> b$ ha probabilità $P_(a b) = 1/2$), il contributo di questo singolo cammino alla probabilità di trovarmi in $b$ al passo successivo è:
  $
    pi_a^{(t)} dot P_(a b) = frac(1, 4) dot frac(1, 2) = frac(1, 8)
  $
]

Se facendo evolvere la catena ($pi^{(t)} = pi^{(0)} P^t$) si raggiunge una configurazione di equilibrio che rimane invariata ai passi successivi, tale distribuzione $pi$ è detta *distribuzione stazionaria* (o di equilibrio) e soddisfa:
$
  pi P = pi, quad "con " sum_(i=1)^n pi_i = 1, space pi_i >= 0
$
Notiamo che questa è *esattamente la stessa equazione dell'indice di Seeley* ($s overline(A) = s$)!

#informally(title: "Interpretazione del Random Surfer (Navigatore Casuale)")[
  Immaginiamo un utente (_random surfer_) che naviga sul Web (o si sposta tra i bambini del grafo di Seeley) partendo da una pagina a caso e, ad ogni passo, cliccando su uno dei link presenti nella pagina corrente scelto in modo equiprobabile.
  
  Per il *teorema ergodico* delle catene di Markov, se il grafo è fortemente connesso e aperiodico, la componente $pi_i$ della distribuzione stazionaria rappresenta la *frazione di tempo a lungo termine* che il navigatore trascorre sul sito $i$ (cioè la frequenza relativa di visite al nodo $i$). Più un sito viene visitato dal navigatore casuale, più è "popolare" e importante!
]

=== Limiti dell'indice di Seeley sui grafi non fortemente connessi (Il Web)

L'indice di Seeley funziona perfettamente solo se il grafo è *fortemente connesso*. Tuttavia, il grafo del Web reale *non è fortemente connesso*: presenta infatti nodi senza archi uscenti (*dead ends* / _dangling nodes_) e componenti fortemente connesse da cui non escono archi verso il resto del grafo (*spider traps* o componenti pozzo).

Cosa succede alla catena di Markov (e quindi a Seeley) in presenza di componenti pozzo?
Consideriamo un grafo composto da una componente fortemente connessa principale $C_0$ da cui partono archi verso due componenti $C_1$ e $C_2$ raggiungibili da $C_0$, ma *dalle quali non è possibile uscire* (pozzi assorbenti).

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    // Componente C0 (sorgente/transiente)
    circle((0, 0), radius: 1.35, fill: blue.lighten(92%), stroke: (paint: blue.darken(20%), thickness: 1.2pt, dash: "dashed"), name: "C0")
    content((0, 1.7), text(weight: "bold", fill: blue.darken(30%))[Componente $C_0$ ($pi -> 0$)])
    circle((-0.55, 0.35), radius: 0.28, fill: white, stroke: blue.darken(20%), name: "u1")
    circle((0.55, 0.35), radius: 0.28, fill: white, stroke: blue.darken(20%), name: "u2")
    circle((0, -0.55), radius: 0.28, fill: white, stroke: blue.darken(20%), name: "u3")

    let arr-sm = (mark: (end: "stealth", fill: blue.darken(20%), scale: 0.5), stroke: blue.darken(20%) + 0.8pt)
    line("u1", "u2", ..arr-sm)
    line("u2", "u3", ..arr-sm)
    line("u3", "u1", ..arr-sm)

    // Componente C1 (pozzo 1)
    circle((4.8, 1.4), radius: 1.15, fill: red.lighten(90%), stroke: red.darken(20%) + 1.3pt, name: "C1")
    content((4.8, 2.85), text(weight: "bold", fill: red.darken(30%))[Pozzo $C_1$ ($pi > 0$)])
    circle((4.3, 1.4), radius: 0.28, fill: white, stroke: red.darken(20%), name: "v1")
    circle((5.3, 1.4), radius: 0.28, fill: white, stroke: red.darken(20%), name: "v2")
    let arr-red = (mark: (end: "stealth", fill: red.darken(20%), scale: 0.5), stroke: red.darken(20%) + 0.8pt)
    bezier("v1.north", "v2.north", (4.8, 1.9), ..arr-red)
    bezier("v2.south", "v1.south", (4.8, 0.9), ..arr-red)

    // Componente C2 (pozzo 2)
    circle((4.8, -1.4), radius: 1.15, fill: red.lighten(90%), stroke: red.darken(20%) + 1.3pt, name: "C2")
    content((4.8, -2.85), text(weight: "bold", fill: red.darken(30%))[Pozzo $C_2$ ($pi > 0$)])
    circle((4.3, -1.4), radius: 0.28, fill: white, stroke: red.darken(20%), name: "w1")
    circle((5.3, -1.4), radius: 0.28, fill: white, stroke: red.darken(20%), name: "w2")
    bezier("w1.north", "w2.north", (4.8, -0.9), ..arr-red)
    bezier("w2.south", "w1.south", (4.8, -1.9), ..arr-red)

    // Archi di uscita da C0 verso C1 e C2 (senza ritorno)
    let trap-arr = (mark: (end: "stealth", fill: black, scale: 0.8), stroke: (paint: black, thickness: 1.3pt))
    line("C0.north-east", "C1.west", ..trap-arr, name: "t1")
    line("C0.south-east", "C2.west", ..trap-arr, name: "t2")
    content((2.3, 0.90), text(size: 8.5pt)[senza ritorno])
    content((2.3, -1.50), text(size: 8.5pt)[senza ritorno])
  }),
  caption: [Grafo non fortemente connesso con due componenti pozzo ($C_1$ e $C_2$). Il _random surfer_ prima o poi esce da $C_0$ e rimane intrappolato in $C_1$ o $C_2$, azzerando il punteggio di tutti i nodi in $C_0$.]
)

1. *Svuotamento delle componenti transienti:* Un _random surfer_ che parte da $C_0$, muovendosi a caso per un tempo sufficientemente lungo, prima o poi imboccherà con probabilità $1$ uno degli archi che portano in $C_1$ o $C_2$. Una volta entrato in $C_1$ o $C_2$, *non potrà più uscirne*. Di conseguenza, al limite per $t -> infinity$, la probabilità stazionaria di tutti i nodi in $C_0$ diventa *esattamente zero* ($pi_i = 0, forall i in C_0$), annullando completamente il ranking della componente principale!
2. *Non unicità dell'autovettore dominante:* Poiché $C_1$ e $C_2$ sono due pozzi separati, ciascuno ammette una propria distribuzione stazionaria indipendente (l'autovalore $lambda = 1$ ha molteplicità geometrica pari a $2$), e la distribuzione finale dipende da dove è partito il navigatore.

#warning(title: "Verso PageRank")[
  Per applicare questo meccanismo al Web (che non è fortemente connesso), è necessario modificare la catena di Markov affinché il navigatore non resti mai intrappolato nei pozzi o nei nodi senza uscite. Questa modifica — che introduce una probabilità di *teletrasporto* casuale verso un qualsiasi nodo del grafo — prende il nome di *PageRank*.
]
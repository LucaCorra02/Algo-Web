#import "../template.typ": *

== Osservazioni preliminari e accesso alle sequenze compresse

Quando si analizza una sequenza compressa (come una lista di affissione), l'accesso diretto all'$i$-esimo elemento non è supportato nativamente in tempo costante, poiché la compressione impedisce di saltare linearmente ai dati precedenti senza una decodifica sequenziale.

Per superare questo limite e gestire interrogazioni complesse in modo efficiente, si ricorre a due strumenti:

- L'operazione di *greatest upperbound* (minimo dei maggioranti / massimo dei minoranti), definita come la capacità di individuare rapidamente il *primo elemento della lista maggiore o uguale a un dato valore target $i$*.

#example[
  Dato il target $i$, si cerca il primo elemento della lista tale per cui $"elemento" >= i$.
]

- Una struttura d'appoggio, la *skip table*, che permette di raggiungere rapidamente l'intorno del punto cercato.

=== Tecnica di campionamento (Skip Table)

Per eseguire questa ricerca in tempi ridotti, si affianca alla lista di affissione una struttura di supporto: un parametro di campionamento $q$ che suddivide la sequenza a intervalli regolari.

- Si memorizza una tabella esplicita contenente i valori campionati ed i relativi puntatori.
- Per ciascun puntatore campionato, viene registrata l'esatta posizione all'interno del *bit stream*.


#note[
  Più $q$ è grande, più il campionamento è lasso (tabella più compatta, scansione locale più lunga); più $q$ è piccolo, più il campionamento è fitto (tabella grande, accesso più diretto).
]

Grazie a questa struttura, l'algoritmo procede in due fasi:

1. Ricerca binaria all'interno della tabella dei campioni per individuare il minore dei maggioranti.
2. Scansione sequenziale locale limitata all'interno del blocco di bit individuato.

Il costo computazionale complessivo risulta pari a:
$
  underbrace(O(log(f/q)), "ricerca binaria sui campioni") + underbrace(O(q), "scansione del blocco")
$
dove $f$ è la lunghezza totale della lista e $q$ la dimensione del campione.

#align(center)[
  #cetz.canvas({
    import cetz.draw: *

    let c-blue = rgb("#cde0fc")
    let c-green = rgb("#c3ecc5")
    let c-orange = rgb("#fbe0bd")
    let c-gray = rgb("#ebebeb")
    let values = ("1", "3", "7", "10", "12", "100", "120", "121", "150")
    let codes = ("001", "1011", "01011", "1100", "010", "100110", "11101", "00110", "10101")
    let block-colors = (c-blue, c-green, c-orange)
    let q = 3
    let cell-w = 1.15
    let cell-h = 0.75
    let y-list = 0.55

    content((4.5 * cell-w, 2.05), [
      *1. Lista campionata*
    ])
    content((-0.3, y-list + cell-h / 2), anchor: "east", [
      *lista* \ #text(size: 7.5pt, fill: luma(90))[(valori)]
    ])

    for i in range(9) {
      let x = i * cell-w
      let fill-col = if calc.rem(i, q) == 0 {
        block-colors.at(int(i / q))
      } else {
        c-gray
      }
      content((x + cell-w / 2, y-list + cell-h + 0.22), text(size: 7.5pt, fill: luma(100))[#i])
      rect((x, y-list), (x + cell-w, y-list + cell-h), fill: fill-col, stroke: 0.7pt + black)
      content((x + cell-w / 2, y-list + cell-h / 2), values.at(i))
    }

    for b in range(3) {
      let x-start = b * q * cell-w + 0.06
      let x-end = (b + 1) * q * cell-w - 0.06
      let y-line = y-list - 0.18
      line((x-start, y-line), (x-end, y-line), stroke: 1.1pt + black)
      content(((x-start + x-end) / 2, y-line - 0.25), text(size: 8pt)[blocco #b ($q=3$)])
    }
  })
]

#pagebreak()

#align(center)[
  #cetz.canvas({
    import cetz.draw: *

    let c-blue = rgb("#cde0fc")
    let c-green = rgb("#c3ecc5")
    let c-orange = rgb("#fbe0bd")
    let c-gray = rgb("#ebebeb")
    let codes = ("001", "1011", "01011", "1100", "010", "100110", "11101", "00110", "10101")
    let block-colors = (c-blue, c-green, c-orange)
    let q = 3
    let cell-w = 1.15
    let cell-h = 0.75
    let y-bit = 0.9
    let y-skip = -1.15
    let box-w = 2.45
    let box-h = 0.75

    content((4.5 * cell-w, 2.4), [*2. Bit stream e skip table*])
    content((-0.3, y-bit + cell-h / 2), anchor: "east", [
      *bit stream* \ #text(size: 7.5pt, fill: luma(90))[(codificato)]
    ])

    for i in range(9) {
      let x = i * cell-w
      let fill-col = if calc.rem(i, q) == 0 {
        block-colors.at(int(i / q))
      } else {
        c-gray
      }
      rect((x, y-bit), (x + cell-w, y-bit + cell-h), fill: fill-col, stroke: 0.7pt + black)
      content((x + cell-w / 2, y-bit + cell-h / 2), text(font: "DejaVu Sans Mono", size: 7.5pt)[#codes.at(i)])
    }

    let offsets = ("offset: 0 bit", "offset: 12 bit", "offset: 25 bit")
    for b in range(3) {
      let x-pos = b * q * cell-w
      content((x-pos, y-bit + cell-h + 0.22), anchor: "west", text(
        size: 7.5pt,
        weight: "bold",
        fill: luma(60),
      )[#offsets.at(b)])
    }

    content((-1.25, y-skip + box-h / 2), anchor: "east", [
      *skip table* \ #text(size: 7.5pt, fill: luma(90))[(campioni)]
    ])
    let skip-entries = (
      "idx 0 (val 1) → 0",
      "idx 3 (val 10) → 12",
      "idx 6 (val 120) → 25",
    )

    for b in range(3) {
      let target-x = (b * q) * cell-w + cell-w / 2
      let box-x = target-x - box-w / 2
      rect((box-x, y-skip), (box-x + box-w, y-skip + box-h), fill: block-colors.at(b), stroke: 0.7pt + black)
      content((target-x, y-skip + box-h / 2), text(size: 8pt)[#skip-entries.at(b)])
      line(
        (target-x, y-skip + box-h + 0.06),
        (target-x, y-bit - 0.08),
        stroke: (paint: luma(90), thickness: 1pt, dash: "dashed"),
        mark: (end: "stealth", fill: luma(90), scale: 0.6),
      )
    }

    let x-idx6 = 6 * cell-w + cell-w / 2
    let x-idx7 = 7 * cell-w + cell-w / 2
    bezier(
      (x-idx6, y-bit - 0.05),
      (x-idx7, y-bit - 0.05),
      (x-idx6 + 0.2, y-bit - 0.55),
      (x-idx7 - 0.2, y-bit - 0.55),
      stroke: (paint: rgb("#c0392b"), thickness: 1pt),
      mark: (end: "stealth", fill: rgb("#c0392b"), scale: 0.5),
    )
    content((x-idx7 + 0.1, y-bit - 0.52), anchor: "west", text(size: 7.5pt, fill: rgb("#c0392b"))[
      *Accesso a `idx 7`*: salto a offset 25 bit \ e decodifica di $7 \bmod 3 = 1$ elemento
    ])
  })
]

#note[
  La medesima tecnica può essere impiegata per ricavare l'$i$-esimo elemento, sebbene il suo utilizzo principale resti legato a campionamenti statistici e misurazioni di prestazione.
]

=== Architettura fisica dell'indice su disco
Un indice invertito completo (come quello adottato dai motori di ricerca su larga scala) è costituito dai seguenti componenti logici memorizzati su disco:

#align(center)[
  #image("../assets/architettura_indice.png")
]

Per recuperare la lista di affissione:
1. Si individua il termine, se ne estrae l'id (rango) tramite la mappa;
2. Dal rango si ottiene il puntatore al valore più vicino;
3. i accede all'indice per avviare la lettura sequenziale.

#note[
  Nei sistemi distribuiti o frammentati (es. architetture Web), l'indice è suddiviso in più porzioni, rendendo necessario coordinare molteplici liste di puntatori.
]

== Information Retrieval System (IRS)

Formalmente, un Information Retrieval System è modellato come una *funzione di ranking* che mappa una coppia di documento e query in un numero reale:
$ R : D times Q -> RR $
Dove $D$ è la collezione documentale e $Q$ l'insieme delle interrogazioni. Il sistema assegna a ogni documento un *punteggio di pertinenza*:

- un punteggio *nullo* ($0$) indica estraneità e il documento viene scartato;
- i punteggi *positivi* definiscono la graduatoria (*rango*) dei risultati.

Il linguaggio di interrogazione $Q$ è composto da atomi (stringhe) combinati tramite *operatori logici*:
- Congiunzione: $q_0 and q_1$
- Disgiunzione: $q_0 or q_1$
- Negazione: $not q$

=== Semantica Insiemistica

La semantica delle query *booleane* si basa sugli insiemi di documenti:

- La semantica di un termine base $["Termine"]$ corrisponde alla sua lista di affissioni (l'insieme dei documenti in cui compare). Se il termine non è indicizzato, restituisce l'insieme vuoto.

#note[
  - $[q_0 or q_1] = [q_0] union [q_1]$

  - $[q_0 and q_1] = [q_0] inter [q_1]$

  - $[not q] = D \\ [q]$ (Complemento rispetto all'intera collezione)

  #align(center)[
    #image("../assets/semantica_insiemistica.png")
  ]
]

=== TAAT vs DAAT

Le strategie implementative fondamentali per la risoluzione delle query si dividono in due categorie:

1. *TAAT (Term-At-A-Time):*
  - Elabora *un termine alla volta*, esaminando per intero la sua posting list prima di passare al termine successivo e accumulando i risultati intermedi (usa quindi le intersezioni *eager*).
  #note[ Ottimale per collezioni di piccole dimensioni, come nel caso di cataloghi di biblioteche. ]

2. *DAAT (Document-At-A-Time):*
  - Risolve la query valutando un documento alla volta attraverso tutte le liste coinvolte. È un approccio intrinsecamente *pigro* (lazy) che esegue il minimo sforzo computazionale indispensabile.
  - Nei motori Web moderni è lo standard obbligato per abilitare tecniche di terminazione precoce (*early termination*).

#align(center)[
  #image("../assets/taat_vs_daat.png")
]

== Valutazione Eager (Solerte)

Nella valutazione eager (solerte) si alloca esplicitamente un vettore in memoria per calcolare e memorizzare l'intero risultato della computazione.

- *Complemento (NOT):* Si alloca un vettore della dimensione dei documenti esclusi (meno i documenti di $[q]$)e si compila con il set complementare.

#align(center)[
  #image("../assets/eager_not.png")
]

- *Intersezione (AND):* Si confrontano gli indici mediante un merge lineare in tempo $O(n + |[q]|)$.

#align(center)[
  #image("../assets/eager_and_merge.png")
]

- *Caso ottimizzato (Lista corta + Lista lunga):* Se una lista è notevolmente più ridotta dell'altra, si preferisce effettuare una ricerca dicotomica (binaria) degli elementi della lista corta all'interno di quella lunga.

#align(center)[
  #image("../assets/corta_lunga.png")
]

=== Galloping Search

La *galloping search* è una variante della ricerca binaria ottimizzata per sfruttare la vicinanza locale dei risultati sul bordo sinistro:

- Si parte dall'inizio dell'array procedendo a passi di ampiezza raddoppiata (galoppo) fino a superare il valore di interesse.

- Raggiunto il limite, si effettua una ricerca ristretta (es. lineare o binaria) nell'intervallo circoscritto.

#align(center)[
  #image("../assets/galloping.png")
]

=== Ottimizzazione delle intersezioni multiple

Quando si elaborano congiunzioni multiple, la strategia ottimale prevede di:

1. Ordinare le liste in ordine crescente di frequenza (lunghezza).

2. Partire dalla lista più corta per filtrare progressivamente i candidati tramite argomenti sempre più restrittivi.

3. Posticipare il lavoro oneroso sulle liste dense solo quando il numero di candidati residui è ridotto al minimo.

#align(center)[
  #image("../assets/intersezioni_multiple.png")
]

=== Unione (OR) con Coda di Priorità (Min-Heap)

Per l'unione di più liste ordinate si utilizza un *k-way merge* basato su una coda di priorità indiretta (*min-heap*).

#align(center)[
  #image("../assets/or_kway_merge.png")
]

== Valutazione Lazy (Pigra)

Nell'approccio lazy l'insieme dei risultati non viene precalcolato. Si utilizzano iteratori dotati di operatori di avanzamento (`next`) e di salto (`skip`) per produrre i risultati in modo incrementale.

- *COMPLEMENTO (NOT) lazy:* Iteratore con operatore `next` che calcola pigramente il complemento a partire da un contatore iniziale.

#align(center)[
  #image("../assets/lazy_not.png")
]

- *UNIONE (OR) lazy:* Coda di priorità indiretta basata su iteratori `next` anziché su vettori statici.

- *INTERSEZIONE (AND) lazy (Minimo dei maggioranti / Min-Mag):* Si sfruttano iteratori con `next` e `skip` (replica semi-pigra).

#align(center)[
  #image("../assets/lazy_and_skip.png")
]

- *Algoritmo greedy:* Dato un candidato iniziale $x$ ricavato dalla prima lista, si invocano i minimi dei maggioranti sulle altre liste. Se i puntatori convergono sullo stesso documento $z$, questo viene emesso; in caso contrario, il processo riparte aggiornando il candidato con il nuovo massimo riscontrato.

#align(center)[
  #image("../assets/lazy_and_flusso.png")
]

#note[
  *Punto chiave:* Grazie all'operatore `skip`, anche saltando porzioni consistenti di liste, si preserva l'invariante di correttezza senza perdere alcun documento valido.
]

== Implementazione dei Skip su Operazioni Composte

L'integrazione dell'operazione di `skip` sulle strutture composte gestisce i salti in base alla gerarchia degli operatori logici:

- *Skip su congiunzioni (AND / link-sections):* Per effettuare uno *skip-to* non è necessario saltare in parallelo su tutte le liste. Si avanza in modo lazy il candidato (o l'iteratore) per cui il salto è più efficiente; raggiunto il nuovo valore, si riavvia l'algoritmo di allineamento (Min-Mag), che riallinea gli iteratori delle altre liste.

- *Skip su disgiunzioni (OR):* Si applica il salto sulla lista in cima all'heap (*top*) fino a quando il suo valore soddisfa la soglia richiesta.

#align(center)[
  #image("../assets/skip_or.png")
]

- *Skip su negazioni (NOT):* L'iteratore del complemento viene adattato per avanzare direttamente oltre il punto saltato.

#align(center)[
  #image("../assets/skip_not.png")
]

#align(center)[
  #image("../assets/albero_query_skip.png")
]

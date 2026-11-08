#import "../template.typ": *

= Compressione di grafi

Per parlare di compressione di un grafo, assumiamo di numerare i suoi nodi da $0$ a $n - 1$. Dato un nodo $x$, l'operazione fondamentale che richiediamo alla nostra struttura dati è la restituzione della lista dei suoi successori (ovvero i nodi a cui $x$ punta). Abbiamo due modalità d'uso principali per l'accesso ai dati: chiedere i successori di un nodo qualunque (accesso casuale) oppure scorrere l'intero grafo nodo per nodo (accesso sequenziale).

#note()[
  Le strutture succinte (ovvero strutture dati compresse che permettono di interrogare i dati senza prima doverli decomprimere interamente) sono molto utilizzate perché oggi il collo di bottiglia principale dell'hardware è il tempo di accesso alla memoria. Il costo computazionale di un algoritmo, infatti, risiede quasi interamente nello spostamento dei dati verso la cache. Con le strutture succinte, l'ingombro spaziale si riduce drasticamente: la parte più rilevante dei dati riesce a risiedere direttamente nella memoria cache, riducendo gli accessi alla memoria principale (RAM) e rendendo la struttura nettamente più prestante rispetto a una classica implementazione ridondante.
]

Esaminiamo le possibili rappresentazioni del grafo:
- La classica rappresentazione tramite *liste di adiacenza* non è assolutamente adatta in questo contesto, poiché non sfrutta adeguatamente la cache disperdendo i dati in memoria.
- È possibile adottare una *rappresentazione compressa per righe* (CSR - _Compressed Sparse Row_), che costituisce una struttura immutabile. Non è necessario memorizzare esplicitamente i gradi dei nodi, poiché risultano impliciti negli offset, garantendo un ingombro ridotto. Funziona bene su grafi di grandi dimensioni, ma per un crawl del web molto esteso richiede ancora troppa memoria RAM; su architetture a 64 bit, in particolare, non è sostenibile.

#example(title: "Rappresentazione di un grafo: Adiacenza vs CSR")[
  Consideriamo un piccolo grafo orientato con 4 nodi ($0, 1, 2, 3$):
  
  #align(center)[
    #fletcher.diagram(
      node-stroke: 1pt,
      edge-stroke: 1pt,
      fletcher.node((0,0), "0", radius: 1.2em),
      fletcher.node((2,0), "1", radius: 1.2em),
      fletcher.node((2,1.5), "2", radius: 1.2em),
      fletcher.node((0,1.5), "3", radius: 1.2em),
      fletcher.edge((0,0), (2,0), "->"), // 0 -> 1
      fletcher.edge((0,0), (0,1.5), "->"), // 0 -> 3
      fletcher.edge((2,0), (2,1.5), "->"), // 1 -> 2
      fletcher.edge((2,0), (0,1.5), "->"), // 1 -> 3
      fletcher.edge((0,1.5), (2,1.5), "->") // 3 -> 2
    )
  ]
  
  Le liste di adiacenza sarebbero:
  $0 -> [1, 3] quad 1 -> [2, 3] quad 2 -> [] quad 3 -> [2]$
  
  Nella *struttura CSR* comprimiamo tutto in due soli array contigui. L'array `Edges` contiene i successori concatenati, l'array `Offsets` indica dove inizia la lista di ciascun nodo.
  
  #align(center)[
    #grid(
      columns: (auto, auto),
      gutter: 20pt,
      table(
        columns: 6,
        align: center,
        stroke: none,
        [*Indice*], [0], [1], [2], [3], [4],
        table.hline(),
        [*Edges*], [1], [3], [2], [3], [2]
      ),
      table(
        columns: 6,
        align: center,
        stroke: none,
        [*Nodo $i$*], [0], [1], [2], [3], [*4*],
        table.hline(),
        [*Offsets*], [0], [2], [4], [4], [5]
      )
    )
  ]
]

#warning()[
  La numerazione scelta per i nodi è fondamentale: l'ordine dei vertici determina l'efficacia della compressione.
]

#example()[
  Se l'ordinamento è casuale, i successori di un nodo risultano dispersi. Numerando ad esempio le pagine secondo l'ordine lessicografico degli URL, le pagine appartenenti allo stesso sito o alla medesima gerarchia si troveranno contigue, raggruppando così le pagine della stessa sezione.
]

La maggior parte dei collegamenti sul web è di tipo *navigazionale* (ovvero punta a risorse interne allo stesso sito); tale riordinamento ha quindi riscontro pratico. L'obiettivo è fare in modo che la differenza numerica tra nodi adiacenti sia minima, concentrando la maggioranza dei link entro intervalli molto ristretti.

Ordinando per URL, possiamo quindi memorizzare le differenze tramite la tecnica degli scarti (*gap*).

== Gli scarti

#informally(title: "Indurre correlazione")[
  In questo modo stiamo *inducendo correlazione*, facendo sì che i gap tra nodi collegati siano molto piccoli.
]

Se un nodo punta ai successori $10, 11, 15$, non memorizziamo questi tre numeri, ma memorizziamo il primo e poi gli scarti: $10, 1, 4$. 

#example(title: "Calcolo degli scarti (Gap Encoding)")[
  #align(center)[
    #table(
      columns: 7,
      align: center,
      stroke: (x, y) => if y == 0 { none } else { 0.5pt },
      [*Originale*], [10], [11], [15], [22], [23], [24],
      [*Gap*], [*10*], [*+1*], [*+4*], [*+7*], [*+1*], [*+1*]
    )
  ]
]

Primo tentativo: uso di codici a byte di lunghezza variabile (rappresentazione binaria a gruppi di 7 bit con un bit di continuazione). Sebbene si induca correlazione, questa soluzione risulta poco efficiente poiché si sprecano bit con frequenza elevata (es. per il valore 1 si spreca un intero byte).

#example(title: "CSR compresso con codici a byte")[
  Concateniamo le liste codificate in un unico vettore di byte. Poiché gli offset ora conteggiano i byte e non il numero di successori, se vogliamo calcolare il grado di un nodo in tempo costante dobbiamo memorizzarlo esplicitamente nei primi byte di ogni lista.
]

Una soluzione migliore consiste nell'usare *flussi di bit* con codifica $gamma$: le liste vengono disposte in sequenza continua all'interno di un unico flusso. Essendo gli offset monotoni crescenti, possiamo memorizzarli in modo compatto ed efficiente interrogandoli in tempo $O(1)$ tramite la struttura di *Elias-Fano*.

#note()[
  È fondamentale non memorizzare i puntatori in forma esplicita, altrimenti il loro costo in byte supererebbe quello dell'intera rappresentazione compressa.
]

#warning(title: "Grafi sparsi e mancanza di correlazione")[
  Nel caso di grafi con indici sparsi, qualunque metodo presenta un costo elevato; come evidenziato nei benchmark, la lista esplicita può risultare addirittura la più economica. È indispensabile indurre correlazione, altrimenti le tecniche di compressione perdono efficacia.
]

Seconda idea per migliorare la compressione: sfruttare *consecutività* e *somiglianza*.
- *Consecutività:* presenza di sequenze di successori con indici contigui (ottenibili mediante un ordinamento opportuno).
- *Somiglianza:* nodi vicini presentano liste di adiacenza simili (situazione tipica per pagine web che condividono menu di navigazione, barre laterali, piè di pagina, ecc.).

Sfruttare unicamente gli scarti valorizza la consecutività, ma trascura la somiglianza. In realtà, consecutività e somiglianza rappresentano lo stesso fenomeno sotto prospettive diverse: considerando le adiacenze come barre verticali e orizzontali nella matrice di adiacenza, nel grafo trasposto le due proprietà si scambiano di ruolo. Qualunque compressione avanzata deve perciò integrare entrambi gli aspetti.

#note()[
  La presenza di gap ridotti implica che molti nodi contigui avranno liste di adiacenza simili tra loro.
]

Risolta la località tramite gli scarti, resta da gestire la similarità tra liste.

== Codifica per riferimenti (Copy Lists)

L'approccio consiste nell'individuare una *lista di riferimento* tra quelle precedenti (per convenzione si considerano solo i predecessori nell'ordinamento).

#example(title: "Liste differenziali")[
  La lista del nodo 1003 può essere espressa come variazione differenziale rispetto alla lista del nodo 1002.
  
  #align(center)[
    #table(
      columns: 7,
      align: center,
      stroke: none,
      [*Nodo Ref (1002)*], [15], [18], [19], [20], [25], [ ],
      [*Nodo Target (1003)*], [15], [18], [ ], [20], [25], [30],
      table.hline(),
      [*Codifica Differenziale*], 
      table.cell(colspan: 2)[*Copy* $2$], 
      table.cell(colspan: 1)[*Skip* $1$], 
      table.cell(colspan: 2)[*Copy* $2$], 
      table.cell(colspan: 1)[*Add* $30$]
    )
  ]
]

Le liste vengono quindi memorizzate come varianti di liste già note. In concreto, per memorizzare il nodo 1003 si conservano un riferimento al nodo 1002 e le liste differenziali dei nodi rimossi e aggiunti. La decodifica avviene tramite una classica operazione di fusione (*merge*).

#note()[
  Tutte le liste devono rimanere rigorosamente ordinate, altrimenti le operazioni di fusione risulterebbero troppo onerose.
]

Per scendere al di sotto di un bit per elemento, al posto di memorizzare flag binari espliciti si sfrutta l'alternanza di lunghi tratti di inclusioni ed esclusioni nella lista differenziale. Scrivere le lunghezze di questi blocchi tramite codifica $gamma$ è conveniente, specialmente in presenza di intervalli lunghi, alternando sequenze di elementi da saltare e sequenze da copiare.

La scelta del nodo di riferimento avviene empiricamente selezionando il candidato che garantisce il miglior guadagno (approccio *greedy*).

#note()[
  Una finestra di ricerca troppo ampia migliora il tasso di compressione, ma penalizza sia la velocità di compressione sia l'accesso casuale: sorgono effetti negativi sulle prestazioni della cache, poiché riferimenti distanti causano frequenti cache miss.
]

#warning(title: "Profondità delle catene")[
  Cosa accade se le catene di riferimenti diventano troppo profonde? Senza un vincolo esplicito possono crescere indefinitamente. In lettura sequenziale l'impatto è trascurabile, ma nell'accesso casuale il degrado prestazionale è inaccettabile. Si definisce quindi una *lunghezza massima* della catena: superata tale soglia, il nodo viene codificato in modo autonomo senza riferimenti.
]

Fissato il raggio $R$, l'algoritmo greedy può compiere scelte subottime: se il riferimento migliore porta a una catena troppo lunga, si potrebbe trovare un ottimo globale esaminando l'intero albero delle dipendenze, ma con il vincolo sulle catene il problema diventa computazionalmente intrattabile.

= Grafo aleatorio orientato e Label Propagation

#theorem(title: "Limite spaziale asintotico")[
  Per una struttura succinta, lo spazio teorico si attesta nell'ordine di:
  $ mg(log(n)^2) / mo(m) quad text("bit per arco") $
]

#note()[
  Nel web la distribuzione dei gradi uscenti (*out-degree*) differisce notevolmente da quella dei gradi entranti (*in-degree*, ovvero la popolarità del sito). Esiste quindi un divario marcato di comprimibilità tra il grafo diretto e il suo trasposto.
]

#note()[
  Wikipedia risulta particolarmente complessa da comprimere poiché i suoi collegamenti sono di natura semantica anziché navigazionale.
]

== Riordinare i nodi

È preferibile adottare metodi di ordinamento indipendenti dal dominio applicativo (senza vincolarsi alla sola struttura lessicografica degli URL), ricorrendo ad algoritmi di clustering su grafi. L'obiettivo consiste nell'organizzare la matrice di adiacenza affinché la densità degli archi si concentri in blocchi lungo la diagonale principale. Tuttavia, i classici algoritmi di clustering non scalano su dimensioni dell'ordine di decine di miliardi di vertici.

L'algoritmo impiegato è la **propagazione di etichette** (*Label Propagation*):
1. Inizialmente a ogni nodo viene assegnata un'etichetta univoca pari al proprio indice.
2. A ogni iterazione, esaminando i nodi in ordine casuale, ciascun vertice assume l'etichetta maggioritaria tra i suoi vicini (risolvendo eventuali parità in modo casuale).
3. L'algoritmo è fortemente parallelizzabile e prosegue fino a convergenza o al raggiungimento di un criterio di arresto.
4. Infine, si applica una permutazione al grafo numerando in modo consecutivo i nodi appartenenti al medesimo cluster, concentrando gli archi in blocchi compatti attorno alla diagonale. Minime correlazioni statistiche iniziali vengono rapidamente amplificate dalla regola di maggioranza, portando a una convergenza veloce.

#example(title: "Effetto della Label Propagation sulla Matrice di Adiacenza")[
  #let on = rect(width: 12pt, height: 12pt, fill: eastern, stroke: 0.5pt + luma(200))
  #let off = rect(width: 12pt, height: 12pt, fill: none, stroke: 0.5pt + luma(200))
  
  #align(center)[
    #grid(
      columns: 2,
      gutter: 40pt,
      [
        *Prima dell'ordinamento* \ _(Archi dispersi, pessima compressione)_
        #v(5pt)
        #grid(
          columns: 6,
          off, on, off, off, on, off,
          off, off, off, on, off, on,
          on, off, off, off, off, off,
          off, on, off, off, off, on,
          off, off, on, off, off, off,
          on, off, off, on, off, off,
        )
      ],
      [
        *Dopo Label Propagation* \ _(Archi densi lungo la diagonale)_
        #v(5pt)
        #grid(
          columns: 6,
          on, on, off, off, off, off,
          on, on, on, off, off, off,
          off, on, on, off, off, off,
          off, off, off, on, on, off,
          off, off, off, on, on, on,
          off, off, off, off, on, on,
        )
      ]
    )
  ]
]
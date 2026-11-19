#import "../template.typ": *

= Compressione di grafi

Per parlare di compressione di un grafo, assumiamo di numerare i suoi nodi da $0$ a $n - 1$. Dato un nodo $x$, l'operazione fondamentale che richiediamo alla nostra struttura dati è la restituzione della *lista ordinata* dei suoi successori (ovvero i nodi a cui $x$ punta). Abbiamo due modalità d'uso principali per l'accesso ai dati: chiedere i successori di un nodo qualunque (accesso casuale) oppure scorrere l'intero grafo nodo per nodo (accesso sequenziale, tipico di PageRank, centralità e visite).

#note()[
  Le strutture succinte (ovvero strutture dati compresse che permettono di interrogare i dati senza prima doverli decomprimere interamente) sono molto utilizzate perché oggi il collo di bottiglia principale dell'hardware è il tempo di accesso alla memoria. Il costo computazionale di un algoritmo, infatti, risiede quasi interamente nello spostamento dei dati verso la cache. Con le strutture succinte, l'ingombro spaziale si riduce drasticamente: la parte più rilevante dei dati riesce a risiedere direttamente nella memoria cache, riducendo gli accessi alla memoria principale (RAM) e rendendo la struttura nettamente più prestante rispetto a una classica implementazione ridondante.
]

Esaminiamo le possibili rappresentazioni del grafo:
- La classica rappresentazione tramite *liste di adiacenza* non è assolutamente adatta in questo contesto, poiché alloca un oggetto separato per nodo (raggiunto da un puntatore da 8 byte), generando miliardi di allocazioni sparse e non sfruttando adeguatamente la cache.
- È possibile adottare una *rappresentazione compressa per righe* (CSR - _Compressed Sparse Row_), che costituisce una struttura immutabile con sole due allocazioni contigue. La lista di $x$ va da `offset[x]` a `offset[x + 1] - 1`: non è quindi necessario memorizzare esplicitamente i gradi dei nodi, poiché risultano impliciti come differenza tra offset consecutivi (`offset[x + 1] - offset[x]`), garantendo un ingombro ridotto. Funziona bene su grafi di grandi dimensioni, ma richiede $m$ successori da 32 bit (o 64 bit se $n > 2^(32)$) più $n + 1$ offset da 64 bit, ovvero *32 o 64 bit per arco*: per un crawl del web molto esteso (es. crawl europeo 2015: $n approx 1.07$ miliardi di pagine, $m approx 91.8$ miliardi di link, pari a $367$ GB di successori più $8.6$ GB di offset) richiede ancora troppa memoria RAM; su architetture a 64 bit, in particolare, non è sostenibile.

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
  
  Nella *struttura CSR* comprimiamo tutto in due soli array contigui. L'array `Edges` contiene i successori concatenati, l'array `Offsets` (lungo $n + 1$) indica dove inizia la lista di ciascun nodo.
  
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

La maggior parte dei collegamenti sul web è di tipo *navigazionale* (ovvero punta a risorse interne allo stesso sito: menu, indici, pagine sorelle); tale riordinamento ha quindi riscontro pratico. L'obiettivo è fare in modo che per molti archi $x -> y$ la differenza $|x - y|$ sia minima (*località* / _locality_), concentrando la maggioranza dei link entro intervalli molto ristretti.

Ordinando per URL, possiamo quindi memorizzare le differenze tramite la tecnica degli scarti (*gap*).

== Gli scarti

#informally(title: "Indurre correlazione")[
  In questo modo stiamo *inducendo correlazione*, facendo sì che i gap tra nodi collegati siano molto piccoli.
]

Se un nodo $x$ punta ai successori ordinati $y_0 < y_1 < dots < y_(d-1)$ (es. $10, 11, 15$), non memorizziamo direttamente i valori, ma il primo e poi gli scarti $y_k - y_(k-1)$: $10, 1, 4$. Per sfruttare ancora meglio la località, nella pratica il primo successore si scrive come differenza $y_0 - x$ dal nodo stesso; poiché questo scarto può essere negativo, si rimappano gli interi alternandoli in positivi:
$ 0, -1, 1, -2, 2, -3, dots mapsto 1, 2, 3, 4, 5, 6, dots $
in modo che tutti gli scarti risultino strettamente positivi.

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

Primo tentativo: uso di codici a byte di lunghezza variabile (_variable-byte_: rappresentazione binaria a gruppi di 7 bit con un bit di continuazione). Il vantaggio è che la decodifica a byte interi è semplice e veloce; tuttavia, sebbene si induca correlazione, questa soluzione risulta poco efficiente poiché si sprecano bit con frequenza elevata (es. per lo scarto $1$, frequentissimo, si spreca un intero byte).

#example(title: "CSR compresso con codici a byte")[
  Concateniamo le liste codificate in un unico vettore di byte. Poiché gli offset ora conteggiano i byte e non il numero di successori, se vogliamo calcolare il grado di un nodo in tempo costante dobbiamo memorizzarlo esplicitamente nei primi byte di ogni lista. In questo modo sappiamo quanti scarti leggere, e per scorrere il grafo sequenzialmente gli offset non servono nemmeno.
]

Una soluzione migliore consiste nell'usare *flussi di bit* con codifica $gamma$: le liste vengono disposte in sequenza continua all'interno di un unico flusso (con offset espressi in bit). Sugli interi positivi $v$, il codice $gamma$ richiede $2 floor(log v) + 1$ bit (così lo scarto $1$ costa un solo bit); poiché il grado scritto in testa a ogni lista può essere $0$, lo si codifica aumentato di uno. Essendo gli offset monotoni crescenti, possiamo memorizzarli in modo compatto ed efficiente interrogandoli in tempo $O(1)$ tramite la struttura di *Elias-Fano*: con $u$ bit totali di liste e $n$ nodi bastano $ceil(log(u / n)) + 2$ bit per nodo (sul crawl 2015, circa $9$ bit per nodo, pari a $1.2$ GB).

#align(center)[
  #image("/assets/flusso_bit.png", width: 90%)
]

#note()[
  È fondamentale non memorizzare i puntatori in forma esplicita, altrimenti il loro costo in byte supererebbe quello dell'intera rappresentazione compressa.
]

#warning(title: "Grafi sparsi e mancanza di correlazione")[
  Nel caso di grafi con indici sparsi, qualunque metodo presenta un costo elevato; come evidenziato nei benchmark, la lista esplicita può risultare addirittura la più economica. È indispensabile indurre correlazione, altrimenti le tecniche di compressione perdono efficacia.
]

Seconda idea per migliorare la compressione: sfruttare *consecutività* e *somiglianza*.
- *Consecutività:* presenza di sequenze di successori con indici contigui (scarti uguali a $1$, ottenibili mediante un ordinamento opportuno).
- *Somiglianza:* nodi vicini presentano liste di adiacenza simili (situazione tipica per pagine web che condividono menu di navigazione, barre laterali, piè di pagina, ecc.).

Sfruttare unicamente gli scarti valorizza la consecutività, ma trascura la somiglianza (ogni lista ripete in gran parte la precedente). In realtà, consecutività e somiglianza rappresentano lo stesso fenomeno sotto prospettive diverse: considerando le adiacenze come barre orizzontali (consecutività) e verticali (somiglianza) nella matrice di adiacenza, nel grafo trasposto $G^T$ le due proprietà si scambiano di ruolo (scarti piccoli in un grafo corrispondono a liste simili nel suo trasposto). Qualunque compressione avanzata deve perciò integrare entrambi gli aspetti.


#align(center)[
  #image("/assets/consecutività_somiglianza.png")
]

#note()[
  La presenza di gap ridotti implica che molti nodi contigui avranno liste di adiacenza simili tra loro.
]

Risolta la località tramite gli scarti, resta da gestire la similarità tra liste.

== Codifica per riferimenti (Copy Lists)

L'approccio consiste nell'individuare una *lista di riferimento* tra quelle precedenti: per la lista di $x$ si sceglie la lista di $x - r$ con un piccolo $r >= 1$ (per convenzione si considerano solo i predecessori nell'ordinamento; $r = 0$ indica nessun riferimento).

#example(title: "Liste differenziali")[
  La lista del nodo 11 può essere espressa come variazione differenziale rispetto alla lista del nodo 10.
  
  #align(center)[
    #table(
      columns: 7,
      align: center,
      stroke: none,
      [*Nodo Ref (10)*], [15], [18], [19], [20], [25], [ ],
      [*Nodo Target (11)*], [15], [18], [ ], [20], [25], [30],
      table.hline(),
      [*Codifica Differenziale*], 
      table.cell(colspan: 2)[*Copy* $2$], 
      table.cell(colspan: 1)[*Skip* $1$], 
      table.cell(colspan: 2)[*Copy* $2$], 
      table.cell(colspan: 1)[*Add* $30$]
    )
  ]
]

Le liste vengono quindi memorizzate come varianti di liste già note. In concreto, per memorizzare il nodo $x$ si scrivono: il grado e $r$ (in $gamma$, aumentati di uno poiché possono valere $0$), una *lista di copia* (_copy list_: un bit per ogni successore del riferimento, `1` se presente anche in $x$, `0` se escluso) e i *successori aggiuntivi* (i successori di $x$ non copiati, codificati con gli scarti). La decodifica avviene tramite una classica operazione di fusione (*merge*) tra elementi copiati dal riferimento ed elementi aggiuntivi.

#align(center)[
  #image("/assets/riferimenti.png", width: 130%)
]

#note()[
  Tutte le liste devono rimanere rigorosamente ordinate, altrimenti le operazioni di fusione risulterebbero troppo onerose.
]

Per scendere al di sotto di un bit per elemento, al posto di memorizzare flag binari espliciti si sfrutta l'alternanza di lunghi tratti di inclusioni ed esclusioni nella lista di copia (*blocchi di copia*). Scrivere le lunghezze di questi blocchi tramite codifica $gamma$ è conveniente specialmente in presenza di intervalli lunghi: per convenzione si parte *sempre* con un blocco da copiare (che può essere $0$, quindi in $gamma$ si scrive aumentato di uno), alternando poi sequenze di elementi da saltare e sequenze da copiare. Quando i tratti sono molto corti, i blocchi possono però costare più della lista di copia esplicita.

#align(center)[
  #image("/assets/blocchi_copia.png", width: 120%)
]

La scelta del nodo di riferimento avviene empiricamente fissando una *finestra* $W$: si provano le $W$ liste precedenti (più $r = 0$, nessun riferimento) selezionando il candidato che garantisce la codifica più corta (approccio *greedy*).

#note()[
  Una finestra di ricerca $W$ troppo ampia migliora di solito il tasso di compressione, ma penalizza sia la velocità di compressione sia l'accesso casuale: sorgono effetti negativi sulle prestazioni della cache, poiché riferimenti distanti causano frequenti cache miss.
]

#warning(title: "Profondità delle catene")[
  Cosa accade se le catene di riferimenti diventano troppo profonde? Senza un vincolo esplicito possono crescere indefinitamente. In lettura sequenziale l'impatto è trascurabile (basta tenere in memoria le ultime $W$ liste decodificate), ma nell'accesso casuale il degrado prestazionale è inaccettabile poiché tocca decodificare molte liste in cascata. Si definisce quindi il *lunghezza massima* $R$ delle catene: il compressore non usa riferimenti che la superano (regolando così il compromesso tra spazio e velocità; con $R = infinity$ si comprime al massimo ma l'accesso diretto può diventare lentissimo).
]
#align(center)[
  #image("/assets/catene_riferimenti.png", width: 70%)
]

Fissata la lunghezza massima $R$, l'algoritmo greedy lista per lista può compiere scelte subottime (al punto che allargare la finestra $W$ può persino peggiorare la compressione): se il riferimento migliore porta a una catena troppo lunga, si potrebbe trovare un ottimo globale esaminando l'intero albero delle dipendenze, ma con il vincolo sulle catene il problema diventa computazionalmente intrattabile.

= Grafo aleatorio orientato e Label Propagation

Un grafo orientato con $n$ nodi e $m$ archi è uno dei $binom(n^2, m)$ grafi possibili; per codificarne uno scelto casualmente servono quindi $log binom(n^2, m)$ bit totali.

#theorem(title: "Limite spaziale asintotico (grafo aleatorio)")[
  Quando $m << n^2$, usando l'approssimazione $binom(n^2, m) approx n^(2m) / m! approx (n^2 e / m)^m$, lo spazio teorico per un grafo aleatorio si attesta nell'ordine di:
  $ log binom(n^2, m) approx m (log(n^2 / m) + log e) quad \ ==> quad mg(log(n^2 / m)) + log e approx mg(log(n^2 / m)) + 1.44 quad "bit per arco" $
]

Sul crawl europeo 2015 il limite per un grafo aleatorio sarebbe circa $25$ bit per arco; il grafo del web è però lontanissimo da un grafo aleatorio: con un buon ordinamento scende a *$0.90$ bit per arco* ($3.6%$ del limite aleatorio), occupando circa *$10$ GB invece di $367$ GB* (l'intero web di un continente sta in memoria su un portatile).

#note()[
  Nel web la distribuzione dei gradi uscenti (*out-degree*) differisce notevolmente da quella dei gradi entranti (*in-degree*, ovvero la popolarità del sito). Esiste quindi un divario marcato di comprimibilità tra il grafo diretto e il suo trasposto: il trasposto del crawl 2015 si comprime addirittura a *$0.72$ bit per arco*, perché le pagine principali di un sito sono puntate da moltissime pagine consecutive.
]

#note()[
  Non tutti i grafi si comprimono come il web (che resta sotto i $2$ bit per arco): i grafi degli *host* (un nodo per sito) richiedono $3$–$7$ bit/arco, mentre le *reti sociali* (es. Facebook $12.3$, Twitter $13.9$ bit/arco) e *Wikipedia* ($11$–$13$ bit/arco, circa il $67%$ del limite aleatorio) risultano particolarmente complesse da comprimere poiché i loro collegamenti sono di natura semantica anziché navigazionale (c'è poca ridondanza; in ordine alfabetico dei titoli Wikipedia andrebbe ancora peggio).
]

#align(center)[
  #image("/assets/confronto_grafi.png", width: 80%)
]

== Riordinare i nodi

È preferibile adottare metodi di ordinamento indipendenti dal dominio applicativo (senza vincolarsi alla sola struttura lessicografica degli URL), ricorrendo ad algoritmi di clustering su grafi. L'obiettivo consiste nell'organizzare la matrice di adiacenza affinché la densità degli archi si concentri in blocchi lungo la diagonale principale (e, con un *clustering gerarchico*, ordinare ricorsivamente anche all'interno di ciascun cluster). Tuttavia, i classici algoritmi di clustering non scalano su dimensioni dell'ordine di decine di miliardi di vertici.

L'algoritmo impiegato è la *propagazione di etichette* (*Label Propagation*):
1. Inizialmente a ogni nodo viene assegnata un'etichetta univoca pari al proprio indice; gli archi del grafo vengono considerati *senza verso*.
2. A ogni iterazione, esaminando i nodi in ordine casuale, ciascun vertice assume l'etichetta maggioritaria tra i suoi vicini (in caso di parità, se può mantiene la propria etichetta, altrimenti sceglie casualmente).
3. L'algoritmo è fortemente parallelizzabile e prosegue fino a convergenza (nessun nodo cambia etichetta) o al raggiungimento di un criterio di arresto.
4. Infine, si applica una permutazione al grafo numerando in modo consecutivo i nodi appartenenti al medesimo cluster, concentrando gli archi in blocchi compatti attorno alla diagonale. Minime correlazioni statistiche iniziali vengono rapidamente amplificate dalla regola di maggioranza, portando a una convergenza veloce.

#align(center)[
  #image("/assets/label_propagation.png", width: 50%)
]

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
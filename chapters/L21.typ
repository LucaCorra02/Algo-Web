#import "../template.typ": *

== Compressione di grafi

Per parlare di compressione numeriamo i nodi da $0$ a $n - 1$ e, dato un nodo $x$, richiediamo la lista dei suoi successori. Abbiamo due modalità d'uso principali: chiedere i successori di un nodo qualunque oppure scorrere l'intero grafo.

#note()[
  Le strutture succinte sono molto utilizzate perché oggi il collo di bottiglia principale è il tempo di accesso alla memoria: il costo computazionale risiede quasi interamente nello spostamento dei dati verso la cache. Con le strutture succinte la parte più rilevante dei dati risiede in cache, riducendo gli accessi alla memoria principale e rendendo la struttura più prestante rispetto a una ridondante.
]

- La classica rappresentazione tramite liste di adiacenza non è adatta, poiché non sfrutta adeguatamente la cache.
- È possibile adottare una rappresentazione compressa per righe (CSR), che costituisce una struttura immutabile. Non è necessario memorizzare i gradi dei nodi, poiché risultano impliciti negli offset, garantendo un ingombro ridotto. Funziona bene su grafi di grandi dimensioni, ma per un crawl del web molto esteso richiede ancora troppa memoria RAM; su architetture a 64 bit non è sostenibile.

#warning()[
  La numerazione scelta per i nodi è fondamentale: l'ordine dei vertici determina l'efficacia della compressione.
]

#example()[
  Se l'ordinamento è casuale, i successori di un nodo risultano dispersi. Numerando ad esempio le pagine secondo l'ordine lessicografico degli URL, le pagine appartenenti allo stesso sito o alla medesima gerarchia si troveranno contigue, raggruppando così le pagine della stessa sezione.
]

La maggior parte dei collegamenti sul web è di tipo navigazionale (ovvero punta a risorse interne allo stesso sito); tale riordinamento ha quindi riscontro pratico. L'obiettivo è fare in modo che la differenza numerica tra nodi adiacenti sia minima, concentrando la maggioranza dei link entro intervalli molto ristretti.

Ordinando per URL, possiamo quindi memorizzare le differenze tramite la tecnica degli scarti (*gap*).

=== Gli scarti

#note()[
  In questo modo stiamo *inducendo correlazione*, facendo sì che i gap tra nodi collegati siano molto piccoli.
]

Primo tentativo: uso di codici a byte di lunghezza variabile (rappresentazione binaria a gruppi di 7 bit con un bit di continuazione). Sebbene si induca correlazione, questa soluzione risulta poco efficiente poiché si sprecano bit con frequenza elevata.

#example()[
  CSR compresso

  Concateniamo le liste codificate in un unico vettore di byte. Poiché gli offset ora conteggiano i byte e non il numero di successori, se vogliamo calcolare il grado di un nodo in tempo costante dobbiamo memorizzarlo esplicitamente nei primi byte di ogni lista.
]

Una soluzione migliore consiste nell'usare flussi di bit con codifica $gamma$: le liste vengono disposte in sequenza continua all'interno di un unico flusso. Essendo gli offset monotoni crescenti, possiamo memorizzarli in modo compatto tramite Elias-Fano.

#note()[
  È fondamentale non memorizzare i puntatori in forma esplicita, altrimenti il loro costo supererebbe quello dell'intera rappresentazione.
]

#warning()[
  Nel caso di grafi con indici sparsi, qualunque metodo presenta un costo elevato; come evidenziato nei benchmark, la lista esplicita può risultare addirittura la più economica. È indispensabile indurre correlazione, altrimenti le tecniche di compressione perdono efficacia.
]

Seconda idea: sfruttare **consecutività** e **somiglianza**.
- *Consecutività:* presenza di sequenze di successori con indici contigui (ottenibili mediante un ordinamento opportuno).
- *Somiglianza:* nodi vicini presentano liste di adiacenza simili (situazione tipica per pagine web che condividono menu di navigazione, barre laterali, piè di pagina, ecc.).

Sfruttare unicamente gli scarti valorizza la consecutività, ma trascura la somiglianza. In realtà consecutività e somiglianza rappresentano lo stesso fenomeno sotto prospettive diverse: considerando le adiacenze come barre verticali e orizzontali nella matrice di adiacenza, nel grafo trasposto le due proprietà si scambiano di ruolo. Qualunque compressione avanzata deve perciò integrare entrambi gli aspetti.

#note()[
  La presenza di gap ridotti implica che molti nodi contigui avranno liste di adiacenza simili tra loro.
]

Risolta la località, resta da gestire la similarità tra liste.

=== Codifica per riferimenti

L'approccio consiste nell'individuare una lista di riferimento tra quelle precedenti (per convenzione si considerano solo i predecessori nell'ordinamento).

#example()[
  La lista del nodo 1003 può essere espressa come variazione differenziale rispetto alla lista del nodo 1002.
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

Cosa accade se le catene di riferimenti diventano troppo profonde? Senza un vincolo esplicito possono crescere indefinitamente. In lettura sequenziale l'impatto è trascurabile, ma nell'accesso casuale il degrado prestazionale è inaccettabile. Si definisce quindi una *lunghezza massima* della catena: superata tale soglia, il nodo viene codificato in modo autonomo senza riferimenti.

Fissato il raggio $R$, l'algoritmo greedy può compiere scelte subottime: se il riferimento migliore porta a una catena troppo lunga, si potrebbe trovare un ottimo globale esaminando l'intero albero delle dipendenze, ma con il vincolo sulle catene il problema diventa computazionalmente intrattabile.

== Grafo aleatorio orientato

Per una struttura succinta lo spazio teorico si attesta nell'ordine di $log(n)^2 / m$.

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
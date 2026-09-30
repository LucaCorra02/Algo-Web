#import "../template.typ": *

= La coda degli Host

Un altro problema in un crawler è il ruolo della *concorrenza*. Vogliamo *scaricare contemporaneamente da più siti*. Per farlo, si istanziano molti *flussi* (*fetching thread*) di esecuzione, nell'ordine delle *migliaia*, che si occupano di scaricare i dati. Questi thread saranno sempre occupati in attività di *I/O*.

Le pagine scaricate verranno poi analizzate da un gruppo di thread molto più ridotto, i *parsing thread*. Questi ultimi estraggono gli URL, che passano attraverso un filtro (il crivello) e la frontiera, per poi essere inseriti nella *coda degli host*, da cui i *fetching thread* preleveranno i prossimi indirizzi da visitare.

#warning(title: "Risoluzione DNS")[
  In questo schema di base, non stiamo tenendo conto della risoluzione del DNS. Sono i *parsing thread* a delegare la risoluzione (in un processo asincrono a parte). Finché l'indirizzo IP associato a un URL non è noto tramite il DNS, l'URL non può essere inserito nella frontiera per il download.
]

== Risoluzione: struttura dati

#warning(title: "Vincolo fondamentale")[
  Al di là delle politiche di gentilezza, non possiamo permetterci che *due flussi accedano allo stesso sito* contemporaneamente. In quanto il server remoto potrebbe non essere in grado di gestire più connessioni simultanee, e potremmo essere *bloccati* o *banditi*.
]

Il problema si risolve *riorganizzando* gli URL che escono dal crivello, con due componenti:

- Una *coda con priorità* (min-priority queue) contenente i *siti noti* al crawler. A ogni sito si assegna come priorità il *primo istante di tempo* in cui è possibile scaricare dal sito senza violare le politiche di gentilezza. La coda restituisce gli elementi in *ordine inverso*: in cima alla coda c'è il *minimo* (il sito scaricabile da più tempo).

- Per *ogni sito*, una *coda* di URL (una *FIFO* nel caso di una visita in ampiezza). Quando degli URL vengono emessi dal crivello, vengono *accodati alla coda associata al loro sito*.


#note(title: "Il concetto di Token")[
  Questo meccanismo rende automatica l'esclusività del download tra *flussi concorrenti*: gli elementi della coda agiscono come *token*. Quando un sito è in cima alla coda (cioè il suo timestamp è superato), il thread che lo estrae prende "in possesso" il token per scaricare da quel sito per una quantità limitata di tempo.
]


#figure(
  caption: [La coda degli host: la priorità di ogni host è il primo istante in cui può essere visitato, ognuno ha la propria coda FIFO di URL.],
)[
  #cetz.canvas({
    import cetz.draw: *

    content((1.2, 6.5), text(size: 8pt)[*Coda con priorità* (min in cima)])
    content((6.2, 6.5), text(size: 8pt)[*Coda FIFO di URL*])

    let hosts = (
      ("host A", "t = 10", ("a1", "a2", "a3")),
      ("host B", "t = 12", ("b1", "b2")),
      ("host C", "t = 15", ("c1",)),
    )

    for (i, h) in hosts.enumerate() {
      let y = 5 - i * 1.6
      rect((0, y), (2.4, y + 1.1), radius: 0.12, fill: rgb("fff0f0"), stroke: 1pt + gray)
      content((1.2, y + 0.55), text(size: 8pt)[#h.at(0) \ #h.at(1)])
      line((2.4, y + 0.55), (3.2, y + 0.55), stroke: 1pt + gray, mark: (end: "stealth"))
      for (j, u) in h.at(2).enumerate() {
        rect((3.3 + j * 1.2, y + 0.2), (4.3 + j * 1.2, y + 0.9), radius: 0.08, fill: rgb("fffcc7"), stroke: 1pt + black)
        content((3.8 + j * 1.2, y + 0.55), text(size: 8pt)[#u])
      }
    }

    rect((-4.8, 4.95), (-2.4, 6.15), radius: 0.12, fill: luma(96%), stroke: 1pt + gray)
    content((-3.6, 5.55), text(size: 8pt)[*Thread* \ di download])
    line((0, 5.85), (-2.4, 5.85), stroke: 1pt + gray, mark: (end: "stealth"))
    content((-1.2, 6.15), text(size: 7pt)[estrae])
    line((-2.4, 5.25), (0, 5.25), stroke: 1pt + gray, mark: (end: "stealth"))
    content((-1.2, 4.95), text(size: 7pt)[riaccoda])
  })
]

Ogni flusso (thread) del crawler procede iterativamente come segue:
+ *Estrae il sito in cima alla coda*, eventualmente aspettando il tempo necessario a far sì che la cima sia scaricabile.

+ *Scarica una o più risorse* dalla coda di URL di quel sito.

+ *Riaccoda il sito* modificandone la priorità in maniera adeguata alla politica di gentilezza (per esempio, impostando la priorità all'istante di tempo *corrente più un intervallo prefissato*).

#example(title: "Esempio di funzionamento")[
  Supponiamo di essere all'istante $10$ e la coda contiene $A$ (priorità $10$), $B$ ($12$), $C$ ($15$), con intervallo prefissato di $4$.

  + Un thread estrae $A$, che è scaricabile subito.
  + Scarica una risorsa da $A$ e riaccoda $A$ con priorità $10 + 4 = 14$.
  + La coda ora è: $B$ ($12$), $A$ ($14$), $C$ ($15$). Un altro thread libero estrae $B$, aspettando se necessario fino all'istante $12$.

  Mentre $A$ "riposa", nessun altro thread può toccarlo: è fuori dalla coda.
]

=== Correttezza

Il meccanismo garantisce due cose: che si scarichi quando si può, e che la politeness non venga mai violata.

#proof(title: "La cima della coda è scaricabile se e solo se c'è qualcosa da scaricare")[
  Se c'è un URL disponibile per lo scaricamento, il sito associato deve essere nello stato "pronto per lo scaricamento prima del tempo corrente". Quindi:
  - o quel sito è *in cima alla coda*;
  - oppure in cima alla coda c'è un sito che era pronto ancora *prima* (la coda è ordinata per priorità).

  In ogni caso, *la cima della coda è scaricabile*. è possibile scaricare un URL *se e solo se la cima della coda è scaricabile*.
]

=== Gestione degli indirizzi IP condivisi (Virtual Hosting)

Un problema può sorge quando più *host logici* sono appoggiati sullo *stesso* indirizzo *IP fisico*. Per evitare di sovraccaricare il server fisico, si utilizza una *coda a tre livelli*:
1. Coda ordinata per *Indirizzo IP* e timestamp.

2. In ognuno di questi oggetti IP, è presente una coda di priorità contenente gli *Host*.

3. Ognuno di questi Host possiede la propria coda (tipicamente FIFO) di URL da scaricare.

La min-priority sulla quale è organizzata la struttura tiene conto del *massimo* tra il timestamp dell'IP e il timestamp dell'Host:
$
  "priorità"("IP") = max("istante dell'IP", "istante del sito in cima alla sua coda")
$
In questo modo si può visitare un sito *solo se* è arrivato il momento di scaricare sia dal sito stesso, sia dal suo indirizzo IP.


=== Ottimizzazioni e Parametri di Crawling

È fortemente consigliato inserire una *cache* tra i parsing thread e il crivello/frontiera per memorizzare gli URL già visitati. Se un URL è in cache, si evita di riprocessarlo, migliorando notevolmente le performance (ricordando che i DNS vanno comunque risolti in via preliminare).

Durante il crawling è fondamentale configurare diversi parametri e filtri:
- *Limiti di frontiera:* Massimo numero di pagine inseribili in frontiera o scaricabili globalmente.

- *Limiti per host:* Massimo numero di URL scaricabili per singolo host e *profondità massima* (numero di livelli di link) da non superare. Questo serve a raccogliere le pagine più rilevanti e ad evitare le cosiddette *spider trap* (trappole infinite). Se un host si comporta in modo anomalo, può essere inserito in *black list*.
- *Filtri distribuiti
:* In ogni passaggio di dati deve esserci un filtro. Si decide cosa inserire in frontiera, cosa scaricare e cosa scartare. I filtri nei *parsing thread* possono analizzare il *contenuto* della pagina; negli altri stadi (es. crivello) i filtri si basano esclusivamente sull'URL.

= Tecniche di programmazione concorrente lock-free

L'accesso alla coda degli host diventa un collo di bottiglia all'aumentare delle dimensioni. L'estrazione da una coda di priorità richiede tempo logaritmico ($O(log n)$). Con un'elevata concorrenza (migliaia di thread), l'uso di semafori o sezioni critiche (mutua esclusione) causerebbe enormi ritardi e forte *contesa* (contention).

Per risolvere il problema si adottano tecniche di programmazione *lock-free*. L'idea è sbarazzarsi dei semafori sfruttando istruzioni hardware elementari offerte direttamente dalla CPU, che garantiscono l'atomicità di operazioni complesse.
Una struttura lock-free non garantisce che il *singolo* thread faccia progresso (wait-freedom), ma garantisce un *progresso globale del sistema*: se il mio thread fallisce un'operazione, significa con certezza che un altro thread l'ha completata con successo.

#informally(title: "Primitive Hardware")[
  Storicamente si usava la *Test-and-Set*, che controlla e imposta atomicamente un bit bloccando il bus di memoria. Nei sistemi moderni si utilizza la *CAS (Compare-And-Swap)*, una sua evoluzione multi-bit.
]

La primitiva CAS prende tre argomenti: un indirizzo in memoria `p`, un valore atteso `a` e un nuovo valore `b`. Sostituisce il valore in `p` con `b` *solo se* il valore attuale è `a`, e restituisce un booleano per confermare l'esito.

#example(title: "Inserimento lock-free in lista concatenata (Algoritmo di Harris)")[
  Per inserire un nodo `n` dopo un nodo `p` senza usare semafori, non possiamo usare l'assegnazione classica perché due thread sovrascriverebbero i puntatori. Utilizziamo invece la CAS in un ciclo:

  #pseudocode(
    no-lines: true,
    [`do`],
    indent[`t <- p.next`],
    indent[`n.next <- t`],
    [`while !CAS(&p.next, t, n)`],
  )
  In ogni istante la lista si trova in uno stato coerente e la lettura non necessita di sincronizzazione.
]

*Exponential Backoff:* Per evitare che troppi thread falliscano ripetutamente la CAS affollando la memoria, si adotta una tecnica di attesa esponenziale: un thread che fallisce attende un tempo via via maggiore prima di riprovare.

#note(title: "Struttura ibrida")[
  Spesso si inserisce una struttura lock-free (es. *ConcurrentLinkedQueue* di Michael e Scott) come "cuscinetto" tra la vera coda degli host e i fetching thread. In questo modo i flussi scaricano dalla struttura lock-free riducendo la contention sulla struttura dati principale.
]

= Tecniche a posteriori per trovare pagine simili

Nella fase *post-crawl*, sorge la necessità di individuare documenti quasi identici. Il calcolo dell'indice di Jaccard (un valore tra 0 e 1) su miliardi di documenti a coppie è *computazionalmente ineseguibile*.
Il documento viene prima ridotto in *shingles* (n-grammi di parole o elementi sintattici).

Entra in gioco il metodo matematico del *MinHash* introdotto da Broder:

#theorem(title: "Teorema di Broder")[
  Immaginiamo una matrice sparsa documenti-shingle (1 se lo shingle è nel documento, 0 altrimenti). Se permutiamo casualmente le righe della matrice e definiamo come $h(d_i)$ l'indice della prima riga in cui il documento $d_i$ presenta un 1, allora la probabilità che due documenti abbiano lo stesso primo 1 è esattamente uguale all'indice di Jaccard tra i due documenti:
  $P[h(d_i) = h(d_j)] = J(d_i, d_j)$
]

Poiché permutare una matrice gigante è impossibile, si approssima la permutazione utilizzando funzioni di hash indipendenti $H_k$:
$ P [ min_(s in d_i) (H_k(s)) = min_(s in d_j) (H_k(s)) ] approx J(d_i, d_j) $

*Il processo operativo:*
1. Si definiscono $K$ funzioni di hash diverse.
2. Per ogni documento, si passano tutti i suoi shingle in queste funzioni, conservando solo il *valore minimo* ottenuto per ciascuna funzione.
3. Il documento (che prima era un testo lunghissimo) viene così sintetizzato in un piccolo vettore di dimensione $K$ (il vettore *signature* di MinHash).
4. Per stimare la similarità di Jaccard tra due documenti, basta contare quante posizioni hanno lo stesso valore nei rispettivi vettori e dividere per $K$.

Per evitare di dover comunque confrontare tutti i vettori a coppie ($O(n^2)$), si utilizza successivamente il *Locality Sensitive Hashing (LSH)* (Non approfondito).

= Crawling Distribuito

Per scalare le prestazioni, si utilizzano molti agenti (slave) che si occupano di fare crawling contemporaneamente. Il problema principale è dividere il web in "partizioni" senza che gli agenti si sovrappongano e scarichino le stesse pagine.

Esistono varie architetture:
- *Macchina centrale:* Un nodo distribuisce il carico dinamicamente. Rischioso perché costituisce un *Single Point of Failure (SPOF)*.
- *Divisione per IP:* Gli indirizzi IP vengono assegnati agli agenti. Molto rischioso perché la risoluzione IP di un host può cambiare nel tempo o distribuirsi su CDN.
- *Divisione per Host (Hash mod N):* Si estrae l'host dall'URL, se ne calcola un hash e si divide per il numero di macchine attive ($"Hash"("host") space mod space N$).

#warning(title: "Il problema del modulo")[
  L'approccio $mod N$ ha un difetto critico: se una macchina fallisce o se ne aggiunge una nuova (quindi $N$ cambia in $N-1$ o $N+1$), quasi tutti gli URL cambieranno assegnazione, invalidando le code e le cache locali degli agenti.
]

=== L'approccio Robusto: Hashing per l'assegnamento (Rendezvous Hashing)
Per risolvere il problema dell'assegnazione instabile, si utilizza una funzione di hash a due argomenti $h(u, a)$, dove $u$ è l'URL (o l'host) e $a$ è l'identificativo dell'agente.

L'agente incaricato di scaricare l'URL $u$ sarà quello che minimizza la funzione:
$ "Agente assegnato" = min_(a in A) h(u, a) $

Questa tecnica offre una proprietà fondamentale chiamata *Controvarianza*: se la lista degli agenti attivi $A$ cambia (aggiunta o rimozione di nodi), gli unici URL che cambieranno assegnatario saranno *solo ed esclusivamente* quelli per cui il nuovo nodo produce un valore di hash strettamente minore. Tutte le altre assegnazioni resteranno stabili, minimizzando il rimescolamento dei dati (richiede calcolo proporzionale ad $A$ ma previene il collasso dell'architettura).

#import "../template.typ": *

= Gestione dei quasi-duplicati

Durante il crawling è molto comune imbattersi in pagine *quasi identiche*: varianti dello stesso sito, calendari, gallerie di immagini, ecc. A seconda del tipo di crawling che si sta costruendo, queste pagine andrebbero considerate *duplicate* e non ulteriormente elaborate, per non sprecare banda, spazio su disco e tempo del crawler.

#example(title: "Dipende dall'obiettivo del crawl")[
  Se il crawler *non scarica le immagini*, due pagine di una galleria che differiscono solo per l'immagine mostrata sono di fatto identiche, e vanno trattate come duplicate.

  Se invece le immagini vengono scaricate, le stesse due pagine sono *contenuti diversi*.
]

#note()[
  Non esiste quindi una nozione assoluta di _quasi-duplicato_, essa va *definita* in base a cosa interessa al crawler.
]

== Approccio semplice: normalizzazione e dizionario approssimato

Un modo semplice ma efficace di gestire il problema *in memoria centrale* è il seguente:

+ Si calcola una *forma normalizzata* del testo della pagina, eliminando ad esempio i tag, le date, ecc. In questo modo si tolgono le parti che cambiano da una copia all'altra senza cambiare il contenuto della pagina.

+ Si calcola la *firma* (hash) della forma normalizzata.

+ La si memorizza in un *dizionario approssimato*, come un *filtro di Bloom*. Se la firma era già presente, la pagina è considerata duplicata.

Come per gli URL, i *falsi positivi* del dizionario approssimato (una pagina nuova scambiata per duplicata) sono un prezzo accettabile se la loro probabilità è bassa. Il vantaggio è che l'occupazione di memoria rimane costante.

#warning(title: "Limite del metodo")[
  Con questo approccio due pagine sono duplicate solo se, *dopo la normalizzazione*, il loro testo è identico (hanno la stessa firma). Basta una differenza di poche parole per ottenere una firma completamente diversa.
]

Metodi molto più sofisticati per la rilevazione dei duplicati possono essere usati *offline*, prima dell'indicizzazione, ma non sono adatti al crawling online. Per la gestione online, un metodo efficace è *SimHash*.

== SimHash

*SimHash* è un algoritmo che è stato utilizzato per qualche tempo dal crawler di Google. L'idea alla base è qualla di generare *hash simili* per pagine simili: più precisamente, pagine simili hanno hash a *distanza di Hamming bassa*.

#note(title: "Distanza di Hamming")[
  La distanza di Hamming tra due stringhe binarie della stessa lunghezza è il *numero di posizioni (bit) in cui differiscono*. Ad esempio, $1000$ e $1010$ hanno distanza $1$ in quanto differiscono di $1$ bit.
]

#informally(title: "Hash normale vs SimHash")[
  Se una funzione di hash "classica" è progettata per produrre hash *completamente diversi* anche per input simili, SimHash fa l'opposto: *piccole modifiche al testo producono piccole modifiche all'hash*.

  Per questo si può usare *l'identità di SimHash come definizione di quasi-duplicato*: due pagine con lo stesso SimHash sono quasi-duplicate.
]

=== Calcolo di SimHash

Dati:
- $b$: *bit* dello hash;
- una buona funzione di hash $h$ che mappa *stringhe* in hash di $b$ bit.

#note()[
  A un maggior numero di bit corrisponde una *nozione di somiglianza più accurata*.
]

A questo punto:
+ Il testo della pagina (in *forma normalizzata*) viene trasformato in un *insieme di segnali* $S$. Un modo banale è usare le *parole* del testo come segnali, ma è più accurato considerare gli *$n$-grammi* per $n$ piccolo (tipicamente tra $3$ e $5$).
+ A ogni segnale $s in S$ si associa il suo hash $h(s)$, di $b$ bit.
+ Il SimHash del testo ha il bit $i$ (con $0 <= i < b$) impostato a uno se e solo se
  $ abs(\{ s in S mid(|) "il bit" i "di" h(s) "è uno" \}) > abs(\{ s in S mid(|) "il bit" i "di" h(s) "è zero" \}) $

In altre parole, ogni bit è deciso con un *voto a maggioranza* tra tutti i segnali: il bit $i$ dello SimHash è uno se la maggioranza dei segnali ha un uno in posizione $i$, zero altrimenti.

#note(title: "Casi particolari")[
  - Il confronto è un $>$ *stretto*: in caso di *parità* tra uni e zeri, il bit dello SimHash è $0$.
  - È banale *pesare i segnali*, in modo che alcuni siano più importanti di altri. Invece di contare i segnali, si sommano i loro pesi nel voto.
]

#example()[
  Dato $b=4$, supponiamo che il testo abbia tre segnali $s_1, s_2, s_3$ con hash
  - $h(s_1) = 1010$
  - $h(s_2) = 1100$
  - $h(s_3) = 1001$

  Voto a maggioranza *bit per bit*:
  - bit 0: $1, 1, 1$ $arrow$ tre uni $arrow$ *1*
  - bit 1: $0, 1, 0$ $arrow$ un uno e due zeri $arrow$ *0*
  - bit 2: $1, 0, 0$ $arrow$ un uno e due zeri $arrow$ *0*
  - bit 3: $0, 0, 1$ $arrow$ un uno e due zeri $arrow$ *0*

  Quindi $"SimHash" = 1000$.

  Se provassimo a modificare leggermente il testo in modo che $s_3$ venga sostituito da un nuovo segnale $s_4$ con $h(s_4) = 1011$ I segnali $s_1$ e $s_2$ restano gli stessi. Rifacendo il voto:

  - bit 0: $1, 1, 1$ $arrow$ *1*
  - bit 1: $0, 1, 0$ $arrow$ *0*
  - bit 2: $1, 0, 1$ $arrow$ due uni $arrow$ *1*
  - bit 3: $0, 0, 1$ $arrow$ *0*

  Il nuovo SimHash è $1010$ con una *distanza di Hamming pari a $1$* rispetto al precedente. Cambiando un segnale su tre il risultato cambia di un solo bit.
]

=== Proprietà e utilizzo

- Due documenti con *lo stesso SimHash* sono molto simili.

- Se si permettono *distanze di Hamming superiori*, la somiglianza diventa sempre *meno significativa*.

- Online si potrebbe andare a inserire lo SimHash di ogni pagina scaricata in un *dizionario* (eventualmente approssimato, con un filtro di Bloom): se è già presente, la pagina è un quasi-duplicato.

#note(title: "Trovare hash a breve distanza")[
  Se si vuole ammettere una piccola distanza di Hamming (non solo l'uguaglianza esatta), il problema diventa *trovare elementi a breve distanza di Hamming* in un grande insieme di hash. In letteratura esistono alcune soluzioni, ma non sono banali da implementare.
]

= Gestione della Politeness

Uno dei problemi pratici che rende il crawling *diverso da una semplice visita* di un grafo è la *gentilezza* (_politeness_): non si deve eccedere nella quantità di tempo dedicato allo scaricamento da un *singolo sito*.

#warning(title: "Cosa rischiamo")[
  Se non si rispetta la politeness, in genere si ottengono *email furiose* dai gestori dei siti, oppure il *taglio del traffico dal nostro IP*.
]

== Due modi di limitare il traffico

Ci sono due modi fondamentali di operare questa limitazione:

+ *Limitare il tempo tra una richiesta e l'altra* allo stesso sito.
+ *Limitare la frazione del tempo di scaricamento* rispetto al tempo di non-scaricamento.

=== Intervallo fisso tra le richieste

Fissato un intervallo $t$ (ad esempio, quattro secondi), si deve aspettare $t$ *tra la fine di una richiesta e l'inizio della successiva* per lo stesso sito.

=== Proporzione tra scaricamento e attesa

Si fissano:
- una *proporzione* $p$;
- un *tempo di scaricamento massimo* $s$ (ad esempio, un secondo).

Bisogna fare in modo che la proporzione tra il *tempo di scaricamento* e quello di *non-scaricamento* sia $p$.

Questa condizione contempla anche una *misurazione effettiva* del tempo di scaricamento, perché risorse particolarmente *lente* potrebbero richiedere un tempo maggiore di $s$.

#informally(title: "Perché la seconda è più interessante")[
  La seconda soluzione permette di sfruttare una caratteristica di *HTTP/1.1*: è possibile fare *richieste multiple attraverso la stessa connessione TCP*, evitando la (lenta) apertura e chiusura di una connessione per ogni risorsa scaricata.

  Con la prima soluzione, invece, si dovrebbe aspettare $t$ dopo *ogni singola risorsa*.
]

=== Funzionamento della seconda politica

+ Si aprono la connessione e si scaricano risorse dal sito, una dopo l'altra.
+ Lo scaricamento termina *non appena si supera la soglia $s$*. Il tempo di scaricamento effettivo è $s'$.
+ A questo punto si *aspetta per un tempo* $ (s') / p $ in modo da forzare la gentilezza.

#example(title: "Esempio numerico")[
  Sia $s = 1$ secondo e $p = 1 / 10$.

  Scarichiamo risorse dallo stesso sito finché superiamo $1$ secondo: supponiamo che il tempo effettivo sia $s' = 1.5$ secondi. Dobbiamo allora aspettare $ (s') / p = 1.5 / (1 / 10) = 15 " secondi" $ prima di tornare su quel sito. Nel frattempo il crawler può lavorare su altri siti.

  Se le risorse sono *lente* e $s'$ è più grande, l'attesa cresce di conseguenza: la proporzione rimane rispettata.
]

#note(title: "Cosa significa p")[
  Con questa definizione $p$ è il *rapporto* tra tempo di scaricamento e tempo di attesa, e l'attesa dopo uno scaricamento di durata $s'$ è $s' / p$. Un $p$ più piccolo significa un crawler *più gentile* (attese più lunghe).
]

== Conseguenza: bisogna alterare l'ordine di visita

Per implementare questo tipo di politica è necessario *alterare l'ordine di visita*. Se si visitano gli URL *nell'ordine in cui escono dal crivello*, si potrebbe incorrere in *attese a vuoto consistenti*: ad esempio, molti URL consecutivi dello stesso sito, che dovremmo scaricare uno dopo l'altro aspettando ogni volta, mentre altri siti sarebbero già pronti.

Questo problema, insieme a quello della concorrenza, si risolve con la *coda degli host*.

= La Coda degli Host

== Il problema della concorrenza

Un altro problema lasciato finora in parte da parte è il ruolo della *concorrenza*. Certamente vogliamo *scaricare contemporaneamente da più siti*.

Per farlo, si istanziano molti *flussi* (_thread_) di esecuzione, nell'ordine delle *migliaia*, che si occupano di scaricare i dati. Questi thread saranno sempre occupati in attività di *I/O*.

Le pagine scaricate possono essere poi analizzate da un gruppo di flussi *molto più ridotto*: non è una buona idea avere migliaia di thread con un carico computazionale significativo.

#warning(title: "Vincolo fondamentale")[
  Al di là delle questioni di gentilezza, non possiamo permetterci che *due flussi accedano allo stesso sito* contemporaneamente.
]

== Struttura dati

Il problema si risolve *riorganizzando gli URL che escono dal crivello*, con due componenti:

- Una *coda con priorità* contenente i *siti noti* al crawler. A ogni sito si assegna come priorità il *primo istante di tempo* in cui è possibile scaricare dal sito senza violare le politiche di gentilezza. La coda restituisce gli elementi in *ordine inverso*: in cima alla coda c'è il *minimo* (il sito scaricabile da più tempo).
- Per *ogni sito*, una *coda* di URL (una *FIFO* nel caso di una visita in ampiezza). Quando degli URL vengono emessi dal crivello, vengono *accodati alla coda associata al loro sito*.

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

== Ciclo di un flusso del crawler

Ogni flusso del crawler procede iterativamente come segue:

+ *Estrae il sito in cima alla coda*, eventualmente aspettando il tempo necessario a far sì che la cima sia scaricabile.
+ *Scarica una o più risorse* dalla coda di URL di quel sito.
+ *Riaccoda il sito* modificandone la priorità in maniera adeguata alla politica di gentilezza (per esempio, impostando la priorità all'istante di tempo *corrente più un intervallo prefissato*).

#example(title: "Esempio di funzionamento")[
  Siamo all'istante $10$ e la coda contiene $A$ (priorità $10$), $B$ ($12$), $C$ ($15$), con intervallo prefissato di $4$.

  + Un thread estrae $A$, che è scaricabile subito.
  + Scarica una risorsa da $A$ e riaccoda $A$ con priorità $10 + 4 = 14$.
  + La coda ora è: $B$ ($12$), $A$ ($14$), $C$ ($15$). Un altro thread libero estrae $B$, aspettando se necessario fino all'istante $12$.

  Mentre $A$ "riposa", nessun altro thread può toccarlo: è fuori dalla coda.
]

== Correttezza

Il meccanismo garantisce due cose: che si scarichi quando si può, e che la politeness non venga mai violata.

#proof(title: "La cima della coda è scaricabile se e solo se c'è qualcosa da scaricare")[
  Se c'è un URL disponibile per lo scaricamento, il sito associato deve essere stato *pronto per lo scaricamento prima del tempo corrente*. Quindi:

  - o quel sito è *in cima alla coda*;
  - oppure in cima alla coda c'è un sito che era pronto ancora *prima* (la coda è ordinata per priorità).

  In ogni caso, *la cima della coda è scaricabile*.

  Quindi è possibile scaricare un URL *se e solo se la cima della coda è scaricabile*: basta guardare la cima.
]

#informally(title: "Gli elementi della coda sono dei token")[
  Gli elementi della coda agiscono come *token* che rappresentano l'*autorizzazione a scaricare da un certo sito*.

  Solo un flusso alla volta può avere il token di un certo sito, perché il sito, una volta estratto, non è più in coda finché non viene riaccodato. Questo rende *automatica l'esclusività* del download tra flussi, e le regole di gentilezza *non possono essere violate*.
]

== Costo

Il costo della coda è *logaritmico*: estrarre e reinserire un sito è un'operazione relativamente poco costosa, ma può diventare *problematica in caso di concorrenza intensa*, perché tutti i flussi devono accedere alla stessa coda.

== Politeness sugli indirizzi IP

Se è necessaria una politica di gentilezza da applicare anche agli *indirizzi IP* (più siti possono stare sullo stesso IP), si può organizzare gli IP in una coda come sopra:

- ogni *IP* ha associata una *coda con priorità di host*;
- la priorità di un IP è il *massimo* tra il proprio istante di tempo e quello del sito in cima alla coda associata.

$ "priorità"("IP") = max("istante dell'IP", "istante del sito in cima alla sua coda") $

In questo modo si può visitare un sito *solo se è arrivato il momento di scaricare sia dal sito stesso, sia dal suo indirizzo IP*.

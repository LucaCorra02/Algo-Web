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

Fissato un intervallo $t$ (ad esempio, quattro secondi), si deve aspettare tempo $t$ *tra la fine di una richiesta e l'inizio della successiva* per lo stesso sito.

=== Proporzione tra scaricamento e attesa

Dati:
- una *proporzione* $p$;
- un *tempo di scaricamento massimo* $s$ (ad esempio, un secondo).

Vogliamo fare in modo che la proporzione tra il *tempo di scaricamento* e quello di *non-scaricamento* sia esattamente $p$. Questa condizione richiede anche una *misurazione effettiva* del tempo di scaricamento, in quanto risorse particolarmente *lente* potrebbero richiedere un tempo maggiore di $s$ e devono quindi essere limitate.

#informally(title: "Perché la seconda soluzione è più interessante")[
  La seconda soluzione permette di sfruttare una caratteristica di *HTTP/1.1*: è possibile fare *richieste multiple attraverso la stessa connessione TCP*, evitando la (lenta) apertura e chiusura di una connessione per ogni risorsa scaricata.

  Con la prima soluzione, invece, si dovrebbe aspettare $t$ dopo *ogni singola risorsa*.
]

Il funzionamento di questa politica è il seguente:
+ Si aprono la connessione e si scaricano risorse dal sito, una dopo l'altra.

+ Lo scaricamento termina *non appena si supera la soglia $s$*. Chiamiamo con $s'$ il tempo di scaricamento effettivo.

+ A questo punto, per forzare la gentilezza, si *aspetta per un tempo*:
  $
    (s') / p
  $

  Con questa definizione $p$ è il *rapporto* tra tempo di scaricamento e tempo di attesa. Un $p$ più piccolo significa un crawler *più gentile* (attese più lunghe).

#example(title: "Esempio numerico")[
  Sia $s = 1 "s"$ e $p = 1 / 10$, vogliamo che il tempo di scaricamento sia al massimo un decimo del tempo di inattività.

  A questo punto scarichiamo risorse dallo stesso sito finché non superiamo $1$ secondo. Supponiamo che il tempo effettivo sia $s' = 1.5$ secondi. Il tempo di attesa è pasi a:
  $
    (s') / p = 1.5 / (1 / 10) = 15 " secondi"
  $
  prima di tornare su quel sito. Tuttavia, nel frattempo il crawler può lavorare su altri siti.

  #note()[
    Se le risorse sono *lente* e $s'$ è più grande, l'attesa cresce di conseguenza: la proporzione rimane rispettata.
  ]
]

#warning()[
  Per implementare questo tipo di politica è necessario *alterare l'ordine di visita*. Se si visitano gli URL nell'*ordine in cui escono dal crivello*, si potrebbe incorrere in *attese a vuoto consistenti*: ad esempio, molti URL consecutivi dello stesso sito, che dovremmo scaricare uno dopo l'altro aspettando ogni volta, mentre altri siti sarebbero già pronti.

  Questo problema, insieme a quello della concorrenza, si risolve con la *coda degli host*.
]

#note()[
  Gran parte dei siti web hanno un *file robots.txt* che specifica la politeness desiderata. Tramite l'uso delle clausole "Disallow" e "Allow", si definiscono per ogni User-Agent (crawler) quali path possono essere visitate e quali no, con priorità crescente.
]
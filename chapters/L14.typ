#import "../template.typ": *

= Indici distribuiti e risoluzione delle interrogazioni

Quando le dimensioni di un indice diventano tali da non poter essere gestite su una singola macchina, è necessario *segmentare* (o partizionare) l'indice complessivo in sottoindici più piccoli, detti *segmenti*, distribuiti su più nodi di calcolo. Esistono due criteri principali di partizionamento:

- *Segmentazione documentale:* la collezione dei documenti viene divisa in blocchi (non necessariamente contigui) e a ciascun blocco viene assegnato un segmento che indicizza solo quei documenti. Una volta costruito l'indice (o durante l'indicizzazione distribuita), questo approccio permette di creare segmenti autonomi e ben bilanciati a livello di spazio occupato. Lo stesso termine comparirà in più segmenti, mentre gli *hapax legomena* compariranno in un solo segmento.
- *Segmentazione lessicale:* l'indice viene diviso in base ai termini del vocabolario (ad esempio dividendo l'insieme delle parole in blocchi). La lista di affissione di ciascun termine è interamente contenuta in un unico segmento. Questa strategia permette, ad esempio, di mantenere i termini più frequenti (o più richiesti dalle query) in un segmento caricato in memoria centrale (RAM) e di lasciare quelli meno frequenti su disco. Per risolvere una query è però necessario effettuare un *dispatch* verso il segmento che detiene il termine: per evitare di interrogare inutilmente i segmenti, si utilizzano solitamente dei *dizionari approssimati* (come filtri di Bloom o funzioni di hash con auto-firma) che indicano in modo compatto quali termini appartengono a ciascun segmento.

In linea di principio è possibile combinare le due strategie: ad esempio, applicare prima una segmentazione documentale e poi, all'interno di ciascun segmento, applicare una segmentazione lessicale (o viceversa). Iterando questo processo si ottiene concettualmente un *albero di segmenti*, in cui ogni nodo interno viene ulteriormente partizionato in un sottoalbero di segmenti.

#note()[
  A livello pratico non conviene creare alberi di segmentazione troppo profondi o complessi, poiché i risultati della query devono essere ricostruiti e fusi risalendo dal basso verso l'alto con un notevole overhead. Nell'architettura standard dei motori di ricerca si effettua un *partizionamento documentale* a livello distribuito (tra server diversi), mentre all'interno del singolo server si può sfruttare una *segmentazione lessicale* (per separare in RAM i termini più usati da quelli su disco).
]

Inoltre, quando i documenti sono distribuiti o le liste sono molto lunghe, è utile introdurre una nozione di *importanza statica* dei documenti (indipendente dalla query), così da poter ordinare o filtrare rapidamente i risultati più promettenti.

#warning()[
  Quando risolviamo una query congiunta (`AND`), la cardinalità del risultato (l'intersezione) è minore o uguale alla lunghezza della lista di affissione più corta, ed è spesso drasticamente più piccola delle singole liste: ad esempio, //$|"Romeo" \land \text{"Giulietta"}| \ll |\text{"Romeo"}|$.

  Per questo motivo il *partizionamento lessicale* su server distribuiti è molto inefficiente per le query in `AND`: per calcolare l'intersezione saremmo costretti a trasferire attraverso la rete le intere liste di affissione dei singoli termini (che possono contare milioni di elementi) verso un unico nodo coordinatore. Al contrario, con il *partizionamento documentale*, ogni server calcola localmente l'intersezione sul proprio sottoinsieme di documenti e trasmette in rete solo i pochi documenti sopravvissuti.
]

=== Funzionamento di un'interrogazione (Query Processing)

Nei moderni sistemi di Information Retrieval, la risoluzione di un'interrogazione avviene tipicamente in più fasi (architettura a imbuto o *cascade*):

+ *Estrazione dei candidati (Matching / Filtering):* si interroga l'indice inverso per estrarre rapidamente un buon insieme di documenti candidati, scremando la stragrande maggioranza dei documenti non rilevanti della collezione.
+ *Ordinamento e Scoring (Ranking):* sul sottoinsieme ridotto di candidati così ottenuto, si applicano funzioni di punteggio (basate su modelli algebrici/vettoriali, probabilistici o reti neurali) per ordinare i documenti in base alla loro effettiva aderenza alla query.

Nella valutazione della qualità di un sistema di recupero delle informazioni si considerano due metriche fondamentali:
- *Precisione (Precision):* misura la frazione di documenti effettivamente rilevanti tra quelli restituiti dal sistema (ovvero l'aderenza dei risultati mostrati rispetto alla query).
- *Richiamo (Recall):* misura la frazione di documenti rilevanti trovati dal sistema rispetto al totale dei documenti rilevanti presenti nell'intera collezione.

Ottenere contemporaneamente alta precisione e alto richiamo è molto difficile, poiché le due metriche sono in naturale tensione tra loro:
- È banale ottenere una *precisione massima* ($100\%$): basta essere estremamente conservativi e restituire un unico documento di cui si è certi (o al limite non restituire quasi nulla, perdendo però quasi tutti gli altri documenti utili e azzerando il richiamo).
- È altrettanto banale ottenere un *richiamo massimo* ($100\%$): basta restituire l'intera collezione documentale, includendo però un'enorme quantità di spazzatura e facendo crollare la precisione.

#note()[
  Una *query frasale* composta interamente da *stopword* (come il celebre esempio `"to be or not to be"` oppure `"one of them and"`) è computazionalmente costosissima. Per risolverla, il motore deve infatti intersecare le liste di affissione di tutti i termini e verificare tramite le liste delle posizioni in quali documenti i termini compaiono esattamente in quell'ordine consecutivo.

  Poiché le stopword hanno una frequenza altissima (compaiono in quasi tutti i documenti), le loro liste di affissione sono enormi e anche la loro intersezione documentale non riduce quasi per nulla il numero di candidati da ispezionare.
]

= Ranking e Scoring

Formalmente, dato un insieme di interrogazioni $Q$ e una collezione documentale $D$ di dimensione $N$, un sistema di Information Retrieval utilizza una funzione di punteggio $r: Q times D -> RR$ per valutare i documenti:

- *Scoring (Assegnamento del punteggio):* è il calcolo di un numero reale (*score*) associato a ciascuna coppia $("query" q, "documento" d)$. I documenti con punteggio nullo sono considerati non rilevanti, mentre più il punteggio è alto, maggiore è la rilevanza stimata.
- *Ranking (Ordinamento):* consiste nel mettere in ordine (creare una graduatoria) i documenti rilevanti in base al loro *score* decrescente. In questo modo possiamo restituire all'utente solo i primi $k$ documenti migliori (*top-$k$ retrieval*).

I criteri di scoring e ranking si classificano lungo due dimensioni:

+ *Statici vs Dinamici:*
  - *Statici:* non dipendono dall'interrogazione $q$; il punteggio di ciascun documento è fisso e può essere precalcolato offline (es. l'autorevolezza generale di una pagina web).
  - *Dinamici:* dipendono dall'interrogazione $q$ e misurano quanto il documento sia pertinente rispetto alle parole cercate dall'utente; vanno calcolati al momento della query.

+ *Endogeni vs Esogeni:*
  - *Endogeni:* utilizzano esclusivamente informazioni *interne* al documento stesso, tipicamente il suo contenuto testuale (è l'approccio classico sviluppato fin dagli anni '60-'70 per i sistemi bibliotecari).
  - *Esogeni:* utilizzano informazioni *esterne* al documento, come la struttura del grafo dei collegamenti ipertestuali del Web (ad esempio quante pagine puntano al documento e quanto sono autorevoli, come in PageRank o HITS, ricostruendo parzialmente il grafo del web).

#note()[
  Sia i punteggi endogeni elementari (come il semplice conteggio delle parole) sia i punteggi esogeni ingenui (come contare semplicemente il grado entrante, cioè quante pagine mi citano) sono facilmente manipolabili (*spamming*): nel primo caso basta ripetere centinaia di volte una parola chiave nella pagina (*keyword stuffing*), nel secondo basta creare una rete di pagine artificiali (*bot* o *link farm*) che puntano al proprio sito. Per questo motivo le metriche grezze vanno sempre normalizzate e prese con le pinze.
]

== Punteggi endogeni e modello Bag of Words

I punteggi endogeni classici si basano sul modello *bag of words* ("sacchetto di parole"): un'interrogazione $q$ è vista semplicemente come un insieme (o multi-insieme) di termini, ignorando l'ordine grammaticale e gli operatori booleani. Di norma si adotta un'interpretazione implicita *disgiunta* (`OR`): i documenti candidati sono tutti quelli che contengono *almeno uno* dei termini della query.

Il metodo più primitivo è il semplice *conteggio*: lo score di un documento $d$ è la somma dei conteggi $c_(t, d)$ dei termini della query all'interno di $d$. Tuttavia, questo approccio ha due gravi difetti:
+ Non tiene conto della lunghezza del documento (un documento molto lungo conterrà naturalmente più occorrenze).
+ Non distingue i termini rari e informativi dalle *stopword*: nella query `"Romeo e Giulietta"`, un documento lunghissimo pieno della congiunzione `"e"` otterrebbe un punteggio altissimo pur non parlando della tragedia di Shakespeare.

Per risolvere questi problemi si introducono gli *schemi di pesatura* (*weighting schemes*).

== TF-IDF

Lo schema *TF-IDF* (*Term Frequency / Inverse Document Frequency*) combina due intuizioni complementari:
+ Se un termine della query compare molte volte in un documento $d$, quel documento è probabilmente rilevante (*contributo locale*).
+ Se però quel termine compare in quasi tutti i documenti della collezione, allora ha uno scarso potere discriminante e il suo peso va ridimensionato (*contributo globale*).

  Mentre la frequenza del termine nella collezione è una grandezza *statica* e globale, il peso complessivo assegnato al documento rispetto alla query è *dinamico*. La formula dello score TF-IDF di un documento $d$ rispetto a una query $q$ è:

$
  "TF-IDF"(q, d) = sum_(t in q "cap" d) underbrace(frac(c_(t, d), l_d), "TF") dot underbrace(log frac(N, f_t), "IDF")
$

dove:
- $c_(t, d)$ è il *conteggio* (numero di occorrenze) del termine $t$ nel documento $d$.
- $l_d$ è la lunghezza del documento $d$ (numero totale di token in $d$; in alcune varianti si divide invece per il conteggio massimo tra i termini presenti in $d$).
- $N$ è il numero totale di documenti nella collezione (*corpus*).
- $f_t$ è la *document frequency* del termine $t$, ovvero il numero di documenti della collezione in cui $t$ compare almeno una volta.

Analizziamo i due fattori:
- *TF (Term Frequency), $c_(t, d) / l_d$:* aumenta il peso se il termine è frequente nel documento, ma lo *normalizza* rispetto alla lunghezza $l_d$ per non favorire ingiustamente i documenti lunghi.
- *IDF (Inverse Document Frequency), $log(N / f_t)$:* riduce il peso dei termini molto comuni nel corpus. Dal punto di vista della teoria dell'informazione, poiché $p_t = f_t / N$ è la probabilità empirica che un documento scelto a caso contenga $t$, la quantità $log(N / f_t) = log(1 / p_t)$ rappresenta esattamente il *contenuto informativo* (di Shannon) del termine $t$:
  - Se un termine compare in tutti i documenti ($f_t = N$), allora $N / f_t = 1$ e $"IDF" = log(1) = 0$ (il termine non porta alcuna informazione discriminante, come la `"e"` di `"Romeo e Giulietta"`).
  - Se un termine compare in un solo documento ($f_t = 1$), raggiunge il punteggio massimo $"IDF" = log N$.

#warning()[
  *Assunzione di indipendenza:* Sommando linearmente i punteggi dei singoli termini di $q$, stiamo assumendo implicitamente che i termini della query compaiano nei documenti in maniera *statisticamente indipendente*. Nella realtà i termini sono spesso fortemente correlati: ad esempio, se una query contiene le parole `"cane"` e `"cani"` (o `"calcio"` e `"rigore"`), una volta osservato il primo termine nel documento, il secondo aggiunge pochissima informazione nuova, mentre la formula somma per intero entrambi i contributi.
]

*Rappresentazione in memoria di $l_d$:* Per calcolare TF-IDF (e BM25), le lunghezze $l_d$ di tutti gli $N$ documenti devono risiedere in memoria centrale (RAM). Poiché usare un intero a 32 bit per ciascuno di miliardi di documenti occuperebbe troppa RAM, nella pratica si quantizza la lunghezza in un singolo byte (*intero a 8 bit*), memorizzando una versione compressa in scala logaritmica (ad esempio calcolando il logaritmo della lunghezza e troncando/arrotondando il risultato).

#note()[
  *Osservazioni su TF-IDF:*
  - Gli *hapax legomena* ($f_t = 1$) possiedono il massimo contenuto informativo possibile ($log N$).
  - Poiché un termine fornisce contributo nullo se e solo se non compare nel documento ($c_(t, d) = 0$, escludendo il caso patologico $f_t = N$), la semantica naturale dell'interrogazione è in `OR`: i documenti con score $> 0$ sono tutti quelli che contengono almeno una parola della query.
  - Per calcolare questo score non servono le posizioni: sono sufficienti le liste di affissione contenenti gli identificativi dei documenti e i *conteggi* ($c_(t, d)$), oltre al vettore delle lunghezze $l_d$ in memoria.
]

== BM25

Il limite principale del TF-IDF classico è che il punteggio cresce *linearmente* con il conteggio $c_(t, d)$: un documento che ripete una parola 100 volte ottiene un peso dieci volte superiore a uno che la ripete 10 volte, rendendo la formula troppo sensibile alle ripetizioni e allo spam.

Lo schema *BM25* (*Best Matching 25*, derivato dal modello probabilistico di recupero delle informazioni) risolve questo problema introducendo un effetto di *saturazione* sul conteggio. La formula che assegna il peso a una query $q$ per il documento $d$ è:

$
  "BM25"(q, d) = sum_(t in q "cap" d) frac((1 + k_1) c_(t, d), k_1 (1 - b + b frac(l_d, L)) + c_(t, d)) dot log frac(N - f_t + 1/2, f_t + 1/2)
$

dove:
- $c_(t, d)$ è il conteggio del termine $t$ nel documento $d$, ed $f_t$ è la sua frequenza documentale nel corpus.
- $l_d$ è la lunghezza del documento $d$.
- $L$ è la *lunghezza media* di un documento all'interno dell'intera collezione.
- $k_1 >= 0$ e $b in [0, 1]$ sono due *parametri liberi* (iperparametri) che vanno tarati empiricamente sulla collezione (tipicamente $k_1 in [1.2, 2.0]$ e $b approx 0.75$).

=== Analisi delle componenti di BM25

+ *Componente IDF (a destra, con smoothing di Laplace):*
  Il fattore $log frac(N - f_t + 0.5, f_t + 0.5)$ deriva dal rapporto delle probabilità a posteriori (*odds ratio* con *smoothing* laplaciano $+0.5$ per evitare divisioni per zero).
  Si noti che se un termine compare in più della metà dei documenti della collezione ($f_t > N / 2$), l'argomento del logaritmo diventa minore di $1$ e il punteggio IDF diventa *negativo* (nella pratica, i motori di ricerca troncano il valore a $0$, per cui qualsiasi termine che compare in più di metà dei documenti non vale nulla).

+ *Componente TF e saturazione asintotica (a sinistra):*
  La frazione a sinistra modella l'impatto della frequenza del termine nel documento, ma *non è più lineare* in $c_(t, d)$: cresce in modo monotono ma presenta un *asintoto orizzontale*.
  Infatti, ponendo per semplicità $b = 0$ (oppure un documento di lunghezza esattamente pari alla media, $l_d = L$, per cui la parentesi vale $1$), il termine sinistro diventa:
  $
    frac((1 + k_1) c_(t, d), k_1 + c_(t, d))
  $
  Se facciamo tendere il numero di occorrenze all'infinito ($c_(t, d) -> infinity$), il rapporto $c_(t, d) / (k_1 + c_(t, d))$ tende a $1$, e il peso raggiunge il limite asintotico superiore:
  $
    lim_(c_(t, d) -> infinity) frac((1 + k_1) c_(t, d), k_1 + c_(t, d)) = 1 + k_1
  $
  Questo significa che ripetere un termine continua ad aumentare lo score (non smette mai del tutto di avere importanza), ma con rendimenti marginali decrescenti: oltre una certa soglia di saturazione, aggiungere ulteriori occorrenze non sposta quasi più il punteggio.

+ *Ruolo del parametro $k_1$:*
  Il parametro $k_1$ controlla la velocità con cui si raggiunge la saturazione e l'altezza dell'asintoto ($1 + k_1$), modulando quanto conta il numero di occorrenze del termine:
  - Se $k_1 = 0$: tutta la frazione a sinistra vale $(1 + 0) c_(t, d) / c_(t, d) = 1$ (per $c_(t, d) > 0$). Il conteggio *non ha alcuna rilevanza* (modello binario: conta solo se il termine è presente o assente) e lo score si riduce unicamente alla parte IDF a destra.
  - Se $k_1 -> infinity$: l'asintoto si alza all'infinito e la curva si appiattisce su una retta; il peso diventa *proporzionale (lineare) al conteggio* $c_(t, d)$, tornando al comportamento non saturato di TF-IDF.

// riguardare
+ *Ruolo del rapporto $l_d / L$ e del parametro $b$:*
  Il rapporto $l_d / L$ confronta la lunghezza del documento corrente con la lunghezza media dei documenti della collezione:
  - Se il documento è più lungo della media ($l_d > L$), allora $l_d / L > 1$: il denominatore aumenta e, a parità di occorrenze $c_(t, d)$, lo score si abbassa (perché in un documento lungo è più facile trovare ripetizioni casuali).
  - Se il documento è più corto della media ($l_d < L$), allora $l_d / L < 1$: il denominatore diminuisce e, a parità di occorrenze, lo score aumenta (trovare più volte il termine in un documento breve è un forte segnale di rilevanza).

  Il parametro $b in [0, 1]$ regola quanto questa normalizzazione sulla lunghezza debba incidere:
  - Se $b = 0$: il termine $(1 - b + b (l_d / L))$ diventa $1$. La lunghezza del documento viene completamente ignorata.
  - Se $b = 1$: nella parentesi rimane solo il rapporto $l_d / L$, per cui il termine al denominatore diventa $k_1 (l_d / L)$ e la penalizzazione/premiazione in base alla lunghezza agisce al massimo della sua forza.

== Re-ranking neurale con BERT

Negli architetture moderne, gli algoritmi lessicali veloci come BM25 vengono utilizzati nella prima fase (*first-stage retrieval*) per estrarre rapidamente dall'indice inverso un *pool* ristretto di documenti candidati (ad esempio i primi $100$ o $1000$ documenti).

Su questo insieme ridotto di candidati è possibile applicare una seconda fase di riordinamento (*re-ranking*) molto più accurata ma computazionalmente pesante, basata su modelli di Deep Learning (architetture *Transformer*) come *BERT*.

Il funzionamento (nella configurazione *cross-encoder*) è il seguente:
- Si fornisce in input a BERT la concatenazione della query e del documento candidato, preceduta dal token speciale di inizio sequenza `[CLS]` e separata dal token `[SEP]`:
  `[CLS] query [SEP] documento [SEP]`
- Grazie al meccanismo di *self-attention* bidirezionale, il modello analizza le interazioni semantiche profonde e contestuali tra tutte le parole della query e tutte le parole del documento (superando i limiti del modello *bag of words* e riconoscendo sinonimi, parafrasi e contesto).
- Il vettore di output (*embedding*) associato al token speciale `[CLS]` riassume la relazione globale tra query e documento: facendolo passare attraverso uno strato lineare finale, il modello viene addestrato (*fine-tuned* su grandi dataset di coppie query-documento etichettate) per produrre direttamente uno *score di rilevanza*.
- I documenti candidati vengono infine riordinati in base a questo nuovo punteggio neurale prima di essere presentati all'utente.

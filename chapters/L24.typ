#import "../template.typ": *

= Database Vettoriali

Una rete neuronale trasforma oggetti (testi, immagini, utenti) in vettori di $d$ numeri reali (immersioni / *embedding*), tipicamente con $d = 512$ per le immagini e $d$ tra $384$ e $3072$ per i modelli linguistici. Le applicazioni principali sono la ricerca semantica, i sistemi di raccomandazione, la deduplicazione e il *RAG* (*Retrieval-Augmented Generation*, in cui un modello linguistico recupera documenti pertinenti prima di rispondere).

Il problema di base è il seguente: dati $N$ vettori $x_0, dots, x_(N-1) in RR^d$ (milioni o miliardi) e un'interrogazione (*query*) $q$, trovare i $t$ vettori più vicini a $q$ (*nearest neighbors*).
La soluzione banale consisterebbe nel calcolare tutte le $N$ distanze e tenere le $t$ più piccole, con costo $O(N d)$ per interrogazione: con $N = 10^9$ e $d = 768$, ciò significa circa $7.7 dot 10^(11)$ moltiplicazioni e somme a ogni query, e $10^9 times 768 times 4$ byte $= 3$ TB di RAM solo per memorizzare i vettori. Emerge così una doppia sfida: *quanto spazio occupa ogni vettore* in memoria e *quanti vettori dobbiamo guardare*.

== Distanze e Calcolo a Blocchi

Per definire cosa significa "vicino", si usano tipicamente:
- *Distanza euclidea* (norma 2): $||q - x|| = sqrt(sum_i (q_i - x_i)^2)$
- *Distanza di Manhattan* (norma 1): $||q - x||_1 = sum_i |q_i - x_i|$
- *Prodotto scalare* (inner product): $chevron.l q, x chevron.r = sum_i q_i x_i$ (più è grande, più i vettori sono simili)
- *Somiglianza / distanza del coseno:* $(chevron.l q, x chevron.r) / (||q|| ||x||)$; la distanza del coseno è $1$ meno la somiglianza.

#note()[
  Esiste una stretta relazione tra distanza euclidea, prodotto scalare e coseno: molti modelli producono vettori normalizzati ($||q|| = ||x|| = 1$), per cui vale $||q - x||^2 = 2 - 2 chevron.l q, x chevron.r$ e tutte e tre le misure ordinano i vicini allo stesso identico modo.
]

In pratica lavoreremo quasi sempre con la *distanza euclidea al quadrato* $||q - x||^2$: ordinare i risultati secondo la distanza euclidea o secondo il suo quadrato produce lo stesso ordine, evitando la radice quadrata.

#informally(title: "Calcolo della distanza a blocchi (Associatività)")[
  Se dividiamo le $d$ coordinate di due vettori in $m$ blocchi consecutivi $x = (x^((0)), dots, x^((m-1)))$ e allo stesso modo $q$, possiamo calcolare le distanze su ciascun blocco separatamente e poi sommare i risultati parziali:
  $ ||q - x||^2 = sum_(j < m) ||q^((j)) - x^((j))||^2 $
  Non c'è nessuna magia: sono tutte somme sulle coordinate, quindi è semplicemente l'*associatività della somma* (l'unico trucco è usare il *quadrato* della distanza euclidea per eliminare la radice). La stessa proprietà vale per la distanza di Manhattan, per il prodotto scalare e (per vettori di norma 1) per la distanza del coseno: si può calcolare persino una dimensione alla volta, oppure — come faremo noi — a blocchi di dimensioni combinando poi i risultati. L'intera idea della *quantizzazione dei prodotti* si basa su questa proprietà.
]

#align(center)[
  #image("/assets/distanze_blocchi.png", width: 40%)
]

== Perché gli alberi falliscono in alta dimensione

In 2 o 3 dimensioni il problema si risolve in modo esatto usando *alberi $k$-dimensionali* (*kd-tree*), che permettono di scartare in blocco una regione dello spazio appena si verifica che è sicuramente lontana dall'interrogazione. Questo funziona perché in bassa dimensione un piccolo intorno della query contiene una parte apprezzabile dei punti.

#warning(title: "Maledizione della dimensionalità")[
  In alta dimensione l'approccio ad albero crolla: la sfera inscritta nel cubo $[-1, 1]^d$ ne occupa una frazione di volume che tende rapidamente a $0$ — il *$79%$ per $d = 2$*, lo *$0.25%$ per $d = 10$*, e appena *$2.5 dot 10^(-8)$ per $d = 20$*. Quasi tutto il volume sta negli "angoli", lontano dal centro: un piccolo intorno dell'interrogazione resta quasi vuoto e tutti i punti finiscono a distanze simili tra loro. Già per $d >= 20$ un albero non riesce più a scartare regioni e finisce per visitare quasi tutti i punti.
]

Poiché gli alberi esatti non funzionano, *rinunciamo all'esattezza* (ricerca approssimata) e adottiamo come misura di qualità il *richiamo* (*recall*):
$ "richiamo@"t = (|R ∩ R^*|) / t $
dove $R$ sono i $t$ risultati restituiti e $R^*$ i veri $t$ vicini (es. 9 veri vicini su 10 significa $"richiamo@10" = 0.9$). Tutti i metodi che vedremo hanno parametri che spostano il compromesso tra tre grandezze: *richiamo, velocità e memoria*.

Esistono tre grandi famiglie di metodi (che i sistemi reali combinano fra loro):
- *Partizionare:* dividere lo spazio in celle e guardare solo le celle vicine all'interrogazione (*IVF*, *inverted file*, l'equivalente dell'indice inverso).
- *Comprimere:* rappresentare ogni vettore in pochi byte e calcolare distanze approssimate in maniera rapida (*quantizzazione*).
- *Navigare:* collegare i vettori in un grafo di prossimità e muoversi rapidamente verso l'interrogazione.

== Quantizzazione e Partizionamento (IVF)

L'idea della *quantizzazione* consiste nel sostituire ogni vettore $x$ con un rappresentante vicino. Fissiamo $k$ vettori $c_0, dots, c_(k-1) in RR^d$, detti *centroidi*, che insieme formano il *dizionario* (*codebook*): il quantizzatore sostituisce $x$ con il centroide più vicino $hat(x)$, memorizzandone solo l'indice in $lg k$ bit (es. con $k = 256$ basta $1$ byte per vettore invece di $4 d$ byte).
I punti più vicini a uno stesso centroide formano la sua *cella di Voronoi*: tutti gli elementi nella cella vengono rappresentati dallo stesso indice, con una perdita di precisione perché si usano le coordinate del centroide.

La qualità si misura tramite l'*errore di quantizzazione*, ovvero il valore atteso della distanza al quadrato tra il vettore originale e il suo rappresentante:
$ xi = bb(E)[||x - hat(x)||^2] $

Come scegliamo i centroidi che rendono minimo $xi$ sui nostri dati? Tramite *$k$-means* (*algoritmo di Lloyd*, dove $k$ è il numero di centroidi scelto dall'utente):
1. Si parte da $k$ centroidi scelti a caso fra i dati.
2. *Assegna:* ogni punto va al centroide più vicino (nella sua cella di Voronoi).
3. *Aggiorna:* ogni centroide si sposta nella media dei punti che gli sono stati assegnati.
4. Si iterano i due passi: nessuno dei due può far crescere l'errore, quindi in poche iterazioni ci si ferma in un punto fisso (in generale solo un *minimo locale*). Il costo di un'iterazione è $O(N k d)$.

Una volta trovati $n_"list"$ centroidi con $k$-means, possiamo usarli anche per *partizionare* lo spazio: per ogni cella si mantiene la lista dei suoi vettori (una lista invertita, da cui *IVF*). Quando arriva un'interrogazione $q$, la si confronta con gli $n_"list"$ centroidi e si enumerano i vettori soltanto nelle $n_"probe"$ celle più vicine (es. con $N = 10^6$, $n_"list" = 1000$ e $n_"probe" = 10$ si calcolano circa $11 thin 000$ distanze invece di un milione), riducendo drasticamente i confronti necessari.

#align(center)[
  #image("/assets/ivf_voronoi.png", width: 50%)
]


#note()[
  Questo partizionamento può introdurre errori: il vero vicino più prossimo di $q$ potrebbe trovarsi appena oltre il confine, in una cella di Voronoi che non viene visitata.
]

== Quantizzazione dei Prodotti (Product Quantization, PQ)

Torniamo alla *compressione*. Con $b$ bit per vettore possiamo distinguere $k = 2^b$ centroidi. Un solo byte ($k = 256$) è però troppo poco in alta dimensione (es. in $RR^(128)$ l'errore è enorme): per un errore accettabile servono codici da almeno $64$ bit, cioè $k = 2^(64) approx 1.8 dot 10^(19)$ centroidi — del tutto impossibile da memorizzare, addestrare con $k$-means o interrogare. Serve quindi un modo per avere moltissimi centroidi descrivendone pochissimi.

L'idea della *Quantizzazione dei Prodotti* (PQ) è spezzare il vettore $x$ in $m$ blocchi di $d / m$ coordinate (sottovettori $x^((j)) in RR^(d/m)$) ed eseguire un $k$-means separato con $k$ centroidi in ogni sottospazio, ottenendo $m$ piccoli dizionari $cal(C)_0, dots, cal(C)_(m-1)$. Un vettore $x$ viene codificato da $m$ piccoli indici $(i_x^((0)), dots, i_x^((m-1)))$, dove $i_x^((j))$ è il centroide di $cal(C)_j$ più vicino a $x^((j))$. Il vettore approssimato ricostruito è:
$ hat(x) = (cal(C)_0 [i_x^((0))], dots, cal(C)_(m-1) [i_x^((m-1))]) $

#align(center)[
  #image("/assets/pq_spezzare.png", width: 65%)
]

#informally(title: "Il dizionario implicito a griglia")[
  Combinando i centroidi di ogni blocco in tutti i modi possibili otteniamo il *prodotto cartesiano* $cal(C)_0 times dots times cal(C)_(m-1)$, pari a $k^m$ centroidi impliciti:
- In dimensione $d = 2$ con $m = 2$ blocchi e $k = 4$ valori per asse, otteniamo $4 times 4 = 16$ centroidi memorizzandone solo $4 + 4 = 8$.
- In un caso reale ($d = 128$, $m = 8$ blocchi da $16$ coordinate, $k = 256$): ogni vettore occupa appena *$8$ byte invece di $512$*, e genera $256^8 = 2^(64)$ centroidi impliciti memorizzando solo $m dot k$ sottovettori di $d / m$ numeri, cioè $k d$ numeri in tutto (appena $128$ KB).
]

#align(center)[
  #image("/assets/pq_griglia.jpg", width: 55%)
]

*Addestramento, codifica ed errore:*
- *Addestramento:* $m$ esecuzioni indipendenti di $k$-means su sottovettori di dimensione $d/m$; il costo per iterazione è $m dot O(N k d / m) = O(N k d)$ (lo stesso di un solo $k$-means con $k$ centroidi).
- *Codifica:* per ogni blocco si cerca il centroide più vicino fra $k$, con costo totale $O(k d)$ per vettore.
- *Errore:* poiché il quadrato della distanza si spezza nei blocchi, l'errore totale è semplicemente la somma degli errori nei singoli sottospazi: $xi = sum_(j < m) xi_j$.
- *Taratura:* tipicamente si sceglie $k = 256$ ($1$ byte per indice); aumentare $m$ riduce l'errore al prezzo di più byte per vettore, tarando i parametri sperimentalmente sul richiamo.

#warning(title: "Vincolo di griglia e perdita di correlazione")[
  I centroidi non sono liberi nello spazio, ma costretti a formare una *griglia*, introducendo un'ulteriore perdita di precisione. Inoltre, trattando i blocchi separatamente si perdono le *correlazioni tra coordinate* di blocchi diversi; questo limite si attenua applicando una rotazione ai dati prima di spezzarli.
]

#example(title: "Esempio svolto: codifica PQ in 2 blocchi")[
  Consideriamo 6 vettori in $RR^4$, spezzati in $m = 2$ blocchi da 2 coordinate con $k = 2$ centroidi per blocco: $cal(C)_0 = {(1, 1), (5, 5)}$ e $cal(C)_1 = {(1, 1), (7, 7)}$.
  #align(center)[
    #table(
      columns: 4,
      align: center,
      [*Vettore*], [*Blocco 0*], [*Blocco 1*], [*Codice*],
      [$x_0$], [$(0, 0)$], [$(2, 0)$], [`(0, 0)`],
      [$x_1$], [$(0, 3)$], [$(8, 6)$], [`(0, 1)`],
      [$x_2$], [$(3, 0)$], [$(6, 8)$], [`(0, 1)`],
      [$x_3$], [$(4, 4)$], [$(0, 2)$], [`(1, 0)`],
      [$x_4$], [$(6, 4)$], [$(1, 1)$], [`(1, 0)`],
      [$x_5$], [$(5, 7)$], [$(7, 7)$], [`(1, 1)`],
    )
  ]
  Il dizionario implicito ha $2 times 2 = 4$ centroidi in $RR^4$. *Vantaggio:* miliardi di vettori diventano piccole sequenze di indici. *Svantaggio:* vettori mappati sullo stesso codice (come $x_1$ e $x_2$) diventano indistinguibili tra loro.
]

=== Distanze senza decomprimere (ADC)

Nel database abbiamo memorizzato solo i codici (piccole liste di indici) e i dizionari dei centroidi; quando arriva un'interrogazione $q$, questa è invece esatta. Vorremmo $||q - x||^2$, ma di $x$ conosciamo solo la sua approssimazione $hat(x)$. Ricostruire $hat(x)$ e calcolare la distanza costerebbe ancora $O(d)$ per vettore, senza alcun guadagno di tempo.

Usiamo allora la *distanza asimmetrica* (*ADC*, _Asymmetric Distance Computation_), perché quantizza solo i vettori del database ma *non* l'interrogazione $q$. Spezzando la distanza euclidea al quadrato sugli $m$ blocchi otteniamo:
$ ||q - hat(x)||^2 = sum_(j < m) ||q^((j)) - cal(C)_j [i_x^((j))]||^2 $
Da notare che *$x$ non compare più*: nel blocco $j$, il sottovettore fisso $q^((j))$ può incontrare soltanto i $k$ centroidi di $cal(C)_j$.

All'arrivo di un'interrogazione $q$ procediamo quindi così:
1. *Spezza $q$* nei suoi $m$ blocchi $q^((0)), dots, q^((m-1))$.
2. *Costruisci la tabella delle distanze $T$ ($m times k$):* calcola $T_j [i] = ||q^((j)) - cal(C)_j [i]||^2$ per ogni blocco $j$ e ogni centroide $i$. Costa $m k$ distanze in dimensione $d/m$, cioè $O(k d)$ *una sola volta per interrogazione*, indipendentemente dal numero di candidati. Con $d = 128, m = 8, k = 256$ la tabella ha solo $2048$ numeri ($8$ KB) e sta interamente nella *cache L1* del processore.
3. *Valuta i codici del database:* per ogni codice $(i_x^((0)), dots, i_x^((m-1)))$ non serve più alcun prodotto scalare: bastano *$m$ letture in tabella (table lookup) e $m$ somme*:
   $ ||q - hat(x)||^2 = sum_(j < m) T_j [i_x^((j))] $
   Con $m = 8$, si leggono appena $8$ byte invece di $512$, con costo proporzionale al numero di blocchi $m$.
4. *Seleziona e riordina:* si tengono i migliori candidati tramite una *coda di priorità*. Per compensare eventuali scambi d'ordine tra vettori quasi equidistanti, si recuperano più candidati del necessario e si rileggono i loro vettori esatti (anche da disco) per riordinarli (*re-ranking*).

#align(center)[
  #image("/assets/adc_tabella.png", width: 60%)
]

#note(title: "Errore dell'ADC vs distanza simmetrica (SDC)")[
  Per la disuguaglianza triangolare, l'errore dell'ADC è limitato unicamente dalla distanza tra il vettore e il suo rappresentante, qualunque sia l'interrogazione $q$:
  $ abs(||q - x|| - ||q - hat(x)||) <= ||x - hat(x)|| $
  Se quantizzassimo anche l'interrogazione (*distanza simmetrica*, *SDC*), potremmo usare una tabella fissa tra centroidi senza calcolare nulla a tempo di query, ma il limite sull'errore salirebbe a $||x - hat(x)|| + ||q - hat(q)||$. Inoltre, per trovare i vicini non serve il valore esatto delle distanze: basta conservare l'ordine relativo.
]

#note(title: "Partizionare e comprimere insieme: IVF + PQ")[
  L'ADC è velocissima ma resta comunque lineare ($O(N m)$), perché guarda tutti gli $N$ codici. La si combina quindi con il partizionamento *IVF*: invece di applicare PQ direttamente al vettore $x$, si codifica con PQ il *residuo* $x - c$ (lo spostamento dal centroide $c$ della sua cella di Voronoi), che è più piccolo e si quantizza molto meglio.
  A tempo di interrogazione si eseguono gli ADC solo nelle $n_"probe"$ celle più vicine; attenzione però che *la tabella $T$ va ricalcolata per ogni cella visitata*, poiché cambia il residuo dell'interrogazione $q - c$. Questa combinazione è il celebre indice `IndexIVFPQ` della libreria FAISS.
]

== Navigazione su Grafi (HNSW)

Un'idea diversa rispetto al partizionamento spaziale è cercare camminando su un grafo (*grafo di prossimità*): invece di dividere lo spazio in celle, si costruisce prima e si memorizza un grafo con un nodo per vettore e un arco tra vettori vicini.

La struttura di vicinanza viene esplorata tramite *ricerca avida (greedy)*: partendo da un nodo qualunque, si guardano i suoi vicini e ci si sposta su quello più vicino a $q$; ci si ferma quando nessun nodo adiacente migliora la distanza. Il costo è pari a $("numero di passi") times ("grado")$ distanze. Il limite è che la ricerca greedy può rimanere intrappolata in *minimi locali*, quando il grafo è connesso ma manca una scorciatoia per passare da una regione a un'altra.

#align(center)[
  #image("/assets/greedy_minimo_locale.jpg", width: 60%)
]

=== Dai grafi di Delaunay ai Piccoli Mondi (NSW)

Se il grafo contenesse il *grafo di Delaunay* (ottenuto costruendo le celle di Voronoi su tutti i vettori e collegando punti con celle adiacenti), la ricerca greedy troverebbe *sempre* il vicino esatto. Tuttavia, in alta dimensione il grafo di Delaunay diventa quasi il grafo completo (fino a $Theta(N^2)$ archi), risultando completamente impraticabile.

Serve quindi un *grafo sparso con grado limitato* in cui la ricerca greedy funzioni quasi sempre e in pochi passi, combinando due ingredienti: *archi corti* per la precisione locale e *archi lunghi* (di tutte le scale: molti medi, pochi lunghissimi, nelle giuste proporzioni rispetto alla dimensione dello spazio) per attraversare lo spazio in fretta. È la struttura dei *mondi piccoli* (*small worlds*).

Un modo semplice per costruirli (*Navigable Small World*, NSW) è inserire i vettori uno alla volta in ordine casuale, cercando ogni nuovo vettore nel grafo costruito fin lì e collegandolo ai suoi vicini più prossimi: all'inizio i nodi sono pochi e lontani (si creano archi molto lunghi), poi man mano che il grafo si riempie si aggiungono archi sempre più corti, generando naturalmente archi di tutte le scale.
*Problema:* i primi nodi inseriti accumulano moltissimi archi e il numero di passi cresce come una potenza di $log N$, mentre noi vogliamo $O(log N)$, usando archi lunghi solo all'inizio della ricerca e archi corti alla fine.

=== HNSW (Hierarchical Navigable Small World)

La soluzione applica ai grafi l'idea delle *liste a salti* (*skip list*, dove livelli superiori contengono un sottoinsieme casuale degli elementi del livello sottostante per fare salti lunghi in alto e rifinitura in basso in $O(log N)$ passi attesi):
- *Livello 0:* contiene tutti i vettori collegati in un grafo di prossimità di grado al più $2 M$.
- *Livelli superiori ($l > 0$):* contengono un sottoinsieme casuale dei nodi del livello $l - 1$, con il proprio grafo di prossimità di grado al più $M$. Nei livelli alti i nodi sono pochi e lontani, quindi gli archi sono lunghi.
- Un nodo presente al livello $l$ è presente anche in tutti i livelli sottostanti ($0, dots, l - 1$). Il livello massimo di un nodo si decide *tirando una moneta* al momento dell'inserimento (con probabilità $1/M$ di salire, per cui ogni livello contiene in media un $M$-esimo dei nodi di quello sotto e il numero di livelli è circa $log_M N$: es. con $N = 10^6$ e $M = 16$, circa $5$ livelli) e non cambia mai per tutta la vita dell'indice. Il punto di ingresso è un nodo del livello più alto.

*Ricerca gerarchica:* si entra dal punto di ingresso al livello più alto; in ogni livello sopra lo $0$ si esegue una *ricerca greedy* fino a un minimo locale, che diventa il punto di partenza per il livello immediatamente inferiore. Più si scende, più la ricerca diventa precisa.

#align(center)[
  #image("/assets/hnsw_ricerca.png", width: 70%)
]

*Ricerca a fascio (Beam Search) al livello 0:* al livello $0$, dove si decide la risposta, la ricerca greedy sarebbe troppo fragile. Invece di un solo nodo corrente si tengono i migliori `ef` candidati trovati finora (*ampiezza del fascio*, con `ef` $>= t$):
- A ogni passo si esplorano i vicini del nodo più promettente non ancora esplorato.
- Un vicino entra nel fascio se è più vicino a $q$ del peggiore attualmente nel fascio (o se il fascio non è ancora pieno).
- Questa "nuvoletta" di candidati viaggia verso l'interrogazione riuscendo spesso ad aggirare i minimi locali; ci si ferma quando nessun nodo da esplorare può più migliorare il fascio, restituendo i migliori $t$. Con `ef` $= 1$ si ricade nella semplice ricerca greedy.

*Costruzione ed euristica di selezione dei vicini:*
si inseriscono i vettori uno alla volta: si estrae il livello $l$ del nuovo vettore $x$; dal livello massimo fino a $l + 1$ si fa ricerca greedy per avvicinarsi; da $l$ fino a $0$ si esegue una ricerca a fascio di ampiezza `efConstruction` collegando $x$ ai suoi $M$ vicini (gli archi sono bidirezionali: se un vicino supera il grado massimo, si potano i suoi archi con lo stesso criterio; se $l$ supera il livello massimo attuale, $x$ diventa il nuovo punto di ingresso).

Per scegliere gli $M$ vicini fra i candidati non conviene prendere banalmente i più vicini (che potrebbero stare tutti dalla stessa parte, creando archi ridondanti): si scorrono i candidati dal più vicino e *si accetta un candidato solo se è più vicino a $x$ che a ogni vicino già scelto*. Un candidato "coperto" da un vicino già scelto si scarta (ci si arriva comunque passando da quello), ottenendo archi bilanciati in tutte le direzioni.

#align(center)[
  #image("/assets/hnsw_euristica.png", width: 60%)
]

*Parametri e costi:*
- `M` (tipicamente $16$): numero di archi per nodo; aumentarlo aumenta memoria e precisione. Oltre ai vettori, gli archi occupano circa $2 M$ numeri per nodo.
- `efConstruction`: quanto si cerca in fase di costruzione; più è grande, migliore è il grafo ma più lenta la costruzione.
- `efSearch` (o `ef`): la manopola che a tempo di interrogazione regola il compromesso tra richiamo e velocità.
- In pratica il costo di interrogazione cresce come $O(log N)$.

#warning(title: "Limiti pratici di HNSW")[
- *Memoria:* tutto deve stare in RAM (sia i vettori sia il grafo).
- *Cancellazioni:* eliminare nodi è complicato; si marcano con delle *lapidi* (*tombstones*) e si ricostruisce l'indice periodicamente.
- *Ricerche filtrate:* con filtri sui metadati (es. _"prezzo sotto i 100 euro"_), se molti nodi vengono esclusi la ricerca greedy si blocca e il richiamo crolla.
- *Costruzione lenta:* ogni inserimento richiede una ricerca nel grafo.
]

#note(title: "Mettere insieme le idee e sistemi reali")[
  *Partizionare, comprimere, navigare:* PQ da sola guarda tutti i vettori, mentre HNSW da solo usa molta RAM. Nella pratica le tecniche si combinano:
- *HNSW + PQ:* si naviga il grafo usando distanze PQ compatte, poi si riordinano i migliori candidati con i vettori esatti.
- *DiskANN:* mantiene grafo e vettori esatti su SSD, tenendo solo i codici PQ in RAM per guidare la navigazione.
- *Come scegliere:* con poca memoria e miliardi di vettori convengono *IVF + PQ* o *DiskANN*; con memoria sufficiente e necessità di richiamo alto conviene *HNSW*.
  
  Sistemi e librerie reali che implementano queste tecniche: *FAISS*, *hnswlib*, *ScaNN*, *Lucene / Elasticsearch*, *pgvector*, *Qdrant*.
]
#import "../template.typ": *

= Elaborazione del Linguaggio Naturale

== Embeddings (Immersioni in Spazi Vettoriali)

#informally(title: "L'intuizione Geometrica")[
  Qual è il senso di trasformare le parole in vettori? L'idea fondamentale è estrarre le parole dai documenti e vederle come entità puramente geometriche. Un'immersione (embedding) associa a ogni oggetto (es. un termine) un vettore in $mb(RR^k)$, ovvero uno spazio astratto e multidimensionale (con $mg(k)$ tipicamente tra qualche decina e qualche migliaio).
]

Lo scopo principale è quello di mappare oggetti simili in vettori vicini. Vogliamo estrarre informazioni semantiche basandoci sul principio che distanze ridotte tra due vettori indicano significati affini.
Vettori di questo tipo vengono solitamente memorizzati all'interno di database vettoriali, essenziali per rispondere a interrogazioni complesse del tipo: _"quali sono gli animali semanticamente più simili al cane?"_.

#align(center)[
  #image("/assets/cluster.png", width: 60%)
]



=== Somiglianza del Coseno (Cosine Similarity)
Per misurare la vicinanza tra due vettori, calcoliamo la somiglianza del coseno: prendiamo il loro prodotto scalare diviso per il prodotto delle loro norme.

$ mb(cos(theta)) = (mg(A) dot mo(B)) / (||mg(A)|| ||mo(B)||) mg(comment("misura indipendente dalla lunghezza")) $

- Se l'angolo è zero ($cos(0) = 1$), i due vettori puntano nella stessa identica direzione: le due cose sono sostanzialmente le stesse. Vale $0$ se sono ortogonali e $-1$ se sono opposti (con coordinate non negative, come i conteggi, sta sempre tra $0$ e $1$).
- Altrimenti, all'aumentare dell'angolo, le due entità sono via via meno simili.
- *Indipendenza dalla lunghezza:* Questo calcolo ha l'immenso vantaggio di non dipendere dalla grandezza del vettore (contano solo le proporzioni fra le coordinate). In ambito testuale, un documento lunghissimo e uno cortissimo che trattano lo stesso argomento risulteranno simili.
- Nel caso in cui si utilizzino vettori normalizzati (di lunghezza 1), il denominatore si semplifica ($||A||=1, ||B||=1$) e il coseno si riduce al semplice *prodotto scalare*. Pertanto, ordinare i risultati per il valore del coseno equivale esattamente a ordinarli per distanza, poiché:
$ ||x - y||^2 = 2 - 2 cos(x, y) $

=== Rappresentazioni Elementari e Ipotesi Distribuzionale

La rappresentazione vettoriale più elementare che esiste per mappare una parola è il *vettore indicatore (One-Hot)*: con un vocabolario di $m$ parole, la parola $i$ diventa il vettore $e_i$ con un `1` in posizione $i$ e `0` altrove.
#warning(title: "Limiti della codifica One-Hot")[
  È un vettore che ha una dimensione pari all'intero dizionario $m$ (centinaia di migliaia di coordinate, pieno di zeri e un solo `1`). Purtroppo non ha alcun significato semantico: il prodotto scalare è non nullo solo se si ha esattamente lo stesso termine (tutti i termini diversi sono ortogonali tra loro, quindi _cane_ è lontano da _gatto_ quanto da _carburatore_).
  È un embedding sostanzialmente inutile per la comprensione, poiché non ha informazioni oltre alla pura sintassi, ma è il punto di partenza tecnico per costruire veri embedding.
]

Per dare un significato ai vettori ci basiamo sull'*Ipotesi Distribuzionale*:
#informally(title: "Ipotesi Distribuzionale")[
  Le parole che compaiono in contesti simili hanno significati simili (ad esempio le espressioni _"pedagogia infantile"_ e _"psicologia infantile"_). Dobbiamo quindi costruire vettori che dipendano strutturalmente dai contesti d'uso.
]

Il modo più naturale per farlo è usare la *co-occorrenza*: per ogni coppia di parole, contiamo in quanti documenti compaiono insieme. Costruiamo una matrice quadrata che ha sulle righe e sulle colonne i termini, e nelle celle il numero di documenti in cui i due termini sono presenti entrambi.
Questo approccio costituisce già un embedding, ma ha un difetto: due termini affini che non occorrono mai all'interno dello stesso identico documento risulteranno ortogonali (prodotto scalare zero) nella matrice termini-documenti. Non appena due termini compaiono nello stesso documento — o compaiono accanto alle stesse parole di contesto nella tabella delle co-occorrenze — abbiamo un vettore che li rappresenta tramite le occorrenze rispetto agli altri.

Nei sistemi di embedding moderni è molto più "fine" e preciso considerare piccole finestre mobili di testo e guardare quante volte il termine compare all'interno della medesima finestra, piuttosto che nell'intero documento (la matrice diventa più sparsa, ma più precisa).

#note(title: "L'intuizione fondante dei modelli moderni")[
  Poter fare addestramento sfruttando piccole finestre locali è la grossa scoperta alla base di Word2Vec. In questo modo non devo calcolare e processare la matrice gigantesca globale: si tratta più di predire la parola al centro date quelle ai lati della finestra.
]

=== Compressione e Densificazione
La matrice di co-occorrenza grezza produce vettori che sono per la quasi totalità composti da zero (vettori sparsi, rumorosi e dipendenti dal caso). Noi vogliamo invece *densificare* questa informazione, ottenendo vettori piccoli e densi.

Per comprimere i contesti, cerchiamo di scomporre (fattorizzare) la matrice gigante $mb(M)$ ($m times n$) scrivendola come il prodotto di due matrici più piccole: una matrice "alta e magra" $A$ ($m times k$) moltiplicata per una "bassa e piatta" $B$ ($k times n$), in modo da approssimare $mb(M)$ con una matrice di rango ridotto $mg(k)$:
$ mb(M) approx A B $

#align(center)[
  #image("/assets/compressione.png", width: 60%)
]

Una volta eseguita questa operazione, le righe di $A$ (i "pezzetti" risultanti di $mg(k)$ numeri) saranno le nostre immersioni, poiché permettono di rappresentare una parola con pochissimi numeri (densi) in modo tale da poter ricostruire quasi l'intera informazione originaria dentro $mb(M)$. I due approcci principali per ottenere $A$ e $B$ sono l'*Indicizzazione della Semantica Latente (LSI)* tramite algebra lineare (SVD) e *Word2Vec* direttamente dal testo.

#note(title: "Vantaggio della compressione")[
  Questa compressione va naturalmente ad eliminare il rumore di fondo (in analogia alla rimozione del rumore a livello di segnali elettrici), stabilizzando l'informazione: con $mg(k)$ piccolo si conserva solo ciò che è comune a molte righe.
]

Questi vettori densi servono quindi a:
- Trovare documenti vicini all'interrogazione (Query), anche senza parole in comune.
- Trovare parole correlate o simili.
- Clustering semantico e classificazione.
- Preparazione per sistemi successivi (una rete neurale legge vettori, non parole, e viene addestrata a partire da questi vettori in ingresso).
- Applicazioni generalizzate: non solo parole, ma anche embedding di grafi, prodotti e utenti (raccomandazioni) e immagini.

=== Decomposizione a Valori Singolari (SVD)

#theorem(title: "Decomposizione a Valori Singolari (SVD)")[
  Ogni matrice reale $mb(M)$ ($m times n$) rappresenta una trasformazione lineare (con i vettori presi in riga, $x mapsto x M$) scomponibile in tre passi: prima una rotazione $U$, poi un allungamento $Sigma$ lungo gli assi e poi un'altra rotazione $V^T$:
  $ mb(M) = U Sigma V^T $
  - $U$ ($m times m$) e $V$ ($n times n$) sono matrici ortogonali ($O^T O = I$): le righe di $U^T$ sono i *vettori singolari sinistri* $u_i$ e quelle di $V^T$ i *vettori singolari destri* $v_j$.
  - $Sigma$ ($m times n$) è diagonale con i *valori singolari* ordinati $sigma_0 >= sigma_1 >= dots >= sigma_(p-1) >= 0$ (dove $p = min(m, n)$). Il numero di valori singolari non nulli è il *rango* di $M$, e vale $u_i M = sigma_i v_i$.
  Possiamo scrivere qualsiasi trasformazione lineare in questo modo, ed è proprio la proprietà che usiamo per rappresentare le parole come vettori.
]

#align(center)[
  #image("/assets/SVD.png", width: 60%)
]

La decomposizione forma dei veri e propri "strati" di rango 1 ($u_i^T v_i$, una colonna per una riga) che, sommati tra loro, ci danno l'informazione finale; ognuno aggiunge qualcosa al totale:
$ mb(M) = sum_(i < p) sigma_i u_i^T v_i $
I primi strati valgono molto (contengono il significato principale), ma più si va avanti più il peso $sigma_i$ degli strati diminuisce (diventano rumore).

Tecnicamente, troncando ai primi $mg(k)$ strati ($M_k = sum_(i < k) sigma_i u_i^T v_i$), l'SVD fornisce l'approssimazione migliore possibile di rango $mg(k)$ (*Teorema di Eckart-Young*): utilizzando come distanza la somma dei quadrati delle differenze fra gli elementi, la differenza matematica tra la matrice originaria e quella approssimata risulta la più piccola possibile e vale esattamente:
$ "errore" = sigma_k^2 + sigma_(k+1)^2 + dots + sigma_(p-1)^2 $

#align(center)[
  #image("/assets/Eckart-Young.png", width: 70%)
]

A questo punto, per memorizzare il tutto serve pochissimo — bastano $mg(k)(m + n + 1)$ numeri invece di $m n$: tagliando il rango (azzerando i valori singolari da $sigma_k$ in poi), tutti gli zeri fanno sparire le colonne di $U$ e le righe di $V^T$ irrilevanti. In sostanza, si ottiene la *forma ridotta*, drasticamente ridotta e ripulita dalle cancellazioni:
$ M_k = U_k Sigma_k V_k^T quad (m times k)(k times k)(k times n) $

#align(center)[
  #image("/assets/forma_ridotta.png", width: 80%)
]

Da qui si ottengono direttamente le immersioni in $RR^k$: le righe di $U_k Sigma_k$ rappresentano le righe di $M$, mentre le righe di $V_k Sigma_k = M^T U_k$ rappresentano le colonne (cioè il vettore $d_j U_k$ per la colonna $j$).

Poiché $M^T M = V Sigma^T Sigma V^T$ (e $M M^T = U Sigma Sigma^T U^T$), i $v_i$ sono gli autovettori di $M^T M$ con autovalori $sigma_i^2$ e gli $u_i$ quelli di $M M^T$. Per effettuare il calcolo si può usare il *metodo delle potenze* (iterando $x mapsto x M^T M$ e normalizzando) o, su matrici grandi e sparse, metodi iterativi basati su prodotti matrice-vettore come il *metodo di Lanczos* per calcolare solo i primi $mg(k)$ strati, il cui costo computazionale è direttamente proporzionale al numero di elementi non nulli presenti, a $mg(k)$ e al numero di iterazioni.

=== Matrice Termini-Documenti
Nel classico Modello Vettoriale si utilizza una matrice $mb(M)$ dove le righe sono i termini (tolte le parole vuote / *stopword*) e le colonne sono i documenti. Per ogni riga abbiamo la presenza (`0`/`1`), il conteggio delle occorrenze in ciascun documento, oppure i pesi BM25: è a tutti gli effetti la rappresentazione matriciale di un *indice inverso logico*. Il modello classico soffre però di due limiti legati al confronto puramente lessicale: *sinonimia* (es. «auto» non trova «automobile») e *polisemia* (es. «pesca» mescola frutta e sport).

È possibile applicare a questa matrice la tecnica di riduzione della dimensionalità tramite SVD (creando embedding anche a questo livello), ottenendo l'*Indicizzazione della Semantica Latente (Latent Semantic Indexing, LSI)*. Mentre prima la ricerca generava similarità solo per lo stesso termine, applicando la riduzione della dimensionalità otteniamo collegamenti anche con termini differenti ma semanticamente vicini.

#note(title: "Perché LSI funziona: le co-occorrenze")[
  Il prodotto $M M^T$ ha in posizione $(x, y)$ proprio il numero di documenti in cui $x$ e $y$ compaiono insieme (la matrice delle co-occorrenze). Poiché gli $u_i$ sono gli autovettori di $M M^T$ (e i $v_i$ quelli di $M^T M$, che conta i termini in comune tra documenti), troncare la SVD ai primi $mg(k)$ strati significa conservare le $mg(k)$ direzioni in cui le co-occorrenze sono più forti, fondendo in un unico concetto termini che condividono gli stessi contesti.
]

#align(center)[
  #image("/assets/esempio_LSI.png", width: 60%)
]

#example(title: "Interrogazione del Modello Vettoriale")[
  Per calcolare il punteggio di un'interrogazione (Query), trasformiamo l'interrogazione in un vettore $k$-hot (con gli `1` che corrispondono ai termini cercati) e ne calcoliamo il prodotto scalare (o il coseno) con i documenti. È molto semplice! Se facciamo il prodotto scalare sulla matrice originale, stiamo eseguendo di fatto un recupero dell'informazione logico in OR (es. BM25).
]

#note(title: "Compromessi del Rango (k)")[
  Riducendo la dimensionalità ho un'ottima ricerca che cattura finalmente la *semantica*, ma bisogna prestare attenzione:

  Ogni piccolo strato aggiunto aumenta i dettagli. Cancellando troppi strati perdo informazioni essenziali (ad esempio, potrei cancellare la differenza concettuale tra animali diversi).
  Se riduco eccessivamente il rango, i vettori si avvicinano troppo fino a confondersi: concetti come _"giocare col cane"_ e _"giocare col gatto"_ potrebbero risultare identici.
]

== Spazio dei Concetti

A questo punto del sistema, ogni concetto è un vettore in uno spazio (bi)dimensionale (o $k$-dimensionale): i termini sono le righe di $U_k Sigma_k$ e i documenti sono le righe di $V_k Sigma_k = d_j U_k$. Interrogare il motore vuol dire prendere il vettore di query $q$, proiettarlo nello spazio dei concetti tramite $q U_k$ e cercare nello spazio i vettori documento $d_j U_k$ più vicini (tramite coseno).

#align(center)[
  #image("/assets/interrogare_spazio_concetti.png", width: 60%)
]

Quando funziona e quando fallisce?
- *Successo:* La riduzione dimensionale toglie di mezzo le co-occorrenze rare. Affinché due concetti risultino vicini, è sufficiente che compaiano insieme o con gli stessi termini di supporto (es. «auto» e «automobile» entrambe vicino a «motore» e «strada»).
#warning(
  title: "Il problema della Polisemia",
)[La polisemia resta: i termini polisemici (che hanno più significati diametralmente opposti, es. «pesca» tra frutta e sport) si posizionano a metà strada, in una zona grigia tra i due vettori concettuali associati.]
- *Taratura:* La scelta del parametro $mg(k)$ (tipicamente qualche centinaio) è critica e va calibrata sperimentalmente sulla collezione di testi (non si tratta di matematica pura, ma di criteri euristici). Non va bene un numero né troppo preciso, né troppo vago.
- *Costo e invecchiamento:* Calcolare la SVD su matrici enormi è costoso; inoltre, i nuovi documenti vengono proiettati con la $U_k$ calcolata all'inizio, che col tempo descrive sempre peggio la collezione.

== Word2Vec

Word2Vec è un modello basato su una rete neuronale addestrata su un compito intenzionalmente inutile (artificiale): fornita una finestra di testo, la rete deve predire la prossima parola (o quella al centro / le parole vicine).
Il punto centrale è che questo escamotage permette di fare *addestramento non supervisionato*, usando quantità sterminate di testo per ottenere risultati eccezionali (schema poi adottato da tutte le reti profonde moderne).

#informally(title: "L'addestramento è un pretesto")[
  - Ogni ingresso della rete è un semplice vettore One-Hot (es. la parola `"cane"`).
  - L'output della rete calcola la distribuzione di probabilità di trovare le parole vicine nel contesto (es. predire `"porto"`, `"il"`, `"dal"`, `"veterinario"` nella frase *"porto il cane dal veterinario"*).
  - *L'addestramento in sé è inutile!* Non ci interessa davvero la predizione delle parole vicine.
  - Quello che ci interessa estrarre alla fine sono i *pesi interni* che collegano ogni parola al *livello nascosto (hidden layer)*. Per svolgere bene il lavoro temporaneo, la rete è costretta a mappare e affinare i pesi, che si trasformano nell'immersione vera e propria. Gli embedding generati da Word2Vec sono letteralmente i pesi della rete.
]

#align(center)[
  #image("/assets/word2vec.png", width: 80%)
]

Mentre LSI decompone una matrice tutta insieme, Word2Vec legge il testo una parola alla volta: avvicina i vettori delle parole che compaiono nella stessa finestra e allontana quelli di parole prese a caso. Per evitare l'overfitting — e impedire che tutti i vettori collassino nello stesso punto — la rete non calcola la probabilità su tutto il dizionario, ma le vengono messe in mezzo "parole a caso" come esempi negativi (tecnica del *Negative Sampling*).
Quando l'addestramento è terminato, l'architettura della rete viene buttata via e si tengono unicamente i pesi strutturati.

#align(center)[
  #image("/assets/avvicinamento.png", width: 70%)
]

#note[
  - Quadrati verdi: parole di contesto
  - Cerchi vuoti -> pieni: spostamento di _cane_, _gatto_ e _auto_ durante l'addestramento: _cane_ e _gatto_ convergono perché attirati dallo stesso contesto
]

A livello computazionale, la rete si addestra con un'enormità di dati tramite la tecnica della *Discesa del Gradiente* (Gradient Descent).
Invece di affidarsi a un gigantesco meccanismo monolitico che alloca in memoria array immensi, si eseguono dei piccolissimi aggiornamenti iterativi, ottimizzati nel corso degli anni. Lo sforzo ingegneristico per implementare reti neurali veloci con discesa del gradiente negli ultimi anni è stato spaventoso, rendendo tutto questo possibile.

#note(title: "Relazione tra Word2Vec e SVD (PMI)")[
  Gli studiosi hanno poi analizzato Word2Vec (nato nel 2013, compreso matematicamente nel 2014) e capito che, implicitamente, la rete sta eseguendo la stessa identica fattorizzazione della matrice originale (*Pointwise Mutual Information Matrix*, PMI) che facevamo prima:
  $ "PMI"(x, y) = log (p(x, y)) / (p(x) p(y)) $
  La PMI misura in scala logaritmica quante volte più spesso del caso $x$ e $y$ compaiono vicine ($> 0$ si attraggono, $0$ indipendenti, $< 0$ si evitano). Il prodotto scalare dei vettori di Word2Vec approssima $"PMI"(x, y)$ meno il logaritmo del numero di esempi negativi per coppia.
  Insomma, la rete calcola in modo fluido la classica moltiplicazione "matrice alta e magra" per "matrice bassa e piatta" senza dover mai avere in memoria la gigantesca matrice originaria nel mezzo (e la SVD diretta delle PMI, azzerando i valori negativi, dà risultati simili).
]

== Analogie Vettoriali

Nelle immersioni di Word2Vec le differenze tra vettori codificano relazioni semantiche e morfologiche. Per esempio, la parola più vicina (per coseno) a $v_"re" - v_"uomo" + v_"donna"$ (escluse le tre di partenza) è «regina»; analogamente funzionano spesso $"Parigi" - "Francia" + "Italia" approx "Roma"$ o $"andava" - "andare" + "mangiare" approx "mangiava"$.

#align(center)[
  #image("/assets/analogie_vettoriali.png", width: 60%)
]

#warning(title: "Limiti e stereotipi (Bias)")[
  Le analogie funzionano meno bene di quanto spesso si racconti (escludere le parole di partenza pesa molto). Inoltre, le immersioni assorbono e replicano anche gli *stereotipi* presenti nei testi di addestramento (es. sui mestieri e sul genere).
]

== Limiti degli Embedding Statici ed Evoluzioni Moderne

Sia LSI sia Word2Vec producono *immersioni statiche*, con due limiti principali:
- *Un solo vettore per parola:* la polisemia non è risolta («pesca» mescola frutta e sport).
- *Parole mai viste:* termini assenti dal corpus di addestramento non hanno alcun vettore.

L'idea di base si è quindi evoluta in tre direzioni:
- *Grafi:* usando passeggiate aleatorie su un grafo al posto delle frasi si ottengono immersioni dei nodi.
- *Immersioni contestuali (Transformer):* le reti neuronali moderne assegnano un vettore diverso a ogni occorrenza di una parola in base alla frase in cui compare.
- *Frasi e documenti interi:* embedding di interi testi, che sono quelli effettivamente memorizzati nei database vettoriali moderni.

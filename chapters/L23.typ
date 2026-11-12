#import "../template.typ": *

= Elaborazione del Linguaggio Naturale

== Embeddings (Immersioni in Spazi Vettoriali)

#informally(title: "L'intuizione Geometrica")[
  Qual è il senso di trasformare le parole in vettori? L'idea fondamentale è estrarre le parole dai documenti e vederle come entità puramente geometriche. Un'immersione (embedding) associa a ogni oggetto (es. un termine) un vettore in $mb(RR^k)$, ovvero uno spazio astratto e multidimensionale. 
]

Lo scopo principale è quello di mappare oggetti simili in vettori vicini. Vogliamo estrarre informazioni semantiche basandoci sul principio che distanze ridotte tra due vettori indicano significati affini. 
Vettori di questo tipo vengono solitamente memorizzati all'interno di database vettoriali, essenziali per rispondere a interrogazioni complesse del tipo: _"quali sono gli animali semanticamente più simili al cane?"_.

=== Somiglianza del Coseno (Cosine Similarity)
Per misurare la vicinanza tra due vettori, calcoliamo la somiglianza del coseno: prendiamo il loro prodotto scalare diviso per il prodotto delle loro norme.

$ mb(cos(theta)) = (mg(A) dot mo(B)) / (||mg(A)|| ||mo(B)||) mg(comment("misura indipendente dalla lunghezza")) $

- Se l'angolo è zero ($cos(0) = 1$), i due vettori puntano nella stessa identica direzione: le due cose sono sostanzialmente le stesse.
- Altrimenti, all'aumentare dell'angolo, le due entità sono via via meno simili.
- *Indipendenza dalla lunghezza:* Questo calcolo ha l'immenso vantaggio di non dipendere dalla grandezza del vettore. In ambito testuale, un documento lunghissimo e uno cortissimo che trattano lo stesso argomento risulteranno simili.
- Nel caso in cui si utilizzino vettori normalizzati (di lunghezza 1), il denominatore si annulla ($||A||=1, ||B||=1$) e il coseno si riduce al semplice *prodotto scalare*. Pertanto, ordinare i risultati per il valore del coseno equivale esattamente a ordinarli per distanza.

=== Rappresentazioni Elementari e Ipotesi Distribuzionale

La rappresentazione vettoriale più elementare che esiste per mappare una parola è il *vettore indicatore (One-Hot)*.
#warning(title: "Limiti della codifica One-Hot")[
  È un vettore che ha una dimensione pari all'intero dizionario (pieno di zeri e un solo `1`). Purtroppo non ha alcun significato semantico: il prodotto scalare è non nullo solo se si ha esattamente lo stesso termine (tutti i termini diversi sono ortogonali tra loro). 
  È un embedding sostanzialmente inutile per la comprensione, poiché non ha informazioni oltre alla pura sintassi, ma è il punto di partenza tecnico per costruire veri embedding.
]

Per dare un significato ai vettori ci basiamo sull'*Ipotesi Distribuzionale*: 
#informally(title: "Ipotesi Distribuzionale")[
  Le parole che compaiono in contesti simili hanno significati simili (ad esempio le espressioni _"pedagogia infantile"_ e _"psicologia infantile"_). Dobbiamo quindi costruire vettori che dipendano strutturalmente dai contesti d'uso.
]

Il modo più naturale per farlo è usare la *co-occorrenza*: per ogni coppia di parole, contiamo in quanti documenti compaiono insieme. Costruiamo una matrice quadrata che ha sulle righe e sulle colonne i termini, e nelle celle il numero di documenti in cui i due termini sono presenti entrambi.
Questo approccio costituisce già un embedding, ma ha un difetto: due termini affini che non occorrono mai all'interno dello stesso identico documento risulteranno ortogonali (prodotto scalare zero). Non appena due termini compaiono nello stesso documento, abbiamo un vettore che li rappresenta tramite le occorrenze rispetto agli altri.

Nei sistemi di embedding moderni è molto più "fine" e preciso considerare piccole finestre mobili di testo e guardare quante volte il termine compare all'interno della medesima finestra, piuttosto che nell'intero documento.

#note(title: "L'intuizione fondante dei modelli moderni")[
  Poter fare addestramento sfruttando piccole finestre locali è la grossa scoperta alla base di Word2Vec. In questo modo non devo calcolare e processare la matrice gigantesca globale: si tratta più di predire la parola al centro date quelle ai lati della finestra.
]

=== Compressione e Densificazione
La matrice di co-occorrenza grezza produce vettori che sono per la quasi totalità composti da zero (vettori sparsi). Noi vogliamo invece *densificare* questa informazione, ottenendo vettori piccoli e densi.

Per comprimere i contesti, cerchiamo di scomporre (fattorizzare) la matrice gigante $mb(M)$ scrivendola come il prodotto di due matrici più piccole: una matrice "alta e magra" moltiplicata per una "bassa e piatta", in modo da approssimare $mb(M)$ con una matrice di rango ridotto $mg(k)$.
Una volta eseguita questa operazione, i "pezzetti" risultanti saranno le nostre immersioni, poiché permettono di rappresentare una parola con pochissimi numeri (densi) in modo tale da poter ricostruire quasi l'intera informazione originaria dentro $mb(M)$.

#note(title: "Vantaggio della compressione")[
  Questa compressione va naturalmente ad eliminare il rumore di fondo (in analogia alla rimozione del rumore a livello di segnali elettrici), stabilizzando l'informazione.
]

Questi vettori densi servono quindi a:
- Trovare documenti vicini all'interrogazione (Query).
- Trovare parole correlate o simili.
- Clustering semantico.
- Preparazione per sistemi successivi (una rete neurale viene addestrata a partire da questi vettori in ingresso).
- Applicazioni generalizzate: non solo parole, ma anche embedding di grafi, prodotti e utenti.

=== Decomposizione a Valori Singolari (SVD)

#theorem(title: "Decomposizione a Valori Singolari")[
  Ogni matrice rappresenta una trasformazione lineare scomponibile in tre passi: prima una rotazione, poi un allungamento e poi un'altra rotazione. Possiamo scrivere qualsiasi trasformazione lineare in questo modo, ed è proprio la proprietà che usiamo per rappresentare le parole come vettori.
]

Tecnicamente, l'SVD fornisce l'approssimazione migliore possibile di rango $mg(k)$ in cui, utilizzando una precisa norma matriciale (somma dei valori singolari al quadrato), la differenza matematica tra la matrice originaria e quella approssimata risulta la più piccola possibile.

La decomposizione forma dei veri e propri "strati" che, sommati tra loro, ci danno l'informazione finale; ognuno aggiunge qualcosa al totale. I primi strati valgono molto (contengono il significato principale), ma più si va avanti più il peso degli strati diminuisce (diventano rumore).
A questo punto, per memorizzare il tutto serve pochissimo: tagliando il rango, tutti gli zeri fanno sparire gli strati irrilevanti. In sostanza, si ottiene una forma drasticamente ridotta e ripulita dalle cancellazioni.

Per effettuare il calcolo si può usare il *metodo delle potenze*, il cui costo computazionale è direttamente proporzionale al numero di elementi non nulli presenti.

=== Matrice Termini-Documenti
Nel classico Modello Vettoriale si utilizza una matrice dove le righe sono i termini e le colonne sono i documenti. Per ogni riga abbiamo il conteggio di in quali documenti il termine compare: è a tutti gli effetti la rappresentazione matriciale di un *indice inverso logico*.

È possibile applicare a questa matrice la tecnica di riduzione della dimensionalità (creando embedding anche a questo livello). Mentre prima la co-occorrenza generava similarità per lo stesso termine, applicando la riduzione della dimensionalità otteniamo collegamenti anche con termini differenti ma semanticamente vicini.

#example(title: "Interrogazione del Modello Vettoriale")[
  Per calcolare il punteggio di un'interrogazione (Query), trasformiamo l'interrogazione in un vettore One-Hot verticale $k$-hot (con gli `1` che corrispondono ai termini cercati) e ne calcoliamo il prodotto scalare con i documenti. È molto semplice! Se facciamo il prodotto scalare sulla matrice originale, stiamo eseguendo di fatto un recupero dell'informazione logico in OR (es. BM25).
]

#note(title: "Compromessi del Rango (k)")[
  Riducendo la dimensionalità ho un'ottima ricerca che cattura finalmente la *semantica*, ma bisogna prestare attenzione:
  
  Ogni piccolo strato aggiunto aumenta i dettagli. Cancellando troppi strati perdo informazioni essenziali (ad esempio, potrei cancellare la differenza concettuale tra animali diversi).
  Se riduco eccessivamente il rango, i vettori si avvicinano troppo fino a confondersi: concetti come _"giocare col cane"_ e _"giocare col gatto"_ potrebbero risultare identici.
]

== Spazio dei Concetti

A questo punto del sistema, ogni concetto è un vettore in uno spazio (bi)dimensionale (o $k$-dimensionale). Interrogare il motore vuol dire prendere il vettore di query e cercare nello spazio i vettori più vicini.

Quando funziona e quando fallisce?
- *Successo:* La riduzione dimensionale toglie di mezzo le co-occorrenze rare. Affinché due concetti risultino vicini, è sufficiente che compaiano con gli stessi termini di supporto.
- #warning(title: "Il problema della Polisemia")[La polisemia resta: i termini polisemici (che hanno più significati diametralmente opposti) si posizionano a metà strada, in una zona grigia tra i due vettori concettuali associati.]
- *Taratura:* La scelta del parametro $mg(k)$ è critica e va calibrata sperimentalmente sulla collezione di testi (non si tratta di matematica pura, ma di criteri euristici). Non va bene un numero né troppo preciso, né troppo vago.

== Word2Vec

Word2Vec è un modello basato su una rete neuronale addestrata su un compito intenzionalmente inutile: fornita una finestra di testo, la rete deve predire la prossima parola (o quella al centro).
Il punto centrale è che questo escamotage permette di fare *addestramento non supervisionato*, usando quantità sterminate di testo per ottenere risultati eccezionali.

#informally(title: "L'addestramento è un pretesto")[
  - Ogni ingresso della rete è un semplice vettore One-Hot.
  - L'output della rete calcola la distribuzione di probabilità di trovare una certa parola (es. indovinare "cane" nella frase "porto il $dots$ dal veterinario" ecc.).
  - *L'addestramento in sé è inutile!* Non ci interessa la predizione della parola mancante. 
  - Quello che ci interessa estrarre alla fine sono i *pesi interni*. Per svolgere bene il lavoro temporaneo, la rete è costretta a mappare e affinare i pesi, che si trasformano nell'immersione vera e propria. L'embedding generato da Word2Vec sono letteralmente i pesi della rete.
]

Per evitare l'overfitting, la rete non calcola la probabilità su tutto il dizionario, ma le vengono messe in mezzo "parole a caso" come esempi negativi (tecnica del *Negative Sampling*).
Quando l'addestramento è terminato, l'architettura della rete viene buttata via e si tengono unicamente i pesi strutturati.

A livello computazionale, la rete si addestra con un'enormità di dati tramite la tecnica della *Discesa del Gradiente* (Gradient Descent).
Invece di affidarsi a un gigantesco meccanismo monolitico che alloca in memoria array immensi, si eseguono dei piccolissimi aggiornamenti iterativi, ottimizzati nel corso degli anni. Lo sforzo ingegneristico per implementare reti neurali veloci con discesa del gradiente negli ultimi anni è stato spaventoso, rendendo tutto questo possibile.

#note(title: "Relazione tra Word2Vec e SVD")[
  Gli studiosi hanno poi analizzato Word2Vec e capito matematicamente che, implicitamente, la rete sta eseguendo la stessa identica fattorizzazione della matrice originale (Pointwise Mutual Information Matrix) che facevamo prima. 
  Insomma, la rete calcola in modo fluido la classica moltiplicazione "matrice alta e magra" per "matrice bassa e piatta" senza dover mai avere in memoria la gigantesca matrice originaria nel mezzo.
]
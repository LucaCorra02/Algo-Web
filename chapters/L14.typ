#import "../template.typ": *

- *Segmentazione documentale*: dividiamo gli indici in base ai documenti che contengono al loro interno. Una volta che abbiano l'indice intero possiamo creare dei segmenti più appropriati a livello di spazio occupato.

- *Lessicale*: prendiamo un indice e dividiamo l'indice in base alle parole che contiene. Potremmo mettere i termini più frequenti in un segmento in memoria e quelli meno frequenti su disco. Dovremmo fare dispatch, recuperare l'indice del termine. solitamente vengono usati dei dizionai approssimati per tale scopo.

Possiamo andare a combinare le due strategie, ad esempio possiamo fare una segmentazione documentale e poi per ogni segmento fare una segmentazione lessicale. Alla fine si crea un albero di segmenti, dove ogni segmento contiene un sottoalbero di segmenti.

#note()[
  A livello pratico non ha senso creare un albero composto perchè le query deve essere ricostruita dal basso. Solitamente si divide per documenti in modo distribuito tra più computer, su un computer si segmenta in maniera lessicale.
]

Ci deve intoltre essere una nozione di importanza statica tra documenti. In modo tale da introdurre un criterio di ordinamento dei risultati dovuti ad un eventuale query.

#warning()[
  Quando abbiamo una query congiunta (and), il numero di risultati è minore della lunghezza delle liste di affissione dei singoli termini. Tipi romeo e giulietta < romo.

  Per questo motivo la divisioni a termini per server distribuiti è inefficiente, dobbiamo trasferire le informazioni dei singoli termini che devono essere combinati, le quali sono molte.
]

=== Interrogazione ad un indice

Interrogazione funzionamento:
- Rispondiamo alla query con un buon insieme di candidati. Questo serve per scremare i documenti che non sono rilevanti per la query. In questo modo possiamo ridurre il numero di documenti da considerare.

- Una volta fatto ciò possiamo andare ad usare tecniche vettoriali per fare un ordinamento dei candidati in base alla lora aderenza alla query.

Precione e richiamo alti sono molto difficili da ottenere, in quanto:
- precisione infinita è ottenuta tornando nessun risultato. Si tratta dell'aderenza dei documenti alla query.
- richiamo troviamo una buona parte di documenti che voleva trovare.

#note()[
  Una frasale su stop word è molto costosa "one them of and". In quanto deve trovare le intersezioni tra le liste di affissione dei termini e verificare quali documenti hanno la frase in questo ordine.

  Le liste sono ad altissima frequenza, non andiamo a ridurre la dimensione delle liste da intersecare.
]

= Ranking Scooring

Ranking = Mettere in ordine. Possono essere statici o dinamici. I ranking statici sono quelli che non dipendono dalla query, mentre quelli dinamici dipendono dalla query.

Score = assegnare un numero reale ad una certa cosa. Possono essere esogeni o endogeni. Endogeni se usano informazioni interne al documento (usato fino agli anni 70 nelle biblioteche, solo testo), esogeni se usano informazioni esterne al documento. Ad esempio il numero di pagine che si collegano a me (ricostruisco parzialmente il grafo del web)

#note()[
  Il ranking esogeno ad esempio quante persone mi citano è sempre facilmente manipolabile, in quanto posso creare un bot che mi cita. Per questo motivo vanno presi con le pinze.
]

Quello che facciamo è assegnare ad ogni documento uno score in base alla query. Successivamente ordiniamo i documenti in base al loro score. In questo modo possiamo andare a prendere i primi k documenti con il miglior score.

== TF-IDF

Quando risolviamo una quey nell'indice abbiamo il termine, il documento e la frequenza del termine nel documento. Se un termine è molto frequente in un documento allora quel documento è più rilevante per la query. Tuttavia se il termine è molto frequente in tutti i documenti allora non è un buon discriminante per la query.

La frequenza del termine nel documento è dinamice, in quanto dipende dalla query, mentre la frequenza del termine nel corpus è statica e globale. La formula di tf-idf è la seguente:
$
  sum_(t in "query" \ "che compaiono" in d) c_t / l_d log (N / f_t)
$
dove:
- f_t = frequenza del termine nel corpus
- c_t = frequenza del termine nel documento
- N = numero di documenti nel corpus

Il fattore nel logaritmo è detto idf (inverse document frequency) e serve per ridurre il peso dei termini molto frequenti nel corpus (il logaritmo serve per far tornare un punteggio da 0 a 1). Il fattore c_t / l_d è detto tf (term frequency) e serve per aumentare il peso dei termini molto frequenti nel documento.

#warning()[
  Stiamo assumento che i termini della query compaiono in maniera indipendente e quindi possiamo andare a sommare i punteggi dei singoli termini. In realtà i termini della query sono correlati tra loro ad esempio se la query è "cane" e "cani" dipo cane il termine ha speso tutto il suo contenuto informativo.
]

per la lunghezza dei documenti in memoria non possiamo usare degli interi a 32 bit, solitamente di usano degli interi a 8 bit, facendo il logaritmo della lunghezza del documento e troncando il risultato.

#note()[
  Gli apax hanno il massimo contenuto informativo.

  Siccome la formula da solo 0 se e solo se il termine non è presente nel documento, allora possiamo andare a effettuae i controlli nell'interrogazione in or. I documenti rilevanti sono quelli che contengono almeno una parola della query.

  Ci bastano le liste di affisione con i conteggi per calcolare questo score.
]

== BM25

La formula di BM25 è la seguente:
$
  (1 + k_1) c_t / (k_1 (1 - b + b (l_d / l)) + c) log ((N-f+1/2) / (f + 1/2))
$
L = lunghezza media del documento nella collezione
l = lunghezza del documento

Il logarmitmo è uno smoothing laplaciano. Qualsiasi termine che compare più di un mezzo dei documento per questo score non vale nulla.

La parte a sinistra rispecchia il modello probabilistico. é una approssimazione della probabilità che il documento sia appartenente ad un interrogazione data appunto l'interrogazione. I termini:
- $l / L$ = se il documento è più grande della media allora il punteggio è > 1

Mettendo $b=0$ e $c=infinity$ lo score ha un asintoto orizzinale che dipende da (1+k_1). Più è grande k_1 più l'asintotno è alto. Non smette mai di avere importanza ma è sempre meno (essendo un asintono)

Ora supponiamo che:
- $k_1 = 0$ ->1 il conteggio non ha nessuna rilevanza, conta solo la parte a destra
- $k_1 = infinity$ -> 0 il conteggio ha rilevanza infinita, conta solo la parte a sinistra

$k_1$ modula fino a quanto il conteggio del termine nel documento è rilevante.

// riguardare
Consideriamo ora i valori di $b$:
- $b=1$ -> rimane $k_1 l/L$. Va ad aumentare il denominatore. Se il termine compare più volte in un documento lungo allora il punteggio è più basso. Se il documento è più corto della media allora il punteggio è più alto.

== Bert

Dopo aver estratto un pool di documenti rilevanti per la query possiamo andare a fare un ordinamento più accurato dei documenti in base alla loro rilevanza.

Ad oggi viene usato Bert. L'idea è quella di allenare il token CLS come miusra della rilevanza del documento rispetto alla query. In questo modo possiamo andare a fare un ordinamento dei documenti in base alla loro rilevanza.

Si tratta di un modello di deep learning che viene allenato su un dataset di query e documenti rilevanti.


#import "../template.typ": *

O abbiamo la lista dei successori per ogni vertice o la lista dei predecessaro. Possiamo sempre effeturare il calcolo. Supponimao di avere l'iterata $x_k$ e vogliamo calcolare $x_(k+1)$ se stiamo usando eighen vector centraloty all'inizo sono tutti 1 vogliamo calcolare il sucessivo.

- Se sul disco abbiammo i successori (e vogliamo falra per predecessori) dobbiamo spargere il contenuto
- Se sul disco abbiamo i predecessori (e vogliamo farlo per successori) dobbiamo raccofliere le somme in $x_(k+1)$.

Il garfo in questa forma limnearizzata dobbiamo averlo in forma reserve, se vogliamo fare multi-threading.

Nel caso di ceily e page rank dobbiamo anche occupare memoria per memorizzare i gradi di ogni vettore, in quanto non abbiamo il grafo in direzione giusta. Se scriviamo poco alla volta in maniera sequenziale, possiamo durettamente scrivero $x_(k+1)$ su disco (almeno che non facciamo multithreading).

Il lavoro in multithreading è proporzionale all'indegree del nodo.

Invece di calcolare l'interazione:
$
  x_(k+1)= x_k * (alpha P + (1-alpha))
$
ma si può usare un risoluture di sistemi iterativi lineari

= Valutazione dei sistemi di riperimento dell'informazione

Perchè BM25 funziona meglio del conteggio ecc, ma su che basi?

Dobbiamo avere un sistema di interrogazioni e per ogni interrogazione un insieme di documenti rilevanti, cioè:
$
  forall q in Q, space R_q subset D
$
Supponiamo di avere i documenti rilevanti (essi dovrebero essere annotati da un esperto). Posso usare questa metrica che si chiama precision
$
  P_q = (| A_q inter R_q|) / | A_q|
$
- Precision ci dice qualìè la frazione di cose che abbiamo fatta giusta
- Recal 1 significa che nella risposta ci sono effettivamente tutti i documenti rilevanti presenti nell'intera collezione di documenti.

Se faccio un solo motore che ritorna un documeto rilevante per singola query, avrò una precisione del 100% ma un recall del 0%.\
Mano a mano che vogliamo estendere il richiamo la precisione va rapidamente verso il basso. L'idea è quella di trovare un compromesso tra precisione e richiamo.

Storicamente il problema è dovuto al richiamo. Ad esempio il databse dei brevetti non posso giocare sulla precisione, devono ritornare tutte le possibili risposte corrette. Piuttosto si scorrono di più i risultati. Con l'avvento del web invece si è spostato il problema sulla precisione, perchè se ritorno 1000 risultati e solo 10 sono rilevanti, l'utente non è contento. Quindi si è spostato il problema sulla precisione.

Supponiamo di avere un insieme di risultati ordinati, ci chiediamo la precision e il richiamo dopo $k$ risultati:
- $P@K$
- $R@K$
Il $k$ deve essere fissati a priori, ad esempio $k=10$ o $k=20$.

*F1-score*: Media armonica tra precisione e richiamo:
$
  "F1" = 2 * (P@K * R@K) / (P@K + R@K) //riguardare
$
#warning()[
  La media è una pessima idea, perchè se la precisione è 0 e il richiamo è 1, la media è 0.5, ma in realtà non abbiamo fatto nulla di buono. La media armonica invece è più sensibile ai valori bassi, da un punteggio valido su tutto il range da $[0,1]$.
]

== Corpus di interrogazioni

=== Min reciprocal rank

Alcune misure sono pensate specificamente per alcune task. Ad esempio per il name page finding, dove vogliamo trovare una specifica pagina web, usiamo il *min reciprocal rank,* che è la media dei reciproci delle posizioni dei documenti rilevanti:
$
  sum_{q in Q} 1 / "rank"_q(d) / |Q|
$
Se il documento rilevante è in prima posizione, il punteggio è 1, se è in seconda posizione il punteggio è 0.5, se è in terza posizione il punteggio è 0.33 e così via. Si tratta di una metrica che ha senso quando solamente il file corretto è uno solo. Metrica usata in passato.

=== Precisione media

Si tratta di una metrica basata sull'ordine. Se abbiamo i documenti in un certo ordine, possiamo guradare la risposta (essa contiene documenti rilevanti e non rilevanti). Si prende la posizione del rilevante e per ognunto di essi si chiama la precisione fino a quel punto ($P@k$).
//aggiungere grafico
Prendiamo l'area sotto la curva. Si tratta di un grafico a _pallini_, quando torviamo un documenti rilevante calcoliamo la precision e prendo l'area che sta sotto, è una sorta di integrale della curva richiamo-precisione. Questa metrica misura quanto rapidamente il motore di ricerca peggiora. Il motore di ricerca ideale forma un quadrato (se guardiamo l'area sotto la curva) oppure una linea essendo la precision sempre a 1.

MAP: fa la media delle precisioni medie per ogni query. Si tratta di una metrica che misura la qualità del motore di ricerca.

== Discounted cumulative gain

Entriamo il modno della rilevanza pesata. Sommiamo per ogni documento rilvante la sua rilvanza divisa per uno sconto (può essere / il suo rango).
$
  sum_(i "rilevante") d_i / log_2("rank")
$
Guardo ogni risultato in ordine, guardo il punteggio di rilevanza e accumo il guadagno scontato di una qualche distanza dall'inzio della lista. più lo sconto cresc esponenzialmente più contanto le sue posizioni.

#note()[
  Il range non è definito. I rel dipendono dall'interrogazione, non significa strettamente che il motore sia migliore o peggiore.
]

=== Normalize d discounted cumulative gain
Lo normalizzo con il massimo punteggio possibile cosi ottengo un numero da 0 a 1. Per ottenere il massimo punteggio possibile dovrei avere un motore perfetto, quindi nn è calcolabile. Non posso sapere qual'è il migliore risultato per ogni query (collezione troppo grande di documenti).

$"NDGG@IO"$: Quello che posso fare è calcolare il massimo punteggio possibile per un insieme ristretto (ad esempio 10) di documenti rilevanti. In modo tale che in questo modo ogni query ha un fattore di normalizzazione fissato. Una volta che assumiamo di trovare sempre un numero sufficiente di documenti per query il problema diventa banale:
$
  sum_(s in "collection") 1 / (log("rank")+1)
$







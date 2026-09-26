#import "../template.typ": *

= Crawling

Ci interessa tenere traccia di tre insiemi:
- l'insieme degli URL già visitati, dei quali abbiamo già estratto le informazioni necessarie;

- la *frontiera*: l'insieme delle pagine che conosciamo ma non abbiamo ancora visitato. Può essere costituita da URL inseriti manualmente oppure raggiungibili dai nodi visitati. \

  La frontiera può essere ordinata secondo un criterio di priorità, che seleziona il prossimo URL da visitare. Con una FIFO otteniamo una visita in ampiezza, con cerchi concentrici a partire da un nodo, mentre il raggio si amplia. Le informazioni contenute nell'URL vengono estratte e memorizzate;

- l'insieme degli URL non ancora visitati e non ancora conosciuti.

Servono strutture dati apposite per tenere traccia di questi insiemi, in particolare per verificare rapidamente se un URL è già presente nell'insieme dei visitati o nella frontiera. Un esempio sono i *filtri*, strutture dati simili a insiemi che permettono di tenere traccia di quali URL sono già stati visitati e quali no. Solitamente, ricordare l'ordine di visita e ciò che abbiamo già visto può essere ricondotto a un'unica struttura dati più efficiente, invece di separare i due problemi.

== Collisioni

In caso di errore, un dizionario approssimato può rispondere usando informazioni probabili invece di memorizzare esplicitamente tutti i dati. Nei crawler solitamente non viene memorizzato l'URL assoluto, ma una firma ottenuta tramite una funzione hash, in modo da risparmiare spazio e velocizzare le operazioni di ricerca. L'unico problema è che due URL diversi possono avere la stessa firma (*collisione*), la cui probabilità deve essere stimata.

Per stimare le collisioni trattiamo la funzione hash come una funzione casuale, che mappa delle palle in delle urne. Per $n$ palle e $u$ urne, il numero atteso di coppie in collisione è circa $n^2 / (2u)$ quando $n$ è molto più piccolo di $u$. Il numero effettivo di collisioni è una variabile aleatoria; per valori grandi può essere approssimato tramite una distribuzione di Poisson.

#example()[
  Su $2^64$ urne, quante collisioni ci sono con 100 miliardi di URL?
  $
    (100 * 10^9)^2 / (2 * 2^64) approx 271
  $
  Il numero atteso di collisioni è basso e può essere gestito, per esempio verificando l'URL originale quando una firma risulta già presente.
]

Nella struttura che rappresenta gli URL già visitati possiamo memorizzare la firma (hash) invece dell'URL stesso, in modo da risparmiare spazio e, dato l'alto numero di accessi, minimizzare i tempi. Se non conserviamo anche l'URL originale, però, una collisione può produrre un falso positivo: per questo la firma deve essere sufficientemente lunga oppure deve essere verificata con i dati originali.

#note()[
  Questo approccio non va bene per la frontiera: lì dobbiamo conservare fisicamente l'URL, perché dobbiamo poterlo visitare.
]

== Riallocazione delle strutture dati

Le riallocazioni delle tabelle hash sono estremamente instabili rispetto all'occupazione di memoria. In questo contesto vogliamo che le strutture dati utilizzino una quantità di memoria centrale fissata a priori. Vogliamo che, man mano che il crawler procede, il sistema rallenti piuttosto che smettere di memorizzare nuovi URL a causa della saturazione della RAM (*graceful degradation*).
#note()[
  Le tabelle hash non sono adatte a questo scopo perché, quando lo spazio è esaurito, spesso devono essere riallocate con una capacità doppia. Se non c'è più memoria disponibile, il crawler si blocca.
]

=== Filtri di bloom

Si tratta di un dizionario approssimato che può produrre falsi positivi, ma non falsi negativi: se la struttura risponde *no*, possiamo fidarci; se risponde *sì*, dobbiamo verificare effettivamente la presenza dell'elemento. La cosa utile è che utilizza una quantità di memoria fissata in anticipo.

Esso è costituito da due elementi:
- $m$: vettore di bit
- $d$: numero di funzioni di hash, che vanno dall'universo delle chiavi $U$ agli indici del vettore, cioè $U -> {0, ..., m - 1}$. Idealmente, ogni funzione di hash è indipendente dalle altre ed è uniformemente distribuita.


Due primitive:
- `insert`: data una chiave $x$, calcola i valori $h_i(x)$, che indicano le posizioni associate a $x$ nel vettore di bit, e imposta a 1 tutte queste posizioni.
- `contains`: data una chiave $x$, calcola i valori $h_i(x)$. Se tutte le posizioni corrispondenti valgono 1, restituisce *true*; altrimenti restituisce *false*. Se restituisce *false*, allora la chiave sicuramente non è presente; se restituisce *true*, allora è probabilmente presente.

#note()[
  Se in passato abbiamo eseguito `insert(x)`, allora `contains(x)` restituisce sicuramente *true*, purché non vengano eseguite operazioni di reset.

  Se, per una collisione, `insert(y)` imposta a 1 tutte le posizioni associate a $x$, allora `contains(x)` restituisce *true* anche se $x$ non è presente: questo è un falso positivo.
]

Per ottenere un falso positivo, tutte le posizioni visitate dalle $d$ funzioni di hash della chiave interrogata devono risultare già impostate a 1. Non è quindi necessario che le funzioni di hash producano lo stesso indice: è sufficiente che le posizioni richieste siano state impostate da inserimenti precedenti.

Problema delle chiavi *multiple*: Una certa chiave $z$ potrebbe collidere su posizione con una chiave $x$ e con una chiave $y$, quindi se faccio head(x) e head(y) allora contains(z) ritorna *true* anche se non c'è. Questo è un falso positivo.

#note()[
  A parità di numero di elementi inseriti e di dimensione del vettore, aumentando $d$ controlliamo più bit e inizialmente il falso positivo diventa meno probabile. Tuttavia, se $d$ è troppo grande, impostiamo molti più bit a 1 e il vettore si satura; perciò esiste un valore ottimale di $d$.

  Inoltre, aumentando $d$ aumentano il tempo di inserimento e il tempo di interrogazione.
]

#warning()[
  Anche un hash set basato su firme può essere soggetto a collisioni e quindi a errori, se non conserva l'elemento originale per la verifica. È tuttavia preferibile un filtro di Bloom quando vogliamo una memoria di dimensione fissa. Una volta superato il numero di inserimenti previsto, il filtro di Bloom degrada gradualmente, presentando un numero sempre maggiore di falsi positivi.
]

#proof()[
  Vogliamo stimare la probabilità di avere un falso positivo.

  Supponiamo che le funzioni di hash siano casuali e indipendenti.

  Consideriamo un singolo inserimento. Per una funzione di hash, la probabilità di impostare un determinato bit a 1 è $1/m$ e quindi la probabilità di non impostarlo è $1 - 1/m$.

  Chiamiamo $n$ il numero atteso di inserimenti distinti. La probabilità che un certo bit sia ancora a 0 dopo $n$ inserimenti con $d$ funzioni di hash è:
  $
    (1-1/m)^(n d)
  $
  La probabilità che sia a 1 è quindi:
  $
    1 - (1-1/m)^(n d)
  $
  La probabilità di avere un falso positivo, cioè di trovare tutti e $d$ i bit a 1 per una chiave assente, è quindi:
  $
    (1 - (1-1/m)^(n d))^d
  $
  Usando il limite notevole classico $(1 + alpha/n)^n -> e^alpha$ e assumendo $m$ grande, possiamo approssimare:
  $
    "divido e moltiplico per m" \
                                & = (1 - (1-1/m)^(m * (n d) / m))^d \
                                & approx (1 - e^(-(n d) / m))^d
  $
  Per minimizzare questa probabilità rispetto a $d$, con $m$ e $n$ fissati, si ottiene come condizione ottimale che la probabilità di un bit a 1 sia $1/2$. Pertanto:

  $
    1/2 = e^(-(n d) / m)
  $
]

La probabilità di falso positivo è $(1/2)^d$ quando è soddisfatta la condizione $m = (n d) / ln 2$. Questo significa che, per ogni elemento che vogliamo inserire e per $d$ funzioni di hash, servono circa $1.44d$ bit. In pratica:
- fisso il falso positivo desiderato e ricavo il valore di $d$;
- stabilisco quanti elementi voglio inserire, cioè $n$;
- calcolo $m$ e quindi la dimensione del vettore di bit. Il costo è circa $1.44$ bit per elemento per ogni dimezzamento del falso positivo.

#note()[
  Il filtro di Bloom occupa circa il $44$% in più rispetto al limite teorico di $d$ bit per elemento associato a un falso positivo pari a $(1/2)^d$.
]

Fissata la precisione, il filtro risponde in un tempo indipendente dal numero di elementi: esegue $d$ calcoli di funzioni di hash e altrettanti accessi al vettore. Il tempo dipende però dall'accesso alla memoria; se ogni interrogazione richiede 100 accessi fuori cache, il costo può essere elevato.

Quando inseriamo circa $n$ elementi, nella configurazione ottimale abbiamo approssimativamente metà zeri e metà uni. Si tratta comunque di una struttura che può diventare lenta, perché le funzioni di hash producono accessi apparentemente imprevedibili e quindi difficili da gestire per la cache dei processori.

#note()[
  Inoltre, quando il vettore è nella configurazione ottimale e si interrompe la ricerca al primo bit uguale a 0, il numero medio di accessi per una query negativa è circa $2$. Per questo motivo, nella pratica, i filtri di Bloom vengono spesso sovradimensionati per evitare la saturazione.
]

=== Blocked bloom filter

L'idea è prendere tanti filtri piccoli e metterli in fila. In un mondo perfetto, una funzione di hash assegna ogni chiave a un filtro e distribuisce lo stesso numero di chiavi in ciascun filtro, cioè circa $n/k$. Otteniamo così tanti filtri che funzionano come quello originale. Inoltre, scegliendo filtri della dimensione di una linea di cache, riduciamo i fallimenti di cache.

Problemi:
- L'analisi dell'errore non funziona direttamente per $m$ piccoli;
- il numero di chiavi assegnate a ciascun sotto-filtro segue una distribuzione binomiale, quindi le urne non saranno piene allo stesso modo. Alcuni sotto-filtri saranno più precisi e altri meno precisi.

#theorem()[
  Se abbiamo $n$ palle e $n$ urne e ogni palla viene assegnata uniformemente a un'urna, l'urna più piena non contiene soltanto un numero costante di elementi: con alta probabilità il suo carico massimo è dell'ordine di $log n / log log n$.
]

Ottimizzazione: per ridurre il costo del calcolo delle $d$ funzioni di hash, possiamo costruirle usando solo due funzioni di base:
$
  h_i (x) = (a(x) * i + b(x)) mod m
$
dove $a(x)$ e $b(x)$ sono due funzioni di hash casuali e $i$ è un indice che facciamo scorrere. In questo modo i calcoli sono più veloci. Le funzioni così ottenute non sono veramente indipendenti, ma in pratica il metodo offre spesso una buona approssimazione dell'indipendenza richiesta dall'analisi.

#import "../template.typ": *

= Crawling

Il crawling è il processo di visita automatica di pagine web, partendo da un insieme iniziale di URL (_seed_). L'obiettivo è estrarre informazioni dalle pagine visitate e scoprire nuovi URL da visitare. Ci interessa tenere traccia di tre insiemi:

- *Visitati*: l'insieme degli URL già visitati. Da essi abbiamo già estratto le informazioni necessarie

- *Frontiera*: l'insieme delle pagine che conosciamo ma non abbiamo ancora visitato. Può essere costituito da URL inseriti manualmente oppure raggiungibili da nodi già visitati. \
  La frontiera può essere ordinata secondo un *criterio di priorità* in modo da personalizzare il criterio del prossimo URL da visitare.
  #example()[
    Con una FIFO otteniamo una visita in ampiezza, con cerchi concentrici a partire da un nodo (ampliando man mano il raggio).
  ]

- *Sconosciuti*: l'insieme degli URL non ancora visitati e non ancora conosciuti.

Il problema fondamentale di quest’attività è la *gestione della frontiera*. Infatti, la frontiera è di ordini di grandezza più grande dell’insieme dei visitati. A tale scopo, è necessario utilizzare strutture dati efficienti per memorizzare la frontiera e per estrarre rapidamente il prossimo URL da visitare. Inoltre, è importante evitare di visitare più volte lo stesso URL, quindi è necessario tenere traccia degli URL già visitati.

== Ciclo di vita della visita

Una domanda naturale riguarda l'inizio e la fine della procedura di visita.

*Inizio della visita*: La visita inizia con l'insieme dei visitati vuoto e la frontiera inizializzata con il _seme_ (seed). Il seme rappresenta la nostra conoscenza esterna iniziale ed è costituito da un certo insieme di URL di partenza. Può essere un singolo vertice così come un milione di elementi.

*Sviluppo della visita*: Durante una visita in ampiezza, il processo procede per "sfere" concentriche attorno al seme (dove la distanza è esatta, al contrario di una "bolla" che comprende tutto il volume interno al raggio):

1. Vengono visitati gli elementi del seme (sfera di raggio 0).

2. Si visitano i successori diretti del seme (sfera di raggio 1).

3. Si procede con i successori di livello successivo (sfera di raggio 2, e così via).
Man mano che la visita procede da più elementi del seme, le rispettive sfere di esplorazione iniziano inevitabilmente a intersecarsi.

*Fine della visita*: Dal punto di vista teorico, la fine naturale del crawling avviene nel momento in cui la frontiera si svuota. Tuttavia, nella pratica dei casi reali:

- La frontiera non si svuota *mai*. Al contrario, tende a crescere esponenzialmente fino a saturare la memoria disponibile della macchina.

- Spesso si impongono limiti artificiali (es. "fermati a un milione di URL" oppure "non superare profondità 1 in ogni dominio").

- La terminazione può essere forzata da colli di bottiglia architetturali, come la saturazione delle strutture dati e la conseguente lentezza (es. limite di capienza del filtro di Bloom).

== Crivelli

Il crivello è la struttura dati di base di un crawler: accetta in ingresso URL potenzialmente da visitare e permette di prelevare URL pronti per la visita. Ogni URL che viene inserito nel crivello esce *una sola volta*, indipendentemente da quante volte è stato inserito. In questo senso il crivello unisce le proprietà di un dizionario a quelle di una coda con priorità, e rappresenta al tempo stesso
la frontiera, l’insieme dei visitati e la coda di visita.

#note()[
  Solitamente ricordare l'ordine di visita e ciò che abbiamo già visto può essere ricondotto a un'unica struttura dati (crivello) più efficiente, invece di separare i due problemi.
]

=== Collisioni

Un esempio sono i *filtri*, strutture dati simili a insiemi che permettono di tenere traccia di quali URL sono già stati visitati e quali no. Essi sono dizionari approssimati: possono produrre falsi positivi, ma non falsi negativi. In altre parole, se il filtro risponde *no*, possiamo fidarci; se risponde *sì*, dobbiamo verificare effettivamente la presenza dell'elemento.

In queste strutture è preferibile sostituire l'URL con una *firma* ottenuta tramite una funzione hash, in modo da risparmiare spazio e velocizzare le operazioni di ricerca. Ad esempio andando a inserire le firme in una tabella di hash si potrebbe risparmiare spazio (La firma ha lo stesso numero di bit). In questo caso, però il dizionario può produrre _falsi positivi_: sostenendo di conoscere un URL che in realtà non è stato visitato.

#warning()[
  L'unico problema è che due URL diversi possono avere la stessa firma (*collisione*), la cui probabilità deve essere stimata.

  #proof()[
    Per stimare le collisioni trattiamo la funzione hash come una funzione casuale, che mappa delle palle in delle urne. Dove siano:
    - $n$ numero di palle (cioè URL o chiavi inserite)
    - $u$ numero di urne (universo delle firme)

    Il numero atteso di coppie in collisione è
    $
      approx n^2 / (2u) "per" n "grande"
    $
    Il numero effettivo di collisioni è una variabile aleatoria; per valori grandi può essere approssimato tramite una distribuzione di Poisson.
  ]
]

#example()[
  Selezionando una funzione hash che produce firme a $64$ bit, abbiamo $2^64$ urne. Con $100$ miliardi di URL, il numero atteso di collisioni è:
  $ (100 * 10^9)^2 / (2 * 2^64) approx 271.05 $
  Il numero atteso di collisioni è basso e può essere gestito, per esempio verificando l'URL originale quando una firma risulta già presente.
]

#note()[
  Una tabella di hash non è adatta a memorizzare la frontiera, in quanto è necessario avere l'URL originale per poterlo visitare e non una firma.
]

=== Riallocazione delle strutture dati

Le *riallocazioni* delle tabelle hash sono estremamente instabili rispetto all'occupazione di memoria. Nel contesto di un Crawler vogliamo che le strutture dati utilizzino una quantità di memoria centrale fissata a priori. L'idea è che man mano che il crawler procede, il sistema rallenti piuttosto che smettere di memorizzare nuovi URL a causa della saturazione della RAM (*graceful degradation*).
#note()[
  Le tabelle hash non sono adatte a questo scopo perché, quando lo spazio è esaurito, spesso devono essere riallocate con una capacità doppia. Se non c'è più memoria disponibile, il crawler si blocca.
]

== Filtri di bloom

Si tratta di una struttura dati probabilistica che rappresenta un dizionario approssimato. Permette di aggiungere elementi all’insieme e chiedere se un elemento appartiene o no all’insieme, con il rischio di ottenere _falsi positivi_.

#note()[
  Un filtro di Bloom può si produrre falsi positivi, ma non falsi negativi: se la struttura risponde *$mr("no")$*, possiamo fidarci; se risponde *$mg("sì")$*, dobbiamo verificare effettivamente la presenza dell'elemento. La cosa utile è che utilizza una quantità di memoria fissata in anticipo.
]

Esso è costituito da due elementi:
- $m$: vettore di bit
- $d$: numero di funzioni di hash:
  $ h_0, h_1, ..., h_(d-1) $
  esse vanno dall'universo delle chiavi $U$ agli indici del vettore, cioè $U -> {0, ..., m - 1}$. Idealmente, ogni funzione di hash è *indipendente* dalle altre ed è uniformemente distribuita.

Due primitive:
- *`insert`*: data una chiave $x$, calcola i valori $h_i (x) forall i in d$, che indicano le posizioni associate a $x$ nel vettore di bit, e imposta a $1$ tutte queste posizioni.

- *`contains`*: data una chiave $x$, calcola i valori $h_i (x) forall i in d$. Se tutte le posizioni corrispondenti valgono $1$ (and), restituisce $mg("true")$; altrimenti restituisce $mr("false")$. Se restituisce $mr("false")$, allora la chiave sicuramente non è presente; se restituisce $mg("true")$, allora è probabilmente presente.

  #note()[
    Per ottenere un falso positivo, tutte le posizioni visitate dalle $d$ funzioni di hash della chiave interrogata devono risultare già impostate a 1. Non è quindi necessario che le funzioni di hash producano lo stesso indice: è sufficiente che le posizioni richieste siano state impostate da inserimenti precedenti.
  ]


#informally()[
  Se in passato abbiamo eseguito `insert(x)`, allora `contains(x)` restituisce sicuramente *true*, purché non vengano eseguite operazioni di reset.

  Se, per una collisione, `insert(y)` imposta a 1 tutte le posizioni associate a $x$, allora `contains(x)` restituisce *true* anche se $x$ non è presente: questo è un falso positivo.
]

Problema delle chiavi *multiple*: Una certa chiave $z$ potrebbe collidere su posizione con una chiave $x$ e con una chiave $y$, quindi se faccio `head(x)` e `head(y)` allora `contains(z)` ritorna *true* anche se non c'è. Questo è un falso positivo.

A parità di numero di elementi inseriti e di dimensione del vettore, aumentando $d$ controlliamo più bit e inizialmente avere un _falso positivo_ diventa meno probabile. Tuttavia, se $d$ è troppo grande, impostiamo molti più bit a $1$ e il vettore si satura.

#proof()[
  Vogliamo stimare la probabilità di avere un falso positivo. In realtà l'analisi fornisce una stima della probabilità di osservare un positivo (vero o falso che sia ) dopo $n$ inserimenti. Questa probabilità è chiaramente una *maggiorazione* della probabilità di avere un falso positivo.

  Supponiamo che le funzioni di hash siano casuali e indipendenti. La dimostrazione avviene per induzione sul numero di inserimenti:

  - *Singolo inserimento*: Per una funzione di hash, la probabilità di impostare un determinato bit a $1$ è $1/m$ e quindi la probabilità di non impostarlo è $1 - 1/m$.

  - *Inserimenti successivi*: Chiamiamo $n$ il numero atteso di inserimenti distinti. La probabilità che un certo bit sia ancora a 0 dopo $n$ inserimenti con $d$ funzioni di hash è:
    $ (1-1/m)^(n d) $
    La probabilità di ottenere un falso positivo, cioè di trovare tutti e $mr(d)$ i bit a $1$ per una chiave assente, è quindi:
    $ (1 - (1-1/m)^(n d))^mr(d) $
    Usando il limite notevole classico $mb((1 + alpha/n)^n -> e^alpha)$ per $n -> infinity$ e assumendo $m$ grande, possiamo approssimare la probabilità che un bit sia $0$ dopo $n$ inserimenti nel seguente modo:
    $
      & = (1 - (1-1/m)^(n d)) \
      & #text("divido e moltiplico per m per usare il limite") \
      & = (1 - (1-1/m)^(mr(m) * (n d) / mr(m))) \
      & = (1-(1-1/m)^m)^((n d) / m) \
      & = (mb(e^(-1)))^((n d) / m) = e^(-(n d)/ m) \
    $
    Per trovare la probabilità di falso positivo basta sostituire questa probabilità nella formula precedente:
    $ (1 - (1-1/m)^(n d))^d approx (1-e^(-(n d)/ m))^d $
    Andiamo ora a *minimizzare* questa probabilità rispetto a $d$, con $m$ e $n$ fissati:
    $
      mr(p) & = e^(-(n d) / m) \
       ln p & = - (n d) / m \
          d & = - m / n ln p
    $
]

#proof()[
  Sostituendo nella formula approssimata otteniamo:
  $ (1-e^(-(n d)/ m))^d = (1-mr(p))^(- m / n ln p) $
  Applicando la regola $ mb(x)^mg(y) = e^(y ln x) $ otteniamo:
  $ = e^(mg(- m / n ln p) ln (mb(1-p))) $
  Per trovare il minimo, deriviamo rispetto a $p$ e poniamo la derivata uguale a zero:
  $ f'(p) = e^(- m / n ln p ln (1-p)) [- m / n ((ln (1-p))/p - (ln p)/(1-p))] $
  Ora poniamo la derivata uguale a zero:
  $ mb(-m/n e^(- m / n ln p ln (1-p))) [ mr(((ln (1-p))/p - (ln p)/(1-p)))] = 0 $
  Siccome il blocco esponenziale $mb("blu")$ non può mai annullarsi, dobbiamo porre uguale a zero il blocco $mr("rosso")$:
  $
    (ln (1-p))/p - (ln p)/(1-p) & = 0 \
                   (ln (1-p))/p & = (ln p)/(1-p)
  $
  Moltiplico per $p(1-p)$:
  $ (1-p) ln (1-p) = p ln p $
  Sia il membro di destra che quello di sinistra sono identici alla forma $x ln x$. Una soluzione immediata si ha quando gli argomenti sono uguali, cioè imponendo $1-p = p$:$ 1-p & = p \
   2p & = 1 \
    p & = 1/2 $
  Sapendo che il minimo errore si ottiene per $p=1/2$ e ricordando la sostituzione $p = e^(-(n d) / m)$, otteniamo:
  $
        1/2 & = e^(-(n d) / m) \
    ln(1/2) & = - (n d) / m \
          d & = - m / n (-ln 2) \
          d & = m / n ln 2
  $
]

La dimostrazione mostra che la probabilità di falso positivo è minimizzata quando $d = (m/n) ln 2$. Invertendo la formula otteniamo:
$
  m & = (n d) / (ln 2) \
  m & = 1 / (ln 2) * n d \
  m & approx 1.44 n d
$
Questo significa che date $d$ funzioni hash, per ogni elemento che vogliamo inserire servono circa *$1.44d$ bit*. In pratica:
- fisso il falso positivo desiderato e ricavo il valore di $d$;
- stabilisco quanti elementi voglio inserire, cioè $n$;
- calcolo $m$ e quindi la dimensione del vettore di bit. Il costo è circa $1.44$ bit per elemento per ogni dimezzamento del falso positivo.

#note()[
  La teoria dell'informazione stabilisce che per identificare un elemento con una probabilità di errore pari a $2^(-d)$, servirebbero esattamente $d$ bit per elemento. Il filtro di Bloom ne richiede circa $1,44d$ per elemento, usando circa il $44\%$ di spazio in più rispetto alla compressione ideale.
]

Dal punto di vista teorico, il tempo di risposta di un filtro di Bloom è *costante e indipendente da $n$*: richiede esattamente $d$ calcoli di funzioni di hash e $d$ accessi in memoria. Nella pratica, tuttavia, il pattern di accesso casuale alla memoria è pessimo: ogni interrogazione positiva genera fino a $d$ fallimenti di cache (cache miss) un'operazione che a livello hardware è estremamente costosa.

#note()[
  Nella configurazione ottima la probabilità che un bit sia a zero è esattamente $1/2$. Ci sono quindi due casi:
  - Query negativa: la ricerca si interrompe al primo bit nullo trovato, bastano in media solo *2 accessi* in memoria per dichiarare l'assenza di un elemento (50% di probabilità di trovare un bit a 0 ad ogni accesso).

  - Query positiva: la ricerca deve controllare tutti i $d$ bit, quindi in media sono necessari *$d/2$ accessi* in memoria per dichiarare la presenza di un elemento.

  Per questo motivo si tende a sovradimensionare i filtri per abbassare ulteriormente i falsi positivi e ridurre le probabilità di query lente.
]

=== Blocked bloom filter

L'idea è prendere tanti filtri piccoli e metterli in fila. In un mondo perfetto, una funzione di hash assegna ogni chiave a un filtro e distribuisce lo stesso numero di chiavi in ciascun filtro, cioè circa $n/k$. Inoltre, dimensionando i  filtri in modo tale che rispecchino la dimensione di una linea di cache possiamo andare a ridurre i fallimenti di cache.

$mr("Problemi")$:
- L'analisi dell'errore non funziona direttamente per $m$ piccoli;
- il numero di chiavi assegnate a ciascun sotto-filtro segue una *distribuzione binomiale*, quindi le urne non saranno piene allo stesso modo. Alcuni sotto-filtri saranno più precisi e altri meno precisi.

#theorem()[
  Se $n$ palle vengono assegnate uniformemente a caso in $n$ urne, l'urna più piena non conterrà un numero costante di elementi: con alta probabilità, il suo carico massimo sarà dell'ordine di $O(log n \/ log log n)$.
]

Una possibile *ottimizzazione* per ridurre il costo del calcolo delle $d$ funzioni di hash è modificarne la costruzione in mod da poterle costruirle usando solo due funzioni di base:
$ h_i (x) = (a(x) * i + b(x)) mod m $
dove $a(x)$ e $b(x)$ sono due funzioni di hash casuali e $i$ è un indice che facciamo scorrere. In questo modo i calcoli sono più veloci. Le funzioni così ottenute non sono veramente indipendenti, ma in pratica il metodo offre spesso una buona approssimazione dell'indipendenza richiesta dall'analisi.

#import "../template.typ": *

= Crawling

Ci interessa di tenere traccia di 3 insieme:
- insieme degli url già visitati, abbiamo già estratto le informazioni necessarie

- frontera: pagine che conosciamo ma non abbiamo ancora visitato. Può essere costituita solo da url manuali o raggiungibili dai nodi visitati. \

  La frontiera può essere ordinata secondo qualche criterio di priorità che seleziona il prossimo url da visitatare (con una fifo abbiamo una visita in ampiezza cerchi concentrici a partire da un nodo, man mano si amplia il raggio). Le informazioni contenute nell'url vengono estratte e memorizzate

- url non ancora visitati e non ancora conosciuti

Servono delle strutture dati apposite per tenere traccia di questi insiemi in particolare capire quelli già visti (operazione che deve essere veloce, url presente in visitati o frontiera). Un esempio sono delle struttre dati detti *crivelli* come degli insiemi che ci permettono di tenere traccia di quali url sono già stati visitati e quali no. Solitamente ricordarsi l'ordine di visita e cosa ho già visto può essere ricondotto a una singola struttura dati più efficiente, rispetto che separare i due problemi.

== Collisioni

In caso di errori quello che viene fatto è rimpiazzare i dati mancanti con dei dati probabili. Nei crawlers solitamente non viene memorizzato l'url assoluto ma l'hash di tale url, in modo da risparmiare spazio e velocizzare le operazioni di ricerca (stringhe della stessa lunghezza). L'unico problema è che due url diversi possono avere lo stesso hash (*collisioni*), il quale è da stimare.

Per stimare le collisioni trattiamo la funzione hash come una funzione casuale, che mappa delle palle in delle urne. Per $n$ palle e $u$ urne il numer di collisioni è  $tilde (n^2) / (2n)$ (con una funzione aleatoria sarebbe una distribuzione di Poisson, per valori alti è talmente stretta che possiamo considerare il valore atteso come il valore reale).

#example()[
  Su $2^64$ urne quante coolsioni ci sono con 100 miiardi di url?
  $
    (100 * 10^9)^2 / (2 * 2^64) = 271
  $
  il numero di collisioni è basso e facilmente evitabile.
]

Nella struttura che rappresenta gli url già visitati andremo a memorizzarne la signatura (hash) e non l'url stesso, in modo da risparmiare spazio ed essendo ad alta frequenza di accesso minimizzare i tempi.

#note()[
  Questo approccio non va bene per la frontiera, lì ci deve essere fisicamente l'url, perché dobbiamo visitarlo fisicamente.
]

== Riallocazione delle strutture dati

Le rialocazini delle tabelle di hash sono estramente instabili rispetto all'occupazione di memoria. Tutte le stutture dati devono essere a memoria centrale costante. Voglio che man mano che il crwaler va avanti si rallenti piuttosto che non memorizzare nuovi url per saturazione della ram (*gracefull degradation*).
#note()[
  Le tabelle di hash non andrebbero bene in quanto se è finita la memoria essa deve essere riallocata con il doppio dello spazio, se non c'è più memoria il crawler si blocca.
]

=== Filtri di bloom

Si tratta di un dizionario approssimato con dei falsi positivi (se la struttura dice no allora posso fidarmi se dice di si che c'è in struttura devo effitivamente controllare). La cosa utile è che utilizza memoria costante.

Esso è costiutio da due pezzi:
- $m$: vettore di bit
- $d$: ci sono $d$ funzioni di hash che vanno da $U->m$ ovvero dall'universo delel chiavi a $m$. Ogni funzione di hash è indipendente dalle altre e uniformemente distribuita.


Due primitive:
- `head`: Data una chiave $x$ calcola le funzioni $h_i (x)$, esse mi danno le posizioni di $x$ nel vettore di bit $m$ e setta a 1 tutte queste posizioni.
- `contains`: prendo una chiave $x$ e calcolo le funzioni $h_i (x)$, se tutte le posizioni sono a 1 (and) allora ritorno *true* altrimenti ritorno *false*. Se ritorno *false* allora sicuramente non c'è, se ritorno *true* allora probabilmente c'è.

#note()[
  Se ho fatto head(x) in passato allora contains(x) ritorna sicuramente *true* (no operazioni di reset).

  Se per sfiga ho facendo head(y) va a settare a 1 tutte le posizioni di x allora contains(x) ritorna *true* anche se non c'è, questo è il falso positivo.
]

Per dare un falso positivo dobbiamo trovare tante collisioni, per favore un errore dobbiamo ottenere un errore su tutte le funzioni di hash.

Problema delle chiavi *multiple*: Una certa chiave $z$ potrebbe collidere su posizione con una chiave $x$ e con una chiave $y$, quindi se faccio head(x) e head(y) allora contains(z) ritorna *true* anche se non c'è. Questo è un falso positivo.

#note()[
  Più alto è $d$ più è alto il bit che andiamo a guardare meno è probabile che ci sia un falso positivo. $d$ più grande è molta più precisione nelle interrogazioni

  Tuttavia maggiore è grande $d$ più bit setto a 1 e quindi vado a saturare il vettore di bit.
]

#warning()[
  Anche avere un hash set con le firme è una stuttura probabilistica tuttavia è preferibile avere un filtro di bloom perché il vettore è a dimensione fissa. Tuttavia il filtro di bloom una volta che superiamo un certo limite di numero di 1 settati il filtro di bloom degrada gradualmente, presentando un numero sempre maggiore di falsi positivi.
]

#proof()[
  Vogliamo stimare la probabilità di avere un falso positivo.

  Andiamo a suppore che le funzioni di hash siano casuali.

  Supponiamo di fare un inserimento singolo (1 bit), la probalità di settare un bit a 1 è $1/m$ e quindi la probabilità di non settarlo è $1-1/m$.

  Chiamiamo con $n$ il numero massimo atteso di inserimenti distinti. Qual'è la probabilità che un certo bit sia a 0 dopo $n$ inserimenti con $d$ funzioni di hash:
  $
    (1-1/m)^(n d)
  $
  la probabilità che sia a 1 è quindi (1 bit a 1 dopo n inserimenti con d funzioni di hash):
  $
    1 - (1-1/m)^(n d)
  $
  La probabilità di avere un positivo (tutti e $d$ i bit a 1) è quindi:
  $
    (1 - (1-1/m)^(n d))^d
  $
  Usando il limite notevole calssico $(1+alpha/n)^n -> e^alpha$ e dato che abbiamo in mente $m$ grandi possiamo usare il limite notevole per approssimare:
  $
    "divido e moltiplico per m" \
                                & = (1 - (1-1/m)^(m * (n d) / m))^d \
                                & approx (1 - e^(-(n d) / m))^d
  $
  Siccome vogliamo minimizzare tale quantità $p = e^(-(n d) / m)$\
  ......\
  ......\
  $e^(-(m/n)ln p ln (1-p))$

  L'unica soluzione alla fine è $p=1/2$

  Ora otteniamo $ 1/2 & = e^(-(n d)/m) \ $
]

La probabilità di errore è $(1/2)^d$ se viene soddisfatta la condizione $m = (n d) / ln 2$: significa che per ogni elemento che vogliamo inserire e d funzioni di hash ci servono $1.4 "bit"$. uso comune:
- fisso l'errore che voglio ovvero $d$
- so quanti elementi voglio inserire $n$
- calcolo $m$ e quindi la dimensione del vettore di bit. il costo è 1.44 bit per ogni fattore emezzo di errore.

#note()[
  Il filtro di bloom occupa il $44$% in più rispetto alla struttura dati ottiamale (essa usa $m = d$ bit).
]

Fissata la precisione risponde con un tempo indipendente dal numero di elementi (risponde in $d$ passi funzioni di hash). Dipende dal tempo di accesso alla memoria, se il tempo costante è 100 accessi fuori cash allora è molto.

Quando andiamo a inserire $n$ elementi abbiamo circa metà zeri e meta uni. Si tratta di una struttura che può diventare molto lenta in quanto . Le funzioni di hash sono dunque impredicibili, di conseguenza è imprevedibile dai processori per quanto riguarda la cache.

#note()[
  Inoltre a regime massimo (dopo $n$ inserimenti) il numero di accessi medio è $2$ in quanto si alza la probabilità di errore. Per questo motivo i filtri di bloom si sotto dimensioano.
]

=== Blocked bloom filter

L'idea è prendere tanti filtri piccoli e metterli in fila. In un mondo perfetto la funzione avendo una funzione di  hash mette lo stesso numero di chiavi in ogni filtro $n/k$ (ad ogni chiave assegna il corispettivo filtro) e tutto torna come prima (tanti filtri che funzionano come prima). Tuttavia per $m$ molto piccoli non ho più fallimenti di cache.

Problemi:
- L'analisi dell'errore non funziona per $m$ piccoli
- la funzione di hash segue una binomaile, le urne non saranno piene allo stesso modo. Alcuni sotto-filtri saranno più precisi e altri meno precisi.

#theorem()[
  Se ho n buci e n urne l'urna più piena non avrà in più un numero costante di elementi ma crescerà con il numero di palle ovvero: $log log n$.
]

Ottimizzazione: per non dipendere da funzioni di hash casuali possiamo andare a costrire le $d$ funzioni di hash in questo modo usandone solo due: 
$
  h_i (x) = (a(x) * i + b(x)) mod m
$
dove $a(x)$ e $b(x)$ sono due funzioni di hash casuali e $i$ è un indce che facciamo scorrere. In questo modo i calcoli sono più veloci e le funzioni di hash sono indipendenti.
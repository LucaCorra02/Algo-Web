#import "../template.typ": *

= Elias fano

Per ogni numero rappresentiamo i bit alti e bassi in maniera diversa. Sia $l$ il numero che permette di dividere in bit alti e bassi:
$
  l = max(0, floor(log_2(u/n)))
$
ogni $x_i$ si spessa nei suoi $l$ bit bassi e nei bit alti $h_i = ceil(x_i/2^l)$. Se abbiamo una successione monotona e dividiamo per una monotona otteniamo una distribuzione monotona. Possiamo vedere i bit bassi come rumore, mentre i bit alti come informazioni, essendo più strutturati riusciamo a rappresentarli in maniera più compatta (crescono piano e sono compatti).

I bit alti vengono rappresentati come scarti in unario. In unario $k$ diventa $k$ zeri seguiti da un uno. L'elemento $x_i$ si lascia $i$ uni a desrra mentre il numero di zero che si lascia a sinistra è pari al numero di bit alti.


$
  p = i + v
$
valore dell'indice + il valore dei bit alti. Se capito in una posizione casuale del vettore, ad esempio questo è l'uno in valore 10 possiamo risalire al valore dei bit alti, stessa cosa al contrario capitando su uno zero. Con elias fano quando cerchiamo per valore abbiamo automaticamente la posizione, ci permette di verificare un qualsiasi tipo di ricerca dicotomica, possiamo fare tutte le operazioni in tempo costante.

Possiamo vedere la posizione di $x_i$ come:
- Il numero di uni a destra è $i$.
- Il numero di zeri a sinistra è $h_i$. Sottraendo l'indice al numero di uni otteniamo il numero di zeri a sinistra, ottenendo il valore dei bit alti.
Questa proprietà è dovuta al fatto di scrivere gli scarti in unario. Questa proprità non si avrebbe se scrivessimo gli scarti con un qualsiasi altra codifica.

//aggiungere esempio

== Spazio occupato

Ci sono di sicuro $n$ uni, in quanto sono i tappi dell'unario.\
Ogni zero aumenta di 1 bit gli alti: Al più ci sono $2n$ zeri. L'idea è trovare l'ultimo valore del vettore e prendere il numero di zero che lo precedendono
$
  h_(n-1) = ceil(x_(n-1)/2^l) <= u / 2^l\
  "con il nostro" l "vale" 2^l >= u / (2n) "cioè"
$
la struttura è succinta: $log (u n)$. Più la lista è densa meno spendiamo per elemento.

#warning()[
  Il limite non dipende dalla distribuzione dei dati (non stiamo facendo compressione). Usiamo il numero minimo di spazio per qualsiasi struttura possibile.
]
Il gamma consuma più spazio quando usiamo degli spazi equi, cioè ogni spazio maniente $u/n$ elementi, ci servono con gamma $2 log(u/n)$ più lento rispetto a Elias fano che ci mette $log(u/n)$. Le strutture succinte sono utili quanto non sappiamo nulla della distribuzione dei dati, mentre i codici istantanei sono utili quando possiamo andare ad approssimare la distribuzione dei dati.

=== Struttura bilanciata
c'è un bilancio ragionevole tra zeri e uni, in media è lo stesso numero. Molto buono in quanto possiamo andare a rendere le operazioni in modo ragionevole. I bit bassi invece possono essere rappresentati in un vettore di dimensione $n$ e quindi possiamo accedere in $O(1)$ al valore dei bit bassi. Per i bit alti invece possiamo usare una struttura bilanciata, che ci permette di fare rank e select in $O(1)$.

#note()[
  Possiamo avere anche delle liste mononotone non crescenti e funziona lo stesso
]

== Lettura in successione

Per leggerli in successione supponiamo di guarfdare solo gli uni. Dobbiamo cercare semplicemente l'uno successivo. Se ho letto i codici unari e sono in posizione $i$, i bit bassi sono $p-i$, mentre i bit alsti sono $i l, x_i = (p-i)2^l$.

Teniamo una finestra grande come una parola che guarda i bit alti, basta cercare il primo uno:
- Dopo averlo trovato posso andare a cancellare l'uno più basso
- $w <- w and (w-1)$ in complemento a due cancella il bit più bassi.
- A questo punto continuamo a cercare l'uno successivo. Procediamo così fino a quando non abbiamo finito di leggere tutti gli uni. In questo modo leggiamo tutti i bit alti in successione.

== Acesso diretto

Tramite $"get"(i)$. Quello che facciamo prendiamo una parola di una macchina e tramite una pop-count contiamo il numero di uni all'intero della parola (vogliamo trovare l'i-esimo uno). Ogni pop-count brucia 20/30 documenti avendo lo stesso numero di zeri e uni.

Una volta trovato l'uno, possiamo andare a leggere i bit bassi e quindi risalire al valore.

== Puntatori in avanti per get

Se saltiamo ad una posizione casuale sapendo l'indice possiamo.

I gap non sono a distanza regolare ma non è un problema se ci sono gap pù grandi e gap più piccoli, in quanto in media sono $3q$ perchè ci sono metà zeri e metà uni e ci sono $q$ uni.

== SkipTo(b)

Se voglio l'elemento $>=b$ equivale a dire che vogliamo trovare un elemento i cui bit alti sono $>=b$. In quanto nessun elemento precedente può essere >=. A questo punto arriviamo su un elemento in una certa posizione, non è detto che esso sia quello finale in quanto dobbiamo andare a controlalre i bit basis.

Se atteriamo su un uno controlliamo i bit bassi, se atteriamo su uno zero, significa che ha i bit alti più grandi, possiamo non dare una ricerca e trovare il primo uno successivo.

Se capito su un uno procedo fino a trovare l'elemento che mi interessa procedendo sequenzialmente guardando i bit bassi.

Possiamo farlo una parola alla volta. Non abbiamo bisono di scorrere sequenzialmente. Se cerco il 50 esimo uno posso parola per parola contare il numero di uni che ci sono e continuare a scalare fino alla parola giusta.

== Conteggi

Per i conteggi usuami una successione crescente delle occorenze, ovvre una somma cumulativa. Tali valori li andremo a rappresentare con Elias fano.

== Posizioni

per ogni documento abbiamo le posizioni in cui compare un termine. Come faccioa a sapere da dove iniziano le posizioni di ogni documento. Ogni documento ha lunghezza c. Anche in questo caso è la somma prefisse dei conteggio, sono i confini per i blocchi. non abbiamo bisogno di nessun indice per campionare dove iniziano le posizioni.

Le posizione vengono memorizate tramite:
- Ogni blocco di posiozni ci salviamo gli scarit
- Somma cumulativa
- Elias fano


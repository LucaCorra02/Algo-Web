#import "../template.typ": *

== Codice binario

Un codice binario di *ampiezza $k$* è istantaneo e ogni parola ha la stessa lunghezza $k$. In questo caso, la lunghezza delle parole è $2^k$.

Se tutti i simboli hanno la stessa frequenza allora il codice *binario è ottimale*, in quanto ogni parola ha la stessa lunghezza e quindi non ci sono parole più lunghe di altre.

== Codice unario

Esistono due tipologie di codice unario:
- *$1^* 0$*: tanti $1$ quanti la lunghezza del numero, seguito da uno $0$.

  #note()[
    Il codice *$1^* 0$* ha un *ordine lessicografico*: l'ordine tra le parole del codice corrisponde all'ordine tra la gli interi da essi rappresentati. Formalmente:
    $ "se" x <= y -> 1^x 0 <= 1^y 0 $

    Ad esempio:
    - $0 = 0$
    - $1 = 10$
    - $2 = 110$
    - $3 = 1110$
  ]

  Nel caso del codice $1^* 0$, per confrontare due parole basta confrontare i bit uno alla volta, fino a trovare il primo bit a $0$. la parola con il primo bit a $0$ più a sinistra è la *minore*, mentre quella con il bit a $0$ più a destra è la *maggiore*.


- *$0^* 1$*: tanti $0$ quanti la lunghezza del numero, seguito da uno $1$.

  Il codice $0^* 1$ invece *non ha ordine lessicografico*. Il suo vantaggio risiede nelle operazioni di lettura del codice. Consideriamo infatti un codice unario rappresentato in little-endian. Per leggere il numero, è necessario calcolarne la sua lunghezza, ossia trovare la *posizione del primo bit a $1$*. Nelle CPU moderne, esistono delle istruzioni apposite per trovare il primo bit a $1$, rendendo questa operazione molto più efficiente.

#warning()[
  Il problema dei codici unari è che, per rappresentare un numero $k$, servono $k+1$ bit.\ Quindi è *utilizzabile solo per $k$ piccoli*.
]

== Codice di Elias $gamma$ (gamma)

Il codice di *Elias $gamma$* è un codice universale per interi non negativi ($x >= 0$), particolarmente efficiente quando la distribuzione dei dati favorisce i numeri piccoli (la lunghezza del codice cresce logaritmicamente con $x$).

=== Rappresentazione binaria ridotta
Per codificare un intero $x >= 0$, si calcola innanzitutto la sua *rappresentazione binaria ridotta*:
1. Si trasla l'intero calcolando *$x + 1$* (necessario poiché il valore $0$ non avrebbe un bit più significativo a $1$).

2. Si scrive $x + 1$ in binario standard.

3. Si rimuove il *bit più significativo* (MSB), che per costruzione è sempre pari a `1`.

Chiamiamo con *$lambda(x+1) = floor(log_2(x+1))$* la lunghezza in bit della rappresentazione binaria ridotta (ovvero la posizione a base zero del bit più significativo di $x+1$). La rappresentazione binaria standard di $x+1$ ha quindi lunghezza $lambda(x+1) + 1$, mentre quella ridotta ha esattamente lunghezza $lambda(x+1)$.

#example()[
  Calcolo della rappresentazione binaria ridotta per alcuni valori di $x$:
  - $mr(x = 0) -> underbrace(x+1, "somma +1") = 1 -> "binario:" 1 -> "rap ridotta:" mb(epsilon)$ (stringa vuota, lunghezza $lambda(1) = 0$)

  - $x = 1 -> x+1 = 2 -> "binario:" 10 -> "ridotta:" 0$ (lunghezza $lambda(2) = 1$)

  - $x = 5 -> x+1 = 6 -> "binario:" 110 -> "ridotta:" 10$ (lunghezza $lambda(6) = 2$)
]

=== Costruzione del codice Elias $gamma$
Il codice Elias $gamma(x)$ si ottiene concatenando due componenti:
1. *Prefisso (Lunghezza in unario):* la lunghezza $lambda(x+1)$ della rappresentazione binaria ridotta, codificata in *unario invertito $0^* 1$* (ovvero $lambda(x+1)$ bit uguali a `0` seguiti da un bit `1` di terminazione).

  #note()[
    L'uno finale funge contemporaneamente da terminatore dell'unario e da bit più significativo implicito di $x+1$.
  ]


2. *Suffisso (Mantissa):* la *rappresentazione binaria ridotta* di $x$, di lunghezza $lambda(x+1)$.

#example()[
  - *Codifica di $x = 0$:* \
    Ridotta: $0 -> 1 -> mb(epsilon)$ (lunghezza $0$ bit)\
    Lunghezza in unario ($0^* 1$): $mr(1)$ \
    Codice finale: $mr(1)mb(epsilon) =$ *`1`*

  - *Codifica di $x = 1$:* \
    Ridotta: $1 arrow.r 2 arrow.r 10 arrow.r mb(0)$ (lunghezza $1$ bit) \
    Lunghezza in unario ($0^* 1$): $mr(01)$ \
    Codice finale: `01` `0` $=$ *$mr(01)mb(0)$*

  - *Codifica di $x = 2$:* \
    Ridotta: $2 arrow.r 3 arrow.r 11 arrow.r$ `1` (lunghezza $1$ bit) \
    Lunghezza in unario ($0^* 1$): `01` \
    Codice finale: `01` `1` $=$ *`011`*

  - *Codifica di $x = 3$:* \
    Ridotta: $3 arrow.r 4 arrow.r 100 arrow.r mb(00)$ (lunghezza $2$ bit) \
    Lunghezza in unario ($0^* 1$): $mr(001)$ \
    Codice finale: `001` `00` $=$ *$mr(001)mb(00)$*
]

Sia $lambda(x+1) = floor(log_2(x+1))$ la *lunghezza della rappresentazione binaria ridotta* di $x$:

- La *parte binaria ridotta* richiede esattamente $lambda(x+1)$ bit.

- La *parte in unario* ($0^(lambda(x+1)) 1$) richiede $lambda(x+1) + 1$ bit.

Sommando i due contributi, la lunghezza totale in bit della parola codificata è:
$
  |gamma(x)| & = underbrace(mr(lambda(x+1)), "ridotta") + underbrace(mb(lambda(x+1) + 1), "unario") \
             & = 2 lambda(x+1) + 1 \
             & = 2 floor(log_2(x+1)) + 1
$

=== Proprietà del codice

Il codice Elias $gamma$ è un *codice istantaneo (o codice prefisso)*, in quanto:

1. *La parte in unario è istantanea per definizione:* leggendo il flusso di bit da sinistra verso destra, contiamo il numero $L$ di zeri consecutivi fino a incontrare il primo bit `1`. Non può esserci ambiguità su dove termini la parte unaria.

2. *La parte binaria ridotta diventa un codice a lunghezza fissa nota:* una volta decodificata la parte unaria, il decodificatore conosce esattamente il valore *$L = lambda(x+1)$*, ovvero sa esattamente quanti bit successivi compongono la rappresentazione ridotta. Poiché tutte le parole con lo stesso prefisso unario hanno una mantissa della *stessa lunghezza fissa* $L$, nessuna può essere prefisso di un'altra.

*Procedura di decodifica:*
1. Si contano gli `0` iniziali fino al primo `1`: sia $L$ il numero di zeri letti.
2. Si leggono i successivi $L$ bit dopo l'`1`.
3. Prependendo l'`1` ai bit appena letti si ottiene direttamente la rappresentazione binaria di $x+1$, da cui si ricava $x$.

#note()[
  Poiché la parte unaria usa la convenzione $0^* 1$, i numeri più grandi hanno più `0` all'inizio. Pertanto, per il codice Elias $gamma$ così definito, l'ordine lessicografico *inverte* l'ordine tra blocchi di diversa grandezza (più il numero ha ordine di grandezza elevato, più zeri iniziali possiede), mentre *preserva* l'ordine naturale all'interno dello stesso blocco di lunghezza $L$ (ad esempio `010` $<$ `011` per $1 < 2$).
]

== Codice di Elias $delta$ (Delta)

Come possiamo migliorare il codice di Elias $gamma$ (Gamma)? Il problema principale di $gamma$ è che richiede circa $2 log(x)$ bit per rappresentare un numero $x$. Quella costante moltiplicativa $2$ davanti al logaritmo può comportare uno spreco di spazio considerevole per numeri molto grandi.

- L'obiettivo del codice *Elias $delta$* è ottenere una rappresentazione più compatta per i numeri grandi, avvicinandosi al limite inferiore teorico di $log(x)$ bit, sacrificando solo una piccola quantità per i metadati (senza sprecare la costante).

L'algoritmo funziona in questo modo (assumendo la mappatura $k -> x = k + 1$ per codificare numeri a partire da zero):
+ Si prende la rappresentazione binaria del numero $x$. Sia $L$ la sua lunghezza in bit, ovvero $L = floor(log(x)) + 1$.
+ Invece di scrivere $L$ in unario (come fa $gamma$), *scriviamo $L$ in codice Elias $gamma$*.
+ Di seguito, scriviamo la rappresentazione binaria di $x$, *omettendo il bit più significativo* (che sappiamo essere sempre 1).

#example(title: [Costruzione del codice Elias $delta$])[
  Di seguito la codifica di $k$ (con $x = k+1$). La colonna "*$gamma(L)$ + Resto*" mostra la concatenazione di due elementi: la lunghezza $L$ codificata in Elias $gamma$ e la rappresentazione binaria di $x$ a cui è stato rimosso il primo bit (il resto).

  #align(center)[
    #table(
      columns: 5,
      align: center,
      stroke: 0.5pt + luma(200),
      fill: (x, y) => if y == 0 { luma(240) },
      [*$k$*], [*$x$*], [*Binario ($x$)*], [*$gamma(L)$ + Resto*], [*Codifica $delta$*],
      [0], [1], [1], [$1$ + $epsilon$], [*1*],
      [1], [2], [10], [$010$ + $0$], [*0100*],
      [2], [3], [11], [$010$ + $1$], [*0101*],
      [3], [4], [100], [$011$ + $00$], [*01100*],
      [4], [5], [101], [$011$ + $01$], [*01101*],
      [5], [6], [110], [$011$ + $10$], [*01110*],
      [6], [7], [111], [$011$ + $11$], [*01111*],
      [7], [8], [1000], [$00100$ + $000$], [*00100000*],
      [8], [9], [1001], [$00100$ + $001$], [*00100001*],
    )
  ]
]

*Analisi della lunghezza:* \
Quanto è lungo il codice $delta$?
- La parte "ridotta" (il resto) occupa $floor(log(x))$ bit.
- La lunghezza $L$ codificata in $gamma$ occupa $2 floor(log(L)) + 1 = 2 floor(log(floor(log(x)) + 1)) + 1$ bit.

Definendo $lambda(x)$ come la lunghezza in bit dell'intero, e sommando il tutto, otteniamo:
$abs(delta(x)) = lambda(x+1) + 2 lambda(lambda(x+1)) + 1 approx log(x) + 2 log(log(x)) + 1$

Inizialmente, per valori di $x$ piccoli, il codice $delta$ è più lungo del $gamma$. Tuttavia, asintoticamente, il termine $2 log(log(x))$ cresce in maniera estremamente lenta (tende ad essere *"evanescente"*), rendendo Elias $delta$ vincente sui grandi numeri.

#note(title: [Codici di Levenshtein (Elias Omega)])[
  Potremmo spingerci oltre e fare una versione iterata di questo ragionamento (chiamata codifica *Elias $omega$* o codici di *Levenshtein*, definiti in maniera ricorsiva applicando ripetutamente il logaritmo).
  Tuttavia, i vantaggi di comprimere ulteriormente il termine $log(log(x))$ inizierebbero a vedersi solo per interi astronomicamente grandi (es. $10^{100}$). Per questo motivo, nessuno usa queste varianti estreme nella pratica.
]


== Codice di Golomb

Rispetto ai codici di Elias, il codice di Golomb ha un parametro di sintonizzazione $b >= 1$. È estremamente efficiente quando i dati seguono una distribuzione geometrica (es. intervalli tra occorrenze in indici invertiti).

Dato un numero $x >= 0$ e un parametro $b$, la codifica divide $x$ in due parti:
+ *Quoziente* $q = floor(x / b)$: codificato in *unario* (ovvero $q$ zeri seguiti da un $1$, o viceversa $0^q 1$).
+ *Resto* $r = x mod b$: codificato in *binario minimale* (o troncato).

Ma come gestiamo il resto se $b$ *non* è una potenza di 2? Non possiamo usare la codifica binaria standard senza sprecare bit. Qui entra in gioco il *binario minimale*.

#informally(title: [Cos'è il Binario Minimale? (Truncated Binary)])[
  Il binario minimale è una famiglia di codici ottima per distribuire parole di codice di lunghezza variabile, minimizzando lo spreco. L'idea è dividere i valori possibili in due gruppi: uno scritto con un bit in meno, l'altro con un bit in più.

  Definiamo $k = ceil(log(b))$ (il numero di bit necessari se arrotondiamo per eccesso) e $S = 2^k$.
  Vogliamo codificare $b$ valori. Se $b < S$, avremo dei "buchi".
  - Le prime *$S - b$* parole di codice usano *$k - 1$ bit*.
  - Le restanti *$2b - S$* parole di codice usano *$k$ bit*.

  *Da sapere per l'esame:* questa tecnica a volte usa più bit del limite inferiore teorico e a volte ne usa di meno. Nel limite, facendo la media, tende a un valore di entropia ottimo. È il modo standard per scrivere i resti modulari nei codici di Golomb quando $b != 2^k$.
]

#example(title: [Esempi di Codifica Golomb e Binario Minimale])[
  - *Caso $b = 1$:*
    Il quoziente è $x/1 = x$. Il resto è sempre $0$. Di fatto, è esattamente la codifica in unario (es. $0^x 1$).

  - *Caso $b = 2$:*
    In questo caso $b$ è potenza di due ($k=1, S=2$). Tutte le parole per il resto usano $k=1$ bit (dimensione costante).
    - $0 -> q=0$ `(1)`, $r=0$ `(0)` $->$ *10*
    - $1 -> q=0$ `(1)`, $r=1$ `(1)` $->$ *11*

  - *Caso $b = 3$:*
    Calcoliamo i limiti: $k = ceil(log(3)) = 2$. $S = 2^2 = 4$.
    Prime $S-b = 4-3 = 1$ parole (il valore $0$) usano $1$ bit.
    Restanti $2b-S = 6-4 = 2$ parole (i valori $1, 2$) usano $2$ bit.
    - $0 -> q=0$ `(1)`, $r=0$ `(0)` $->$ *10*
    - $1 -> q=0$ `(1)`, $r=1$ `(10)` $->$ *110*
    - $2 -> q=0$ `(1)`, $r=2$ `(11)` $->$ *111*
    - $3 -> q=1$ `(01)`, $r=0$ `(0)` $->$ *010*

  - *Caso $b = 4$:*
    Essendo potenza di 2, usa bit costanti per il resto ($k=2$).
    - $0 -> 00$, $1 -> 01$, $2 -> 10$, $3 -> 11$.

  - *Caso $b = 5$:*
    $k = 3, S = 8$. Le prime $8-5=3$ parole usano 2 bit, le restanti 2 usano 3 bit.
    - $0 -> 00$
    - $1 -> 01$
    - $2 -> 10$
    - $3 -> 110$
    - $4 -> 111$
]

=== Varianti del Golomb

- *Golomb-Rice ($b = 2^k$):*
  È una restrizione in cui il parametro $b$ deve obbligatoriamente essere una potenza di $2$. In hardware/software:
  - La divisione diventa uno *shift a destra* dei bit.
  - Il modulo diventa un'*operazione AND* bit a bit (maschera).

- *Ottimizzazioni hardware/software (Constant Folding):*
  Quando $b$ non è una potenza di due (Golomb standard), l'operazione di modulo è computazionalmente costosa. Nelle implementazioni reali, i compilatori precalcolano delle tabelle per fare *constant folding*, trasformando la divisione/modulo in una moltiplicazione per l'inverso dell'intero, velocizzando drasticamente la codifica.

- *Exp-Golomb (Exponential Golomb):*
  Se i numeri sono molto grandi, l'unario del quoziente esplode. L'Exp-Golomb codifica il quoziente usando codici logaritmici come l'Elias $gamma$ o $delta$, unendo la granularità del parametro di Golomb alla scalabilità asintotica di Elias. È ampiamente utilizzato negli standard di compressione video moderni (come H.264 e HEVC). La ricostruzione del valore originale in fase di decodifica avviene calcolando semplicemente: $x = b dot q + r$.


== Codici a Blocchi a Lunghezza Variabile (Variable-Length Block Codes)

I codici a blocchi (come il codice variabile a *nibble* o a *byte*, spesso noto come *vByte*) sono tra i più utilizzati in pratica. Essendo allineati ai limiti di byte (o multipli), sono estremamente "*hardware-friendly*", garantendo velocità di decodifica eccezionali.

L'idea generale è che ogni parola è formata da un numero variabile di blocchi di $k$ bit (es. $k=4$ per il nibble, $k=8$ per il byte).
- Il *primo bit* del blocco è il *bit di continuazione*: se è `1`, indica che il codice continua nel blocco successivo; se è `0`, indica l'ultimo blocco.
- I restanti *$k-1$ bit* (il *payload*) contengono la rappresentazione binaria dell'intero $x$.

*Formula della Lunghezza:* \
Un intero $x$ viene scritto in notazione binaria e diviso in blocchi da $k-1$ bit. La lunghezza totale in bit della parola di codice per $x$ sarà quindi:
$mr(L) = ceil((log(x) + 1) / (k - 1)) dot k$

Poiché per ogni 7 bit di informazione utile siamo costretti ad aggiungere 1 bit di overhead (il bit di continuazione), il costo asintotico di questo codice è circa $8/7 log(x)$. Pur essendo leggermente meno compresso di Elias, la sua natura byte-aligned lo rende immensamente più veloce in decodifica.

#warning(title: [Il problema dell'Incompletezza (Ridondanza)])[
  I codici a lunghezza variabile classici sono privi di prefissi, ma *non sono completi*. Questo accade perché permettono di aggiungere blocchi di zeri non necessari (padding).
  Ad esempio, una lista di blocchi contenente solo bit a zero decodifica allo stesso numero $0$ rappresentato da un singolo blocco di zeri. Nello spazio sintattico del codice esistono parole (e combinazioni) valide che non codificano nuovi valori utili, sprecando capienza.
]

=== Miglioramenti alla Decodifica (Prefissi e Biiettività)

Ci sono due miglioramenti principali che si possono applicare a questa famiglia di codici:

*1. Predicibilità in decodifica (Spostamento dei bit di continuazione)* \
Per rendere il codice più veloce e ridurre i salti condizionali (branch) della CPU, si possono rimuovere i bit di continuazione sparsi e raggrupparli all'inizio. In molte implementazioni reali, il *primo byte* contiene semplicemente un intero che esprime il *numero esatto di byte successivi* da leggere.

*2. Rendere il codice Completo (vByte Biiettivo o Shifted)* \
Per recuperare lo spazio sprecato dalle ridondanze, si modifica la logica di codifica. Nel vByte standard, un numero come $5$ può essere scritto usando un solo blocco, ma tecnicamente anche usando due blocchi (aggiungendo un blocco di zeri). Questo significa che lo spazio semantico non è coperto in modo ottimale.

Nel vByte biiettivo (o shifted), *ogni intero ha una e una sola rappresentazione valida*. L'idea è che con $b$ blocchi codifichiamo *esclusivamente* i valori successivi a quelli già coperti usando $b-1$ blocchi.

In fase di decodifica, al valore binario letto (il payload $P$) sommiamo un *offset* pari al numero totale di valori esprimibili con stringhe più corte. Formalmente, per blocchi con $k-1$ bit di payload, la decodifica di una parola lunga $b$ blocchi è:

$ mb(X) = P + sum_{i=1}^{b-1} 2^{i(k-1)} $

#example(title: [Rappresentazione Visiva: Intervalli nel vByte Biiettivo ($k=8$)])[
  In questo schema, usando blocchi da 1 byte ($k=8$, di cui 7 bit di payload), vediamo come gli intervalli si impilino perfettamente sfruttando le potenze di due. L'offset è esattamente la somma delle capacità di tutte le righe precedenti.

  #align(center)[
    #table(
      columns: (auto, auto, 1fr, 1fr),
      align: (center, center, left, left),
      stroke: 0.5pt + luma(200),
      fill: (x, y) => if y == 0 { luma(240) },
      [*Byte ($b$)*], [*Payload*], [*Inizio Range (Offset)*], [*Fine Range*],
      [1], [7 bit], [$0$], [$2^7 - 1$ #h(1fr) (127)],
      [2], [14 bit], [$2^7$ #h(1fr) (128)], [$2^7 + 2^{14} - 1$ #h(1fr) (16.511)],
      [3], [21 bit], [$2^7 + 2^{14}$ #h(1fr) (16.512)], [$2^7 + 2^{14} + 2^{21} - 1$ #h(1fr) (2.113.663)],
      [4],
      [28 bit],
      [$2^7 + 2^{14} + 2^{21}$ #h(1fr) (2.113.664)],
      [$2^7 + 2^{14} + 2^{21} + 2^{28} - 1$ #h(1fr) (270.549.119)],
    )
  ]

  *Come funziona nella pratica?* \
  Immagina di decodificare una sequenza di 2 byte il cui payload binario vale $P = 5$.
  - Nel *vByte standard*, questo decodificherebbe al numero $5$ (una ridondanza sprecata, dato che il 5 si poteva benissimo scrivere in 1 solo byte).
  - Nel *vByte biiettivo*, sapendo di aver letto 2 byte, il valore reale è $P + "Offset"$, ovvero $5 + 2^7 = 5 + 128 = 133$. Lo spazio generato dai 2 byte viene così sfruttato al 100% per rappresentare numeri "nuovi".
]


== PFor-Delta (Frame Of Reference)

Un approccio che ha rivoluzionato la compressione delle liste di affissioni (e in generale degli interi che rappresentano distanze o "scarti" in indici invertiti) è il *PFOR-DELTA* (Patched Frame Of Reference).

L'algoritmo (cui ha contribuito significativamente il ricercatore *Daniel Lemire*) è progettato per massimizzare il throughput sulle moderne *CPU superscalari*. Leggendo lo stream a blocchi e non elemento per elemento, si elimina quasi del tutto la necessità di istruzioni di controllo (branching) nel ciclo di decodifica principale.
L'obiettivo primario di PFor non è raggiungere la massima compressione teorica, ma garantire *velocità di decodifica estreme*, elaborando dati in blocchi (SIMD/Streaming).

*Come funziona l'algoritmo?*
+ Si divide la sequenza degli scarti in *blocchi di dimensione fissa $B$* (generalmente $B = 128$ o $B = 256$).
+ Per ogni blocco, si analizza la distribuzione dei numeri e si sceglie un numero di bit *$b$* tale che la maggioranza degli elementi (es. il 95%) possa essere rappresentata in esattamente $b$ bit.
+ Si alloca un vettore (Vettore Principale) di $B$ slot, ognuno grande esattamente $b$ bit.
+ Gli elementi che superano il valore massimo rappresentabile in $b$ bit (ovvero $> 2^b - 1$) vengono definiti *eccezioni* (il restante 5%). Nello slot del vettore principale corrispondente all'eccezione si inserisce temporaneamente uno $0$ (o un segnaposto).
+ I veri valori delle eccezioni vengono salvati in un array separato (Vettore delle Eccezioni), tipicamente come coppie `(indice, valore vero)`.

#example(title: [Rappresentazione della Memoria in PFor-Delta])[
  Ipotizziamo un mini-blocco di $B=8$ elementi: `[3, 5, 12, 300, 2, 8, 450, 1]`. \
  Scegliamo $b=4$ bit (il massimo valore scrivibile è $15$). \
  I valori `300` (indice 3) e `450` (indice 6) sono *eccezioni*.

  *1. Vettore Principale* ($B=8$, slot da $b=4$ bit)
  #align(center)[
    #table(
      columns: 8,
      align: center,
      stroke: 0.5pt + luma(200),
      fill: (x, y) => if y == 0 { luma(240) },
      [idx 0], [idx 1], [idx 2], [*idx 3*], [idx 4], [idx 5], [*idx 6*], [idx 7],
      [`3`], [`5`], [`12`], [*`0`*], [`2`], [`8`], [*`0`*], [`1`],
    )
  ]

  *2. Vettore delle Eccezioni*
  #align(center)[
    #table(
      columns: 2,
      align: center,
      stroke: 0.5pt + luma(200),
      fill: (x, y) => if y == 0 { luma(240) },
      [*Indice*], [*Valore (32 bit)*],
      [3], [300],
      [6], [450],
    )
  ]
]

=== Vantaggi in Decodifica (Loop Unrolling)
In fase di decodifica, si leggono i $B$ valori a $b$ bit copiandoli in un vettore di interi a 32/64 bit. Poiché $b$ è fisso per tutto il blocco, non ci sono istruzioni condizionali (if/else) nel ciclo principale.
Questa operazione è velocissima perché sfrutta *cicli srotolati (loop unrolling)*: vengono create (e compilate) routine diverse per ogni possibile valore di $b$ (es. una funzione ottimizzata che estrae sempre e solo blocchi da 4 bit, una per i 5 bit, ecc.).
Solo dopo aver riempito il vettore si scorre la lista delle eccezioni per "sovrascrivere" i buchi (le *patch*).

=== Variante per evitare l'indice delle eccezioni (Salto / Distanza)
Per ottimizzare ulteriormente lo spazio, in molte implementazioni non si memorizza l'indice dell'eccezione nel vettore separato. Invece, nel Vettore Principale (nello slot da $b$ bit dell'eccezione), si salva *la distanza (offset) verso la prossima eccezione*.

#example(title: [Variante a "Salti" (Linked List nel Vettore Principale)])[
  Usando lo stesso esempio di prima (eccezioni agli indici 3 e 6). \
  Invece di mettere $0$ all'indice 3, scriviamo $3$ (perché la prossima eccezione è 3 posizioni più avanti, all'indice 6).

  #align(center)[
    #table(
      columns: 8,
      align: center,
      stroke: 0.5pt + luma(200),
      fill: (x, y) => if y == 0 { luma(240) },
      [idx 0], [idx 1], [idx 2], [*idx 3*], [idx 4], [idx 5], [*idx 6*], [idx 7],
      [`3`], [`5`], [`12`], [*`-> 3`*], [`2`], [`8`], [*`null`*], [`1`],
    )
  ]
  Il Vettore delle Eccezioni conterrà ora *solo i valori*, in ordine: `[300, 450]`. L'indice della primissima eccezione viene solitamente salvato nei metadati del blocco.

  _Nota:_ Se la distanza verso l'eccezione successiva è maggiore del numero massimo rappresentabile con $b$ bit (es. distanza $> 15$ con $b=4$ bit), l'algoritmo inserisce una *eccezione fittizia (dummy)* nel mezzo per fungere da "ponte" e far continuare la catena di salti.
]

#import "../template.typ": *

== Rappresentazione di Elias-Fano

=== Ripasso: liste di posting e motivazioni

Un indice inverso associa a ogni termine una lista dei documenti che lo contengono. Le liste (dette anche *liste di affissione* o *posting lists*), ordinate per identificativo del documento, supportano essenzialmente tre operazioni:
- la *lettura sequenziale*;
- l'*accesso diretto* a un elemento dato il suo rango ordinale;
- la ricerca del primo elemento maggiore o uguale a un valore dato (*skip to* o salto).

Una rappresentazione non compressa memorizza ogni identificativo usando $ceil(log_2(u))$ bit, dove i valori appartengono all'universo ${0, dots, u - 1}$. Per una lista di $n$ elementi richiede quindi complessivamente $n ceil(log_2(u))$ bit.

Per ridurre lo spazio si usa comprimere la lista memorizzando gli scarti tra valori consecutivi (*gap encoding*). Tuttavia, la compressione basata su codici a lunghezza variabile per gli scarti (come i codici $gamma$, $delta$ o Golomb) non consente l'accesso casuale in tempo costante e rende l'operazione di *skip to* molto onerosa, costringendo a decodificare sequenzialmente tutti gli scarti precedenti. L'impiego di tabelle ausiliarie di salto (*skip tables*) a intervalli di campionamento $q$ mitiga il problema, ma richiede spazio aggiuntivo e un difficile fine-tuning dei parametri.

La codifica di Elias-Fano offre invece una rappresentazione *quasi-succinta* che unisce un'ottima compressione alla capacità di supportare l'accesso casuale e lo *skip to* in modo estremamente efficiente direttamente sui dati compressi.

=== Il metodo Elias-Fano

La tecnica fu introdotta indipendentemente da Peter Elias e Robert Fano nel 1975.

#note()[
  *Idea di base:* Una successione crescente si può memorizzare senza scrivere esplicitamente gli scarti (deltas) fra gli elementi. Si applica infatti a una successione monotona non decrescente (o strettamente crescente) di $n$ interi:
  $ 0 <= x_0 <= x_1 <= dots <= x_(n - 1) < u $
  dove $u$ rappresenta il limite superiore (*upper bound*) dell'universo dei valori.
  *(Nota: il metodo funziona altrettanto bene, in modo simmetrico, su liste monotone non crescenti).*
]

La codifica consiste nel suddividere ciascun intero $x_i$ in due componenti: una parte bassa di bit meno significativi memorizzata esplicitamente (perché cambia in modo imprevedibile) e una parte alta di bit più significativi memorizzata in forma unaria (che cresce molto piano e si comprime bene).

Fissiamo il numero $l$ di bit bassi per ciascun elemento ponendo:
$ l = max(0, floor(log_2(u / n))) $

Per ogni elemento $x_i$, separiamo i bit bassi (o resti) $r_i$ dai bit alti (o quozienti) $q_i$:
$ r_i = x_i mod 2^l quad quad q_i = floor(x_i / 2^l) $

#informally(title: "Rumore vs Informazione")[
  Possiamo interpretare i bit bassi come puro *rumore*, ragion per cui non proviamo a comprimerli. I bit alti, invece, possiedono *informazione strutturata*: poiché l'operazione di divisione preserva la monotonia, la distribuzione dei bit alti è a sua volta monotona, permettendoci di comprimerla drasticamente.
]

- *Vettore $L$ (bit bassi):* memorizza i valori $r_i$, ciascuno allineato a esattamente $l$ bit, concatenati consecutivamente. Il vettore $L$ occupa complessivamente $n dot l$ bit ed è indicizzato ad accesso diretto a blocchi di $l$ bit: la parte bassa dell'$i$-esimo elemento si trova all'offset $i dot l$.
- *Vettore $H$ (bit alti):* poiché la successione $x_i$ è monotona, i quozienti $q_i$ formano a loro volta una successione monotona non decrescente. I valori $q_i$ vengono codificati come scarti in *unario*.

Ogni scarto fra i bit alti viene scritto come un numero di zeri pari allo scarto, seguito da un `1` (terminatore). Poiché il valore massimo dei bit alti è limitato, gli scarti sommano a $q_(n-1) <= u/2^l <= 2n$. Questo significa che in media gli scarti valgono meno di 2.

Nella convenzione compatta a vettore di bit, ogni elemento $q_i$ inserisce un bit `1` nella posizione assoluta:
$ p_i = q_i + i $
ponendo a `0` tutte le altre posizioni intermedie. In modo del tutto equivalente, il quoziente $q_i$ corrisponde esattamente al *numero di zeri che precedono l'$(i+1)$-esimo bit `1`* all'interno di $H$. Conoscendo la posizione $p_i$ dell'$i$-esimo bit `1`, il valore alto si recupera immediatamente come:
$ q_i = p_i - i $

#note(title: "Semantica degli Zeri e degli Uni")[
  Che la posizione totale sia uguale a zeri + uni è un'ovvietà matematica ($p_i = q_i + i$), ma la proprietà fondamentale qui è la semantica della codifica in unario: gli `1` rappresentano l'avanzamento degli elementi (il loro indice $i$ posizionato a destra), mentre gli `0` accumulano il valore dei bit alti ($q_i$, posizionato a sinistra) associati a quegli elementi.
  In altri contesti, come la codifica Gamma, questa comoda corrispondenza non avrebbe senso. Con Elias-Fano, invece, cercare per valore ci garantisce automaticamente la posizione e viceversa.
]

=== Esempi di Codifica

#example(title: "Esempio didattico compatto")[
  Consideriamo l'universo $u = 16$ e la sequenza $(3, 5, 8, 14)$, con $n = 4$.
  Calcoliamo i bit bassi: $l = floor(log_2(16 / 4)) = 2$.

  Scomponendo ciascun elemento in base a $2^l = 4$:
  - $x_0 = 3 = 0 dot 4 + 3 arrow.r q_0 = 0, r_0 = 3$ (bit `11`)
  - $x_1 = 5 = 1 dot 4 + 1 arrow.r q_1 = 1, r_1 = 1$ (bit `01`)
  - $x_2 = 8 = 2 dot 4 + 0 arrow.r q_2 = 2, r_2 = 0$ (bit `00`)
  - $x_3 = 14 = 3 dot 4 + 2 arrow.r q_3 = 3, r_3 = 2$ (bit `10`)

  I vettori risultanti sono:
  $L = text("11 01 00 10")$

  Le posizioni dei bit ad `1` in $H$ sono $p_i = q_i + i$:
  $p_0 = 0+0 = 0, quad p_1 = 1+1 = 2, quad p_2 = 2+2 = 4, quad p_3 = 3+3 = 6$.

  Il vettore alto $H$ è dunque: `1010101`.
]

#example(title: "Esempio con scarti e duplicati")[
  Consideriamo la successione $(5, 8, 8, 15, 32)$ con $n = 5$ e $u = 36$.
  Bit bassi: $l = floor(log_2(36 / 5)) = 2$.
  Valori decomposti:
  - $5 = 1 dot 4 + 1 arrow.r q_0 = 1, r_0 = 1$ (bit `01`)
  - $8 = 2 dot 4 + 0 arrow.r q_1 = 2, r_1 = 0$ (bit `00`)
  - $8 = 2 dot 4 + 0 arrow.r q_2 = 2, r_2 = 0$ (bit `00`)
  - $15 = 3 dot 4 + 3 arrow.r q_3 = 3, r_3 = 3$ (bit `11`)
  - $32 = 8 dot 4 + 0 arrow.r q_4 = 8, r_4 = 0$ (bit `00`)

  $L = text("01 00 00 11 00")$.

  Dato $p_i = q_i + i$ le posizioni degli uni in $H$ saranno
  $p_0 = 1 + 0 = 1, quad p_1 = 2 + 1 = 3, quad p_2 = 2 + 2 = 4, quad p_3 = 3 + 3 = 6, quad p_4 = 8 + 4 = 12$
  e otteniamo la stringa di bit per $H$: `0101101000001`.

  Si noti che per gli elementi identici ($x_1 = x_2 = 8$) i bit ad `1` compaiono in posizioni adiacenti senza zeri intermedi (`...11...`).
]

#example(title: "Ricostruzione inversa (Accesso Diretto)")[
  Vogliamo ricostruire l'elemento $x_9$.

  Cerchiamo il decimo `1` (indice $i=9$, partendo da 0) nel vettore dei bit alti $H$. Supponiamo di trovarlo in posizione $p = 15$.
  Il numero di zeri superati (che corrisponde al valore dei bit alti $q_9$) è:
  $ q_9 = p - i = 15 - 9 = 6 $
  I bit bassi $r_9$ (supponiamo siano 55, codificati su $l$ bit) li leggiamo direttamente all'indice $9 dot l$.
  Il valore finale sarà:
  $ x_9 = q_9 dot 2^l + 55 $
]

=== Analisi dello spazio occupato

#theorem(title: "Occupazione di memoria di Elias-Fano")[
  Una successione monotona non decrescente di $n$ interi appartenenti a $[0, u)$ può essere memorizzata mediante la codifica di Elias-Fano occupando al più:
  $ ceil(log_2(u / n)) + 2 quad text("bit per elemento") $
]

#proof[
  Lo spazio totale impiegato dalla struttura è dato dalla somma dello spazio per il vettore dei bit bassi $L$ e quello per il vettore dei bit alti $H$.

  1. *Vettore dei bit bassi ($L$):*
    Contiene $n$ valori, ciascuno rappresentato su $l = floor(log_2(u / n))$ bit:
    $ |L| = n dot l = n floor(log_2(u / n)) <= n log_2(u / n) $

  2. *Vettore dei bit alti ($H$):*
    Ogni elemento introduce esattamente un bit `1` (in totale $n$ bit ad `1`, i cosiddetti "tappi" dell'unario). Il numero totale di bit `0` corrisponde alla somma degli scarti dei quozienti, cioè al valore massimo del quoziente $q_(n - 1) = floor(x_(n - 1) / 2^l) < u / 2^l$.
    La lunghezza complessiva di $H$ è data da:
    $ |H| = sum_(i=0)^(n-1) (q_i - q_(i-1) + 1) = n + q_(n-1) <= n + floor(u / 2^l) $
    (assumendo per convenzione $q_(-1) = 0$).

    Analizziamo il termine $u / 2^l$:
    - Se $u / n$ è potenza di 2:
    $ quad l = log_2(u / n) arrow.r 2^l = u / n arrow.r u / 2^l = n $. Ne consegue $|H| <= 2n$.


    - Nel caso generale, poiché $l = floor(log_2(u / n)) > log_2(u / n) - 1$, si ha:
    $ 2^l > 2^(log_2(u / n) - 1) = u / (2n) arrow.r u / 2^l < 2n $ Pertanto $|H| < 3n$ bit in ogni caso.

  Unificando i due contributi attraverso $ceil(log_2(u / n))$:
  $ |L| + |H| <= n dot l + n + u / 2^l <= n ceil(log_2(u / n)) + 2n $

  Dividendo per il numero di elementi $n$, la dimensione media per elemento risulta essere al più:
  $ ceil(log_2(u / n)) + 2 quad text("bit") $
]

#note(title: "Succintezza e bound informativo")[
  Il limite teorico inferiore (Shannon) per rappresentare un sottoinsieme ordinato di $n$ elementi distinti scelti da un universo di cardinalità $u$ è dato da:
  $ log_2 binom(u, n) approx n log_2(u / n) + n log_2(e) approx n log_2(u / n) + 1.442 n quad text("bit") $
  Elias-Fano dista quindi meno di 0.56 bit per elemento dal limite teorico (essendo asintoticamente irrilevante), configurandosi come una struttura *quasi-succinta*.
]

#informally(title: "Efficienza asintotica vs. Codici Istantanei")[
  Per ogni singolo elemento, si spende in proporzione sempre meno memoria man mano che la struttura si ingrandisce o si popola.
  Mentre i codici istantanei (come Elias Gamma) soffrono maledettamente nel caso di liste perfettamente equispaziate (consumando circa $2 log_2(u/n)$ bit per elemento), Elias-Fano rimane inchiodato a $log_2(u/n)$. Le strutture succinte vincono proprio quando ignoriamo tutto sulla distribuzione di partenza.
]

#warning()[
  Tutto questo limite di spazio è indipendente da come sono distribuiti i dati. Le strutture succinte garantiscono di usare uno spazio vicino al minimo teorico possibile per *tutte* le sequenze. Se i dati seguono una distribuzione molto specifica (es. clusterizzati), alcune strutture compresse ad-hoc potrebbero fare di meglio, ma nel caso peggiore la struttura succinta garantisce sempre un *bound* superiore eccellente.
]

#informally(title: "Indipendenza dalla distribuzione")[
  Il limite allo spazio di Elias-Fano dipende solo da $n$ e $u$: non ci sono liste "sfortunate". Con i codici a lunghezza variabile basati sugli scarti (come il codice $gamma$), lo spazio complessivo dipende pesantemente dai valori reali degli scarti. Se, ad esempio, ci trovassimo con scarti tutti uguali a 8, il codice $gamma$ consumerebbe ben 112 bit per essere memorizzato. Elias-Fano, invece, mantiene lo stesso costo garantito di 79 bit a prescindere da come i dati sono distribuiti internamente.
]

#align(center)[
  #image("/assets/indipendenza_distribuzione.png", width: 70%)
]

=== Operazioni sulla lista compressa

Nel vettore dei bit alti c'è un bilancio ragionevole tra zeri e uni (al massimo un rapporto 2:1, ma in media uno a uno). Questo vuol dire che se scandisco il vettore, in media trovo un'alternanza fitta di uno e zeri. Questo rende estremamente veloci tutte le operazioni. I bit bassi non si scorrono mai per la ricerca: si leggono direttamente ad accesso casuale.

Le primitive di navigazione si basano sulle operazioni standard di *rango* e *selezione* su vettori di bit in tempo costante $O(1)$:
- `select_1(H, i)`: restituisce la posizione assoluta nel vettore $H$ dell'$i$-esimo bit impostato a `1`.
- `select_0(H, k)`: restituisce la posizione assoluta nel vettore $H$ del $k$-esimo bit impostato a `0`.
- `rank_1(H, p)`: restituisce il numero di bit ad `1` che precedono la posizione $p$.

Scorrendo il vettore dei bit alti si tiene traccia della posizione $p$, dell'indice $i$ e degli zeri superati $q$.

#note(title: "Invariante di Scansione")[
  L'invariante è sempre:
  $ mb(p) = mo(i) + mg(q) $
  #align(center)[$comment("posizione") = comment("uni superati (indice)") + comment("zeri superati (quoziente)")$]
  Basta conoscerne due: il terzo si ricava direttamente dall'equazione.
]

Vediamo l'implementazione delle operazioni fondamentali:

==== 1. Lettura in successione (Next)

L'operazione `Next` scandisce gli elementi in ordine crescente mantenendo l'indice ordinale $i$ e la posizione assoluta $p$ in $H$:

1. *Ricerca del bit 1*: Si avanza da $p$ fino al successivo bit ad `1`, posto a indice $p_i$.
2. *Quoziente ($q_i$)*: Dall'invariante $p_i = q_i + i$, si ricava $q_i = p_i - i$.
3. *Resto ($r_i$)*: Si leggono gli $l$ bit consecutivi in $L$ all'offset $i dot l$: $r_i = L[i]$.
4. *Elemento*: $x_i = q_i dot 2^l + r_i$. Si incrementa $i arrow.l i + 1$.

*Ottimizzazione "Una parola alla volta"*: All'interno di una parola di macchina $w$ a 64 bit, l'individuazione sequenziale degli uni può essere eseguita a bassissimo costo tramite istruzioni hardware dedicate come `CTZ` (*Count Trailing Zeros*). 
Tale istruzione conta in un singolo ciclo i bit a zero prima del primo `1`.
Una volta letto l'uno più basso, lo si "cancella" iterativamente azzerando il bit meno significativo tramite l'operazione bitwise `w = w and (w - 1)`,
in modo che al ciclo successivo `CTZ` trovi l'1 successivo.

#align(center)[
  #image("../assets/una_parola_alla_volta.png", width: 100%)
]

==== 2. Accesso diretto (Get $i$ o Select)
Si vuole accedere all'$i$-esimo elemento $x_i$.

I bit bassi dell'i-esimo elemento si leggono in tempo costante in quando ogni elemento occupa un numero fisso di bit. 

Per i bit alti è necessario calcolare `p_i = select_1(H, i)`:
1. *Scansione a blocchi tramite `POPCNT`:*  
   Invece di testare i bit uno alla volta, si scorrono le parole macchina di $H$ (blocchi a 64 bit) accumulando il conteggio degli uni tramite l'istruzione hardware dedicata `POPCNT` (*Population Count*).  
   
   - *Cosa fa `POPCNT`:* È un'istruzione della CPU che restituisce all'istante il numero complessivo di bit impostati a `1` presenti all'interno di una parola a 64 bit.
   - *Avanzamento a blocchi:* Sommando il valore restituito da `POPCNT` a un contatore progressivo, si determina rapidamente quanti elementi (`1`) sono contenuti in ciascuna word. Poiché in $H$ il rapporto medio tra zeri e uni è circa $1:1$, in ogni parola a 64 bit sono presenti mediamente $20-30$ bit ad `1`: ciò significa che con una sola operazione hardware si "bruciano" e superano decine di elementi in un colpo solo.
   - *Arresto:* Non appena la parola corrente fa raggiungere o superare l'$i$-esimo uno cercato, la scansione a parole si ferma e si individua la posizione esatta all'interno dell'ultimo blocco.
2. Trovata la posizione $p_i$, il quoziente è $q_i = p_i - i$.
3. Si estraggono gli $l$ bit del vettore $L$: $r_i = L[i]$.
4. L'elemento vale $x_i = q_i dot 2^l + r_i$.

*Puntatori in avanti*: Contare gli uni dall'inizio ogni volta costerebbe $O(i)$ (troppo lento). Per garantire l'accesso in tempo costante $O(1)$, si usano dei *puntatori in avanti*. Fissiamo un intero $q$ (quantum). Per ogni $k$, memorizziamo in un array a parte la posizione assoluta $p$ del $(k dot q)$-esimo uno.
Si parte dalla posizione memorizzata e si devono superare al massimo $q$ uni, impiegando una scansione locale molto breve (poche word lette). Il puntatore dà $p$, l'indice $i = k dot q$ è noto a priori, e da $p = i + q_i$ ripartiamo fluidamente. *Anche se i gap non sono a distanza regolare, in media si esaminano circa $3q$ bit.*

#align(center)[
  #image("/assets/puntatori_in_avanti.png", width: 130%)
]

==== 3. Ricerca `skip to` (Rango su valore)
Data una soglia di ricerca $b$, l'obiettivo è trovare il primo elemento $>= b$. È il motivo per il quale Elias-Fano domina nei motori di ricerca.

Si scompone la soglia: $q_b = floor(b / 2^l)$ e $r_b = b mod 2^l$.
Qualunque numero $>= b$ deve avere bit alti $>= q_b$. Questo significa che è matematicamente impossibile trovare il risultato prima di avere saltato almeno $q_b$ zeri.

1. Invece di saltare gli uni come nell'accesso diretto, *si saltano gli zeri*. Si individua la posizione del $q_b$-esimo zero: `p = select_0(H, q_b)`. *(I puntatori in avanti per lo skip-to indicizzano gli zeri esattamente come gli altri indicizzano gli uni)*.
2. Il primo bit ad `1` successivo identifica il primo candidato potenziale. L'indice $i$ è dato dal numero di uni che precedono la posizione corrente: $i = p - q_b$.
3. Si valuta la parte alta $q_i$:
  - Se $q_i > q_b$, allora $x_i >= b$ è verificata ed è il minimo cercato.
  - Se $q_i = q_b$, si estrae la parte bassa $r_i = L[i]$ e la si confronta con $r_b$. Se $r_i >= r_b$ è lui, altrimenti si avanza linearmente agli elementi successivi finché la parte bassa non è sufficiente o la parte alta si incrementa.

#note(title: "Casi particolari dello Skip To")[
  - *Un buco:* Se cerchiamo un elemento con bit alti $q_b$ e, dopo aver superato $q_b$ zeri, scopriamo che la posizione successiva è ancora uno zero, significa che c'è un "buco": nessun elemento possiede quei bit alti. In questo caso si prosegue senza fare calcoli fino al primo `1` utile. Quando i bit alti dell'elemento trovato superano quelli cercati, non serve nemmeno guardare i bit bassi: l'elemento è sicuramente $>= b$ e costituisce direttamente il risultato.
  - *Oltre la fine:* Se la ricerca richiede di saltare un numero di zeri superiore a quelli disponibili, o se dopo averli saltati non ci sono più uni nel vettore, significa che nessun elemento nella lista è $>= b$. Il risultato della ricerca restituisce immediatamente infinito ($infinity$).
]

*Puntatori in avanti per Skip To*: Contare gli zeri partendo dall'inizio è lento quanto contare gli uni. Si memorizza quindi, per ogni $k$, la posizione *subito dopo* i primi $k dot q$ zeri. Da lì, gli elementi avranno bit alti $>= k dot q$. L'operazione `skipTo` parte dal puntatore $floor(q_b / q)$, superando poi localmente solo i restanti zeri (meno di $q$) e confrontando gli elementi trovati. Essendo gli zeri almeno circa la metà del vettore alto, il salto locale legge mediamente pochissimi bit.

#align(center)[
  #image("../assets/skip_to_buco.png", width: 130%)
]

#align(center)[
  #image("../assets/puntatori_in_avanti_skipto.png", width: 130%)
]

#example(title: "Tracciamento dello Skip To")[
  Riprendiamo la sequenza $(5, 8, 8, 15, 32)$ con $l = 2$ e $H = text("0101101000001")$.
  Cerchiamo il primo elemento $>= 9$ ($b = 9$).
  - Scomposizione: $q_b = floor(9 / 4) = 2$, $r_b = 9 mod 4 = 1$.
  - Si saltano 2 zeri in $H$. Il secondo zero è in posizione 2.
  - Il bit successivo è un `1` (in pos. 3): abbiamo saltato 2 zeri, indice candidato $i = 3 - 2 = 1$.
  - Il quoziente è $q_1 = 2 == q_b$. Controlliamo $L[1]$: vale $0$. L'elemento è $8 < 9$.
  - Si avanza: in posizione 4 c'è un altro `1` (indice $i = 4 - 2 = 2$). $L[2] = 0$, quindi $x_2 = 8 < 9$.
  - Si avanza ancora: in posizione 5 troviamo uno `0`. Saltiamo al primo `1` successivo, in posizione 6.
  - Zeri saltati = 3. Indice $i = 6 - 3 = 3$. Parte alta $q_3 = 3 > q_b$.
  - L'elemento $x_3 = 3 dot 4 + 3 = 15 >= 9$.
]

=== Applicazione: Frequenze e Posizioni negli Indici Invertiti

In un motore di ricerca, ogni elemento di una lista di affissione completa ha la struttura tipica:
$ (p, c, (y_1, dots, y_c)) $
dove $p$ è l'ID del documento (*docID*), $c$ è il conteggio (*term frequency*) del termine all'interno del documento, e $(y_1, dots, y_c)$ è la successione crescente delle posizioni in cui il termine occorre nel testo.

Per applicare vantaggiosamente Elias-Fano si adottano le seguenti trasformazioni:

1. *Identificativi dei documenti (DocID)*: I puntatori documentali $p_0 < p_1 < dots < p_(n-1)$ formano già una successione strettamente crescente nell'universo $N$ e vengono codificati direttamente con Elias-Fano.

2. *Conteggi (Term Frequencies)*: I singoli conteggi $c_0, c_1, dots$ non sono monotoni. Tuttavia, memorizzando la loro *successione cumulata* $C_k = sum_(i=0)^k c_i$, si ottiene una successione strettamente crescente che può essere compressa con Elias-Fano.
  - Il singolo conteggio di un doc $k$ si ricava istantaneamente per differenza: $c_k = C_k - C_(k-1)$.
  - *Autoindicizzazione*: La cumulata crea un effetto secondario utilissimo. Il valore $C_(k-1)$ corrisponde esattamente al *numero totale di posizioni che precedono il documento $k$*, fungendo da puntatore diretto all'inizio delle informazioni posizionali del documento! Non servono strutture ausiliarie per indicizzare gli offset.

3. *Posizioni*: All'interno del documento, le occorrenze $y_1 < y_2 < dots < y_c$ sono crescenti, ma da un blocco (documento) all'altro ricominciano. Si calcolano gli scarti ricominciando ad ogni documento e si memorizzano le loro somme prefisse, comprimibili con Elias-Fano in un'unica successione non decrescente globale. Per estrarre le posizioni del documento di indice $k$, la cumulata dei conteggi $C_k$ funge da indice: si effettua una `get` per trovare l'inizio del blocco, si legge in successione fino a $C_k$, e si sottrae a ogni elemento il valore letto all'inizio (ovvero l'elemento di indice $C_(k-1)$ che precede il blocco).

#align(center)[
  #image("/assets/posizioni_Elias-Fano.png", width: 60%)
]

#example(title: "Schema di indicizzazione unificata")[
  L'intera lista di affissione (documenti, frequenze e posizioni) viene rappresentata con strutture quasi-succinte omogenee ad altissima velocità di scansione e salto, legate matematicamente l'una all'altra.
]

#note(title: "Conclusioni Pratiche ed Estensioni")[
  Elias-Fano comprime meglio della maggior parte dei codici per scarti ed è più veloce sia in successione che nei salti. L'unico caso in cui risulta subottimale è quando la lista è estremamente *densa* (ovvero oltre circa $u/3$ dei documenti contiene il termine): in questo scenario conviene allocare direttamente un vettore di bit (Bit Mask) non compresso dotato di strutture per `get` e `skipTo`.

  *Estensioni della struttura:*
  - *Elias-Fano Partizionato:* Una variante avanzata prevede di spezzare la lista in blocchi, calcolando i parametri $u$ e $n$ (e quindi il numero di bit bassi $l$) in modo indipendente per ciascun blocco. Questo permette alla struttura di adattare dinamicamente lo spazio in base alla densità locale della distribuzione.
  - *Applicazioni universali:* Lo stesso identico schema matematico è utile ovunque vi sia una successione crescente. Trova applicazione non solo nei motori di ricerca, ma anche nella memorizzazione di grafi compressi, nelle funzioni di hash minimali perfette e, in generale, nella realizzazione di strutture dati succinte.
]

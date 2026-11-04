#import "../template.typ": *

= Rappresentazione di Elias-Fano

== Ripasso: liste di posting

Un indice inverso associa a ogni termine una lista dei documenti che lo contengono[cite: 1, 35]. Le liste (dette anche *liste di affissione* o *posting lists*), ordinate per identificativo del documento, supportano essenzialmente tre operazioni[cite: 1, 35]:

- la *lettura sequenziale*;
- l'*accesso diretto* a un elemento dato il suo rango ordinale;
- la ricerca del primo elemento maggiore o uguale a un valore dato (*skip to* o salto).

Una rappresentazione diretta memorizza ogni identificativo usando $ceil(log_2(u))$ bit, dove i valori appartengono all'universo ${0, dots, u - 1}$[cite: 1]. Per una lista di $n$ elementi richiede quindi complessivamente $n ceil(log_2(u))$ bit[cite: 1].

Per ridurre lo spazio occupato si comprime abitualmente la lista memorizzando gli scarti tra valori consecutivi (gap encoding)[cite: 1, 29]. Tuttavia, una compressione basata su codici istantanei per scarti (come i codici $gamma$, $delta$ o Golomb) non consente l'accesso casuale in tempo costante e rende l'operazione di *skip to* molto onerosa, costringendo a decodificare sequenzialmente tutti gli scarti precedenti[cite: 1, 37]. L'impiego di tabelle ausiliarie di salto (skip tables) a intervalli di campionamento $q$ mitiga il problema, ma richiede spazio aggiuntivo e sintonizzazione di parametri[cite: 1, 37].

La codifica di Elias-Fano offre una rappresentazione *quasi-succinta* che unisce un'ottima compressione alla capacità di supportare l'accesso casuale e lo *skip to* in modo estremamente efficiente direttamente sui dati compressi[cite: 1, 29, 31].

== Elias-Fano

La tecnica fu introdotta indipendentemente da Peter Elias e Robert Fano nel 1975[cite: 1, 27]. Si applica a una successione monotona non decrescente (o strettamente crescente) di $n$ interi:

$0 <= x_0 <= x_1 <= dots <= x_(n - 1) < u$[cite: 1, 30]

dove $u$ rappresenta il limite superiore (*upper bound*) dell'universo dei valori considerati[cite: 1, 32].

Adottiamo la notazione standard:
- $floor(z)$: parte intera per difetto (il più grande intero $<= z$)[cite: 1];
- $ceil(z)$: parte intera per eccesso (il più piccolo intero $>= z$)[cite: 1].

La codifica consiste nel suddividere ciascun intero $x_i$ in due componenti: una parte bassa di bit meno significativi memorizzata esplicitamente e una parte alta di bit più significativi memorizzata in forma unaria[cite: 1, 30, 32].

Fissiamo il numero $l$ di bit bassi per ciascun elemento ponendo:

$l = max(0, floor(log_2(u / n)))$[cite: 1, 30]

Per ogni elemento $x_i$, separiamo i bit bassi $r_i$ dai bit alti $q_i$[cite: 1]:

$r_i = x_i mod 2^l quad q_i = floor(x_i / 2^l)$[cite: 1]

- *Vettore $L$ (bit bassi):* memorizza i valori $r_i$, ciascuno allineato a esattamente $l$ bit, concatenati consecutivamente[cite: 1, 30]. Il vettore $L$ occupa complessivamente $n l$ bit ed è indicizzato a blocchi di $l$ bit: la parte bassa dell'$i$-esimo elemento si trova all'offset $i dot l$[cite: 1, 30].
- *Vettore $H$ (bit alti):* poiché la successione $x_i$ è monotona, i quozienti $q_i$ formano una successione monotona non decrescente[cite: 1, 29]. I valori $q_i$ vengono codificati come scarti unari[cite: 30, 32]. Nella convenzione compatta a vettore di bit, ogni elemento $q_i$ inserisce un bit `1` nella posizione assoluta:

$p_i = q_i + i$[cite: 1]

ponendo a `0` tutte le altre posizioni intermedie[cite: 1]. In modo del tutto equivalente, il quoziente $q_i$ corrisponde esattamente al *numero di zeri che precedono l'$(i+1)$-esimo bit `1`* all'interno di $H$[cite: 1, 30]. Conoscendo la posizione $p_i$ dell'$i$-esimo bit `1`, il valore alto si recupera immediatamente come:

$q_i = p_i - i$[cite: 1]

== Esempio

#example(title: "Esempio didattico compatto")[
Consideriamo $u = 16$ e la sequenza $(3, 5, 8, 14)$, con $n = 4$[cite: 1].
Si ha:
$l = floor(log_2(16 / 4)) = 2$[cite: 1]

Scomponendo ciascun elemento in base a $2^l = 4$:
- $x_0 = 3 = 0 dot 4 + 3 arrow.r q_0 = 0, r_0 = 3$ (bit `11` in base 2)
- $x_1 = 5 = 1 dot 4 + 1 arrow.r q_1 = 1, r_1 = 1$ (bit `01` in base 2)
- $x_2 = 8 = 2 dot 4 + 0 arrow.r q_2 = 2, r_2 = 0$ (bit `00` in base 2)
- $x_3 = 14 = 3 dot 4 + 2 arrow.r q_3 = 3, r_3 = 2$ (bit `10` in base 2)[cite: 1]

Quindi:
$(r_i) = (3, 1, 0, 2) quad (q_i) = (0, 1, 2, 3)$[cite: 1]
$L = "11 01 00 10"$

Le posizioni dei bit ad `1` in $H$ sono $p_i = q_i + i$:
$p_0 = 0 + 0 = 0, quad p_1 = 1 + 1 = 2, quad p_2 = 2 + 2 = 4, quad p_3 = 3 + 3 = 6$[cite: 1]

Il vettore alto $H$ è dunque `1010101`[cite: 1].
Per ricostruire $x_2$: il terzo `1` (indice 2) si trova in posizione $p_2 = 4$; il numero di zeri precedenti è $q_2 = 4 - 2 = 2$; leggendo $L[2] = 0$, otteniamo $x_2 = 2 dot 4 + 0 = 8$[cite: 1].
]

#example(title: "Esempio con scarti e duplicati")[
Consideriamo la successione $(5, 8, 8, 15, 32)$ con $n = 5$ e $u = 36$[cite: 30].
Il numero di bit bassi è $l = floor(log_2(36 / 5)) = floor(log_2(7.2)) = 2$[cite: 30].
I valori decomposti:
- $5 = 1 dot 4 + 1 arrow.r q_0 = 1, r_0 = 1$ (bit `01` in base 2)
- $8 = 2 dot 4 + 0 arrow.r q_1 = 2, r_1 = 0$ (bit `00` in base 2)
- $8 = 2 dot 4 + 0 arrow.r q_2 = 2, r_2 = 0$ (bit `00` in base 2)
- $15 = 3 dot 4 + 3 arrow.r q_3 = 3, r_3 = 3$ (bit `11` in base 2)
- $32 = 8 dot 4 + 0 arrow.r q_4 = 8, r_4 = 0$ (bit `00` in base 2)[cite: 30]

Il vettore basso è:
$L = "01 00 00 11 00"$[cite: 30]

Per il vettore $H$, rappresentando i quozienti con $0^k 1$ (dove lo scarto tra quozienti consecutivi determina il numero di zeri intermedi), le posizioni degli uni sono:
$p_0 = 1 + 0 = 1$
$p_1 = 2 + 1 = 3$
$p_2 = 2 + 2 = 4$
$p_3 = 3 + 3 = 6$
$p_4 = 8 + 4 = 12$

Ottenendo la stringa di bit per $H$:
`0101101000001`[cite: 30]
Si noti che per gli elementi identici ($x_1 = x_2 = 8$) i bit ad `1` compaiono in posizioni adiacenti senza zeri intermedi (`...11...`)[cite: 30].
]

== Analisi dello spazio occupato

#theorem(title: "Occupazione di memoria di Elias-Fano")[
Una successione monotona non decrescente di $n$ interi appartenenti a $[0, u)$ può essere memorizzata mediante la codifica di Elias-Fano occupando al più:

$ceil(log_2(u / n)) + 2 quad "bit per elemento"$[cite: 32]
]

#proof[
Lo spazio totale impiegato dalla struttura è dato dalla somma dello spazio per il vettore dei bit bassi $L$ e quello per il vettore dei bit alti $H$[cite: 1, 32].

1. *Vettore dei bit bassi ($L$):*
  Contiene $n$ valori, ciascuno rappresentato su $l = floor(log_2(u / n))$ bit:
  $|L| = n l = n floor(log_2(u / n)) <= n log_2(u / n)$[cite: 1, 32]

2. *Vettore dei bit alti ($H$):*
  La parte alta memorizza gli scarti tra quozienti consecutivi tramite codifica unaria $0^k 1$[cite: 30, 32]. Ogni elemento introduce esattamente un bit `1` (in totale $n$ bit ad `1`)[cite: 1, 32]. Il numero totale di bit `0` corrisponde alla somma degli scarti dei quozienti, cioè al valore massimo del quoziente $q_(n - 1) = floor(x_(n - 1) / 2^l) < u / 2^l$[cite: 1, 32].
  La lunghezza complessiva di $H$ è data da:
  $|H| = sum_(i=0)^(n-1) (q_i - q_(i-1) + 1) = n + q_(n-1) <= n + floor(u / 2^l)$[cite: 32]
  (assumendo per convenzione $q_(-1) = 0$)[cite: 32].

  Analizziamo il termine $u / 2^l$:
  - Se $u / n$ è potenza di 2, $l = log_2(u / n)$, per cui $2^l = u / n$ e quindi $u / 2^l = n$. Ne consegue $|H| <= 2n$[cite: 33].
  - Nel caso generale, poiché $l = floor(log_2(u / n)) > log_2(u / n) - 1$, si ha:
    $2^l > 2^(log_2(u / n) - 1) = u / (2n) arrow.r u / 2^l < 2n$[cite: 33]
    Pertanto $|H| < 3n$ bit[cite: 1, 33].

Unificando i due contributi attraverso $ceil(log_2(u / n))$:
$|L| + |H| <= n l + n + u / 2^l <= n ceil(log_2(u / n)) + 2n$[cite: 1, 33]

Dividendo per il numero di elementi $n$, la dimensione media per elemento risulta essere al più:
$ceil(log_2(u / n)) + 2 quad "bit"$[cite: 32]
]

#note(title: "Succintezza e bound informativo")[
Il limite teorico inferiore stabilito dalla teoria dell'informazione per rappresentare un sottoinsieme ordinato di $n$ elementi distinti scelti da un universo di cardinalità $u$ è dato da:

$log_2 binom(u, n) approx n log_2(u / n) + n log_2(e) approx n log_2(u / n) + 1.442 n quad "bit"$[cite: 1]

Elias-Fano garantisce un'occupazione di al più $n log_2(u / n) + 2n$ bit[cite: 1]. Dista quindi meno di mezzo bit per elemento dal limite teorico di Shannon, configurandosi come una struttura *quasi-succinta* che non richiede alcuna assunzione a priori sulla distribuzione probabilistica dei dati[cite: 1, 29].
]

== Operazioni sulla lista compressa

Il vettore $H$ contiene $n$ bit ad `1` e al più $2n$ bit a `0`, per una lunghezza totale limitata superiormente da $3n = O(n)$[cite: 1, 33]. Le primitive di navigazione si basano sulle operazioni standard di *rango* e *selezione* su vettori di bit[cite: 29]:

- `select_1(H, i)`: restituisce la posizione assoluta nel vettore $H$ dell'$i$-esimo bit impostato a `1` (indicizzato da 0)[cite: 1, 30].
- `select_0(H, k)`: restituisce la posizione assoluta nel vettore $H$ del $k$-esimo bit impostato a `0`[cite: 1, 30].
- `rank_1(H, p)`: restituisce il numero di bit ad `1` che precedono la posizione $p$[cite: 40].

=== Lettura sequenziale

Durante la scansione iterativa si mantiene l'indice ordinale $i$ (partendo da $0$) e si cerca il successivo bit ad `1` in $H$[cite: 1]. Trovato il bit in posizione $p_i$, si ricava il quoziente $q_i = p_i - i$ e si leggono gli $l$ bit consecutivi in $L$ a partire dall'offset $i dot l$[cite: 1]:

$x_i = q_i dot 2^l + r_i$[cite: 1]

#informally(title: "Ottimizzazione hardware")[
All'interno di una parola di macchina $w$ a 64 bit, l'individuazione sequenziale degli uni può essere eseguita a bassissimo costo tramite istruzioni hardware dedicate come `CTZ` (*Count Trailing Zeros*) / *Bit Scan Forward*, oppure azzerando iterativamente il bit meno significativo tramite l'operazione bitwise $w and (w - 1)$[cite: 1].
]

=== Accesso diretto (Select)

Per accedere all'$i$-esimo elemento $x_i$ è necessario calcolare `p_i = select_1(H, i)`[cite: 1].

1. A livello hardware si scorrono le parole macchina di $H$ accumulando il conteggio degli uni con l'istruzione `POPCNT` finché la parola corrente non contiene l'$i$-esimo uno cercato[cite: 1].
2. Trovata la posizione $p_i$, il quoziente è $q_i = p_i - i$[cite: 1].
3. Si estraggono gli $l$ bit del vettore $L$ all'indice $i$: $r_i = L[i]$[cite: 1, 30].
4. L'elemento vale $x_i = (p_i - i) dot 2^l + r_i$[cite: 1].

Per garantire l'accesso in tempo costante $O(1)$ anche su liste lunghe, si affianca al vettore $H$ un indice ausiliario di selezione che memorizza la posizione di un bit ad `1` ogni $s$ occorrenze (con costo di spazio trascurabile pari a $o(n)$)[cite: 1, 40].

=== Ricerca `skip to` (Rango su valore)

Data una soglia di ricerca $b$, l'obiettivo è trovare il minimo elemento della successione $x_i >= b$[cite: 1, 30].
Si scompone la soglia:

$q_b = floor(b / 2^l) quad r_b = b mod 2^l$[cite: 1]

Poiché i valori sono ordinati, qualsiasi elemento avente parte alta $q_i < q_b$ è certamente $< b$ e può essere escluso a priori[cite: 1].

1. Nel vettore $H$ si saltano i primi $q_b$ zeri; ciò equivale a calcolare la posizione del $q_b$-esimo zero:
  `p = select_0(H, q_b)`[cite: 1, 30]
2. Il primo bit ad `1` successivo a questa posizione identifica il primo candidato potenziale $x_i$[cite: 31]. L'indice $i$ di questo elemento è dato dal numero di uni che precedono la posizione corrente[cite: 1, 31]:
  $i = p - q_b$[cite: 31]
3. Si valuta la parte alta dell'elemento:
  - Se $q_i > q_b$, allora $x_i >= b$ è verificata e $x_i$ è il minimo cercato[cite: 1, 31].
  - Se $q_i = q_b$, si estrae la parte bassa $r_i = L[i]$ e la si confronta con $r_b$[cite: 1, 31]:
    - Se $r_i >= r_b$, il valore cercato è esattamente $x_i$[cite: 1, 31].
    - Se $r_i < r_b$, si avanzano linearmente gli elementi successivi aventi la medesima parte alta ($q_(i+1) = q_b$) finché non si trova un elemento con parte bassa sufficiente oppure la parte alta si incrementa[cite: 1, 31].

#example(title: "Tracciamento dello Skip To")[
Riprendiamo la sequenza $(5, 8, 8, 15, 32)$ con $l = 2$ e $H = "0101101000001"$[cite: 30].
Cerchiamo il primo elemento $>= 9$ ($b = 9$)[cite: 31].
- Scomposizione: $q_b = floor(9 / 4) = 2$, $r_b = 9 mod 4 = 1$[cite: 31].
- Si saltano 2 zeri in $H$[cite: 31]. Il secondo zero è in posizione 2.
- Il bit successivo è un `1` (in posizione 3): abbiamo saltato 2 zeri, dunque l'indice candidato è $i = 3 - 2 = 1$[cite: 31].
- Il quoziente è $q_1 = 2 == q_b$[cite: 31]. Controlliamo $L[1]$: vale $0$[cite: 31]. L'elemento è $2 dot 4 + 0 = 8 < 9$[cite: 31].
- Si avanza: in posizione 4 c'è un altro `1` (indice $i = 4 - 2 = 2$)[cite: 31]. La sua parte bassa è $L[2] = 0$, quindi $x_2 = 8 < 9$[cite: 31].
- Si avanza ancora: in posizione 5 troviamo uno `0`[cite: 31]. Saltiamo al primo `1` successivo, situato in posizione 6[cite: 31].
- Gli zeri saltati finora sono 3, dunque il nuovo indice candidato è $i = 6 - 3 = 3$ e la parte alta è $q_3 = 3 > q_b$[cite: 31].
- L'elemento in posizione 3 soddisfa necessariamente il criterio: $x_3 = 3 dot 4 + L[3] = 12 + 3 = 15 >= 9$[cite: 31].
]

== Memorizzazione di conteggi e posizioni

In un motore di ricerca, ogni elemento di una lista di affissione completa ha la struttura tipica[cite: 35]:

$(p, c, (y_1, dots, y_c))$[cite: 35]

dove $p$ è l'ID del documento (*docID*), $c$ è il conteggio (*term frequency*) del termine all'interno del documento, e $(y_1, dots, y_c)$ è la successione crescente delle posizioni in cui il termine occorre nel testo[cite: 35].

Per applicare vantaggiosamente Elias-Fano, che richiede successioni monotone, si adottano le seguenti trasformazioni[cite: 29, 31]:

=== 1. Identificativi dei documenti (DocID)
I puntatori documentali $p_0 < p_1 < dots < p_(n-1)$ formano già una successione strettamente crescente nell'universo $u = N$ (numero totale di documenti nella collezione) e vengono codificati direttamente con Elias-Fano[cite: 1, 31, 35].

=== 2. Conteggi (Term Frequencies)
I singoli conteggi $c_0, c_1, dots, c_(n-1)$ non sono monotoni[cite: 31]. Tuttavia, memorizzando la loro *successione cumulata*:

$C_k = sum_(i=0)^k c_i quad arrow.r quad (C_0, C_1, C_2, dots, C_(n-1))$[cite: 31]

si ottiene una successione strettamente monotona crescente (essendo $c_i >= 1$) con limite superiore pari al numero complessivo di occorrenze del termine nell'intera collezione[cite: 31].
- La cumulata può quindi essere compressa integralmente con Elias-Fano[cite: 31].
- Il singolo conteggio di un documento $k$ si ricava istantaneamente per differenza:
  $c_k = cases(C_0 & "se" k = 0, C_k - C_(k-1) & "se" k > 0)$
- Proprietà fondamentale: il valore $C_(k-1)$ corrisponde esattamente al *numero totale di posizioni che precedono il documento $k$*, fungendo da puntatore diretto all'inizio delle posizioni del documento nella sequenza globale[cite: 31]!

=== 3. Posizioni
All'interno di ciascun documento, le occorrenze $y_1 < y_2 < dots < y_c$ sono strettamente crescenti e bounded dalla lunghezza del documento[cite: 35]. Per memorizzare l'intero flusso delle posizioni lungo l'intera lista di posting in un unico blocco quasi-succinto:
- Si calcolano gli scarti consecutivi tra le posizioni (all'interno dello stesso documento e tra la transizione di documenti)[cite: 31];
- Si memorizza la *cumulata globale degli scarti delle posizioni*, rappresentabile anch'essa in Elias-Fano[cite: 31].
- La cumulata dei conteggi $C_k$ funge da indice d'accesso per estrarre il sotto-intervallo $[C_(k-1), C_k)$ delle posizioni pertinenti al documento $k$[cite: 31].

In questo modo, l'intera lista di affissione (documenti, frequenze e posizioni) viene rappresentata con strutture quasi-succinte omogenee ad altissima velocità di scansione e salto[cite: 29, 31].
#import "../template.typ": *


#note()[
  L'algoritmo di Huffman è ottimo solo se le probabilità sono diadiche, ovvero nella forma $p_i = 2^{-k_i}$ per qualche intero $k_i$.
]

Non esiste un codice istantano che occupa $log x + "costante"$ bit. La parte costante non può esistere, deve crescere con $x$.

== Elias delta

Anziche metterci l'unario della lunghezza davanti alla ridotta di x, mettia la lunghezza di x in elias gamma.

La parte di lunghezza non costerà più quanto la ridotta ma avrà un costo logaritmico.

Parole del codice:
- $0 -> 1 -> epsilon -> 1 epsilon = 1$
- $1 -> 2 -> 0 -> 0100$
- $2 -> 3 -> 1 -> 0101$
- $4 -> 4 -> 00 -> 011000$

#note()[
  Il codice di Elias delta inizia ad avere vantaggi rispetto al codice di Elias gamma per valori di $x$ maggiori, in cui si nota che la parte della lunghezza ha un costo logaritmico.
]

Il costo totale è:
$
  underbrace(lambda(x+1), "ridotta") + underbrace(2 lambda(lambda(x+1)) + 1, "elias" gamma)
$
che riscritto diventa:
$
  approx log x + 2 log log x
$
Ci vuole un po' per vedere i vantaggi in quanto per un certo periodo $log log x$ è > di $log x$. L'asintotico è comunque migliore.

#note()[
  Potremmo ripetere il procedimento con Elias $epsilon$ ma non si avrebbero vantaggi in quanto l'asintotico migliorerebbe ma a partire da valori di $x$ molto grandi, quindi non si noterebbe alcun vantaggio pratico.
]

== Codice di Golomb

Data $x$ memorizza in unario $floor(x div m)$ e in *binario minimale* $x mod b$.

Il binaro binimale serve se $x$ non è una potenza di $b$ quindi se c'è resto. Il binario minimale è un codice ottimo per la distribuzione uniforme.

#example()[
  Il binario minimale per $b=3$ è:
  - $0 -> 00$
  - $1 -> 01$
  - $2 -> 11$

  il binario minimale per $b=4$ è:
  - $0 -> 00$
  - $1 -> 01$
  - $2 -> 10$
  - $3 -> 11$

  il binario minimale per $b=5$ è:
  - $0 -> 00$
  - $1 -> 01$
  - $2 -> 10$
  - $3 -> 110$
  - $4 -> 111$
]

Prendiamo $S$ come $S = 2^ceil(log b)$ le prime $S-K$ parole di codice sono parole che usano $S-1$ bit. Mentre poi ci sono le $2k -S$ parole di $S$ bit

#informally()[
  Il codice usa per un certo numero di parole meno bit e poi per le altre parole più bit. Si tratta di un codice istantaneo e completo.
]

#example()[
  Per $b =1$ il modolo è 0 mod 1 quindi il resto della divisione è sempre 0, si scrive 1.
  .....

  per $b=3$ diventa:
  - 0 -> 10
  - 1 -> 110
  - 2 -> 111
  - 3 -> 010
  - 4 -> 0110
  - 5 -> 0111
]
Il blocco unario è diviso a blocchi, non di lunghezza costante ma di lunghezza logaritmica.

Il vantaggio dei codici di Golomb rice con $b=2^k$ il modolo viene molto semplice in quanto è fatto attraverso uno shft.

Quello che fanno i compilatori è precalcolare delle tabelle per fare folding delle costanti. L'idea è quella di andare a trovare l'inverso per un certo intero, in modo da usare il modulo in modo più efficiente.

== Exp Golom

Anziche scrivere la divisione in unario andiamo a scriverla in elias gamma. Si tratta del codice usato per i video compresis.

#note()[
  Una volta che ho il quoziente della divisione posso andare a risalire ad $x$ originale. Per farlo devo conoscere il modulo $b$ e il quoziente della divisione, facendo
  $
    x = b * (x div b) + (x mod b)
  $
]

#note()[
  In un bit stream possiamo andare a utilizzare più codici in modo da decodificare con codici diversi, ovviamente dobbiamo sapere dove finisce un codice e dove inizia l'altro.
]

== Variable length codding

Per decodificare:
- Il primo bit è un bit di codificazione: se è 0 allora non ci sono bit successivi, se è 1 allora ci sono bit successivi.

L'idea è usare:
- 1 byte per valori da 0 a 2^7
- 2 byte per valori da 2^7 a 2^14
- 3 byte per valori da 2^14 a 2^28

in base al valore dell'intero che sto rappresentano (in base al range) esso occupera 1 byte, 2 byte o 3 byte. Il primo bit serve a capire quanti byte ci sono.

Nel secondo caso è solo una permutazione di bit quindi l'unario non esprime l'effettiva lunghezza ma

RIGUARDARE ....

#note()[
  Il codice non è completo. Ci sono tanti modi di rappresentare zero, posso rappresentare zero con 1 byte tutti a zero, 2 byte o 3 byte. Ci sono delle parola che sono non confrontabili con le altre parole del codice.

  Per rendere il codice completo si può modificare il range di valori ch ogni range codifica. Tuttavia nel secondo blocco esiste una sequenza delle 2^14 che codifica zero che non viene usata (lo zero lo rappresento con 1 byte). Ci sono delle parole che non vengono usate.

  Do un significato alla parola 2 byte a zero, per farlo posso spostare il range di valori del massimo del blocco precedente. Per il secondo il range diventa da 2^7 a 2^14 + 2^7.
]

Costo, in variabile byte coding, di rappresentare un intero $x$ è:
- Dobbiamo stabilire di quanti byte p bisgono, mi serve la posizione del bit più significativo. Inoltre la diviso per 7 (numero di bit in un byte):
$
  ceil((lambda(x)+1) / 7) * 8/7 lg x
$
Molto più vicino a elis gamma, in quanto 1 bit di continuazione ci da 7 bit di contenuto.

== P-for delta

lo scopo è sempre quello di comprmere sequenze di interi frequentemente piccoli e raramente grandi. Si tratta di un codice che non punta alla massima compressione ma a una compressione veloce. Funziona su CPU super scalari.

Dato un blocco di B grande interi (128,256). Stabiliamo un numero $b$ di bit tale per cui il $95%$ dei valori si può rappresentare con $b$ bit. Costruiamo un array di $B$ interi diviso a blocchi di $b$ bit. Dentro ai blocchetti scriviamo i valori, tuttavia i valoro che non ci stanno in $b$ bit vengono saltati (saranno pochi grazie alla soglia)

L'idea è fissare la soglia e calcoliamo il numero $b$ empiricamente.

I numero che non ci stanno (maggio di 2^b bit) vengono scritti in una lista di eccezzione. Chiamiamo con l il numero che indica quanti bit è grande la lista delle eccezioni. La lista contiene prima i valori che non ci stanno e poi i loro indici. Gli indici rappresentano la posizione di dove dovrebbe andare il valore nella sequenza originale.

//Vedere meglio come è fatta la lista delle eccezioni.

#note()[
  Non possiamo leggere un elemento alla volta ma dobbiamo leggere a blocchi.

  //guardare come vengono letti i bit dallo stream.

  La decodifica non presenta istruzioni di controllo se non quella del loop per scorrere il bit stream.
]

Esistono delle ottimazioni per cui non si memorizzano le posizioni dei buchi, ma nel buco stesso si memorizza la distanza dal buco successivo (ottengo una sorta di linked list). Ho quindi ottenuto un link tra tutti i buchi. Il problma è che se le distanze sono grandi allora il delta non ci sta in b bit, andiamo a inserire un buco fittizzio.

//Daniel Lenire


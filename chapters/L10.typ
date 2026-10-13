#import "../template.typ": *

= Codifica aritmetica

A ogni sequenza associamo un sotto intervallo di $[0,1)$ di lunghezza pari alla probabilità della sequenza stessa.

Sia $C_s$ la cumulativa delle probabilità dei simboli. Per codificare un simbolo $s$. Guardo l'intevallo di $a$ e lo riscalo in modo che tutto l'insieme degli intervalli sia compreso da 0 a max 1. Quando arriva b scalo di nuovo l'intervallo.

#note()[
  L'immagine non è chiara, nel senco che l'intervallo di C sarà dentro l'intervallo di B il quale è compreso nell'intervallo di A. Prediamo sempre un intervallo più piccolo contenuto in quello precedente. Gli intervalli non sono fisicamente separati.
]

Se abbiamo una sequenza di solito abbiamo una distribuzione empirica (non sempre è cosi). Possiamo andare a calcolare l'entropia empirica della sequenza e quindi la lunghezza minima di bit per codificare la sequenza. La codifica aritmetica ci permette di arrivare a questa lunghezza minima.
$
  log 1 / p_"si"
$
entropia della codifica del singolo simbolo. Se la probabiià della sequenza è P, allora la lunghezza minima di bit per codificare la sequenza è
$
  log 1 / P = sum_(i=1)^n log 1 / p_"si"
$

L'intervallo si restringe ogni volta in base alla probabilità del simbolo che stiamo codificando.

== Trasmissione

per trasmettere la sequenza basta trasmettere un diadico all'interno dell'intervallo finale. Conoscendo un punto dell'intervallo, conosiamo anche l'intervallo finale.

Data una sequenza $S$, possiamo riscrivere il costo come:
$
  (sum_(s in S) "#s" 1 /p_"s") / n
$
ma la cardinalità di s fratto n è letteralmente la probabilità empirica del simbolo s. Quindi se la distribuzione effettiva della sorgente è la stessa della distribuzione empirica, allora il costo medio per simbolo è l'entropia della sorgente (si semplifica nella formula sopra).




== Decodifica

Dato un punto nell'intervallo unitario (un diadico). L'ide è quel quel diadico attraversa la scalatura dei vari intervalli, partendo da quello più piccolo possiamo risalire alla sequenxza degli intervalli originali.

//rgiaurdare e completare. Aggiungere un immagine che mostra la figura non scalata e mostra il punto dell'intervallo originario che denota intervallo diversi

#note()[
  Al momento supponiamo di conoscere la distribuzione dei simboli. In realtà possiamo partire da una distribuzione uniforme e aggiornare la distribuzione dei simboli man mano che decodifichiamo e codifichiamo, fino a convergere all'entropia.
]

== Codifica in pratica

Gli estremi dell'intervallo vengono approssimati in interi a dimensione fissa. Quando i bit significativi dei due estremi coincidono non potranno più cambiare. Possiamo quindi emettere quei bit e scalare l'intervallo. In questo modo man mano che l'intervallo diventa più piccolo, possiamo emettere bit e scalare l'intervallo. In questo modo non abbiamo bisogno di una precisione infinita.

Siccome è richiesta una divisione nella fase di decodifica questa rappresentazione è molto più lenta di un codice istantaneo.

= Sistmea di numerazione aritmetica

Codifichiamo la sequenza con un intero molto grande $X$ (a differenza della codifica aritmetica che aveva un intervallo piccolo). Aggiungendo un simbolo $s$ di probabiità $p_s$ vorremmo ottenere:
$
  x^' approx x / p_s
$
In questo modo i bit che servono per specificare la nuova sequenza è dato dal logaritmo della vecchia sequenza più il logaritmo della probabilità del simbolo che stiamo aggiungendo. Quindi la lunghezza della sequenza codificata è data dalla somma dei logaritmi delle probabilità dei simboli che è esattamente l'entropia della sequenza.

=== Caso banale

Se $x$ è la codifica dei simboli visti fino ad ora, allora aggiungendo s otteniamo:
$
  x^' = 2x+s
$
ogni volta che arriva un bit moltilica per 2 e aggiunge il bit che arriva. Il risultato è l'intero che in base 2 è descritto dalla sequenza.

Per decodificare x' l'ultimo simbolo è x^' mod 2, la sequenza rimane $x^' / 2$.


#note()[
  ANS non è in grado di codificare e decodificare nella stessa direzione, decodifica al contrario.
]

Il rango si ricorda il numero di pari o dispari precedenti (sempre numero di diviso 2), il colore s è l'ultima cifra binario mod 2.

//aggiugere esempio con immagine

=== COlorazione assimetrica

I simboli più frequenti si prendono più colore. L'idea è che coloriamo i colori in modo che il colore $s$ occupi una frazione $p_s$.

Fissaimo una precisione $d$ e approssimiamo ogni probabilità con $p_s approx f_s/2^d$ darà un errore di approssimazione, ma con un d grande possiamo rendere l'errore trascurabile.

Sia c_s la cumulativa, essa mi servira per capire un intero in che blocco sta.

#example()[
  Da 0 a 8 divido gli interi inmodo proporzionale alla probabilità dei simboli. ora ho tante a un po di b e pochisseme c. Tutti gli interi sono divisi in blocchi da 2^8. Ogni blocco lo colore in modo proporzionale alla probabilità dei simboli.

  I ranghi crescono in base al blocco di a, nell'immagine c cresce di 1 alla volta.

  Quando dobbiamo codificare c dobbiamo prendere un inter molto grande in quanto il ranfo di c è cresce molto in fretta.

  C ci costa 5 volte tanto quanto a quando codifichiamo un elemento di ordine c.
]

il naturale di colore $s$ di rango $x$ è dato dat:
- si trova il blocco di indice $floor(x / f_s)$
- è il naturale di colore $s$ di rango $x mod f_s$ all'interno del blocco.
- cioè si trova in posizione $c_s + x mod f_s$

Per le devisioni le possiamo fare in modo che siano precomputate

Per tornare indietro. Il colore di $x$ è dato da $s = "sym"(x mod 2^d)$ (in questo modo trovo il simbolo, ovvero a). Devo ora trovare lo stato precedente: I naturali di colore $s$ che precedono $x$ sono:
- f_s per ognuno dei $x>>d$ blocchi precedenti
- più degli $x mod 2^d-c_s$ che lo precedono nel suo blocco.

=== Dettagli implementativi

Quando butto via i bit, vado a perdere man mano la precisione.

#warning()[
  In questo caso non possiamo più appredere la distribuzione ma dobbiamo conoscere la distribuzione. Dobbiamo salvarci i dati ancillari di un blocco (f_s) da qualche parte. Se essi occupano troppo spazio vanno a intaccare la rappresentazione dei codici. La soluzione è usare delle tecniche di packing per gli f_s
]

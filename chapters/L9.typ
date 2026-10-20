#import "../template.typ": *

= Codici Istantanei e Distribuzione Implicita

#informally(title: "Il Criterio di Scelta e la Distribuzione Implicita")[
  Come si valuta l'efficacia di un codice istantaneo per interi? Il criterio principale è l'analisi della sua *distribuzione intesa o implicita*.
  In un codice ottimale, la lunghezza della parola di codice $|c(x)|$ assegnata a un dato simbolo $x$ dovrebbe idealmente coincidere con la sua quantità di informazione (misurata in bit), ovvero:
  $ |c(x)| = log(1 / p(x)) $
  dove $p(x)$ è la probabilità di occorrenza del simbolo $x$ nella sorgente dati. Facendo il logaritmo otteniamo la lunghezza della parola di codice in bit.
]

Invertendo questa relazione fondamentale, otteniamo la distribuzione di probabilità che il codice sta "implicitamente" assumendo per i dati:
$ p(x) = 2^(-|c(x)|) $
Parole lunghe vengono assegnate a simboli assunti come meno probabili, mentre parole corte a simboli più probabili.

Di seguito analizziamo i principali codici istantanei, calcolandone la lunghezza $|c(x)|$ e derivandone la distribuzione implicita $p(x)$ per comprendere a quali modelli di dati reali si adattino meglio.

== Unario
- *Lunghezza:* $abs(c(x)) = x + 1$
- *Distribuzione implicita:* $p(x) = 2^(-(x + 1))$

Si tratta di una distribuzione *esponenziale* (o geometrica). Ogni simbolo successivo ha una probabilità dimezzata rispetto al precedente. L'andamento decresce verso lo zero in maniera estremamente rapida, rendendo questo codice adatto solo a distribuzioni molto sbilanciate verso valori piccoli.

#figure(image("../assets/unario.png", width: 80%), caption: [Distribuzione Implicita: Codice Unario])

#pagebreak()

== Gamma (Elias $gamma$)
- *Lunghezza:* $abs(c(x)) = 2 floor(log(x)) + 1$
- *Distribuzione implicita:* $p(x) = 2^(-(2 log(x) + 1)) = 2^(-1) dot 2^(-2 log(x)) = 1 / (2 x^2)$

Questa è una distribuzione *polinomiale* (legge di potenza di ordine 2). Il decadimento è molto più lento rispetto all'esponenziale: ad esempio, il 100° simbolo ha probabilità $≈ 1/1000$ (valore irraggiungibile per l'unario).
A causa dei troncamenti del logaritmo intero, all'atto pratico la distribuzione forma un'approssimazione di una funzione a scalini.

#figure(image("../assets/gamma.png", width: 80%), caption: [Distribuzione Implicita: Codice Gamma])

== Delta (Elias $delta$)
- *Lunghezza:*
  $
    abs(c(x)) & = floor(log(x)) + 2 floor(log(floor(log(x)) + 1)) + 1 \
              & approx log(x) + 2 log(log(x))
  $
- *Distribuzione implicita:*
  $
    p(x) & approx 2^(-(log(x) + 2 log(log(x)))) \
         & = 2^(-log(x)) dot 2^(-2 log(log(x))) \
         & = 1 / (x log(x)^2)
  $

L'andamento decresce ancora più lentamente, grazie al termine $log(x)^2$ al denominatore. La presenza di questo fattore è strettamente necessaria per garantire la convergenza della sommatoria delle probabilità. Il codice Delta risulta *eccellente per codificare numeri interi molto grandi*.

#note()[
  Non è possibile ridurre ulteriormente il denominatore (es. a $1/x$), poiché la serie divergerebbe all'infinito violando la definizione di distribuzione di probabilità ($sum p(x) = 1$).
]


#figure(image("../assets/delta.png", width: 80%), caption: [Distribuzione Implicita: Codice Delta])

== Golomb
- *Lunghezza:* Dipende dal parametro $b$.
  $
    abs(c(x)) ≈ x / b + log(b)
  $
- *Distribuzione implicita:*
  $
    p(x) & approx 2^(-(x / b + log(b))) \
         & = 1 / (b dot 2^(x / b))
  $

Rappresenta il *codice ideale per le distribuzioni esponenziali*. A differenza dell'Unario, l'introduzione del parametro $b$ permette di sintonizzare la base della distribuzione geometrica, ottimizzandola per lo specifico set di dati in esame.

#figure(image("../assets/golomb.png", width: 80%), caption: [Distribuzione Implicita: Codice Golomb])

#note()[
  Seppur il grafico della distribuzione implicita del Golomb sembri simile a quello dell'Unario, la differenza è sostanziale: il parametro $b$ permette di "spostare" la curva verso destra, adattandola a valori medi più grandi. *L'Unario è un caso particolare del Golomb con $b = 1$*.
]

== Golomb Esponenziale
- *Lunghezza:* $abs(c(x)) ≈ 2 log(x / b) + log(b)$
- *Distribuzione implicita:*
  $
    p(x) & approx 2^(-(2 log(x / b) + log(b))) \
         & = 1 / (b (x / b)^2) = 1 / b dot b^2 / x^2 \
         & = b / x^2
  $

Si ottiene nuovamente una *legge di potenza di ordine 2*, simile al codice Gamma, ma scalata di un fattore parametrico $b$.

#figure(image("../assets/golomb_esp.png", width: 80%), caption: [Distribuzione Implicita: Golomb Esponenziale])

== Codice Variable Byte
- *Lunghezza:* Dipende dal numero di bit del blocco $k$. $abs(c(x)) = k ceil(log(x) / (k - 1))$
- *Distribuzione implicita:*
  $ p(x) approx 2^(-(k / (k - 1) log(x))) = 1 / x^(k / (k - 1)) $

Segue anch'essa una *legge di potenza*, collocandosi concettualmente e prestazionalmente a metà strada tra il codice Delta e il codice Gamma. Il grafico presenta un picco iniziale dovuto al fatto che i numeri più piccoli vengono codificati con un solo blocco, mentre i numeri più grandi richiedono più blocchi e quindi più bit.

#figure(image("../assets/variable_byte.png", width: 80%), caption: [Distribuzione Implicita: Variable Byte])


#pagebreak()

= Ottimalità ed Entropia

Ogni *codice prefisso risulta ottimale* unicamente se applicato alla propria *distribuzione implicita*.
Sia $X$ un insieme finito o numerabile di simboli, sul quale è definita una distribuzione di probabilità $p(x)$ tale che $sum p(x) = 1$. Assumiamo per convenzione $p(x) > 0$ $forall x in X$.

Si desidera costruire un codice per $X$ tramite una funzione $c: X -> {0,1}^*$ *iniettiva* (ogni simbolo ha una parola univoca), la cui immagine costituisca un codice *istantaneo* (ogni parola è decodificabile senza ambiguità e senza guardare i simboli successivi).

Il costo medio in bit per simbolo è misurato dalla *lunghezza attesa* ($mr(L_c(p))$):
$ mr(L_c(p)) = sum_(x in X) p(x) |c(x)| $

#theorem(title: "Teorema di Shannon")[
  Esiste un limite inferiore teorico assoluto per la lunghezza attesa, definito dall'*Entropia* ($mb(H(p))$) della sorgente informativa:
  $ mb(H(p)) = sum_(x in X) p(x) log(1 / p(x)) = -sum_(x in X) p(x) log(p(x)) $
]

L'entropia rappresenta il valore atteso ideale contro cui confrontare le prestazioni di qualsiasi schema di codifica.

#proof(title: "Dimostrazione del limite di Entropia")[
  Fissata la distribuzione $p$, dimostriamo formalmente che $mb(H(p)) - mr(L_c(p)) <= 0$, e dunque che in media è *impossibile* ottenere una *lunghezza attesa inferiore all'entropia*.

  Esplicitiamo la differenza e raccogliamo $p(x)$ nella sommatoria:
  $
    H(p) - L_c(p) & = -sum_(x in X) p(x) log(p(x)) - sum_(x in X) p(x) |c(x)| \
                  & = sum_(x in X) p(x) ( -|c(x)| - log(p(x)) )
  $

  Riscrivendo $-|c(x)|$ in forma logaritmica come $log(2^(-|c(x)|))$, sostituiamo:
  $
    H(p) - L_c(p) & = sum_(x in X) p(x) [ log(2^(-|c(x)|)) - log(p(x)) ] \
                  & = sum_(x in X) p(x) log(2^(-|c(x)|) / p(x))
  $

  Sfruttiamo la disuguaglianza notevole $ln(z) <= z - 1$. Passando alla base 2 implicita nei logaritmi informatici, la relazione diviene $log(z) <= (z - 1) 1 / ln(2)$. Ponendo $mr(z) = 2^(-|c(x)|) / p(x)$:
  $
    H(p) - L_c(p) & <= 1 / ln(2) sum_(x in X) p(x) ( mr(2^(-|c(x)|) / p(x)) - 1 ) \
                  & = 1 / ln(2) ( sum_(x in X) p(x) 2^(-|c(x)|) / p(x) - sum_(x in X) p(x) ) \
                  & = 1 / ln(2) ( sum_(x in X) 2^(-|c(x)|) - sum_(x in X) p(x) )
  $

  Richiamiamo a questo punto una proprietà fondamentale della teoria dei codici:

  #theorem(title: "Disuguaglianza di Kraft-McMillan")[
    Condizione necessaria e sufficiente affinché esista un codice istantaneo con lunghezze di parola $|c(x)|$ è che valga:
    $ sum_(x in X) 2^(-|c(x)|) <= 1 $
  ]

  Sapendo inoltre che $sum p(x) = 1$ per definizione di probabilità, otteniamo:
  $ H(p) - L_c(p) <= 1 / ln(2) (1 - 1) = 0 $

  La disuguaglianza $H(p) - L_c(p) <= 0$ implica direttamente che $mr(L_c(p)) >= mb(H(p))$. La *lunghezza attesa è sempre inferiormente limitata dall'entropia*.
]

#note(title: "Versione Compatta (da Esame)")[
  La dimostrazione precedente può essere condensata in un'unica catena di disuguaglianze:
  $
    H(p) - L_c(p) &= sum_(x in X) p(x) log(1 / p(x)) + sum_(x in X) p(x) (-|c(x)|) = sum_(x in X) p(x) log(2^(-|c(x)|) / p(x)) \
    &<= 1 / ln(2) sum_(x in X) p(x) ( 2^(-|c(x)|) / p(x) - 1 ) = 1 / ln(2) ( sum_(x in X) 2^(-|c(x)|) - 1 ) <= 0
  $
]

*Condizioni per l'uguaglianza ($L_c(p) = H(p)$):*
- Le maggiorazioni applicate risultano esatte (uguaglianza stretta) *se e solo* se $z = 1$. Ciò implica:
  $ 2^(-|c(x)|) / p(x) = 1 space ->space p(x) = 2^(-|c(x)|) $

#note()[
  L'uguaglianza si verifica unicamente quando la distribuzione dei dati coincide perfettamente con la *distribuzione implicita* del codice.
]

- Affinché la differenza si annulli, la somma nella disuguaglianza di Kraft deve essere pari a 1 ($sum 2^(-|c(x)|) = 1$). Questo richiede che il codice sia *completo*.

#warning(title: "Limite strutturale dei codici prefissi")[
  La codifica di Huffman e i codici istantanei classici assegnano necessariamente *almeno un bit intero* a ogni simbolo. Se la sorgente presenta un simbolo con probabilità $p(x) > 1/2$, la sua informazione teorica (entropia) risulta inferiore a 1 bit. In questi casi, un codice prefisso che mappa simboli individuali in parole discrete non potrà mai raggiungere l'efficienza entropica ottimale.
]

== Codici Universali e Asintoticamente Ottimi

Nella pratica computazionale, è computazionalmente *oneroso ricalcolare la codifica ottimale per ogni set di dati*. Si ricercano pertanto famiglie di codici dotate di garanzie matematiche assolute a prescindere dalla distribuzione sorgente.

#note(title: "Definizione: Codice Universale")[
  Un codice si definisce *Universale* per i numeri interi se, per qualunque distribuzione $p$ monotona non crescente ($p(i) >= p(i+1)$), la lunghezza attesa $L_c(p)$ è *superiormente limitata* dall'entropia di $p$ a meno di costanti additive e moltiplicative indipendenti dalla distribuzione:
  $ L_c(p) <= c dot H(p) + d $
]

Tale proprietà garantisce una perdita di efficienza limitata rispetto all'ottimo teorico (es. la lunghezza attesa non supererà mai il doppio dell'entropia). Il codice Gamma, ad esempio, è universale; l'Unario, al contrario, non lo è, poiché per specifiche distribuzioni la sua lunghezza attesa può divergere arbitrariamente rispetto all'entropia.

Un codice si definisce invece *Asintoticamente Ottimo* se ammette un limite superiore del tipo *$L_c(p) <= f(H(p))$*, dove la funzione $f$ rispetta:
$ lim_(x -> infinity) f(x) / x = 1 $
Al crescere del quantitativo di informazione da codificare, il rapporto tra i bit spesi e l'entropia ideale converge a 1.

== Compressione Aritmetica

Per aggirare il limite strutturale dei codici prefissi discreti (che richiedono almeno 1 bit per simbolo), sono state sviluppate tecniche globali come la *Compressione Aritmetica*.

Questa famiglia di algoritmi permette di ottenere una lunghezza compressa strettamente prossima all'entropia anche in presenza di distribuzioni fortemente sbilanciate (es. probabilità $> 1/2$):
- *Assenza di parole discrete:* Non si assegna una stringa di bit a ciascun simbolo. L'intero flusso di dati (o grandi blocchi di esso) viene mappato in un singolo intervallo di numeri reali e tradotto in un unico stream continuo di bit.
- *Flessibilità vs. Efficienza:* Pur garantendo una precisione estrema in termini di risparmio spaziale, la compressione aritmetica produce un monoblocco. Ciò rende impossibile la sincronizzazione arbitraria o l'estrazione di segmenti isolati senza procedere alla completa decodifica sequenziale a partire dal primo bit.

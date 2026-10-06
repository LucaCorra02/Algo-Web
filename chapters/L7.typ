#import "../template.typ": *

== Disegualianza di kraft

Permette di dire se un codice è istantaneo o meno. Essa dice che se $C$ è istantaneo *allora* la somma di tutte le lunghezze dei codici deve essere minore o uguale a 1. In formula:
$
  C "ist" -> sum_(w in c) 2^(-|w|) <= 1
$
#warning()[
  Se eccediamo il budget allora il codice è sicuramente non istantaneo. Se invece siamo sotto il budget allora il codice potrebbe essere istantaneo oppure no, non possiamo dirlo. In questo caso dobbiamo guardare le parole.

  $
    "Se" sum_(w in c) 2^(-|w|) > 1 -> C "non ist"
  $
]



in questo modo tramite tramite solo un conto possiamo dire se un codice è istantaneo o meno (non dobbiamo fare tutte le combinazioni possibili di parole).\
Posta l'istantanita vale:
$
  C "completo" <-> sum_(w in c) 2^(-|w|) = 1
$

Ogni parola consuma dello spazio che è $2^(-|w|)$ parole corte consumano meno spazio e parole lunghe di più. L'idea è che ogni parola consuma un certo budget, dobbiamo rimanere sotto il budget di 1. Se superiamo il budget allora il codice non è istantaneo.

#proof()[
  Associamo ad ogni parola $w$ un determinato intervallo e ogni volta lo spezziamo in due parti. La parola vuota è l'intervallo unitario in [0,1].\
  Ogni volta che aggiungiamo una parola $w$ allora spezziamo l'intervallo in due parti, una parte che corrisponde alla parola $w$ e l'altra parte che corrisponde a tutte le altre parole.\

  Formalmente:
  $
    epsilon -> [0,1] "condizione baso" \
                                "se" x & -> [a..b) \
                                       & x 0 ->[ a, (a+b)/2) \
                                       & x 1 ->[ (a+b)/2, b) \
  $
  possiamo vederlo anche come un albero binario dove per ogni livello tutte le parole occupano lo stesso spazio.\

  // riguardare
  La lunghezza di una parola è $|I(epsilon)|$=1 successivamente ogni volta che aggiungiamo una parola $w$ diventa $|I(w)|=2^(-|w|)$ quindi ogni volta che aggiungiamo una parola il suo intervallo è la metà di quello della parola precedente.\

  #note()[
    Parole lughe poco spazio, parole corte molto spazio
  ]

  Consideriamo $x$ e $y$ due parobe binarie.

  La relazione di prefisso diventa la relazione di inclusione tra intervalli. $x <= y -> I(x) subset I(y)$. Se x è un prefisso di y allora l'intervallo di x contiene l'intervallo di y. Siccome le parole lunghe cosumano più spazio allora il loro intervallo è più piccolo.

  Se $x$ e $y$ soo inconfrontabili allora i loro intervalli sono disgiunti $I(x) inter I(y)$

  Se sono inconfrontabili allora hanno un prefisso comune (possibilmente di lunghezza 0) e poi un bit diverso. Quindi i loro intervalli sono disgiunti.
  $
    exists z in Z^* "t.c" x = z 0 x^', y= z 1 y^'
  $
  //riguardare
  .....

  Fare esempio con un albero. Le due parole seguono rami diversi, i sottoalbero sono disgiunti. Il risultato è che quando scriviamo la somma di tutte le lunghezze dei codici allora stiamo sommando intervalli disgiunti che sono tutti sotto insiemi dell'intervallo unitario. Quindi la somma di tutti gli intervalli è minore o uguale a 1.\
]

#proof(title: "C completo")[
  La dimostrazione con la contronominale (scambio e nego), la contronominale è vera se e solo se la diretta è vera.
  la contronominale è: se la somma di tutte le lunghezze dei codici è diversa da 1 allora il codice non è completo. In formula:
  $
    sum != 1 -> C "non completo"
  $
  Indipendentemente dalla dimensione di $k$

  la prola che $j$ rappresenta su $k$ bit allora ottengo esattamente un intervallo che parte da $j(2^k)$ e arriva esattamente a $(j+1)(2^k)$. Se riesxo a trovare due diadici consecutivi che comprono l'intervallo per scrivere la parola $j$ posso prendere quella parola.
  //riguardare e aggiungere esempio

  $
    C "non completo" -> sum != 1
  $
  Vuol dire che c'è un buco e quindi posso aggiungere una parola per riempire il buco ? che cazzo vuol dire

  Se è non completo posso aggiungere una parola $z$ per no violare l'istantanieta. Se faccio la somma su D allora controllo che è minore di 1. La dimensione originale del codice è la somma meno la lunghezza della parola che ho aggiunto. Quindi la somma è minore di 1.\
]

=== inversione della disequaglianza di Kraft

Supponiamo di avere dei valori crescenti di lunghezza $l_1 < l_2 < ... < l_n$ e vogliamo costruire un codice istantaneo con queste lunghezze. Allora se la somma di tutte le lunghezze dei codici è minore o uguale a 1 allora possiamo costruire un codice istantaneo con queste lunghezze.

#note()[
  Non è una vera e propria inversione della disequaglianza di Kraft, perché non posso dire con certezza che il codice costruito sia istantaneo, ma l'errore non è nelle lunghezze scelte ma nella scelta dei bit associati a quelle lunghezze.
]

#proof()[
  $d_0 = 1 / 2^(t_0)$ si tratta di un diagono di ordine zero, questo intervallo rappresenta la parola vuota (tutti 0).

  il diacono consecutivo è per una parola di lunghezza t_i,vogliamo trovare il seguente intervallo:
  $
    k / 2^(t_i), dots , (k+1) / 2^(t_i)
  $
  la vera domanda è che vogliamo riscrivere $d = d/2^t_i$ come un diadico di ordine $t_i+1$, per farlo:
  $
    d = 2/2^(t_i) =
  $

  Possiamo sempre scegliere l'intervallo consecutivo in quanto possiamo interpretare il diadico con qui abbiamo appena finito come il diadico di ordine successivo.
  //add example
  #example()[
    Se devo rappresntare parole di lunghezza 1, 3, 3, 5. Allora la prima parola di lunghezza 1 è 0, uso 1/2 come intervallo. La seconda parola di lunghezza 3 è 100, uso 4/8 -> 5/8 come intervallo. La terza parola di lunghezza 3 è 101, uso 5/8 come intervallo. La quarta parola di lunghezza 5 è 10100, uso 20/32 come intervallo.
  ]

]

== Codici istantanei

=== Codice binario
Un codice binario di ampiezza $k$ è istantaneo e ogni parola ha la stessa lunghezza $k$. In questo caso la lunghezza di parole è $2^k$. Se tutti i simboli hanno la stessa frequenza allora il codice binario è ottimale.\

=== Codice unario

Abbiamo due codice $0^* 1$ e $1^* 0$.
Il codice $1^* 0$ ha un unario lessicografico, l'ordine tra le parole corrisponde all'ordine tra gli interi intesi. Se $x <= y -> 1^x 0 <= 1^y 0$

Lessicografico vuol dire che l'ordine tra le parole corrisponde all'ordine tra gli interi intesi. Se $x <= y -> 1^x 0 <= 1^y 0$. In questo caso fermo il confronto tra due parole alla prima differenza tra i due bit. Se il primo bit diverso è 0 allora la parola è minore, se il primo bit diverso è 1 allora la parola è maggiore.\

#note()[
  Questo codice unario viene usato da UTF-8 per rappresentare i caratteri.
]

Con il prino non è vero, perche 0 -> 1, 1 -> 01 cioè 0 < 1 ma 1 > 01. Quindi il codice unario non è lessicografico.

Tutte le cpu hanno delle istruzioni per trovare il primo bit a 1, se usiamo la prima codifica allora possiamo trovare il primo bit a 1 e quindi trovare la lunghezza della parola. Se usiamo la seconda codifica allora non possiamo trovare la lunghezza della parola, dobbiamo prima invertire la parola e poi trovare il primo bit a 1. Quindi la prima codifica è più efficiente della seconda.

il problema è che se voglio rappresentare un numero $k$ allora mi servono $k+1$ bit. Quindi per $k$ piccoli va bene, altrimenti no.

=== Codice elias gamma

Il numero viene scritto in binario e davanti ci metto in unario la lunghezza della parola. Dato un $x >= 0$ lo incrementiamo di 1 $x+1$, a questo punto buttiamo via il bit più significiativo.
#example()[
  - 5 -> 6 -> 110 -> 10
  - 0 -> 1 -> 1 -> $epsilon$
  1 -> 2 -> 10 -> 0
]
questa rappresentazione di chiama *codifica unaria ridotta*. Il codice è costruito cosi:
$
  0 -> 1 -> epsilon -> 1 epsilon = 1\
  1 -> 2 -> 10 -> 0 -> 010 = 010\
  2 -> 3 -> 11 -> 1 -> 011 = 011\
  3 -> 4 -> 100 -> 00 -> 001 00
$

Lunghezza e costo di una parola: lambda è la posizione del numero più significativo. La ridotta è data da $x+1$ in binario e poi butto via il bit più significativo. Il numero in unario è data dalla lunghezza della ridotta + 1 (mi serve un bit in più in unario)
$
  lambda(x+1) + lambda(x+1) + 1 \
  2 lambda(x+1) + 1 \
  2 floor(log_2(x+1)) + 1 \
$

Si tratta di un codice istantaneo, in quanto la parte dell'unaria è ovviamente istantanea e la parte ridotta è istantanea in quanto non contiene il bit più significativo.Escludendo il bit più significativo, la parte ridotta non può essere prefisso di un'altra parola, la parte ridotta è composta da parole di lunghezza $lambda(x+1) - 1$ e quindi non può essere prefisso di un'altra parola.\
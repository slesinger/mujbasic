256 moznosti
moznost je bud list , tzn prikaz
        nebo node, ktery ma pod sebou nody
                   nebo listy
prikaz musi byt presruseny mezerou|entrem|jinymOdelovacem

# Pokus
mem
medlik
reg

0
CTI
1m   |   2r
CTI
3e   |   4e
CTI
5m(mem)|6d(medlik)    |   7g (reg)

tabulka
stav | novy char | akce/novyStav
0|m|1
0|r|2
1|e|3
2|e|4
3|m|5
3|d|6
4|g|7
5|<konec prikazu>|prikaz mem
6|<konec prikazu>|prikaz medlik
7|<konec prikazu>|prikaz reg
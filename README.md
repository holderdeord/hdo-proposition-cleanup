2009-2010:
==========

- Mulighet til å redigere / lage / slette forslag
  - Eksempel: 2009-12-07 15:58:44
  - Eksempel på manglende forslagstekst / kopiering fra referat: 2009-12-10 12:28:01
  - Eksempel på manglende forslagstekst m/ forslagstekst i tittel: 2010-03-23 21:34
- Enstemmige voteringer er skrapt fra referatene:
  * Har ofte tittel: "Kart: 7, Sak: 1" - kan redigeres
  * Tidspunkt er feil, siden vi ikke kan vite (fremgår ofte heller ikke nøyaktig referatet). Er fordelt utover dagen basert på kartnr/saknr fra 1200, f.eks. 12:07:01. Bør fikses om det er mulig å finne ut av fra referatet, men må være unikt på sekundet.
    * Eksempel: 2010-04-17
   * Datasettet inkluderer andregangsvotering, og det skal egentlig eksluderes. (finn eksempel?)
- Kan mangle forslag
- Kan være duplikate forslag - bruk slettknappen.

Etter vasking:
--------------

- vote.time kan ha endret seg
- rekalkuler externalId
- rekalkuler proposition's externalId md5(vote.time + body)
- sjekk at telling for/mot stemmer med representantene

2010-2011:
==========

* alternative voteringer har ikke forslagene knyttet riktig
  * vet ikke ut fra dataene hvilket av forslagene som ble vedtatt
  * marker den som er riktig som Godkjent, den andre med Avvist
  * eksempel:
* Referat-lenken er feil for møter som går over midnatt - lenker til neste dags referat
  * eksempel: 2010-11-26
* Overskrift på forslag stemmer ikke? 2010-11-26 01:53:19.340j Lovenes overskrifter og lovene i sin helhet
* Ufullstendig tekst:
  * 2010-10-28 16:04:49.050n Forslag nr. 2 på vegne av FrP.
  * dupliserte voteringer i 2010-10-28
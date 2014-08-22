/*INDEXE

Hier sind einige Indexe vermerkt, die bei grossem Datenvolumen sehr hilfreich sind.
Die groessten Daten sind:
	1. Reservierungen
	2. Kunden
	3. Speisen und Getraenke
	4. Zimmer
	5. bezahlen
	6. benutzen
	7. mieten
	8. konsumieren

*/


/* 1. Reservierungen*/

	CREATE INDEX index_reservierungen
	ON reservierungen (reservierungsnummer);
	-- hier ist vll. anreise oder abreise gut

/* 2. Kunden */

	CREATE INDEX index_kunden
	ON kunden (kid);
	-- hier ist vll. kunde nicht so geeignet


/* 3. Speisen und Getraenke*/

	CREATE INDEX index_speisenundgetraenke
	on speisenundgetraenke (speiseid);
	-- hier ist vll. wirdserviert in besser mit index auf gehoertzuhotel, aid
	
/* 4. Zimmer */

	CREATE INDEX index_zimmer
	on zimmer (gehoertzuhotel,zimmernummer);
	-- hier ist vll. gehoertZuHotel,dreckig gut


/* 5.bezahlen */
	
	CREATE INDEX index_bezahlen
	on bezahlen (reservierungsnummer,kid,zeitpunkt);
	-- hier ist vll. nur kid besser


/* 6.benutzen */

	CREATE INDEX index_benutzen
	on benutzen (gehoertzuhotel,aid,kid,von);
	-- hier ist vll. bewohntezimmerview gut mit index auf gehoertzuhotel

/* 7.mieten */

	CREATE INDEX index_mieten
	on mieten (gehoertzuhotel,aid,kid,von,bis);
	-- hier ist vll. nur kid besser

/* 8.konsumieren */

	CREATE INDEX index_konsumieren
	on konsumieren (kid, zeitpunkt);
	-- hier ist vll. nur kid besser

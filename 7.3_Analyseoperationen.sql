/* ANALYSOPERATIONEN

	1. Wir wollen die Hotels betrachten, die mehr als 10.000 EUR Umsatz erzielt haben.
	2. Welche Anreisenden Gaeste werden mehr als 100 Tage bei uns uebernachten.
	3. Wieviele Gaeste pro Hotel gibt es, die mehr als 500 EUR noch nicht bezahlte Rechnungen haben?	
	4. Die Zimmerbelegung aller Häuser in Prozent
	5. Wie oft wurde die Zimmer bereits in der Vergangenheit gereinigt, die heute auf der Reinigungsliste stehen?*/


/* 1. Gesamtumsatz */

	SELECT sum(gesamtumsatz) as grosshotels
	FROM hotelmanagerview
	GROUP BY gesamtumsatz
	HAVING gesamtumsatz > '10.000,00 €';


/* 1.2: Hotel-Mogul Frau Dreist ist heimliche Promijaegerin. Sie moechte jeden Tag immer an dem Hotel dienstlich taetig sein, 
wo die meisten VIPs anreisen. */
	SELECT 	HotelID, count(reservierungsnummer) AS AnzahlAnreisendeVIPS
	FROM 	anreisendeview
		JOIN Hotel ON anreisendeview.gehoertZuHotel = Hotel.HotelID
	WHERE 	VIP = true
	GROUP BY HotelID
	ORDER BY AnzahlAnreisendeVIPS DESC
	FETCH FIRST 1 ROWS ONLY;

/*2. Auswahl Gaeste, die mehr als 100 Tage uebernachten werden*/

	SELECT 	gehoertzuhotel, zimmernummer, anreise, abreise, dreckig, max(abreise-anreise) AS Uebernachtungen
	FROM	bewohntezimmerview
	GROUP BY gehoertzuhotel, zimmernummer, anreise, abreise, dreckig
	HAVING 	(abreise-anreise) > 100;
	
/*2.2. Abreise Tag der Gaeste die mehr als 100 Tage bleiben. Ein Geschenk oder sowas zum Abschied ist denkbar. */
	SELECT 	gehoertzuHotel, Abreise, count(reservierungsnummer) AS AbreisendeKunden
	FROM 	bewohntezimmerview
	WHERE	Abreise - Anreise > 100
	GROUP BY gehoertZuHotel,Abreise
	ORDER BY gehoertzuHotel;
	 
/*3. Anzahl der nichtbezahlten Gaeste pro Hotel */

	WITH 	alleoffen as (
	SELECT 	hotelid, count(kunde)
	FROM 	unbezahltereservierungview
	GROUP BY hotelid, gesamtoffen
	HAVING gesamtoffen > '500,00 €')
	SELECT hotelid, count(hotelid) as nichtbezahltegaeste
	FROM alleoffen
	GROUP BY hotelid
	ORDER BY hotelid ASC ;

/*3.2 Die Buchhaltung moechte die Summe der nichtbezahlten Gaesteposten pro Hotel, von Gaesten die heute abreisen, falls sie 999.99 € ueberschreiten, 
um eventuelle Risiken zu analysieren. */
	SELECT 	hotelID , sum(gesamtoffen) AS SummeOffenerPosten
	FROM 	unbezahltereservierungview
		JOIN Reservierungen ON Kunde = reserviertVonKunde 
	WHERE 	Abreise = current_date
	GROUP BY hotelID
	HAVING 	sum(gesamtoffen) > '999,99';


/*4. Zimmerbelegung */

	WITH Gesamtezimmer as (SELECT gehoertzuhotel, count (zimmerkategorie) as Gesamtzimmeranzahl
	from zimmer
	GROUP BY gehoertzuhotel
	ORDER BY gehoertzuhotel), BelegteZimmer as
	(SELECT gehoertzuhotel, count (zimmernummer) as belegtezimmeranzahl
	from bewohntezimmerview
	GROUP BY gehoertzuhotel
	ORDER BY gehoertzuhotel)

	SELECT gesamtezimmer.gehoertzuhotel, gesamtzimmeranzahl, COALESCE(belegtezimmeranzahl,0) as belegtezimmeranzahl, COALESCE(belegtezimmeranzahl*100/gesamtzimmeranzahl, 0) as zimmerbelegung 
	FROM Gesamtezimmer
	LEFT OUTER JOIN
	BelegteZimmer
	on gesamtezimmer.gehoertzuhotel = BelegteZimmer.gehoertzuhotel;

/*5. Wie oft gereinigt? */

	SELECT Reinigungspersonalview.gehoertzuhotel, zimmernummer, count(zimmer) as AnzahlGereinigt
	from 
	Reinigungspersonalview
	join reservierungen
	on Reinigungspersonalview.gehoertzuhotel = reservierungen.gehoertzuhotel and
	Reinigungspersonalview.zimmernummer = reservierungen.zimmer
	GROUP BY Reinigungspersonalview.gehoertzuhotel, zimmernummer
	ORDER by gehoertzuhotel, zimmernummer ASC;



/* ANALYSOPERATIONEN

	1. Hotel-Mogul Frau Dreist ist heimliche Promijaegerin. Sie moechte jeden Tag immer an dem Hotel dienstlich taetig sein, wo die meisten VIPs anreisen.
	2. Welche Anreisenden Gaeste werden mehr als 100 Tage bei uns uebernachten, und wann reisen sie ab. Ein Geschenk oder sowas zum Abschied ist denkbar.
	3. Die Buchhaltung moechte die Summe der nichtbezahlten Gaesteposten pro Hotel, von Gaesten die in den naechsten 2 Tagen abreisen, falls sie 999.99 € ueberschreiten, 
	   um eventuelle Risiken zu analysieren.	
	4. Die Zimmerbelegung aller Hotels in Prozent.
	5. Die Wartungs und Reinigungsfirma SqueakyClean reist an: Falls mehr als 3 Zimmer im Hotel ein Grossputz benoetigen und gleichzeitig kapput sind (Rock Star Party),
	   ist es nicht wirtschaftlich die Zimmerreinigung dafuer einzuteilen und danach vom Hausmeister reparieren zu lassen, da dies zu viel Zeit kostet. 
	   Statt dessen wird Firma SqueakyClelan gerufen. */


/* 1. Hotel-Mogul Frau Dreist ist heimliche Promijaegerin. Sie moechte jeden Tag immer an dem Hotel dienstlich taetig sein, wo die meisten VIPs anreisen. */	
	SELECT 	HotelID, count(reservierungsnummer) AS AnzahlAnreisendeVIPS
	FROM 	anreisendeview
		JOIN Hotel ON anreisendeview.gehoertZuHotel = Hotel.HotelID
	WHERE 	VIP = true
	GROUP BY HotelID
	ORDER BY AnzahlAnreisendeVIPS DESC
	FETCH FIRST 1 ROWS ONLY;
	
/*2. Welche Anreisenden Gaeste werden mehr als 100 Tage bei uns uebernachten, und wann reisen sie ab. Ein Geschenk oder sowas zum Abschied ist denkbar. */
	SELECT 	gehoertzuHotel, Abreise, count(reservierungsnummer) AS AbreisendeKunden
	FROM 	bewohntezimmerview
	WHERE	Abreise - Anreise > 100
	GROUP BY gehoertZuHotel,Abreise
	ORDER BY gehoertzuHotel;
	 
/*3. Die Buchhaltung moechte die Summe der nichtbezahlten Gaesteposten pro Hotel, von Gaesten die in den naechsten 2 Tagen abreisen, falls sie 999.99 € ueberschreiten, 
um eventuelle Risiken zu analysieren. */

	SELECT 	hotelID , sum(gesamtBetrag-bereitsBezahlt) AS SummeOffenerPosten
	FROM 	unbezahltereservierungview
		JOIN Reservierungen ON Kunde = reserviertVonKunde 
	WHERE 	Abreise - current_date <= 2
	GROUP BY hotelID
	HAVING 	sum(gesamtBetrag-bereitsBezahlt) > '999,99';

/*4. Zimmerbelegung in Prozent. */

	WITH 	Gesamtezimmer as (
	SELECT 	gehoertzuhotel, count (zimmerkategorie)::numeric as Gesamtzimmeranzahl
	FROM 	zimmer
	GROUP BY gehoertzuhotel
	ORDER BY gehoertzuhotel), 
	BelegteZimmer as (
	SELECT 	gehoertzuhotel, count (zimmernummer)::numeric as belegtezimmeranzahl
	FROM 	bewohntezimmerview
	GROUP BY gehoertzuhotel
	ORDER BY gehoertzuhotel)

	SELECT 	gesamtezimmer.gehoertzuhotel, gesamtzimmeranzahl, COALESCE(belegtezimmeranzahl,0) as belegtezimmeranzahl, 
		COALESCE((belegtezimmeranzahl*100)/gesamtzimmeranzahl, 0)::numeric as zimmerbelegungProzent 
	FROM 	Gesamtezimmer
	LEFT OUTER JOIN BelegteZimmer ON gesamtezimmer.gehoertzuhotel = BelegteZimmer.gehoertzuhotel
	ORDER BY zimmerbelegungProzent;


/* 5. Die Wartungs und Reinigungsfirma SqueakyClean reist an: Falls mehr als 3 Zimmer im Hotel dreckig und gleichzeitig kapput sind (Rock Star Party),
ist es nicht wirtschaftlich die Zimmerreinigung dafuer einzuteilen und danach vom Hausmeister reparieren zu lassen, da dies zu viel Zeit kostet. 
Statt dessen wird Firma SqueakyClean gerufen. */
	SELECT 	Reinigungspersonalview.gehoertZuHotel, count(Reinigungspersonalview.Zimmernummer) AS AnzahlDreckig	
	FROM 	Reinigungspersonalview
		JOIN Zimmer ON Reinigungspersonalview.gehoertZuHotel = Zimmer.gehoertZuHotel
		AND Reinigungspersonalview.Zimmernummer = Zimmer.Zimmernummer
	WHERE 	dreckig
	GROUP BY Reinigungspersonalview.gehoertZuHotel
	HAVING 	count(Reinigungspersonalview.Zimmernummer) > 3;

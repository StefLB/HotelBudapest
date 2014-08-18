/* LESEOPERATIONEN

10 Leseoperationen, vier davon keine skalaren Unteranfragen

INHALTSANGABE

1. Der Manager Herr 'Goldfish', der gleichzeitig zwei Hotels betreut, moechte vom 'Witz-Garlton', sowie vom 'The Octopus' den bis zum heutigen Tage angenommen Gesamtumsatz des 
Hotels betrachten, aufgesplittet.

2. Die leitende Hausdame, Frau 'Putzfee' vom 'BudgetInn' moechte ihre Listen fuer die Reinigungskraefte ausdrucken.
Da sie moechte, dass ihre werten Kollegen wissen, wie die Gaeste heissen, moechte sie die Namen zu den 
bewohnten Zimmer vermerkt haben.

3. Der exzentrische REstaurationsleiter Herr 'Gourmant' moechte sich anschauen, wieviel bis jetzt in seinen
Etablissements verzehrt wurde.

4. Ein Feueralarm bricht im Hotel 'The Shinings' aus, schnell moechte sich die Rezeptionistin alle Daten 
der Gaeste holen, die im Haus sind.



*/

/* 1. 'Witz-Garlton' & 'The Octopus' Manager fragt an*/

	WITH Goldfish  as(
		SELECT hotelid,gesamtumsatz, umsatzrooms, barumsatz,konsumumsatz,mietumsatz,benutzenumsatz
		FROM HotelmanagerView
		WHERE hotelid=3 

		UNION

		SELECT hotelid, gesamtumsatz, umsatzrooms, barumsatz,konsumumsatz,mietumsatz,benutzenumsatz
		FROM HotelmanagerView
		WHERE hotelid=4)
	SELECT Goldfish.hotelid, hotelname, adresse, hoteltyp, gesamtumsatz, umsatzrooms, barumsatz,konsumumsatz,mietumsatz,benutzenumsatz
	FROM Goldfish
	JOIN hotel
	on Goldfish.hotelid = hotel.hotelid;


/*2. Frau 'Putzfee' druckt ihre Liste aus */

WITH KundenInHouse AS (SELECT *
	FROM
	reservierungen
	WHERE gaestestatus='IN-HOUSE')
	SELECT ReinigungspersonalView.gehoertzuhotel, ReinigungspersonalView.zimmernummer, grossputz, reserviertvonkunde, vorname, nachname
	FROM ReinigungspersonalView
	LEFT OUTER JOIN
	KundenInHouse
	ON Reinigungspersonalview.gehoertzuhotel = KundenInHouse.gehoertzuhotel and Reinigungspersonalview.zimmernummer = KundenInHouse.zimmer
	LEFT OUTER JOIN
	kunden
	ON reserviertvonkunde = kunden.KID
	WHERE Reinigungspersonalview.gehoertzuhotel=5;

/*3 Herr 'Gourmant' möchte es wissen.*/

	SELECT hotelmanagerview.hotelid,hotelname, konsumumsatz
	FROM hotelmanagerview
	JOIN
	hotel
	ON hotelmanagerview.hotelid=hotel.hotelid
	Where hotelmanagerview.hotelid=4

/*4 Feueralarm*/

	SELECT*
	FROM bewohnteZimmerView
	JOIN REservierungen
	ON bewohntezimmerview.gehoertzuhotel=reservierungen.gehoertzuhotel
	AND bewohnteZimmerView.zimmernummer = reservierungen.zimmer
	AND bewohntezimmerview.anreise = reservierungen.anreise
	AND bewohntezimmerview.abreise = reservierungen.abreise
	WHERE bewohntezimmerview.gehoertzuhotel=6;







/* LESEOPERATIONEN

10 Leseoperationen, vier davon keine skalaren Unteranfragen

INHALTSANGABE

1. Der Manager Herr 'Goldfish', der gleichzeitig zwei Hotels betreut, moechte vom 'Witz-Garlton', sowie vom 'The Octopus' den bis zum heutigen Tage angenommen Gesamtumsatz des 
Hotels betrachten, aufgesplittet.

2. Die leitende Hausdame, Frau 'Putzfee' vom 'BudgetInn' moechte ihre Listen fuer die Reinigungskraefte ausdrucken.
Da sie moechte, dass ihre werten Kollegen wissen, wie die Gaeste heissen, moechte sie die Namen zu den 
bewohnten Zimmer vermerkt haben.

3. Der exzentrische Restaurationsleiter Herr 'Gourmant' moechte sich anschauen, wieviel bis jetzt in seinen
Etablissements verzehrt wurde.

4. Ein Feueralarm bricht im Hotel 'The Shining' aus, schnell moechte sich die Rezeptionistin alle Daten 
der Gaeste holen, die im Haus sind.

5. 'Welches Hotel habe ich heute nochmal gebucht', fragt die viel reisende Frau 'Hamilton' in der zentralen Reservierung nach.
Bevor die Reservierungsmitabrieterin die Daten nennt, gleicht sie nochmal die persoenlichen Daten mit Frau 'Hamilton' ab.

6. Das Flugzeug 'Boring Airline' musste seinen Flug aufgrund von schlechten WEtterbedingngen stornieren.
Sie rufen in der zentralen Reservierung an, um zu schauen, in welchen Hotels 150 Fluggaeste fuer eine Nacht untergebracht werden koennen.
Dazu muss an ueberpruefen, welche Zimmer gerade zur Verfuegung stehen.

7. Brauchen wir weitere Karten im System, fragt sich die der Rooms-Divison Manager und schaut in das System, wieviel noch verfügbar sind.
Ansonsten muss er weitere mit seiner Maschine einspeisen.

8. Der Manager Herr 'Goldfish' moechte wissen, welche Kunden noch nicht bezahlt haben und wann diese Personen abreisen,
ausserdem waee es noch gut, die Namen diese Kunden zu wissen.

9. Herr. 'Goldfish' moechte wissen, wie sich die offenen Posten zusammensetzen, allerdings schon zusammengefasst.

10. VIPS bekommen im 'Witz-Garlton' jeden Tag einen frischen Fruechteteller auf das Zimmer gestellt, dazu muss ueberprueft werden, welche Gaeste VIPS sind.



*/

/* 1. 'Witz-Garlton' und 'The Octopus' Manager fragt an*/

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

/*3. Herr 'Gourmant' möchte es wissen.*/

	SELECT hotelmanagerview.hotelid,hotelname, konsumumsatz
	FROM hotelmanagerview
	JOIN
	hotel
	ON hotelmanagerview.hotelid=hotel.hotelid
	Where hotelmanagerview.hotelid=4;

/*4. Feueralarm im 'The Shining'*/

	SELECT bewohnteZimmerView.zimmernummer, bewohnteZimmerView.anreise, bewohnteZimmerView.abreise, bewohnteZimmerview.reserviertvonkunde, vorname, nachname
	FROM bewohnteZimmerView
	JOIN Reservierungen
	ON bewohntezimmerview.gehoertzuhotel=reservierungen.gehoertzuhotel
	AND bewohnteZimmerView.zimmernummer = reservierungen.zimmer
	AND bewohntezimmerview.anreise = reservierungen.anreise
	AND bewohntezimmerview.abreise = reservierungen.abreise
	join kunden
	on bewohntezimmerview.reserviertvonkunde = kid
	WHERE bewohntezimmerview.gehoertzuhotel=6;

/*5. Welches Hotel*/

	SELECT anreisendeview.gehoertzuhotel, anreisendeview.nachname, reserviertvonkunde, kunden.vorname, kunden.adresse
	from
	anreisendeview  
	join
	reservierungen
	on anreisendeview.reservierungsnummer = reservierungen.reservierungsnummer
	join
	kunden
	ON reserviertvonkunde = kid
	WHERE anreisendeview.nachname = 'Hamilton';

/*6. 150 Fluggaeste, aber wo unterbringen*/

	SELECT freiezimmeraktuellview.hotelid, hotelname, adresse, hoteltyp,ezom,ezmm,dzom,dzmm,trom,trmm,suit
	FROM 
	freiezimmeraktuellview
	join
	hotel
	on
	freiezimmeraktuellview.hotelid = hotel.hotelid;

/*7. Wieviele freie Karten haben wir noch?*/

	SELECT counte(kartenid) as AnzahlKarten
	from
	freiekartenview;

/*8. Wer hat noch nicht bezahlt */

	SELECT gehoertzuhotel,resa as Reservierungsnummer, kunde, vorname,nachname, anreise, abreise
	from
	Nichtbezahltkundenview
	JOIN
	kunden
	on kunde = kid
	WHERE gehoertzuhotel=3 or gehoertzuhotel=4;

/*9. Wie sehen die Umsaetze der Kunden aus, die noch nicht bezahlt haben?*/

	SELECT hotelid,reservierungsnummer,kunde,vorname, nachname,gesamtoffen,konsumiert,gemietet,benutzt,naechteumsatz
	from unbezahltereservierungview
	join KUNDEn
	on kunde=kid
	WHERE hotelid=3 or hotelid=4;

/*10. Suche den VIP*/

	SELECT bewohntezimmerview.gehoertzuhotel, zimmernummer, reserviertvonkunde, vip
	from bewohntezimmerview
	join
	reservierungen
	on bewohntezimmerview.zimmernummer = reservierungen.zimmer
	and bewohntezimmerview.anreise = reservierungen.anreise
	and bewohntezimmerview.abreise = reservierungen.abreise
	and bewohntezimmerview.gehoertzuhotel = reservierungen.gehoertzuhotel
	join
	kunden
	on reserviertvonkunde=kid
	where bewohntezimmerview.gehoertzuhotel=3 and vip=true;



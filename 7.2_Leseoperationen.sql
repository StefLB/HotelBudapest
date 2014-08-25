/* 
LESEOPERATIONEN

10 Leseoperationen, vier davon mit nicht skalaren Unteranfragen

INHALTSANGABE

	1. Der Manager Herr Goldfish, der gleichzeitig zwei Hotels betreut, moechte vom Witz-Garlton, sowie vom The Octopus 
	   den bis zum heutigen Tage angenommen Gesamtumsatz des Hotels betrachten, aufgesplittet.

	2. Die leitende Hausdame, Frau Putzfee vom BudgetInn moechte ihre Listen fuer die Reinigungskraefte ausdrucken.
	   Da sie moechte, dass ihre werten Kollegen wissen, wie die Gaeste heissen, moechte sie die Namen zu den 
	   bewohnten Zimmer vermerkt haben, und eventuelle Wuensche der Gaeste.

	3. Der exzentrische Restaurationsleiter Herr Gourmant moechte sich anschauen, wieviel bis jetzt in seinen
	   Etablissements verzehrt wurde.

	4. Ein Feueralarm bricht im Hotel The Shining aus, schnell moechte sich die Rezeptionistin alle Daten 
	   der Gaeste holen, die im Haus sind.

	5. 'Welches Hotel habe ich heute nochmal gebucht?', fragt die viel reisende Frau Hamilton in der zentralen Reservierung nach.
	   Bevor die Reservierungsmitabrieterin die Daten nennt, gleicht sie nochmal die persoenlichen Daten mit Frau Hamilton ab.

	6. Das Flugzeug Boring Airline GmbH musste seinen Flug aufgrund von schlechten Wetterbedingngen stornieren.
	   Sie rufen in der zentralen Reservierung an, um zu schauen, in welchen Hotels 150 Fluggaeste fuer eine Nacht untergebracht werden koennen.
	   Dazu muss an ueberpruefen, welche Zimmer gerade zur Verfuegung stehen.

	7. Brauchen wir weitere Karten im System, fragt sich die der Rooms-Divison Manager und schaut in das System, wieviel noch verfügbar sind.
	   Ansonsten muss er weitere mit seiner Maschine einspeisen.

	8. Der Manager Herr Goldfish moechte wissen, welche Kunden noch nicht bezahlt haben und wann diese Personen abreisen,
	   ausserdem waere es noch gut, die Namen diese Kunden zu wissen.

	9. Herr. Goldfish moechte wissen, wie sich die offenen Posten zusammensetzen, allerdings schon zusammengefasst.

	10. VIPS bekommen im Witz-Garlton jeden Tag einen frischen Fruechteteller auf das Zimmer gestellt, dazu muss ueberprueft werden, welche Gaeste VIPS sind.



*/

/* 1. 'Witz-Garlton' und 'The Octopus' Manager fragt an*/

	WITH 	Goldfish  AS(
	SELECT 	hotelid,gesamtumsatz, umsatzrooms, barumsatz,konsumumsatz,mietumsatz,benutzenumsatz
	FROM 	HotelmanagerView
	WHERE 	hotelid=3 
	UNION
	SELECT 	hotelid, gesamtumsatz, umsatzrooms, barumsatz,konsumumsatz,mietumsatz,benutzenumsatz
	FROM 	HotelmanagerView
	WHERE 	hotelid=4)
	
	SELECT 	Goldfish.hotelid, hotelname, adresse, hoteltyp, gesamtumsatz, umsatzrooms, barumsatz,konsumumsatz,mietumsatz,benutzenumsatz
	FROM 	Goldfish
	JOIN 	hotel ON Goldfish.hotelid = hotel.hotelid;


/*2. Frau 'Putzfee' druckt ihre Liste aus */

	WITH	KundenInHouse AS (
	SELECT	*
	FROM	reservierungen
	WHERE 	gaestestatus='IN-HOUSE')
	
	SELECT 	ReinigungspersonalView.zimmernummer, grossputz, reserviertvonkunde, vorname, nachname, Wuensche
	FROM 	ReinigungspersonalView
		LEFT OUTER JOIN KundenInHouse
		ON Reinigungspersonalview.gehoertzuhotel = KundenInHouse.gehoertzuhotel and Reinigungspersonalview.zimmernummer = KundenInHouse.zimmer
		LEFT OUTER JOIN
		kunden
		ON reserviertvonkunde = kunden.KID
	WHERE 	Reinigungspersonalview.gehoertzuhotel=5;

/*3. Herr Gourmant moechte es wissen.*/

	SELECT 	hotelmanagerview.hotelid,hotelname, konsumumsatz
	FROM 	hotelmanagerview
		JOIN hotel
		ON hotelmanagerview.hotelid=hotel.hotelid
	WHERE	hotelmanagerview.hotelid=4;

/*4. Feueralarm in The Shining. */

	SELECT 	bewohnteZimmerView.zimmernummer, bewohnteZimmerView.anreise, bewohnteZimmerView.abreise, bewohnteZimmerview.reserviertvonkunde, 
		vorname, nachname, Reservierungen.PersonenAnzahl AS GesamtPersonenImZimmer
	FROM 	bewohnteZimmerView
		JOIN Reservierungen
		ON bewohntezimmerview.gehoertzuhotel=reservierungen.gehoertzuhotel
		AND bewohnteZimmerView.zimmernummer = reservierungen.zimmer
		AND bewohntezimmerview.anreise = reservierungen.anreise
		AND bewohntezimmerview.abreise = reservierungen.abreise
		JOIN kunden
		ON bewohntezimmerview.reserviertvonkunde = kid
	WHERE 	bewohntezimmerview.gehoertzuhotel=6;

/*5. Welches Hotel nochmal? */

	-- Falls 4.3.Beispielanfragen uebersprungen wurden
	SELECT 	setArrivals();
	
	SELECT 	Hotelname, Hotel.Adresse, anreisendeview.nachname, kunden.vorname, kunden.adresse
	FROM 	anreisendeview  
		JOIN Hotel ON anreisendeview.gehoertZuHotel = Hotel.HotelID
		JOIN kunden ON anreisendeview.reserviertvonkunde = kid
	WHERE 	anreisendeview.nachname = 'Hamilton';

/*6. 150 Fluggaeste, aber wo unterbringen? */

	SELECT 	freiezimmeraktuellview.hotelid, hotelname, adresse, hoteltyp,ezom,ezmm,dzom,dzmm,trom,trmm,suit, Preis
	FROM 	freiezimmeraktuellview
		JOIN Hotel ON freiezimmeraktuellview.hotelid = hotel.hotelid
		JOIN Preistabelle ON Hotel.hatPreisTabelle::text LIKE rtrim(CodeUndPosten,'-ABCDEFGHIJKLMNOPQRSTUVWXYZ')
	-- bevorzuge billigste Einzelzimmer.
	WHERE	'EZOM' LIKE ltrim(CodeUndPosten,'-0123456789') 
	ORDER BY Preis DESC;

/*7. Wieviele freie Karten haben wir noch? */

	SELECT 	count(kartenid) as AnzahlKarten
	FROM	freiekartenview;

/*8. Wer hat noch nicht bezahlt */

	SELECT 	gehoertzuhotel,resa as Reservierungsnummer, kunde, vorname,nachname, anreise, abreise
	FROM	Nichtbezahltkundenview
		JOIN kunden ON kunde = kid
	WHERE 	gehoertzuhotel=3 or gehoertzuhotel=4;

/*9. Wie sehen die Umsaetze der Kunden aus, die noch nicht bezahlt haben?*/

	SELECT 	hotelid,reservierungsnummer,kunde,vorname, nachname,gesamtbetrag,konsumiert,gemietet,benutzt,naechteumsatz
	FROM	unbezahltereservierungview
		JOIN Kunden
	ON 	kunde=kid
	WHERE 	hotelid=3 or hotelid=4;
	-- Whoa, Jeremy Duncan

/*10. Suche den VIP*/

	SELECT 	bewohntezimmerview.gehoertzuhotel, zimmernummer, bewohntezimmerview.reserviertvonkunde, vip
	FROM	bewohntezimmerview
		JOIN reservierungen ON bewohntezimmerview.zimmernummer = reservierungen.zimmer
		AND bewohntezimmerview.anreise = reservierungen.anreise
		AND bewohntezimmerview.abreise = reservierungen.abreise
		AND bewohntezimmerview.gehoertzuhotel = reservierungen.gehoertzuhotel
		JOIN kunden ON bewohntezimmerview.reserviertvonkunde=kid
	WHERE	bewohntezimmerview.gehoertzuhotel=3 and vip=true;



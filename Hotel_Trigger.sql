--TRIGGER, FUNKTIONEN,RULES

-- RULES

-- belegteZimmerUpdate 
-- Beim Updaten der belegten Zimmer auf dreckig in der belegteZimmerView werden in
-- Relation Zimmer, die entsprechenden Zimmer auf dreckig gestellt. 
CREATE OR REPLACE RULE bewohnteZimmerZimmerUpdate AS ON UPDATE 
TO bewohnteZimmerView 
DO INSTEAD 
	UPDATE 	Zimmer
	SET 	dreckig = true
	WHERE 	Zimmer.Zimmernummer = NEW.Zimmernummer AND Zimmer.gehoertZuHotel = NEW.gehoertZuHotel; 



-- kartenGueltigInsert
-- Bei der Ausgabe einer Zimmerkarte, darf diese nicht gesperrt sein
-- offentsichtlich kann nur eine wiedergefundene karte aushaendigt werden
CREATE OR REPLACE RULE kartenGueltigInsert AS ON INSERT
TO erhalten 
DO ALSO 
	UPDATE 	Zimmerkarte
	SET 	gesperrt = FALSE 
	WHERE 	NEW.KartenID = Zimmerkarte.KartenID;



-- FUNKTIONEN 

-- getPreisTabelle
-- gibt die Preise des Hotels aus der Preistabelle zurueck
CREATE OR REPLACE FUNCTION getPreisTabelle(Hotelparam int) RETURNS TABLE (Posten varChar, Preis money)
AS $$	
	DECLARE Tabellennummer int;
BEGIN
	
	SELECT 	hatPreistabelle INTO Tabellennummer
	FROM 	Hotel
	WHERE 	Hotelparam = HotelID;

	RETURN 	QUERY
	SELECT 	*
	FROM 	Preistabelle
	--  
	WHERE 	Tabellennummer::text LIKE rtrim(CodeUndPosten::text , '-ABCDEFGHIJKLMNOPQRSTUVWXYZ');

END	
$$LANGUAGE plpgsql; 

-- berechneSaison
-- Berechnet die Anzahl an Haupt/Nebensaison Naechte im Zeitraum von Anreise bis Abreise
CREATE OR REPLACE FUNCTION berechneSaison(Anreise date,Abreise date) RETURNS AnzahlnaechteType
AS $$
	DECLARE beginHaupt date DEFAULT EXTRACT(YEAR FROM now())::text||'-01-08' ; 
		endHaupt date DEFAULT   EXTRACT(YEAR FROM now())::text||'-10-31'; 
		countHaupt int DEFAULT 0;
BEGIN

	FOR i IN 0..(Abreise-Anreise) LOOP
		IF (Anreise + i BETWEEN beginHaupt AND endHaupt) THEN
			countHaupt = countHaupt + 1;
		END IF;
	END LOOP;

	RETURN (countHaupt, (Abreise-Anreise-countHaupt+1));
	
END
$$LANGUAGE plpgsql; 


-- ZimmerFreiAnDate
-- Gibt alle Zimmer einer gewuenschten Kategorie in Hotel zurueck, die frei sind von-bis, aufsteigend sortiert
CREATE OR REPLACE FUNCTION ZimmerFreiAnDate(Hotel int, Zimmerkat Zimmerkategorie, von date, bis date) 
RETURNS TABLE (Zimmernummer  int)
AS $$	
BEGIN
	RETURN QUERY
	WITH 	freieZimmer AS(
	SELECT 	Zimmer.Zimmernummer,Zimmer.Zimmerkategorie
	FROM 	Zimmer
	WHERE 	gehoertZuHotel = Hotel 
	EXCEPT ( 
	-- Zimmer die nicht frei sind zum gegebenen Zeitraum
	SELECT 	Reservierungen.Zimmer, Reservierungen.Zimmerkategorie
	FROM 	Reservierungen 
	WHERE 	gehoertZuHotel = Hotel 
		-- muss frei sein von - bis
		AND ((von >= Anreise AND von <= Abreise) OR (bis >= Anreise AND bis <= Abreise))
		-- nur vorgemerkte, ankommende oder belegte Zimmer abziehen
		AND (Gaestestatus = 'RESERVED' OR Gaestestatus = 'ARRIVAL' OR Gaestestatus = 'IN-HOUSE')))

	SELECT 	freieZimmer.Zimmernummer
	FROM 	freieZimmer
	WHERE 	freieZimmer.Zimmerkategorie = Zimmerkat
	ORDER BY  Zimmernummer ASC;
END	
$$LANGUAGE plpgsql; 




-- Zimmeranfrage
-- Der Anfragende gibt seine Anfrage Parameter an, und wieviele Zimmer des Typs
CREATE OR REPLACE FUNCTION Zimmeranfrage(Hotel int, Zimmerkategorie Zimmerkategorie, Anreise date, Abreise date, 
					Verpflegung Verpflegungsstufe, Wuensche varChar,PersonenAnzahl int, AnzahlZimmer int) 
RETURNS Angebot
AS $$
	DECLARE AnzahlZimmervar int; zimmervar int; preisvar money; Anzahlnaechte AnzahlnaechteType;
		Hauptsaisonzuschlag money; countMaxPersonen int; maxPersonenvar int;
BEGIN
	-- hole alle freien Zimmer des gefragten typs
	CREATE TEMP TABLE temptable
		(Zimmernummer, maxPersonen)
	ON COMMIT DROP AS
	SELECT 	Zimmer.Zimmernummer, maxPersonen
	FROM  	ZimmerFreiAnDate(Hotel, Zimmerkategorie, Anreise, Abreise)
		JOIN Zimmer ON ZimmerFreiAnDate.Zimmernummer = Zimmer.Zimmernummer
	WHERE 	gehoertZuHotel = Hotel;

	-- Pruefe ob soviele Zimmer frei sind	
	SELECT 	count(*) INTO AnzahlZimmervar
	FROM 	temptable;
			
	-- Falls nicht, dann Anfragender informieren
	IF (AnzahlZimmervar < AnzahlZimmer) THEN
		RAISE EXCEPTION 'Die gewuenschte Anzahl an Zimmern ist nicht frei';
	END IF;

	-- Hole Preise aus der zum Hotel zugeordneten Tabelle
	-- und addiere diese zusammen
	SELECT 	sum(preis) INTO preisvar 
	FROM 	getPreisTabelle(Hotel) 
	WHERE 	Zimmerkategorie LIKE ltrim(Posten::text , '-0123456789')
		OR Verpflegung  LIKE ltrim(Posten::text , '-0123456789');

		
	-- Berechne Anzahl an Haupt- und Nebensaisontagen
	Anzahlnaechte = berechneSaison(Anreise,Abreise); 
	-- beruecksichtige Hauptsaisonzuschlag
	SELECT 	Preis INTO Hauptsaisonzuschlag
	FROM 	getPreisTabelle(Hotel) 
	WHERE 	'HS' LIKE  ltrim(Posten::text , '-0123456789');
	
	preisvar = (preisvar + Hauptsaisonzuschlag ) * Anzahlnaechte.AnzahlHauptsaison 
		  + preisvar * Anzahlnaechte.AnzahlNebensaison;

	-- Falls ja, lege eine vorgemerkte Reservierung an
	-- eine reservierung pro zimmer
	FOR i IN 0..AnzahlZimmer LOOP
		SELECT 	Zimmernummer,maxPersonen INTO zimmervar,maxPersonenvar
		FROM 	temptable
		ORDER BY Zimmernummer ASC
		OFFSET i
		FETCH FIRST 1 ROWS ONLY;
		
		INSERT INTO Reservierungen VALUES (Hotel,zimmervar, preisvar, DEFAULT, Verpflegung, Zimmerkategorie,
					Anreise, Abreise, DEFAULT , DEFAULT, 'AWAITING-CONFIRMATION', Wuensche, Personenanzahl, now());

		-- addiere maxPersonen der vorgemerkten Zimmer 
		countmaxPersonen = countmaxPersonen + maxPersonenvar;
	END LOOP;
	-- Pruefe ob vergebene Zimmer die Personenanzahl beherbergen kann
	IF (countmaxPersonen < AnzahlPersonen) THEN
		RAISE EXCEPTION 'Zu viele Gaeste fuer diese Zimmerkombination';
	END IF;
	
	-- Der Kunde erhaelt ein Angebot
	RETURN (Hotel, Zimmerkategorie, AnzahlZimmer,  preisvar*AnzahlZimmer) ;		
END
$$ LANGUAGE plpgsql; 


-- AblehnungAngebot 
-- Der Kunde kann ein Angebot ablehnen
CREATE OR REPLACE FUNCTION AblehnungAngebot( Angebotsdaten Angebot, Grund varChar) RETURNS VOID 
AS $$
BEGIN
	WITH 	vorgemerkt AS (
	-- die vorgemerkten Reservierungen
	SELECT 	Reservierungsnummer
	FROM 	Reservierungen
	WHERE 	Angebotsdaten.Hotel =  Reservierungen.Hotel AND GaesteStatus = 'AWAITING-CONFIRMATION'
		AND Angebotsdaten.Zimmerkategorie = Reservierungen.Zimmerkategorie
	OFFSET 	O
	LIMIT 	Angebotsdaten.AnzahlZimmer::count)
	
	-- die jetzt als Turn-Downs eingetragen werden
	UPDATE 	Reservierungen
	SET 	GaesteStatus = 'TURN-DOWN'
	WHERE 	Reservierungen.Reservierungsnummer= vorgemerkte.Reservierungsnummer;

	
	INSERT INTO Ablehnungen VALUES (Angebotsdaten.reservierungsnummer, Grund);
END
$$LANGUAGE plpgsql;


-- AnnahmeAngebot 
-- Ein Kunde mit bereits angelegter KID nimmt ein Angebot an
CREATE OR REPLACE FUNCTION AnnahmeAngebot(KundenID int, Angebotsdaten Angebot) RETURNS VOID 
AS $$
BEGIN
	-- hier werden die bei der anfrage vorgemerkte zimmer
	-- dem kunden zugeteilt. bei mehreren kundenanfragen gleichzeitig
	-- werden die zimmer durch neusortierung moeglichst zusammenhaengend verteilt
	WITH 	vorgemerkte AS (
	-- durch das splitten der reservierung ist 
	-- zimmer jetzt eindeutig durch reservierungsnummer gegeben
	SELECT 	Reservierungsnummer
	FROM 	Reservierungen
	WHERE 	Angebotsdaten.Hotel =  Reservierungen.Hotel AND GaesteStatus = 'AWAITING_CONFIRMATION'
		AND Angebotsdaten.Zimmerkategorie = Reservierungen.Zimmerkategorie
	-- zusammenhaengende Zimmer waere nett
	ORDER BY Zimmer ASC
	-- kunde wird den vorgemerkte zimmer zugeteilt, 
	-- auch bei gleichzeitigen Anfragen geht die gesamtzahl auf 
	OFFSET 	O
	LIMIT 	Angebotsdaten.AnzahlZimmer::count)
	
	UPDATE 	Reservierungen
	SET 	Reservierungen.KID = KundenId, GaesteStatus = 'RESERVED'
	WHERE 	Reservierungen.Reservierungsnummer= vorgemerkte.Reservierungsnummer;
	
END
$$LANGUAGE plpgsql;



-- AnnahmeAngebotNeuKunde 
-- Ein neuer Kunde nimmt ein Angebot an
CREATE OR REPLACE FUNCTION AnnahmeAngebotNeuKunde(Vorname varChar,Name VarChar,Adresse varChar, Telefonnummer int, 
						Kreditkarte int, Besonderheiten varChar, Angebotsdaten Angebot) RETURNS VOID 
AS $$
	DECLARE neuID int;
BEGIN
	-- Atomizitaet wichtig, wegen ermitteln des IDs, aber Postgres meckert wecken Syntax
	-- BEGIN;
	INSERT INTO Kunden  VALUES (DEFAULT, Vorname, Name, Adresse, Telefonnummer, Kreditkarte, Besonderheiten, DEFAULT, now());
	SELECT 	KID INTO neuID
	FROM 	Kunden
	ORDER BY KID DESC
	FETCH FIRST 1 ROWS ONLY;
	
	SELECT AnnahmeAngebot(neuID, Angebotsdaten);

	--COMMIT;

END
$$LANGUAGE plpgsql;



-- zuReinigendeZimmer
-- Um 0:00 Uhr werden alle belegte Zimmer auf dreckig gestellt.
-- Simuliert hier durch eine Funktion
CREATE OR REPLACE FUNCTION ZimmerDreckig() RETURNS VOID 
AS $$
BEGIN
	UPDATE 	bewohnteZimmerView 
	SET 	dreckig = TRUE;
END
$$ LANGUAGE plpgsql;


-- Rechnungsposten
-- Ausammeln aller Posten, die wahrend der aktuellen Reservierung aufs Zimmer gebucht wurden
-- Entspricht einem Zimmerkonto 
CREATE OR REPLACE FUNCTION Rechnungsposten(Hotelnummer int, Zimmernummer int) 
RETURNS TABLE(Posten varChar, Zeitpunkt timestamp, Preis money)
AS $$
BEGIN	
	RETURN QUERY
	WITH 	Rechnungskunde AS( 
	SELECT 	reserviertvonkunde AS KID, anreise 
	FROM 	Reservierungen 
	WHERE 	Hotelnummer = Reservierungen.gehoertZuHotel AND Zimmernummer = Reservierungen.Zimmer
	-- zeige letzte Reservierung des Zimmers an
	ORDER BY anreise
	FETCH FIRST 1 ROWS ONLY)

	-- konsumierte Posten
	SELECT 	Name, konsumieren.Zeitpunkt, SpeisenUndGetraenke.Preis
	FROM 	konsumieren 
		JOIN SpeisenUndGetraenke ON konsumieren.SpeiseID = SpeisenUndGetraenke.SpeiseID
		JOIN Rechnungskunde ON Rechnungskunde.KID = konsumieren.KID
	WHERE 	konsumieren.zeitpunkt >= anreise
	-- gemietete Posten
	UNION 
	SELECT 	Name , mieten.Zeitpunkt, Preis
	FROM 	mieten 
		JOIN Abteilung ON mieten.gehoertZuHotel = Abteilung.gehoertZuHotel
		AND mieten.AID = Abteilung.AID
		JOIN Rechnungskunde ON Rechnungskunde.KID = mieten.KID		
	WHERE 	mieten.zeitpunkt >= anreise
	-- benutzte Posten
	UNION
	SELECT 	Name , von AS Zeitpunkt, Preis
	FROM 	benutzen 
		JOIN Abteilung ON benutzen.gehoertZuHotel = Abteilung.gehoertZuHotel
		AND benutzen.AID = Abteilung.AID
		JOIN Rechnungskunde ON Rechnungskunde.KID = benutzen.KID		
	WHERE 	von >= anreise;
END		 
$$ LANGUAGE plpgsql;

-- gourmetGast
-- Ein Gast moechte alle Hotel Restaurants angezeigt bekommen die mehr als 3 Sterne haben,
-- dazu das exklusivste (Teuerste) Gericht. 
CREATE OR REPLACE FUNCTION gourmetGast(Hotel int) RETURNS TABLE(Restaurantname varChar, Location varChar, Sterne int, ExklusivMenu varChar,Preis money)
AS $$
BEGIN
	RETURN QUERY
	WITH 	gourmetRestaurants AS (
	SELECT	Abteilung.gehoertZuHotel, Abteilung.AID, Name
	FROM 	Restaurant 
		JOIN Abteilung ON Restaurant.gehoertZuHotel = Abteilung.gehoertZuHotel 
		AND Restaurant.AID = Abteilung.AID
	WHERE 	Abteilung.gehoertZuHotel = Hotel AND Restaurant.Sterne >= 1),
	gourmetSpeiseID AS (
	SELECT  Name AS Restaurant, Location, Sterne, SpeiseID
	FROM 	wirdServiertIn
		JOIN gourmetRestaurants ON wirdServiertIn.gehoertZuHotel = gourmetRestaurants.gehoertZuHotel
		AND wirdServiertIn.AID = gourmetRestaurants.AID )	
	SELECT 	Restaurant, gourmetSpeiseID.Location, gourmetSpeiseID.Sterne,SpeisenUndGetraenke.Name,
		max(SpeisenUndGetraenke.Preis)	
	FROM 	gourmetSpeiseID 
		JOIN SpeisenUndGetraenke ON gourmetSpeiseID.SpeiseID = SpeisenUndGetraenke.SpeiseID 
	GROUP BY Restaurant, gourmetSpeiseID.Location, gourmetSpeiseID.Sterne,SpeisenUndGetraenke.Name, SpeisenUndGetraenke.Preis;
END 
$$ LANGUAGE plpgsql;



-- freieSportplaetze 
-- Ein Gast moechte sehen, welche Sportplaetze am jetzigen Tag noch frei zum vermieten sind
CREATE OR REPLACE FUNCTION freieSportplaetze(Hotel int) RETURNS TABLE(Sportplatz varChar, Location varChar, Oeffnungszeiten Oeffnungszeit)
AS $$
BEGIN
	RETURN 	QUERY
	WITH 	sportplatzIDs AS (
	SELECT 	gehoertZuHotel, AID
	FROM 	mieten 
	WHERE	bis > now() AND von >= (current_date + 1  || ' 00:00:00')::timestamp )

	SELECT 	Name, Abteilung.Location, Abteilung.Oeffnungszeiten
	FROM 	Abteilung 
		JOIN sportplatzIDs ON sportplatzIDs.gehoertZuHotel = Abteilung.gehoertZuHotel 
		AND sportplatzIDs.AID = Abteilung.AID 
	WHERE 	sportplatzIDs.gehoertZuHotel = Abteilung.gehoertZuHotel AND sportplatzIDs.AID = Abteilung.AID;
END 
$$ LANGUAGE plpgsql;



-- getNaechsteFreieKarte
-- gibt naechste freie zimmerkarte zurueck
CREATE OR REPLACE FUNCTION getNaechsteFreieKarte() RETURNS int
AS $$
	DECLARE neuKartenID int;
BEGIN
	SELECT 	KartenID INTO neuKartenID
	FROM 	FreieKarten
	FETCH FIRST 1 ROWS ONLY;

	RETURN neuKartenID;
END 
$$ LANGUAGE plpgsql;



-- TRIGGER 

-- EinChecken
-- Falls beim Einchecken von einem Gast, in Reservierungen
-- mehr als ein Zimmer auf den Kunden eingetragen sind, muss aus Sicherheitsgruenden
-- pro zusaestzliches Zimmer eine Verantwortliche Person eingetragen werden.   
CREATE OR REPLACE FUNCTION einChecken() RETURNS TRIGGER 
AS $$
	DECLARE AnzahlZimmer int; Reservierungsnummervar int; 
BEGIN

	SELECT 	count(*) INTO AnzahlZimmer
	FROM 	Reservierungen 
	WHERE 	Reservierungen.KID = NEW.KID AND Status = 'ARRIVAL';

	IF (AnzahlZimmer > 1) THEN 
		-- beginn ab offset 1, d.h. erste 
		-- reservierung bleibt unveraendert
		FOR i in 1..AnzahlZimmer LOOP
			SELECT 	Reservierungsnummer INTO Reservierungsnummervar
			FROM 	Reservierungen 
			WHERE 	Reservierungen.KID = NEW.KID AND Status = 'ARRIVAL'
			ORDER BY Reservierungsnummer
			OFFSET 	i
			FETCH FIRST 1 ROWS ONLY; 
			-- Nehme neue Kundendaten auf fuer Reservierung		
			SELECT checkInNeuKunde(Reservierungsnummervar);
		END LOOP;
	END IF;

END
$$ LANGUAGE plpgsql;

CREATE TRIGGER einCheckenTrigger BEFORE UPDATE OF Gaestestatus
ON Reservierungen 
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'IN-HOUSE')
	EXECUTE PROCEDURE einChecken();



-- Kartenvergabe
-- Jeder Kunde erhaelt 2 Karten fuer Zimmer
CREATE OR REPLACE FUNCTION kartenvergabe() RETURNS TRIGGER 
AS $$
	DECLARE neuKartenID int;
BEGIN
	FOR i IN 1..2 LOOP 

		SELECT *
		FROM freieKarten;

		-- keine freie Karten mehr im umlauf
		IF(!FOUND) THEN 
			-- erstelle 
			INSERT INTO Zimmerkarte VALUES (DEFAULT,DEFAULT);
		END IF;

		neuKartenID = getNaechsteFreieKarte();

		INSERT INTO erhalten VALUES (NEW.KID, neuKartenID,NEW.Reservierungsnummer);
	END LOOP;
END
$$ LANGUAGE plpgsql;


CREATE TRIGGER kartenvergabeTrigger AFTER UPDATE OF Gaestestatus
ON Reservierungen 
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'IN-HOUSE')
	EXECUTE PROCEDURE kartenvergabe();

-- Kartenverlust
-- Beim Verlust der Karte, wird diese gesperrt und aus erhalten geloescht.
-- Der Kunde bekommt eine neue
CREATE OR REPLACE FUNCTION sperreUndErsetzeZimmerkarte() RETURNS TRIGGER 
AS $$
	DECLARE neuKartenID int;kundennummervar int; revnummervar int;
BEGIN

	-- finde zur verlorenen Karte KundenID und reservierungsnummer
	SELECT 	KundenID , reservierungsnummer INTO kundennummervar,revnummervar
	FROM 	erhalten
	WHERE 	NEW.KartenID = erhalten.KartenID; 

	-- neue Karte austellen
	neuKartenID = getNaechsteFreieKarte();
	INSERT INTO erhalten VALUES (kundennummervar, neuKartenID,revnummervar);

	-- Zugangsberechtigung der alten karte loeschen
	DELETE FROM erhalten
	WHERE 	NEW.KartenID = erhalten.KartenID;

END
$$ LANGUAGE plpgsql;

CREATE TRIGGER verloreneKarteTrigger AFTER UPDATE OF gesperrt
ON Zimmerkarte 
	FOR EACH ROW
	WHEN (NEW.gesperrt = TRUE)
	EXECUTE PROCEDURE sperreUndErsetzeZimmerkarte();



-- CheckOut 
-- Beim CHECK-OUT des Kunden, gibt dieser die Karte ab 
-- Alle Karten, die der Reservierung zugeteilt wurden werden 
-- aus erhalten geloescht und koennen nicht mehr die entsprechende Tuer oeffnen
CREATE OR REPLACE FUNCTION checkOut() RETURNS TRIGGER 
AS $$
BEGIN
	DELETE FROM erhalten
	WHERE NEW.Reservierungsnummer = erhalten.Reservierungsnummer;
END
$$ LANGUAGE plpgsql;

-- Hat der auscheckende Gast bereits bezahlt?
CREATE OR REPLACE FUNCTION schonBezahlt() RETURNS TRIGGER 
AS $$
BEGIN
	SELECT Reservierungsnummer
	FROM Bezahlen
	WHERE NEW.Reservierungsnummer = Bezahlen.Reservierungsnummer;

	IF(!FOUND) THEN
		RAISE EXCEPTION 'Gast muss noch bezahlen';

	ELSE 
		PERFORM checkOut();
	END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER checkOutTrigger BEFORE UPDATE OF Gaestestatus ON Reservierungen
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'CHECKED-OUT')
	EXECUTE PROCEDURE schonBezahlt();


-- VIPTrigger
-- Bei der 100 Uebernachtung bekommt der Gast VIP Status
CREATE OR REPLACE FUNCTION checkVIP() RETURNS TRIGGER 
AS $$
	DECLARE sum int;
BEGIN
	SELECT 	sum(Abreise-Anreise) INTO sum
	FROM 	Reservierungen
	WHERE 	NEW.reserviertVonKunde = Reservierungen.reserviertVonKunde;

	IF (sum > 99 ) THEN
		UPDATE 	Kunden 
		SET 	VIP = TRUE
		WHERE	Kunden.Kid = New.reserviertVonKunde;
	END IF;

	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER VIPTrigger AFTER INSERT ON Reservierungen
	FOR EACH ROW
	EXECUTE PROCEDURE checkVIP();


-- TuerOeffner
-- Beim oeffnen einer Tuer wird die Zugangsberechtigung geprueft
-- Nur zugelassene Tueren duerfen geoeffnet werden
CREATE OR REPLACE FUNCTION checkZimmerkartenRechte() RETURNS TRIGGER 
AS $$
BEGIN
	WITH 	berechtigtesZimmer AS (
	SELECT 	gehoertZuHotel, Zimmer
	FROM 	Reservierungen
	WHERE 	Reservierungen.Reservierungsnummer = NEW.Reservierungsnummer) 
	SELECT  *
	FROM 	erhalten
	WHERE 	NEW.KartenId = erhalten.KartenId AND NEW.Zimmernummer = berechtigtesZimmer.Zimmer
		AND NEW.gehoertZuHotel = berechtigtesZimmer;

	IF (!FOUND) THEN
		RAISE NOTICE 'Kein Zutritt!'; 
		RAISE EXCEPTION 'Hey, du Spanner!';
	END IF;	

END
$$ LANGUAGE plpgsql;

CREATE TRIGGER oeffnenInsertTrigger BEFORE INSERT ON oeffnet
	FOR EACH ROW
	EXECUTE PROCEDURE checkZimmerkartenRechte();



-- checkZimmerOutOfOrder
-- check ob zugewiesenes Zimmer out of order -> wenn ja neues zuweisen
CREATE OR REPLACE FUNCTION checkoutoforder() RETURNS TRIGGER 
AS $$
	DECLARE zimmernr int; hotelnr int; zimmerstatus boolean; newzimmer int;
BEGIN

	SELECT 	zimmer INTO Zimmernr
	FROM 	Reservierungen 
	WHERE 	Reservierungen.reservierungsnummer = NEW.reservierungsnummer;

	SELECT 	gehoertzuhotel INTO hotelnr
	FROM 	Reservierungen 
	WHERE 	Reservierungen.reservierungsnummer = NEW.reservierungsnummer;

	select outoforder INTO zimmerstatus
	from zimmer
	WHERE zimmernummer=zimmernr and gehoertzuhotel=hotelnr;

	
	
	IF (zimmerstatus = FALSE) THEN RETURN NEW; ELSE
		SELECT FIRST(zimmernummer) INTO newzimmer
		FROM ZimmerFreiAnDate (hotelnr, NEW.zimmerkategorie, NEW.anreise, NEW.abreise);
		IF NOT FOUND THEN
		RAISE EXCEPTION 'Keine freien ZImmer vorhanden'; ELSE
		UPDATE 	Reservierungen
		SET 	zimmer = newzimmer
		WHERE 	Reservierungen.Reservierungsnummer= new.reservierungsnummer;	
		END IF;

	END IF;

END
$$ LANGUAGE plpgsql;


CREATE TRIGGER checkoutoforder AFTER UPDATE OF Gaestestatus ON Reservierungen 
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'ARRIVAL')
	EXECUTE PROCEDURE checkoutoforder();
	

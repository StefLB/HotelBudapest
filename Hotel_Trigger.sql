--TRIGGER, FUNKTIONEN,RULES

-- RULES

-- belegteZimmerUpdate 
-- Beim Update auf belegteZimmerView werden in
-- Relation Zimmer, die entsprechenden Zimmer auf dreckig gestellt. 
CREATE OR REPLACE RULE belegteZimmerUpdate AS ON UPDATE 
TO belegteZimmerView WHERE NEW.dreckig = true 
DO INSTEAD 
	UPDATE Zimmer
	SET dreckig = true
	WHERE Zimmernummer = NEW.zugewiesenesZimmer AND gehoertZuHotel = NEW.ZimmerInHotel; 



-- kartenGueltigInsert
-- Bei der Ausgabe einer Zimmerkarte, darf diese nicht gesperrt sein
-- offentsichtlich kann nur eine wiedergefundene karte aushaendigt werden
CREATE OR REPLACE RULE kartenGueltigInsert AS ON INSERT
TO erhalten 
DO ALSO 
	UPDATE Zimmerkarte
	SET gesperrt = FALSE 
	WHERE NEW.KartenID = Zimmerkarte.KartenID;



-- FUNKTIONEN 


-- getPreisTabelle
-- gibt die Preise des Hotels aus der Preistabelle zurueck
CREATE OR REPLACE FUNCTION getPreisTabelle(Hotelparam int) RETURNS TABLE (Posten varChar, Preis money)
AS $$	
	DECLARE Tabellennummer int;
BEGIN
	RETURN QUERY
	SELECT 	hatPreistabelle INTO Tabellennummer
	FROM 	Hotel
	WHERE 	Hotelparam = HotelID;

	SELECT 	*
	FROM 	Preistabelle
	-- 
	WHERE 	Tabellennummer LIKE rtrim(CodeUndPosten::string , '-abcdefghijklmnopqrstuvwxyz');

END	
$$LANGUAGE plpgsql; 



-- ZimmerFreiAnDate
-- Gibt Zimmer einer gewuenschten Kategorie in Hotel zurueck, die frei sind von-bis, austeigend sortiert
CREATE OR REPLACE FUNCTION ZimmerFreiAnDate(Hotel int, Zimmerkat Zimmerkategorie, von date, bis date) RETURNS TABLE (Zimmernummer  int)
AS $$	
BEGIN
	RETURN QUERY
	WITH freieZimmer AS(
	SELECT 	Zimmer.Zimmernummer,Zimmer.Zimmerkategorie
	FROM 	Zimmer
	WHERE 	gehoertZuHotel = Hotel 
	EXCEPT ( 
	-- Zimmer die nicht frei sind zum gegebenen Zeitraum
	SELECT Reservierungen.Zimmer, Reservierungen.Zimmerkategorie
	FROM 	Reservierungen 
	WHERE 	gehoertZuHotel = Hotel 
		-- muss frei sein von - bis
		AND ((von >= Anreise AND von <= Abreise) OR (bis >= Anreise AND bis <= Abreise))
		-- nur vorgemerkte, ankommende oder belegte Zimmer abziehen
		AND (Gaestestatus = 'RESERVED' OR Gaestestatus = 'ARRIVAL' OR Gaestestatus = 'IN-HOUSE')))

	SELECT 	freieZimmer.Zimmernummer AS Zimmernummer
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
		Hauptsaisonzuschlag int;
BEGIN
	-- Pruefe ob soviele Zimmer frei sind
	CREATE TEMP TABLE temptable
	(Zimmernummer)
	ON COMMIT DROP AS
	SELECT ZimmerFreiAnDate(Hotel, Zimmerkategorie, Anreise, Abreise);
	
	SELECT count(*) INTO AnzahlZimmervar
	FROM temptable;
			
	-- Falls nicht, dann Anfragender informieren
	IF (AnzahlZimmervar < AnzahlZimmer) THEN
		RAISE EXCEPTION 'Die gewuenschte Anzahl an Zimmer ist nicht frei';
	END IF;

	-- Hole Preise aus der zum Hotel zugeordneten Tabelle
	-- und addiere diese zusammen
	SELECT 	sum(preis) INTO preisvar 
	FROM 	getPreisTabelle(Hotel) 
	WHERE 	Zimmerkategorie LIKE ltrim(CodeUndPosten::string , '-0123456789')
		OR Verpflegung  LIKE ltrim(CodeUndPosten::string , '-0123456789');

		
	-- Berechne Anzahl an Haupt- und Nebensaisontagen
	Anzahlnaechte = berechneSaison(Anreise,Abreise); 
	-- beruecksichtige Hauptsaisonzuschlag
	SELECT 	Preis INTO Hauptsaisonzuschlag
	FROM 	getPreisTabelle(Hotel) 
	WHERE 	'HS' LIKE  ltrim(CodeUndPosten::string , '-0123456789');
	
	preisvar = (preisvar + Hauptsaisonzuschlag ) * Anzahlnaechte.Hauptsaisonanzahl 
		  + preisvar * Anzahlnaechte.Nebensaisonanzahl;

	-- Falls ja, lege eine vorgemerkte Reservierung an
	-- eine reservierung pro zimmer
	FOR i IN 0..AnzahlZimmer LOOP
		PERFORM Zimmernummer INTO zimmervar
		FROM temptable
		ORDER BY Zimmernummer ASC
		OFFSET i
		FETCH FIRST 1 ROWS ONLY;
		
		INSERT INTO Reservierungen VALUES (Hotel,zimmervar, preisvar, DEFAULT, Verpflegung, Zimmerkategorie,
					Anreise, Abreise, DEFAULT , NULL, 'AWAITING_CONFIRMATION', Wuensche, Personenanzahl, now());
	END LOOP;
	
	-- Der Kunde erhaelt ein Angebot
	RETURN (Hotel, preisvar*AnzahlZimmer, AnzahlZimmer) ;		
END
$$ LANGUAGE plpgsql; 


-- Ablehnung // TODO ELLI
-- Der Kunde kann ein Angebot ablehnen
CREATE OR REPLACE FUNCTION Zimmeranfrage(Hotel int, Zimmerkategorie Zimmerkategorie, Anreise date, Abreise date, 




-- AnnahmeAngebot Teil 1
-- Ein Kunde mit bereits angelegter KID nimmt ein Angebot an
CREATE OR REPLACE FUNCTION AnnahmeAngebot(KundenID int, Angebotsdaten Angebot) RETURNS VOID 
AS $$
BEGIN
	WITH vorgemerkteZimmer AS (
	-- durch das splitten ist zimmer eindeutig durch 
	-- reservierungsnummer gegeben
	SELECT Reservierungsnummer
	FROM Reservierungen
	WHERE Angebotsdaten.Hotel =  Reservierungen.Hotel AND GaesteStatus = 'AWAITING_CONFIRMATION'
	-- zusammenhaengende Zimmer waeren nett
	ORDER BY Zimmer ASC
	-- kunde wird den im vorigen Schritt 
	-- vorgemerkt zimmer zugeteilt, auch bei gleichzeitigen
	-- Anfragen geht die gesamtzahl auf 
	OFFSET O
	LIMIT Angebotsdaten.AnzahlZimmer::count)
	
	UPDATE 	Reservierungen
	SET 	Reservierungen.KID = KundenId
	WHERE 	Reservierungen.Reservierungsnummer= vorgemerkteZimmer.Reservierungsnummer;
	
END
$$LANGUAGE plpgsql;

-- AnnahmeAngebot Teil 2
-- Ein neuer Kunde nimmt ein Angebot an //TODO ELLI





-- ZimmerDreckig
-- Um 0:00 Uhr werden alle belegte Zimmer auf dreckig gestellt.
-- Simuliert hier durch eine Funktion
CREATE OR REPLACE FUNCTION ZimmerDreckig() RETURNS VOID 
AS $$
	UPDATE belegteZimmer 
	SET dreckig = TRUE
$$ LANGUAGE SQL;



-- Rechnungsposten
-- Ausammeln aller Posten, die wahrend der aktuellen Reservierung aufs Zimmer gebucht wurden
-- Entspricht einem Zimmerkonto 
CREATE OR REPLACE FUNCTION Rechnungsposten(Hotelnummer int, Zimmernummer int) RETURNS 
SETOF RECORD
AS $$
BEGIN	
	WITH Rechnungskunde AS( 
	SELECT 	KID, anreise 
	FROM 	Reservierungen 
	WHERE 	Hotelnummer = Reservierungen.gehoertZuHotel AND Zimmernummer = Reservierungen.Zimmernummer
	-- zeige letzte Reservierung des Zimmers an
	ORDER BY anreise
	FETCH FIRST 1 ROWS ONLY)

	SELECT 	SpeiseID, Name, Zeitpunkt, Preis, sum(Preis) AS GesamtPreis
	FROM 	konsumieren 
		JOIN SpeisenUndGetraenke ON konsumieren.SpeiseID = SpeisenUndGetraenke.SpeiseID
	WHERE 	Rechnungskunde. KID = konsumieren.KID AND konsumieren.zeitpunkt > anreise; 

	RETURN;
END		 
$$ LANGUAGE plpgsql;


-- GourmetGast
-- Ein Gast moechte alle Hotel Restaurants angezeigt bekommen die mehr als 3 Sterne haben



-- FreieSportplaetze 
-- Ein Gast moechte sehen, welche Sportplaetze am jetzigen Tag noch zu vermieten sind





-- TRIGGER 

-- EinChecken
-- Beim Einchecken von einem Gast, muessen fuer alle 
-- zusaetzlichen einen Eintrag in Kunden stattfinden
-- Allen Gaesten des Zimmers wird eine Karte ausgehaendigt TODO: ER Modell anpassen, aus 1 wird 0!





-- Bezahlen






-- Kartenverlust
-- Beim Verlust der Karte, wird diese gesperrt und aus erhalten geloescht.
-- Der Kunde bekommt eine neue




-- CheckOut 
-- Beim CHECK-OUT des Kunden, gibt dieser die Karte ab 
-- Alle Karten, die der Reservierung zugeteilt wurden werden 
-- aus erhalten geloescht und koennen nicht mehr die entsprechende Tuer oeffnen
CREATE OR REPLACE FUNCTION CheckOut() RETURNS TRIGGER 
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
	END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER CheckOutTrigger BEFORE UPDATE OF Gaestestatus ON Reservierungen
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'CHECKED-OUT')
	EXECUTE PROCEDURE schonBezahlt();
	EXECUTE PROCEDURE KartenRueckgabe();


-- VIP
-- Bei der 100 Uebernachtung bekommt der Gast VIP Status





-- TuerOeffner
-- Beim oeffnen einer Tuer wird die Zugangsberechtigung geprueft
-- Nur zugelassene Tueren duerfen geoeffnet werden



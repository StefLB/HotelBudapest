﻿/*
SCHEMA

INHALTSANGABE:
	1. SEQUENZEN
	2. DOMAENEN
	3. TYPEN
	4. TABELLEN
*/

-- 1. SEQUENZEN


CREATE SEQUENCE IDSequenz START 1;

-- 2. DOMAENEN

CREATE DOMAIN HOTELTYP varchar
	CHECK (	VALUE = 'Romantik' OR 
		VALUE = 'Business' OR 
		VALUE = 'Family' OR 
		VALUE = 'Budget' OR
		VALUE = 'Wellness' OR
		VALUE = 'Luxus' );

CREATE DOMAIN OEFFNUNGSZEIT varchar
	CHECK (	VALUE = 'MO-FR 07/17' OR
		VALUE = 'MO-SO 07/17' OR 
		VALUE = 'MO-FR 07/20' OR 
		VALUE = 'MO-SO 07/20' OR 
		VALUE = 'MO-SO 07/23' OR
		VALUE = '24/7' OR 
		VALUE = 'MO-SO 18/03' );

CREATE DOMAIN BESONDERHEIT varchar
	CHECK ( VALUE = 'vegan' OR
		VALUE = 'vegetarisch' or
		VALUE = 'Lactose-Intoleranz' OR
		VALUE = 'Ei-Allergie' OR
		VALUE = 'kosher' OR
		VALUE = 'halal');

CREATE DOMAIN PLATZART varchar
	CHECK (	VALUE = 'Rasenplatz' OR 
		VALUE = 'Asphaltplatz' OR
		VALUE = 'Gummiplatz' OR
		VALUE = 'Astroturf' );

CREATE DOMAIN KUECHE varchar
	CHECK (	VALUE = 'italienisch' OR 
		VALUE = 'chinesisch' OR
		VALUE = 'vegetarisch' OR
		VALUE = 'deutsch' OR
		VALUE = 'rustikal' OR
		VALUE = 'japanish' OR
		VALUE = 'urbanisch' OR
		VALUE = 'organic'  OR
		VALUE = 'international' OR
		VALUE = 'franzoesisch');

CREATE DOMAIN AUSRUESTUNGSTYP varchar
	CHECK (	VALUE = 'Schlaeger' OR 
		VALUE = 'Helm' OR
		VALUE = 'Golfwagen' OR
		VALUE = 'Knieschoner' OR
		VALUE = 'Golfhandschuhe' OR
		VALUE = 'Golftasche' );

CREATE DOMAIN MENUKATEGORIE varchar
	CHECK (	VALUE = 'Softgetraenk' OR 
		VALUE = 'Vorspeise' OR
		VALUE = 'Hauptspeise' OR
		VALUE = 'Nachspeise' OR
		VALUE = 'Cocktail' OR
		VALUE = 'Longdrink' OR
		VALUE = 'Likoer' OR
		VALUE = 'Hochprozentiges' OR
		VALUE = 'Heissgetraenk' OR
		VALUE = 'Snack' OR
		VALUE = 'Salat' OR
		VALUE = 'Beilage' OR
		VALUE = 'Lowfat' OR
		VALUE = 'Kinderkarte' OR
		VALUE = 'Seniors');

CREATE DOMAIN GAESTESTATUS varchar
	CHECK ( VALUE = 'AWAITING-CONFIRMATION' OR	-- abwarten auf annahme oder ablehnung
		VALUE = 'ARRIVAL' OR	-- am Tag der Anreise
		VALUE = 'RESERVED' OR 	-- normale Reservierung
		VALUE = 'CANCELED' OR 	-- storniert, war reserved
		VALUE = 'IN-HOUSE' OR	-- im Haus eingecheckt
		VALUE = 'CHECKED-OUT' OR --abgereist
		VALUE = 'TURN-DOWN' ) ;	-- Reservierung nicht angenommen (Ablehnung)

CREATE DOMAIN VERPFLEGUNGSSTUFE varchar
	CHECK ( VALUE = 'ROOM' OR 	--nur Zimmer
		VALUE = 'BRFST' OR	--Fruehstueck
		VALUE = 'HBL' OR 	--Halbpension Mittag (half board lunch)
		VALUE = 'HBD' OR 	--Halbpension Abends (half bord dinner)
		VALUE = 'FB' OR 	--Vollpension (full board)
		VALUE = 'ALL'); 	--All inclusive

CREATE DOMAIN ZIMMERKATEGORIE varchar
	CHECK ( VALUE = 'EZMM' OR	--Einzelzmmer mit Meerblick
		VALUE = 'EZOM' OR	--Einzelzimmer ohne Meerblick
		VALUE = 'DZMM' OR	--Doppelzimmer mit Meerblick
		VALUE = 'DZOM' OR	--Doppelzimmer ohne Meerblick
		VALUE = 'TRMM' OR	--Drei-Bett-Zimmer mit Meerblick
		VALUE = 'TROM' OR	--Drei-Bett-Zimmer ohne Meerblick
		VALUE = 'SUIT');

-- 3. TYPEN

CREATE TYPE Angebot AS (
	Hotel int,
	Zimmerkategorie Zimmerkategorie,
	AnzahlZimmer int,
	Anreise date,
	Abreise date,
	Gesamtpreis money

);

CREATE TYPE Anzahlnaechtetype AS (
	AnzahlHauptsaison int,
	AnzahlNebensaison int
);


-- 4. TABELLEN

CREATE TABLE Preistabelle (
	CodeUndPosten varChar,		-- ein CodeUndPosten hat bspw. die Form 1-EZMM. Die Nummer korrespondiert 
					-- mit Attribut hatPreistabelle in der Tabelle Hotel. Der zweite Teil ist der eigentliche Posten. 
	Preis money NOT NULL,

	PRIMARY KEY (CodeUndPosten)

);


CREATE TABLE Hotel (
	HotelID SERIAL,
	Hotelname varchar NOT NULL,
	Adresse varchar NOT NULL,
	Hoteltyp HOTELTYP NOT NULL,
	hatPreistabelle int NOT NULL, 	-- zeigt welche Preise fuer das Hotel gelten 

	PRIMARY KEY (HotelID)
);

CREATE TABLE Kunden(
	KID SERIAL, 
	Vorname varChar NOT NULL,
	Nachname varChar NOT NULL,
	Adresse varChar ,
	Telefonnummer bigint ,
	Kreditkarte bigint, 
	Besonderheiten BESONDERHEIT,
	VIP boolean DEFAULT FALSE,
	Erstellungszeitpunkt timestamp NOT NULL DEFAULT now(),

	UNIQUE (Kreditkarte),
	UNIQUE (Vorname, Nachname, Adresse),
	PRIMARY KEY (KID)
);

CREATE TABLE Zimmer (
	gehoertZuHotel int NOT NULL, 
	Zimmernummer int NOT NULL,
	Zimmerkategorie ZIMMERKATEGORIE NOT NULL,
	maxPersonen int NOT NULL,
	Dreckig boolean NOT NULL,
	OutofOrder boolean NOT NULL,

	CHECK (Zimmernummer > 0),
	CHECK (maxPersonen > 0),

	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel ON DELETE CASCADE, -- loeschen eines Hotels soll alle Zimmer loeschen
	PRIMARY KEY (gehoertZuHotel,Zimmernummer) -- Zimmernummer koennen in mehreren Hotels gleich sein

);

CREATE TABLE Abteilung(
	gehoertZuHotel int NOT NULL,
	AID int NOT NULL,
	Name varchar NOT NULL,
	Location varchar NOT NULL,
	Oeffnungszeiten OEFFNUNGSZEIT NOT NULL,
	
	UNIQUE (Name, Location), -- damit der Gast die Abteilung eindeutig finden kann
	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel ON DELETE CASCADE, -- loeschen eines Hotels soll alle Abteilungen loeschen
	PRIMARY KEY(gehoertZuHotel, AID) -- Abteilungen in verschiedenen Hotels koennen gleiche Nummern besitzen

);

CREATE TABLE Sporteinrichtungen (
	gehoertzuHotel int NOT NULL,
	AID int NOT NULL,
	Preis money NOT NULL,

	FOREIGN Key(gehoertZuHotel) REFERENCES Hotel ON DELETE CASCADE, 
	PRIMARY KEY(AID, gehoertZuHotel)
);

CREATE TABLE Fahrraeder (
	gehoertzuHotel int NOT NULL,
	AID int NOT NULL,
	Gaenge int NOT NULL,
	Modell varchar,

	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel ON DELETE CASCADE,
	PRIMARY KEY(AID, gehoertZuHotel)
);

CREATE TABLE Tennisplaetze (
	gehoertzuHotel int NOT NULL,
	AID int NOT NULL,
	Platzart PLATZART,

	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel ON DELETE CASCADE,
	PRIMARY KEY(AID, gehoertZuHotel)
);

CREATE TABLE Golf (
	gehoertzuHotel int NOT NULL,
	AID int NOT NULL,
	Schwierigkeitsgrad int,

	CHECK (Schwierigkeitsgrad > 0),
	
	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel ON DELETE CASCADE,
	PRIMARY KEY(AID, gehoertZuHotel)
);

CREATE TABLE Minigolf (
	gehoertzuHotel int NOT NULL,
	AID int NOT NULL,
	Schwierigkeitsgrad int,

	CHECK (Schwierigkeitsgrad > 0),

	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel ON DELETE CASCADE,
	PRIMARY KEY(AID, gehoertZuHotel)
);

CREATE TABLE mieten (
	gehoertZuHotel int NOT NULL,
	AID int NOT NULL ,
	KID int NOT NULL,
	von timestamp NOT NULL,
	bis timestamp NOT NULL,
	Zeitpunkt timestamp,

	CHECK ((bis - von) <= '1 day' ), -- Es gilt eine maximale Mietdauer fuer Sportplaetze 
	CHECK (bis > von ),
	
	FOREIGN KEY (gehoertZuHotel, AID) REFERENCES Sporteinrichtungen(gehoertZuHotel,AID) ON DELETE RESTRICT, -- Keine Tupel loeschen...
	FOREIGN KEY (KID) REFERENCES Kunden ON DELETE RESTRICT, -- ...die fuer Statistiken wichtig sind.
	PRIMARY KEY (von, gehoertZuHotel,AID)
);

CREATE TABLE Schwimmbad (
	gehoertZuHotel int,
	AID int NOT NULL,
	LaengeBecken int NOT NULL,
	Sauna boolean,
	Preis money,

	CHECK (LaengeBecken > 0),

	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel ON DELETE CASCADE,
	PRIMARY KEY (gehoertZuHotel,AID)
);

CREATE TABLE Ausruestung (
	gehoertZuHotel int REFERENCES Hotel ON DELETE CASCADE,
	gehoertZuSporteinrichtung int NOT NULL,
	Ausruestungsnummer int NOT NULL,
	Ausruestungstyp AUSRUESTUNGSTYP NOT NULL,

	PRIMARY KEY (gehoertZuHotel, gehoertZuSporteinrichtung, Ausruestungsnummer, Ausruestungstyp)
);

CREATE TABLE leihen (
	gehoertZuHotel int NOT NULL,
	gehoertZuSporteinrichtung int NOT NULL, 
	KID int NOT NULL, 
	Ausruestungsnummer int NOT NULL,
	Ausruestungstyp AUSRUESTUNGSTYP NOT NULL,
	von timestamp NOT NULL,
	bis timestamp NOT NULL,

	CHECK ((bis - von) <= '1 day' ), 	-- Es gilt eine maximale Leihdauer fuer Sportgeraete 
	CHECK (bis > von ),

	FOREIGN KEY (KID) REFERENCES Kunden ON DELETE RESTRICT,
	FOREIGN KEY (gehoertZuHotel, gehoertZuSporteinrichtung, Ausruestungsnummer,Ausruestungstyp) REFERENCES Ausruestung ON DELETE RESTRICT,
	PRIMARY KEY (gehoertZuHotel, gehoertZuSporteinrichtung, Ausruestungsnummer,Ausruestungstyp, von)
);

CREATE TABLE benutzen (
	gehoertZuHotel int NOT NULL,
	AID int NOT NULL,
	KID int NOT NULL, 
	von timestamp NOT NULL,
	bis timestamp NOT NULL,

	CHECK (bis > von ),

	UNIQUE (KID, bis),
	FOREIGN KEY (KID) REFERENCES Kunden ON DELETE RESTRICT,
	PRIMARY KEY (KID,von)
);

CREATE TABLE Restauration  (
	gehoertZuHotel int NOT NULL,
	AID int NOT NULL,
	
	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel ON DELETE CASCADE,
	PRIMARY KEY (gehoertZuHotel, AID)
);

CREATE TABLE Hotelbar  (
	gehoertZuHotel int NOT NULL,
	AID int NOT NULL,

	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel ON DELETE CASCADE,
	PRIMARY KEY (gehoertZuHotel, AID)
);

CREATE TABLE Restaurant  (
	gehoertZuHotel int NOT NULL,
	AID int NOT NULL,
	Kueche Kueche NOT NULL,
	Sterne int NOT NULL,

	CHECK (Sterne > 0),
	
	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel ON DELETE CASCADE,
	PRIMARY KEY (gehoertZuHotel, AID)
);

CREATE TABLE SpeisenUndGetraenke(
	SpeiseID SERIAL ,
	Menukategorie MENUKATEGORIE NOT NULL,
	Name varChar NOT NULL,
	Preis money NOT NULL,

	PRIMARY KEY (SpeiseID)	
);

CREATE TABLE Essen(
	SpeiseID int,
	Besonderheit Besonderheit,

	PRIMARY KEY (SpeiseID)	
);

CREATE TABLE Trinken(
	SpeiseID int NOT NULL,
	Alkoholgehalt numeric,
	
	CHECK (Alkoholgehalt > 0::numeric),
	
	PRIMARY KEY (SpeiseID)	
);


CREATE TABLE wirdServiertIn(
	gehoertZuHotel int NOT NULL, 
	AID int NOT NULL,
	SpeiseID int NOT NULL ,

	FOREIGN KEY(SpeiseID) REFERENCES SpeisenUndGetraenke ON DELETE CASCADE,
	FOREIGN KEY(gehoertZuHotel,AID) REFERENCES Restauration ON DELETE CASCADE,
	PRIMARY KEY (gehoertZuHotel,AID,SpeiseID)
);



CREATE TABLE konsumieren(
	imHotel int NOT NULL,	
	verspeistIn INT NOT NULL,
	KID int NOT NULL,
	SpeiseID int NOT NULL, 
	Zeitpunkt timestamp NOT NULL DEFAULT now(),

	FOREIGN KEY (imHotel, verspeistIn) REFERENCES Restauration ON DELETE RESTRICT,
	FOREIGN KEY (KID) REFERENCES Kunden ON DELETE RESTRICT,
	PRIMARY KEY (KID, Zeitpunkt)
	
);

	
CREATE TABLE Reservierungen(
	gehoertZuHotel int,
	Zimmer int,
	Zimmerpreis money NOT NULL,
	Stornierungsnummer int DEFAULT NULL,
	Verpflegungsstufe VERPFLEGUNGSSTUFE NOT NULL,
	Zimmerkategorie ZIMMERKATEGORIE,
	Anreise date NOT NULL,
	Abreise date NOT NULL,
	Reservierungsnummer SERIAL,
	reserviertVonKunde int NOT NULL, 
	Gaestestatus GAESTESTATUS,
	Wuensche varchar,
	Personenanzahl int NOT NULL,
	Reservierungszeitpunkt timestamp NOT NULL,

	CHECK (Personenanzahl > 0),
	CHECK (Anreise < Abreise ),
	--CHECK (Anreise >= current_date), auskommentiert, da sonst keine daten in der vergangenheit eingefuegt werden koennen
	
	FOREIGN KEY (reserviertVonKunde) REFERENCES Kunden ON DELETE RESTRICT,
	FOREIGN KEY (gehoertzuhotel, Zimmer) REFERENCES Zimmer ON DELETE RESTRICT,
	UNIQUE (Reservierungsnummer),
	UNIQUE (Stornierungsnummer),
	PRIMARY KEY  (Reservierungsnummer)

);

CREATE TABLE Ablehnungen(
	Reservierungsnummer int NOT NULL,
	Grund varchar,
	Ablehnungszeitpunkt timestamp DEFAULT now(),
	
	PRIMARY KEY  (Reservierungsnummer)
);

CREATE TABLE bezahlen (
	Reservierungsnummer int NOT NULL,
	KID int NOT NULL,
	Betrag money NOT NULL, 
	Zeitpunkt timestamp,

	FOREIGN KEY (Reservierungsnummer) REFERENCES Reservierungen ON DELETE RESTRICT,
	FOREIGN KEY (KID) REFERENCES Kunden ON DELETE RESTRICT,
	PRIMARY KEY (Reservierungsnummer)
);


CREATE TABLE Zimmerkarte (
	KartenID SERIAL,
	gesperrt boolean DEFAULT FALSE,

	PRIMARY KEY (KartenID)
);

CREATE TABLE oeffnet (
	gehoertZuHotel int,
	Zimmernummer int,
	KartenID int NOT NULL,
	Zeitpunkt timestamp NOT NULL,
	
	UNIQUE (gehoertZuHotel,Zimmernummer, Zeitpunkt), -- angenommen jedes Zimmer hat nur eine Tuer
	FOREIGN KEY (gehoertZuHotel,Zimmernummer) REFERENCES Zimmer(gehoertZuHotel,Zimmernummer) ON DELETE RESTRICT,-- Ein Log...
	FOREIGN KEY (KartenID) REFERENCES Zimmerkarte ON DELETE RESTRICT,  -- ... muss unberuehrt bleiben
	PRIMARY KEY (KartenID, Zeitpunkt)
);

CREATE TABLE erhalten (
	KundenID int,
	KartenID int,
	Reservierungsnummer int,

	FOREIGN KEY (Reservierungsnummer) REFERENCES Reservierungen ON DELETE NO ACTION, -- Erhalten beinhaltet nur anwesende Reservierungen...
	FOREIGN KEY (KundenID) REFERENCES Kunden ON DELETE NO ACTION,-- ...und Kunden, die nicht geloescht werden. 
	FOREIGN KEY (KartenID) REFERENCES Zimmerkarte,
	PRIMARY KEY (KartenID)
);



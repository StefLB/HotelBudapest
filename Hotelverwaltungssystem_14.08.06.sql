--Hotelverwaltugssystem

--Domaenen

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
		VALUE = 'Golfhanschuhe' OR
		VALUE = 'Golftasche' );

CREATE DOMAIN MENUKATEGORIE varchar
	CHECK (	VALUE = 'Softgetraenk' OR 
		VALUE = 'Vorspeise' OR
		VALUE = 'Hauptspeise' OR
		VALUE = 'Nachspeise' OR
		VALUE = 'Cocktail' OR
		VALUE = 'Longdrink' OR
		VALUE = 'Likoer' OR
		VALUE = 'Hochprozetiges' OR
		VALUE = 'Heissgetraenk' OR
		VALUE = 'Snack' OR
		VALUE = 'Salat' OR
		VALUE = 'Beilage' OR
		VALUE = 'Lowfat' OR
		VALUE = 'Kinderkarte' OR
		VALUE = 'Seniors');

CREATE DOMAIN GAESTESTATUS varchar
	CHECK ( VALUE = 'ARRIVAL' OR	--am Tag der Anreise
		VALUE = 'RESERVED' OR 	-- normale Reservierung
		VALUE = 'CANCELED' OR 	-- storniert, war reserved
		VALUE = 'IN-HOUSE' OR	--im Haus eingecheckt
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


--Hotel

CREATE TABLE Hotel (
	HotelID int NOT NULL,
	Hotelname varchar NOT NULL,
	Adresse varchar NOT NULL,
	Hoteltyp HOTELTYP NOT NULL,

	PRIMARY KEY (HotelID),
	UNIQUE (HotelID)
);

CREATE TABLE Kunden(
	KID int NOT NULL, 
	Erstellungszeitpunkt timestamp DEFAULT now()NOT NULL,
	Telefonnummer int,
	Kreditkarte int,
	Besonderheiten BESONDERHEIT,
	Nachname varChar NOT NULL,
	Vorname varChar NOT NULL,
	Adresse varChar,
	VIP boolean DEFAULT false,

	PRIMARY KEY (KID),
	UNIQUE (KID)
);

CREATE TABLE Zimmer (
	gehoertZuHotel int NOT NULL, 
	Zimmernummer int NOT NULL,
	Zimmerkategorie ZIMMERKATEGORIE NOT NULL,
	Dreckig boolean NOT NULL,
	OutofOrder boolean NOT NULL,
	maxPersonen int NOT NULL,

	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel,
	UNIQUE (gehoertZuHotel, Zimmernummer), -- hinzugefuegt 07.08.14
	PRIMARY KEY (gehoertZuHotel,Zimmernummer)

);

CREATE TABLE Abteilung(
	gehoertZuHotel int NOT NULL,
	AID int NOT NULL,
	Oeffnungszeiten OEFFNUNGSZEIT NOT NULL,
	Location varchar NOT NULL,
	Name varchar NOT NULL,


	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel,
	UNIQUE (gehoertZuHotel, AID), -- hinzugefuegt 07.08.14
	PRIMARY KEY(gehoertZuHotel, AID)
);

CREATE TABLE Sporteinrichtungen (
	gehoertzuHotel int NOT NULL,
	AID int NOT NULL,
	Oeffnungszeiten OEFFNUNGSZEIT NOT NULL,
	Location varchar NOT NULL,
	Name varchar NOT NULL,
	Preis money NOT NULL,

	FOREIGN Key(gehoertZuHotel) REFERENCES Hotel,
	UNIQUE (AID, gehoertZuHotel), -- hinzugefuegt 07.08.14
	PRIMARY KEY(AID, gehoertZuHotel)
);

CREATE TABLE Fahrraeder (
	gehoertzuHotel int NOT NULL,
	AID int NOT NULL,
	Oeffnungszeiten OEFFNUNGSZEIT NOT NULL,
	Location varchar NOT NULL,
	Name varchar NOT NULL,
	Preis money NOT NULL,
	Gaenge int NOT NULL,
	Modell varchar,

	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel,
	UNIQUE (AID, gehoertZuHotel), -- hinzugefuegt 07.08.14
	PRIMARY KEY(AID, gehoertZuHotel)
);

CREATE TABLE Tennisplaetze (
	gehoertzuHotel int NOT NULL,
	AID int NOT NULL,
	Oeffnungszeiten OEFFNUNGSZEIT NOT NULL,
	Location varchar NOT NULL,
	Name varchar NOT NULL,
	Preis money NOT NULL,
	Platzart PLATZART,

	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel,
	UNIQUE (AID, gehoertZuHotel), -- hinzugefuegt 07.08.14
	PRIMARY KEY(AID, gehoertZuHotel)
);

CREATE TABLE Golf (
	gehoertzuHotel int NOT NULL,
	AID int NOT NULL,
	Oeffnungszeiten OEFFNUNGSZEIT NOT NULL,
	Location varchar NOT NULL,
	Name varchar NOT NULL,
	Preis money NOT NULL,
	Schwierigkeitsgrad int,
	
	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel,
	UNIQUE (AID, gehoertZuHotel), -- hinzugefuegt 07.08.14
	PRIMARY KEY(AID, gehoertZuHotel)
);

CREATE TABLE Minigolf (
	gehoertzuHotel int NOT NULL,
	AID int NOT NULL,
	Oeffnungszeiten OEFFNUNGSZEIT NOT NULL,
	Location varchar NOT NULL,
	Name varchar NOT NULL,
	Preis money NOT NULL,
	Schwierigkeitsgrad int,
	
	FOREIGN KEY (gehoertZuHotel) REFERENCES Hotel,
	UNIQUE (AID, gehoertZuHotel), -- hinzugefuegt 07.08.14
	PRIMARY KEY(AID, gehoertZuHotel)
);

CREATE TABLE mieten (
	KID int NOT NULL REFERENCES Kunden,
	Zeitpunkt timestamp,
	von timestamp NOT NULL,
	bis timestamp NOT NULL,
	gehoertZuHotel int NOT NULL,
	AID int NOT NULL ,

	
	FOREIGN KEY (gehoertZuHotel, AID) REFERENCES Sporteinrichtungen,
	FOREIGN KEY (KID) REFERENCES Kunden,
	PRIMARY KEY (von, AID, gehoertZuHotel)
);

CREATE TABLE Schwimmbad (
	gehoertZuHotel int REFERENCES Hotel,
	AID int NOT NULL,
	Oeffnugszeiten OEFFNUNGSZEIT NOT NULL,
	Location varchar NOT NULL,
	Name varchar NOT NULL,
	LaengeBecken int NOT NULL,
	Sauna boolean,
	Preis money,

	UNIQUE (gehoertZuHotel,AID), -- hinzugefuegt 07.08.14
	PRIMARY KEY (gehoertZuHotel,AID)
);

CREATE TABLE Ausruestung (
	Ausruestungstyp AUSRUESTUNGSTYP NOT NULL,
	Ausruestungsnummer int NOT NULL,
	gehoertZuSporteinrichtung int NOT NULL,
	gehoertZuHotel int REFERENCES Hotel,

	FOREIGN KEY (gehoertZuSporteinrichtung, gehoertzuHotel) REFERENCES Sporteinrichtungen,
	PRIMARY KEY (Ausruestungstyp ,Ausruestungsnummer,
	gehoertZuSporteinrichtung,
	gehoertZuHotel)
);

CREATE TABLE leihen (
	KID int NOT NULL REFERENCES Kunden, 
	Ausruestungstyp AUSRUESTUNGSTYP NOT NULL,
	Ausruestungsnummer int NOT NULL,
	gehoertZuSporteinrichtung int NOT NULL, 
	gehoertZuHotel int NOT NULL,
	von timestamp NOT NULL,
	bis timestamp NOT NULL,

	FOREIGN KEY (Ausruestungstyp, Ausruestungsnummer, gehoertZuSporteinrichtung, gehoertZuHotel) REFERENCES Ausruestung,
	PRIMARY KEY (Ausruestungstyp,Ausruestungsnummer, gehoertZuSporteinrichtung, gehoertZuHotel,von)

);



CREATE TABLE benutzen (

	KID int NOT NULL, 
	gehoertZuHotel int NOT NULL,
	AID int NOT NULL,
	von timestamp NOT NULL,
	bis timestamp NOT NULL,

	FOREIGN KEY (KID) REFERENCES Kunden,
	PRIMARY KEY (KID,von)
);

CREATE TABLE Restauration  (
	gehoertZuHotel int NOT NULL REFERENCES Hotel,
	AID int NOT NULL,
	Oeffnungszeiten Oeffnungszeit,
	Location varChar,
	Name varChar,

	UNIQUE (gehoertZuHotel,AID), -- hinzugefuegt 07.08.14
	PRIMARY KEY (gehoertZuHotel, AID)
);

CREATE TABLE Hotelbar  (
	gehoertZuHotel int NOT NULL REFERENCES Hotel,
	AID int NOT NULL,
	Oeffnungszeiten Oeffnungszeit NOT NULL,
	Location varChar NOT NULL,
	Name varChar NOT NULL,

	PRIMARY KEY (gehoertZuHotel, AID)
);

CREATE TABLE Restaurant  (
	gehoertZuHotel int NOT NULL REFERENCES Hotel,
	AID int NOT NULL,
	Oeffnungszeiten Oeffnungszeit NOT NULL,
	Location varChar NOT NULL,
	Name varChar NOT NULL,
	Sterne int NOT NULL,
	Kueche Kueche NOT NULL,
	
	UNIQUE (gehoertZuHotel,AID), -- hinzugefuegt 07.08.14
	 PRIMARY KEY (gehoertZuHotel, AID)
);

CREATE TABLE SpeisenUndGetraenke(
	SpeiseID int NOT NULL ,
	Name varChar NOT NULL,
	Preis money NOT NULL,
	Menukategorie MENUKATEGORIE NOT NULL,

	PRIMARY KEY (SpeiseID)	
);

CREATE TABLE Essen(
	SpeiseID int,
	Name varChar,
	Preis money NOT NULL,
	Menukategorie Menukategorie NOT NULL,
	Besonderheit Besonderheit,

	PRIMARY KEY (SpeiseID)	
);

CREATE TABLE Trinken(
	SpeiseID int NOT NULL,
	Name varChar NOT NULL,
	Preis money NOT NULL,
	Menukategorie Menukategorie NOT NULL,
	Alkoholgehalt numeric,
	
	PRIMARY KEY (SpeiseID)	
);


CREATE TABLE wirdServiertIn(
	SpeiseID int NOT NULL ,
	gehoertZuHotel int NOT NULL, 
	AID int NOT NULL,

	FOREIGN KEY(SpeiseID) REFERENCES SpeisenUndGetraenke,
	FOREIGN KEY(AID, gehoertZuHotel) REFERENCES Restauration
);



CREATE TABLE konsumieren(
	KID int NOT NULL,
	SpeiseID int NOT NULL, 
	Zeitpunkt timestamp NOT NULL,

	FOREIGN KEY (KID) REFERENCES Kunden,
	PRIMARY KEY (KID, Zeitpunkt)
	
);

	
CREATE TABLE Reservierungen(
	Reservierungsnummer int NOT NULL, --eventuell serial hier
	Zimmerpreis money NOT NULL,
	Stornierungsnummer int,
	Verpflegungsstufe VERPFLEGUNGSSTUFE NOT NULL,
	Zimmerkategorie ZIMMERKATEGORIE,
	Anreise date NOT NULL,
	Abreise date NOT NULL,
	Gaestestatus GAESTESTATUS,
	Wuensche varchar,
	Personenanzahl int NOT NULL,
	Reservierungszeitpunkt timestamp NOT NULL,
	reserviertVonKunde int NOT NULL,
	zugewiesenesZimmer int,
	ZimmerInHotel int,

	FOREIGN KEY (reserviertVonKunde) REFERENCES Kunden,
	FOREIGN KEY (zugewiesenesZimmer, ZimmerInHotel) REFERENCES Zimmer,
	UNIQUE (Reservierungsnummer),
	UNIQUE (Stornierungsnummer),
	UNIQUE (zugewiesenesZimmer,ZimmerInHotel ,Anreise),
	PRIMARY KEY  (Reservierungsnummer)
);

CREATE TABLE Ablehnungen(
	Reservierungsnummer int NOT NULL,
	Zimmerpreis money NOT NULL,
	Stornierungsnummer int DEFAULT NULL,
	Verpflegungsstufe Verpflegungsstufe,
	Zimmerkategorie Zimmerkategorie,
	Anreise date NOT NULL,
	Abreise date NOT NULL,
	Gaestestatus Gaestestatus,
	Wuensche varchar,
	Personenanzahl int,
	Reservierungszeitpunkt timestamp NOT NULL,
	reserviertVonKunde int,
	zugewiesenesZimmer int,
	ZimmerInHotel int,
	Grund varchar,
	Ablehnungszeitpunkt timestamp,
	
	FOREIGN KEY (reserviertVonKunde) REFERENCES Kunden,
	FOREIGN KEY (zugewiesenesZimmer, ZimmerInHotel) REFERENCES Zimmer,
	UNIQUE (Reservierungsnummer),
	UNIQUE (Stornierungsnummer),
	PRIMARY KEY  (Reservierungsnummer)
);

CREATE TABLE bezahlen (
	Reservierungsnummer int REFERENCES Reservierungen NOT NULL,
	KID int REFERENCES Kunden NOT NULL,
	Zeitpunkt timestamp,

	PRIMARY KEY (Reservierungsnummer)
);


CREATE TABLE Zimmerkarte (
	KartenID int NOT NULL,
	gesperrt boolean,

	PRIMARY KEY (KartenID)
);

CREATE TABLE oeffnet (
	KartenID int NOT NULL,
	Zeitpunkt timestamp NOT NULL,
	Zimmernummer int,
	ZimmerInHotel int REFERENCES Hotel,
	
	FOREIGN KEY (Zimmernummer, ZimmerInHotel) REFERENCES Zimmer,
	FOREIGN KEY (KartenID) REFERENCES Zimmerkarte,
	PRIMARY KEY (KartenID, Zeitpunkt)
);

CREATE TABLE erhalten (
	KundenID int REFERENCES Kunden,
	KartenID int ,
	Reservierungsnummer  int REFERENCES Reservierungen,
	FOREIGN KEY (KartenID) REFERENCES Zimmerkarte
);



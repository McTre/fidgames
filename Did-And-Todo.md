# Did and Todo

Projektin ajantasainen työtilanne: mitä valmistui viimeksi ja mistä jatketaan.

## Päivityskäytäntö

- Päivitä tämä tiedosto jokaisen valmistuneen työvaiheen jälkeen.
- Kirjaa viimeksi tehdyt muutokset, suoritetut tarkistukset ja mahdolliset keskeneräiset asiat.
- Päivitä seuraava vaihe konkreettiseksi tehtäväksi nykyisen tilanteen perusteella.
- Erota toteutetut ominaisuudet suunnitelmista. Pidä tämä tilannekuvana; tarkempi muutoshistoria löytyy Gitistä.

## Viimeksi tehty

- Toteutettu Godot 4.7.2:lla FidGames Lab: 170 × 320 pikselin laitenäyttö, 1×/2×-esikatselu, simuloidut ohjaimet sekä pelin lukitus ja tilan palautus.
- Toteutettu Pixel Studio: kahdeksan väriä ja läpinäkyvyys, piirtäminen, kumoaminen, enintään kuusi animaatioruutua, toisto ja tiedostojen tallennus.
- Lisätty objektien raahaus laitenäytölle koon ja animaatioiden vertailua varten.
- Muutettu oletusobjekti 32 × 32 näyttöpikselin kokoiseksi, mutta piirtoresoluutioltaan 8 × 8 ruuduksi. Lisätty myös 64 × 64 koko, jonka piirtoresoluutio on 16 × 16 ruutua.
- Otettu Reactor-prototyypissä käyttöön piirretyt cursor-, goal- ja Line-spritet. Osuma-alue pysyy vakiona, ja pelinäytön tekstit on karsittu nimeen, pisteisiin sekä START/MISSED-tilaan.
- Täydennetty pelinkehityksen periaatteita: pelit opitaan kokeilemalla, ilman turhia ohjetekstejä tai monimutkaisia yksityiskohtia.
- Lisätty projektin README ja pushattu toteutus GitHubin main-haaraan commitissa `c50c51d`. Pelin ja grafiikkaeditorin toimintatestit läpäistiin.
- Sovittu seuraavaksi suunnaksi yhteinen C++-pelilogiikka, joka käännetään erikseen tietokoneelle ja ESP32-S3:lle. Tämä on suunnitelma; nykyinen peli on vielä GDScriptiä.
- Lisätty tämä tiedosto työvaiheiden jatkuvaa seurantaa varten.

## Seuraava vaihe

Suunnitellaan ja toteutetaan ensimmäinen yhteinen C++-peliydin Reactor-pelin avulla.

1. Määritellään peliytimen pieni alustasta riippumaton rajapinta: ohjainten tila, peliaika, spritejen piirto, haptiikkatapahtumat sekä pelitilan tallennus ja palautus.
2. Siirretään Reactor-pelin säännöt, pisteytys, ajoitus ja tila GDScriptistä C++:aan. Pidetään Godot- ja ESP32-riippuvuudet peliytimen ulkopuolella.
3. Toteutetaan Godotiin yhteys C++-peliytimeen. Säilytetään nykyinen grafiikkaeditori ja laitteen esikatselu.
4. Valitaan ESP32-toteutuksen kehys (Arduino tai ESP-IDF) ja tehdään samaa peliydintä käyttävä ensimmäinen laitetoteutus.
5. Määritellään spritejen vienti laitteelle sopivaan muotoon ja tarkistetaan pelin toiminta oikealla näytöllä ja ohjaimilla.

Ensimmäinen tavoite on saada Reactor toimimaan Godotissa C++-peliytimellä niin, että sama ydin voidaan kääntää ESP32-S3:lle. Valmis siirto edellyttää myös laiteversion kääntämistä ja testaamista; pelkkä toimiva Godot-versio ei vielä varmista laitetukea.

## Vielä avoinna

- Godotin ja C++-ytimen yhdistämistapa sekä käännöstyökalut.
- Arduino- tai ESP-IDF-kehys ja laitteiston lopulliset liitännät.
- Spritejen laiteformaatti ja piirron muistibudjetti.
- Suorituskyky, virrankulutus, heräämisviive ja ohjainten tuntuma oikealla laitteella.
- Monen pelin valikko, liikeohjainten simulointi ja syötteiden tallennus/toisto ovat edelleen myöhempää työtä.

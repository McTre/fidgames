# FidGames

FidGames on avaimenperäkokoinen fidget-pelilaite lyhyisiin pelisessioihin. Tavoitteena ovat miellyttävät fyysiset ohjaimet, yhdellä kädellä pelattavat pelit ja ennätysten tavoittelu. Pelin pitää jatkua lukituksen jälkeen siitä, mihin pelaaja jäi.

Suunniteltu laite perustuu LILYGO T-Display-S3:een. Ohjaimina ovat magneettisesti keskittävä liukusäädin, takaliipaisin ja lukituspainike. Haptiikka antaa palautetta äänen sijaan.

## Nykyinen toteutus

Projektissa on Godotilla tehty **FidGames Lab**, jolla voi kokeilla peli-ideoita ja piirtää niiden grafiikkaa ennen laitteiston toteuttamista.

- Laitenäytön resoluutio on **170 × 320 pikseliä**, oletuksena 2×-esikatselu (**340 × 640**).
- Työkalu toimii erillisessä **1380 × 900** ikkunassa.
- Pelattava Reactor-prototyyppi käyttää projektin omia spritejä.
- Liukusäätimen ja liipaisimen simulointi, lukitus, pelitilan tallennus ja palautus.
- Pixel Studio: kahdeksan väriä, läpinäkyvyys, piirtäminen, pyyhkiminen ja kumoaminen.
- Animaatioissa 1–6 ruutua, toisto ja säädettävä kesto.
- PNG-tallennus, animaation vienti erillisiksi kuviksi sekä muokattavien `.fidsprite`-tiedostojen tallennus ja avaus.
- Piirrettyjä objekteja voi raahata laitenäytölle, siirtää ja vertailla oikeassa pikselikoossa.

Kyseessä on pelinkehitystyökalu. ESP32-laiteohjelmistoa tai laitteiston tarkkaa emulointia ei ole vielä toteutettu.

## Käynnistys

Käytetty versio: **Godot 4.7.2 stable**, GDScript ja GL Compatibility -renderöinti.

1. Tuo [emulator/project.godot](emulator/project.godot) Godotiin.
2. Käynnistä projekti painamalla **F5**.
3. Poista Godotin upotettu peliesikatselu käytöstä, jos haluat työkalun omaan ikkunaan.

Jos Godot on PATH-muuttujassa, voit käynnistää projektin juuresta:

```text
godot --path emulator
```

| Ohjain | Toiminto |
| --- | --- |
| A/D tai nuolinäppäimet | Liukusäädin, joka palautuu vapautettaessa keskelle |
| Hiiri | Liukusäätimen raahaus ja editorin käyttö |
| Space | Liipaisin / pelin aloitus |
| L | Lukitus ja jatkaminen |
| R | Pelin uudelleenkäynnistys |

Ikkunan menettäessä fokuksen peli lukittuu automaattisesti. Jatka painamalla L. Piirrokset pitää tallentaa ennen sulkemista; objektien vertailuasettelu on väliaikainen.

## Viimeksi tehty

- Lisätty periaate selkeästä, kokeilemalla opittavasta pelaamisesta: ei turhia ohjetekstejä, piilosääntöjä tai monimutkaisia yksityiskohtia.
- Siistitty pelinäyttö: ylhäällä **RACTOR** ja pisteet, alhaalla **START** tai **MISSED** tilanteen mukaan.
- Osuma-alue pysyy vakiona koko 32 pikselin kohteen levyisenä. Vaikeus kasvaa lyhenevän aikarajan kautta.
- Otettu käyttöön piirretyt [cursor.png](emulator/Sprites/cursor.png), [goal.png](emulator/Sprites/goal.png) ja [Line.png](emulator/Sprites/Line.png).
- Muutettu oletusgrafiikka karkeammaksi: **32 × 32** näyttöpikselin objekti piirretään **8 × 8** ruudukossa. Yksi ruutu vastaa **4 × 4** näyttöpikseliä.
- Lisätty **64 × 64** objektikoko, jossa piirtoalue on **16 × 16** ruutua. Vanhat piirrokset avautuvat alkuperäisellä tarkkuudellaan.

## Suunnitelmat ja ohjeet

- [MasterPlan.md](MasterPlan.md) – laitteen idea ja tavoitteet.
- [HardwarePlan.md](HardwarePlan.md) – suunniteltu laitteisto.
- [SoftwarePlan.md](SoftwarePlan.md) – ohjelmisto ja pelinkehityksen periaatteet.
- [GameDevToolPlan.md](GameDevToolPlan.md) – kehitystyökalun suunnitelma ja toteutustilanne.
- [Emulaattorin ohjeet](emulator/README.md) – grafiikkaeditori, tallennus ja uusien pelien lisääminen.

## Tarkistukset

Aja projektin juuresta:

```text
godot --headless --path emulator --editor --import --quit
godot --headless --path emulator --script res://tests/smoke.gd
godot --headless --path emulator --script res://tests/studio.gd
```

Testit kattavat pelin keskeiset toiminnot, tilan palautuksen, sprite-editorin, animaatiorajan ja kuvaviennin. Graafinen raahaustesti ja esikatselukuva:

```text
godot --path emulator --script res://tests/studio.gd -- --capture
```

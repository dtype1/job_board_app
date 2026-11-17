# Bacheca Lavoro – App Flutter

App Flutter per una bacheca di annunci di lavoro. Le **aziende** si registrano,
pubblicano annunci e consultano le candidature; i **candidati**, senza registrarsi,
consultano la bacheca e si candidano inviando dati e curriculum.

Back-end: repository [`job_board_backend`](https://github.com/dtype1/job_board_backend) (Dart + shelf).

## Avvio

1. Avviare il back-end (`dart run bin/server.dart`) e annotare l'indirizzo Wi-Fi stampato
   (es. `http://192.168.1.2:8080`).
2. Collegare lo smartphone Android (debug USB attivo) e lanciare:
   ```bash
   flutter pub get
   flutter run
   ```
3. Nell'app toccare l'icona **Impostazioni server** (in alto a destra), inserire l'indirizzo
   del server e premere *Salva e verifica connessione*. L'indirizzo resta memorizzato.

In alternativa si può fissare l'indirizzo in compilazione:
`flutter run --dart-define=API_URL=http://192.168.1.2:8080`.
Sull'emulatore Android l'indirizzo predefinito `http://10.0.2.2:8080` funziona già.

## Funzionalità

| Requisito | Dove |
|---|---|
| R1 Registrazione azienda | Area aziende → "Registra la tua azienda" |
| R2 Login | Area aziende → Accedi |
| R3 Logout | Area riservata → icona logout |
| R4 Pubblicazione annuncio | Area riservata → "Nuovo annuncio" |
| R5 Consultazione bacheca | Schermata iniziale + dettaglio annuncio |
| R6 Candidatura | Dettaglio annuncio → "Candidati" (nome, cognome, email, CV) |
| R7 Consultazione candidature | Area riservata → annuncio → candidatura → "Apri curriculum" |

La sessione dell'azienda (token) è salvata con `shared_preferences`, quindi resta attiva
alla riapertura dell'app finché non si esegue il logout.

## Scenari (per i video)

**S1 – Pubblicare un annuncio**
Bacheca → *Area aziende* → *Registra la tua azienda* → compila e *Crea account* →
torna al login con email precompilata → inserisci password → *Accedi* (area riservata) →
*Nuovo annuncio* → titolo e descrizione → *Pubblica annuncio* → indietro alla bacheca:
l'annuncio è in elenco.

**S2 – Candidarsi** (se l'azienda è ancora loggata, prima fare logout)
Bacheca → tocca l'annuncio (dettaglio) → *Candidati* → nome, cognome, email →
*Scegli* il CV PDF → *Invia candidatura* → schermata di conferma.

**S3 – Consultare le candidature e uscire**
*Area aziende* → login → nell'area riservata tocca l'annuncio → elenco candidature →
tocca una candidatura (dati del candidato) → *Apri curriculum* (si apre nel visualizzatore
PDF del telefono) → indietro → icona *Logout* → *Esci* → l'app torna alla bacheca e il
pulsante mostra di nuovo "Area aziende" (serve un nuovo login).

## Struttura

```
lib/
  main.dart                 avvio, tema
  session.dart              indirizzo server + sessione azienda (persistiti)
  api_client.dart           chiamate HTTP al back-end
  models.dart               Company, Job, JobApplication
  widgets.dart              componenti e validatori comuni
  screens/
    board_screen.dart              bacheca pubblica (R5)
    job_detail_screen.dart         dettaglio annuncio (R5)
    apply_screen.dart              form candidatura + conferma (R6)
    login_screen.dart              login (R2)
    register_screen.dart           registrazione (R1)
    company_home_screen.dart       area riservata, logout (R3, R7)
    new_job_screen.dart            nuovo annuncio (R4)
    job_applications_screen.dart   candidature di un annuncio (R7)
    application_detail_screen.dart dati candidato + apertura CV (R7)
    server_settings_screen.dart    indirizzo del server
```

Pacchetti: `http`, `file_picker`, `shared_preferences`, `path_provider`, `open_filex`.

# Schemat bazy danych PostgreSQL dla 10x-cards MVP

## Tabele

### 1. `flashcards_gen_sessions` - Sesje generowania AI

| Kolumna | Typ | Ograniczenia | Opis |
|---------|-----|--------------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | Unikalny identyfikator |
| user_id | UUID | FK -> auth.users, NOT NULL | Użytkownik |
| source_text | TEXT | NOT NULL, CHECK (length >= 1000 AND length <= 10000) | Tekst wejściowy |
| proposals | JSONB | NOT NULL, DEFAULT '[]' | Tablica propozycji fiszek |
| generated_count | INTEGER | NOT NULL, DEFAULT 0 | Liczba wygenerowanych propozycji |
| accepted_count | INTEGER | NOT NULL, DEFAULT 0 | Liczba zaakceptowanych fiszek |
| created_at | TIMESTAMPTZ | DEFAULT now() | Data utworzenia |
| updated_at | TIMESTAMPTZ | DEFAULT now() | Data ostatniej modyfikacji |

### 2. `flashcards` - Fiszki użytkowników

| Kolumna | Typ | Ograniczenia | Opis |
|---------|-----|--------------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | Unikalny identyfikator |
| user_id | UUID | FK -> auth.users, NOT NULL | Właściciel fiszki |
| front | VARCHAR(500) | NOT NULL | Przód fiszki (pytanie) |
| back | VARCHAR(2000) | NOT NULL | Tył fiszki (odpowiedź) |
| source | VARCHAR(20) | NOT NULL, CHECK (source IN ('manual', 'ai_generated')) | Źródło utworzenia |
| generation_id | UUID | FK -> flashcards_gen_sessions, NULL | Referencja do sesji AI (jeśli dotyczy) |
| created_at | TIMESTAMPTZ | DEFAULT now() | Data utworzenia |
| updated_at | TIMESTAMPTZ | DEFAULT now() | Data ostatniej modyfikacji |

### Struktura JSONB `proposals`

```json
[
  {
    "id": "uuid",
    "front": "Pytanie",
    "back": "Odpowiedź", 
    "status": "pending|accepted|rejected"
  }
]
```

## Indeksy

```sql
-- Pobieranie fiszek użytkownika
CREATE INDEX idx_flashcards_user_id ON flashcards(user_id);

-- Historia sesji generowania użytkownika
CREATE INDEX idx_flashcards_gen_sessions_user_id ON flashcards_gen_sessions(user_id);
```

## Row Level Security (RLS)

Polityki RLS dla każdej tabeli zapewnią izolację danych:

```sql
-- flashcards: użytkownik widzi tylko swoje fiszki
ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own flashcards" ON flashcards
    FOR ALL USING (user_id = auth.uid());

-- flashcards_gen_sessions: użytkownik widzi tylko swoje sesje
ALTER TABLE flashcards_gen_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own flashcards_gen_sessions" ON flashcards_gen_sessions
    FOR ALL USING (user_id = auth.uid());
```

## Kaskadowe usuwanie

```sql
-- Przy usunięciu użytkownika - usuń wszystkie jego dane
flashcards.user_id -> ON DELETE CASCADE
flashcards_gen_sessions.user_id -> ON DELETE CASCADE
```

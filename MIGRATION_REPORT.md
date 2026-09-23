# Rapport de migration LangChain 1.x : exam_Langchain

Date : 2026-09-23. Objectif : mêmes versions que le cours (`Learn_Content`, chapitres FR/EN 01 et 06) et que les branches `chap1` à `chap5` de `Langchain_Cours_MLOps`.

## Versions avant / après (vérifiées sur PyPI le 2026-09-23)

| Paquet | Avant | Après |
|---|---|---|
| langchain | 1.2.12 | 1.4.2 |
| langchain-core | 1.2.20 | 1.6.4 |
| langgraph | 1.1.3 | 1.2.12 |
| langsmith | 0.7.20 | 0.14.0 |
| langchain-groq | 1.1.2 | 1.1.3 |
| langchain-openai | 1.1.11 | 1.6.4 |
| langchain-community | 0.4.1 | retiré (aucun usage dans l'examen ; package archivé) |
| fastapi | 0.116.1 | 0.141.1 |
| uvicorn | 0.35.0 | 0.53.0 |
| pydantic | 2.11.7 | 2.13.5 |
| pyjwt | 2.10.1 | 2.14.0 |
| python-dotenv | 1.1.1 | 1.2.3 |
| python-multipart | 0.0.20 | 0.0.32 |
| streamlit | 1.47.1 | 1.64.0 |
| requests | 2.32.5 | 2.34.2 |
| pytest | 8.4.1 | 9.1.1 |
| httpx | absent | 0.28.1 (requis par `fastapi.testclient` dans les tests fournis) |

## Fichiers modifiés

- `pyproject.toml` + nouveau `uv.lock` ; `Dockerfile.test` copie maintenant `uv.lock`.
- `src/api/assistant/requirements.txt`, `src/api/authentification/requirements.txt`, `src/requirements.txt` : mêmes pins.
- `README.md` : bloc « Versions de référence » et `CHAT_MODEL="groq:openai/gpt-oss-120b"`. `llama-3.3-70b-versatile` a été arrêté par Groq le 2026-08-16. Le texte est identique au chapitre 06 du cours (FR).
- `.env` (placeholders) : `LANGCHAIN_TRACING_V2` / `LANGCHAIN_API_KEY` / `LANGCHAIN_ENDPOINT` remplacés par `LANGSMITH_TRACING` / `LANGSMITH_API_KEY` / `LANGSMITH_PROJECT`, comme dans le README ; ajout de `CHAT_MODEL`.

Livrables d'examen inchangés : mêmes endpoints, même structure, mêmes tests.

## Tests

- `uv sync` : OK (Python 3.13).
- Le squelette est volontairement vide, donc les tests fournis ne peuvent pas passer tels quels. Pour vérifier qu'ils restent valides avec la nouvelle pile, ils ont été lancés sur une implémentation de référence minimale, non commitée. Elle suit les patterns du cours : `prompt | llm.with_structured_output(...)`, `create_agent` + `InMemorySaver` + `thread_id`, FastAPI, JWT.
  Résultat : **6 passed, 3 skipped** (les 3 tests Docker `RUN_CONTAINER_TESTS`, ignorés hors conteneur, comme prévu). Aucun `DeprecationWarning`.
- `Langchain_Cours_MLOps/scripts/check_versions.sh` avec `EXAM_PYPROJECT=../exam_Langchain/pyproject.toml` : versions identiques (27 paquets).

## Points d'attention

- pyjwt 2.14 émet `InsecureKeyLengthWarning` si la clé HMAC fait moins de 32 octets. Ce n'est pas bloquant, mais un élève qui choisit une clé courte verra ce warning.
- Tests live et tests Docker (`make tests`) non exécutés : aucune clé API valide n'était disponible, et Docker n'a pas été lancé.

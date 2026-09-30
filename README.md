# Examen LangChain : Assistant de Tests Unitaires Python

## Consignes générales

L'examen a pour objectif de développer un assistant intelligent capable d'analyser du code Python, de générer automatiquement des tests unitaires avec `pytest`, et d'expliquer ces tests de manière pédagogique.

Pour y parvenir, vous devrez mettre en place une architecture complète combinant plusieurs outils :

- **LangChain** pour gérer les chaînes, les prompts, les schémas structurés et la mémoire
- **FastAPI** pour exposer les fonctionnalités à travers une API
- **Docker** avec un **Makefile** afin de conteneuriser et d'orchestrer l'ensemble du projet
- une interface utilisateur avec **Streamlit** peut être ajoutée en complément, mais elle reste optionnelle

Pour réaliser cet examen, un répertoire GitHub vous est mis à disposition :
[langchain_examen](https://github.com/DataScientest/exam_Langchain)

La première étape consiste à cloner ce dépôt sur votre machine afin de disposer de toute la structure de projet attendue.

Ce dépôt sert de squelette : il vous fournit l'architecture de base que vous devrez compléter en implémentant les différents composants.

## Versions de référence

Pour rester aligné avec le cours, vous pouvez partir sur les versions suivantes :

```toml
langchain = "1.4.2"
langchain-core = "1.6.4"
langgraph = "1.2.12"
langsmith = "0.14.0"
langchain-groq = "1.1.3"
langchain-openai = "1.6.4"
fastapi = "0.141.1"
uvicorn = "0.53.0"
python-multipart = "0.0.32"
pydantic = "2.13.5"
python-dotenv = "1.2.3"
```

## Structure du projet

```txt
exam_Langchain/
├── .env
├── .python-version
├── pyproject.toml
├── Makefile
├── docker-compose.yml
├── README.md
└── src/
    ├── api/
    │   ├── authentification/
    │   │   ├── Dockerfile.auth
    │   │   ├── requirements.txt
    │   │   └── auth.py
    │   └── assistant/
    │       ├── Dockerfile.main
    │       ├── requirements.txt
    │       └── main.py
    ├── core/
    │   ├── llm.py
    │   ├── chains.py
    │   └── schemas.py
    ├── memory/
    │   └── memory.py
    ├── prompts/
    │   └── prompts.py
    ├── Dockerfile.streamlit
    ├── requirements.txt
    └── app.py
```

L'ensemble des consignes décrites ci-dessous doit être suivi en vous appuyant sur cette structure déjà préparée.

Les dépendances sont déclarées une seule fois dans `pyproject.toml`, avec un groupe par service (`auth`, `assistant`, `streamlit`).
Les fichiers `requirements.txt` de chaque service en sont générés : si vous ajoutez une dépendance, ajoutez-la au bon groupe, puis lancez `make requirements`.

### Le LLM (`src/core/llm.py`)

Le coeur de l'assistant repose sur le modèle de langage.
Ce fichier a pour rôle de configurer et d'initialiser le modèle choisi.

L'implémentation doit inclure :

- un modèle principal, utilisé par défaut pour toutes les requêtes
- une récupération des clés API depuis le fichier `.env`

Exemple de variables d'environnement :

```env
GROQ_API_KEY="your_api_key"
CHAT_MODEL="groq:openai/gpt-oss-120b"
LANGSMITH_TRACING=true
LANGSMITH_API_KEY=<your_api_key>
LANGSMITH_PROJECT=exam_langchain
```


### Les Prompts (`src/prompts/prompts.py`)

Les prompts jouent un rôle central dans l'architecture.
Ils définissent la manière dont le modèle doit raisonner et formuler ses réponses.

Dans cet examen, vous devez mettre en place différents prompts correspondant aux fonctionnalités attendues de l'assistant :

- **Prompt d'analyse de code** : demande au LLM d'évaluer un extrait de code Python et de déterminer s'il est optimal. Le modèle doit identifier d'éventuels problèmes et proposer des améliorations.
- **Prompt de génération de tests unitaires** : à partir d'une fonction Python donnée, l'assistant doit produire un test unitaire en `pytest`.
- **Prompt d'explication de tests** : explication pédagogique et détaillée d'un test unitaire.
- **Prompt de conversation libre** : discussion naturelle avec l'utilisateur.

Chaque prompt doit être construit de façon claire, avec les bons placeholders, afin que le modèle reçoive les bonnes informations.

### Les schémas structurés (`src/core/schemas.py`)

Les sorties du modèle doivent être transformées en objets structurés et exploitables.

Dans cet examen, vous pouvez vous appuyer sur des schémas Pydantic, par exemple :

- `CodeAnalysisResult`
- `GeneratedTestResult`
- `TestExplanationResult`

Ces schémas doivent permettre :

- une validation du format attendu
- un retour clair dans les endpoints API
- une meilleure robustesse face aux erreurs de format du modèle

### Les Chaînes (`src/core/chains.py`)

Les chaînes LangChain constituent le coeur logique de l'assistant.
Chaque fonctionnalité repose sur une chaîne dédiée.

Vous devez mettre en place plusieurs chaînes :

- **Chaîne d'analyse de code** : utilise le prompt d'analyse, envoie la requête au LLM, puis structure la réponse.
- **Chaîne de génération de tests unitaires** : prend en entrée une fonction Python et renvoie un test unitaire en `pytest`.
- **Chaîne d'explication de tests** : transforme un test Python en une explication claire et pédagogique.
- **Agent de chat libre** : un agent avec mémoire (`create_agent` + `checkpointer`, comme au chapitre 4) qui garde le contexte de la conversation.

Pattern attendu pour les chaînes structurées :

```python
chain = prompt | llm.with_structured_output(MySchema, method="json_schema")
```

Chaque chaîne doit être construite de manière simple et modulaire, afin que l'API puisse les invoquer directement.

### La Mémoire (`src/memory/memory.py`)

La mémoire doit être implémentée de manière à gérer plusieurs utilisateurs en parallèle.

Points importants à respecter :

- le `thread_id` ou identifiant utilisateur doit être unique
- une solution en mémoire suffit pour l'examen
- le système doit permettre de conserver l'historique d'une conversation tant que le service tourne

### Les APIs (`src/api/`)

L'examen repose sur deux APIs distinctes, toutes deux développées avec FastAPI et exécutées dans des conteneurs séparés.

#### L'API d'authentification (`src/api/authentification/`)

Cette API est dédiée à la gestion de la sécurité et des utilisateurs. Elle doit permettre :

- **L’inscription (signup)** : créer un nouvel utilisateur et l’enregistrer dans une base (ici simulée par une structure interne).
- **La connexion (login)** : vérifier les identifiants permettant d’accéder aux autres services.

Chaque endpoint doit renvoyer des erreurs claires en cas de problème.

#### L'API principale (`src/api/assistant/`)

Cette API constitue le coeur de l'assistant. Elle doit exposer plusieurs endpoints permettant d'interagir avec les chaînes définies dans `src/core/`.

Les fonctionnalités attendues sont :

- **Analyser un code Python (`/analyze`)**
- **Générer un test unitaire (`/generate_test`)**
- **Expliquer un test (`/explain_test`)**
- **Exécuter le pipeline complet (`/full_pipeline`)**
- **Chat conversationnel (`/chat`)**
- **Historique (`/history`)**

Rôle de chaque endpoint :

- **`/analyze`** : reçoit un code Python et renvoie une analyse structurée du code
- **`/generate_test`** : reçoit un code Python et renvoie un test unitaire `pytest`
- **`/explain_test`** : reçoit un test et renvoie une explication pédagogique
- **`/full_pipeline`** : enchaîne plusieurs étapes automatiquement pour éviter à l'utilisateur de les lancer une par une
- **`/chat`** : permet une conversation libre avec mémoire entre plusieurs messages
- **`/history`** : permet de consulter les échanges déjà enregistrés pour une session ou un utilisateur

Points d'attention :

- les résultats des endpoints `/analyze`, `/generate_test`, `/explain_test` et `/full_pipeline` doivent être enregistrés dans l'historique associé à l'utilisateur
- les deux APIs doivent tourner dans des conteneurs distincts
- l'API principale dépend de l'API d'authentification pour vérifier l'identité des utilisateurs
- une gestion rigoureuse des erreurs est indispensable : les exceptions doivent être transformées en réponses HTTP explicites

### Logique du pipeline complet

L'endpoint `/full_pipeline` doit suivre cette logique :

1. analyser le code soumis
2. si le code est jugé non optimal, arrêter le pipeline et renvoyer l'analyse
3. sinon, générer un test unitaire
4. puis expliquer ce test de manière pédagogique

Cette logique permet de montrer que l'application sait prendre une décision simple en fonction d'un premier résultat.

### Suivi et Monitoring avec LangSmith

Pour améliorer la traçabilité et le suivi de l'assistant, il est nécessaire d'intégrer LangSmith.

LangSmith permet notamment de :

- tracer toutes les requêtes envoyées au LLM
- visualiser les chaînes et leurs étapes
- déboguer plus facilement en cas d'erreur
- comparer plusieurs versions de prompts ou de chaînes

Une bonne habitude est de tester vos endpoints dans `/docs`, puis d'aller voir ensuite dans LangSmith :

- le prompt réellement envoyé
- la réponse du modèle
- la chaîne ou l'agent utilisé
- les éventuelles erreurs

### Interface Streamlit

En plus des APIs, vous pouvez proposer une interface utilisateur développée avec Streamlit.
Elle reste **optionnelle**.

Fonctionnalités possibles :

- authentification et connexion
- analyse de code
- génération de tests
- explication de tests
- pipeline complet
- chat libre
- affichage de l'historique

### Déploiement avec Docker et Makefile

L'ensemble du projet doit être conteneurisé afin de garantir une mise en place simple, reproductible et indépendante de l'environnement de développement.

Services attendus :

- **auth** : l'API d'authentification
- **main** : l'API principale
- **streamlit** : l'interface utilisateur si vous choisissez de l'ajouter

### Makefile

Chaque service dispose de son propre `Dockerfile` et de ses dépendances.

Le Makefile doit centraliser toutes les commandes utiles au projet. Lse déploiement complet du projet ne doit nécessiter qu’une seule commande :

```bash
make
```

### README.md

Votre projet doit obligatoirement contenir un fichier `README.md` clair et structuré.
Ce document doit expliquer le fonctionnement global de votre assistant, ainsi que la manière de le déployer et de le tester.

Il doit notamment contenir :

- les étapes pour configurer le fichier `.env`
- les commandes principales du `Makefile`
- la liste des endpoints disponibles et des ports

### Tests à réaliser (make tests)

Instructions minimales à prévoir pour vérifier que l'API fonctionne correctement :

- inscription
- login
- analyse
- génération de test
- explication
- pipeline complet
- chat avec mémoire
- affichage de l'historique

## Rappels et conseils

Avant de commencer, gardez en tête les points suivants :

- **Organisation** : respectez scrupuleusement la structure fournie
- **Variables d'environnement** : ne mettez jamais vos clés en clair dans le code
- **Prompts** : utilisez les bons placeholders pour injecter les informations utiles
- **Schémas structurés** : utilisez-les pour fiabiliser les sorties du modèle
- **Mémoire** : utilisez un identifiant clair pour éviter de mélanger les historiques
- **Docker** : ne mettez dans vos images que ce qui est nécessaire
- **README** : écrivez-le comme si le lecteur ne connaissait pas votre projet
- **Tests** : vérifiez les fonctionnalités au fur et à mesure

## Rendu

N'oubliez pas d'uploader votre examen au format d'une archive zip ou tar, dans l'onglet **Mes Exams**, après avoir validé tous les exercices du module.

> ⚠️ **IMPORTANT** ⚠️ : N’envoyez pas votre environnement virtuel (par ex. .venv ou uv) dans votre rendu. En cas de non-respect de cette consigne, un **repass automatique** de l’examen vous sera attribué.

Félicitations ! Si vous avez atteint ce point, vous avez terminé le module sur LangChain et LLM Experimentation ! 🎉.
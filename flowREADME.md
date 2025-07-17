Start: fetchAndPostListingsForUser(user)
├── Calls Source APIs:
│   ├── Zillow via ScraperAPI
│   ├── Redfin via ScraperAPI
│   └── Repliers.io API
│
└── Live Listings Found?
    ├── Yes →
    │   └── Normalize Listings to FeedModel (PostTypes.PropertyListing)
    │       └── Deduplicate Listings (MLS #, Address)
    │           └── Post Listings to Firebase Feed
    │
    └── No →
        └── Trigger HistoricalListingService
            └── Fetch Historical Listings:
                ├── Zillow
                ├── Redfin
                ├── Repliers
                └── County Data
                    └── Tag as OffMarket/Historical
                        └── Post Listings to Firebase Feed

Genii Feed OS
├──→ AI Agents Layer
│     └──→ Memory and Scoring
├──→ Memory and Scoring
├──→ Factory and Install Ops
│     └──→ Housing SKUs
├──→ Customer Funnel and CRM
├──→ Contractor App
├──→ MLS and Land Ingest
└──→ Capital: REIT / HoldCo / Refi

Data ↔ Genii Feed OS (feedback loop)

AI Agent Layer
├──→ Task Agent
│     └──→ Outcome Trainer
├──→ Insight Agent
│     └──→ Outcome Trainer
├──→ Router / Dispatcher
│     └──→ Outcome Trainer
└──→ Outcome Trainer
      └──→ Vector DB
Vector DB → AI Agent Layer (feedback loop)

Vector Memory
├──← Document Parser
├──← Feed Threads
├──← Property Logs and History
├──← Feedback Loop
└──→ Scoring Engine




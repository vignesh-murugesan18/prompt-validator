examples = [
  {
    title: "Marketing Seminar Landing Page",
    score: 4.8,
    prompt_text: "Create a landing page for my marketing seminar where people can register their interest. If they register, they get a free PDF with information about the event and what to expect. I use Kit.com for my newsletter and already uploaded the PDF to Google Drive. What else do I need?"
  },
  {
    title: "Lead Capture Page",
    score: 8.9,
    prompt_text: "You are a Next.js expert who builds lead capture pages with API integrations. Before writing code, explain what React hooks you will use and how you will handle form state. Then create the implementation in steps. Step 1: create a landing page at /lp/lead-magnet in my existing Next.js 16 project using TypeScript and Tailwind 3.4. Follow the form patterns in our /contact page if you can access it."
  },
  {
    title: "Rails Activity Metrics",
    score: 9.2,
    prompt_text: "Act as a senior Rails engineer working in a production-scale application. We currently show one tour completed column in admin activity metrics. Add three additional columns using the tour_stats payload with total_completed, completed_last_7_days, completed_last_30_days, and completion_rate. Update the controller, query object, model tests, and request specs while preserving the existing CSV export format."
  },
  {
    title: "Vague Product Idea",
    score: 2.9,
    prompt_text: "I want to build a peer-to-peer tutoring platform based on Superprof, but for current and former students helping younger students with primary and secondary curriculum materials."
  }
]

examples.each_with_index do |attributes, index|
  ExamplePrompt.find_or_initialize_by(title: attributes[:title]).tap do |example|
    example.assign_attributes(attributes.merge(position: index + 1))
    example.save!
  end
end

templates = [
  {
    title: "Rails bug investigation (with reproduction)",
    slug: "rails-bug-investigation",
    category: "Debugging",
    description: "A structured prompt that forces reproduction steps, logs, and a safe fix plan before code changes.",
    web_search_default: false,
    ai_model: "llama-3.3-70b-versatile",
    prompt_text: <<~TEXT
      You are a senior Rails engineer. Before suggesting fixes, ask clarifying questions if anything is missing.

      Step 1: Restate the bug in one sentence and list 3 hypotheses.
      Step 2: Propose the smallest reproducible test or console reproduction steps.
      Step 3: Identify the most likely root cause in the existing code (name files/functions to inspect).
      Step 4: Provide a safe fix with rollback plan, and a test plan (unit + request/system as appropriate).

      Context:
      - Rails version:
      - Error message / stack trace:
      - What changed recently:
      - Expected vs actual behavior:
      - Relevant code paths (files/classes):
    TEXT
  },
  {
    title: "Feature build spec (scoped MVP)",
    slug: "feature-build-mvp-spec",
    category: "Productivity",
    description: "Turns a vague feature request into a clear, testable MVP with edge cases and error handling.",
    web_search_default: true,
    ai_model: "llama-3.1-8b-instant",
    prompt_text: <<~TEXT
      Act as a senior SaaS product engineer. If any requirement is unclear, ask questions before proposing an implementation.

      Goal: <one sentence>
      Users: <who uses it>
      Constraints: <tech constraints, latency, cost, security>

      Step 1: Write an MVP spec with acceptance criteria and non-goals.
      Step 2: List edge cases and error states (new users + existing users).
      Step 3: Propose a data model and API/UI flow.
      Step 4: Provide an incremental implementation plan (small PR-sized steps).
      Step 5: Provide a test plan.
    TEXT
  },
  {
    title: "Refactor plan (safe and incremental)",
    slug: "safe-refactor-plan",
    category: "Engineering",
    description: "A refactor prompt that prioritizes safety, observability, and incremental rollout.",
    web_search_default: false,
    ai_model: "llama-3.1-8b-instant",
    prompt_text: <<~TEXT
      You are a principal engineer. Before writing code, propose 2-3 refactor approaches with trade-offs.
      Prioritize safety and incremental rollout.

      Step 1: Identify the current pain (performance, readability, coupling, bugs).
      Step 2: Suggest a target design and incremental steps.
      Step 3: Include error handling and rollback strategy.
      Step 4: Provide a test plan and success metrics.

      Existing code (key files/snippets):
      - <paste here>
    TEXT
  }
]

templates.each do |attributes|
  PromptTemplate.find_or_initialize_by(slug: attributes[:slug]).tap do |template|
    template.assign_attributes(attributes.merge(public: true))
    template.save!
  end
end

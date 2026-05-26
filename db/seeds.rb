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

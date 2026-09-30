#import "template.typ": *

#show: academic-notes.with(
  // --- Required
  title: "Algo Web",
  subtitle: "Unimi - Master's Degree in Computer Science",
  authors: (
    ("Luca Corradini", "LucaCorra02"),
    ("Giacomo comitatno", "ComitaniGiacomo"),
  ),
  lang: "en", // or "it", IMPORTANT!

  // --- Optional, uncomment to change
  repo-url: "https://github.com/LucaCorra02/Algo-Web",
  course-url: "https://university/professor/course",
  year: "2026-27",
  lecturer: "Sebastiano Vigna",
  // date: datetime.today(),
  // license: "CC-BY-4.0",
  // license-url: "https://creativecommons.org/licenses/by/4.0/",
  // heading-numbering: "1.1.",
  // equation-numbering: none,
  // page-numbering: "1",

  // --- Optional with language-based defaults, uncomment to change
  // introduction: auto,
  // last-modified-label: auto,
  // outline-title: auto,
  // part-label: auto,
  // note-title: auto,
  // warning-title: auto,
  // informally-title: auto,
  // example-title: auto,
  // proof-title: auto,
  // theorem-title: auto,
  // theorem-label: auto,
  // equation-supplement: auto,
  // figure-supplement: auto,
)

// ============================================================================
// YOUR CONTENT STARTS HERE
// ============================================================================

#part("First Part")
#include "chapters/L1.typ"
#include "chapters/L2.typ"
#include "chapters/L4.typ"
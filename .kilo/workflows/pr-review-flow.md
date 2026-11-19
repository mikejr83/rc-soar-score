---
name: PR Review Revision Pipeline
description: Two-stage workflow that uses a high-reasoning planner to audit PR comments and a fast implementer to execute code fixes.
---

# PR Review Revision Workflow

Follow this procedure sequentially to process reviewer feedback, plan surgical code updates, and verify implementation.

<Sequence>
  <Step subtitle="Context Preparation" title="Gather PR Context & Review Findings">
    Collect all review comments, inline suggestions, and current git branch diff into a single reference file at `.kilo/pr_context.md`.
    
    Ensure `.kilo/pr_context.md` and `.kilo/PR_REVISION_PLAN.md` are added to your project's `.gitignore` file so temporary operational files are not committed to source control.
  </Step>

  <Step subtitle="Phase 1: Planning (pr-planner)" title="Generate Revision Strategy">
    Switch to or delegate task to the `@pr-planner` agent:
    
    > **Prompt to Agent:** "Read `.kilo/pr_context.md` and inspect the referenced files. Analyze the root cause of the review feedback and draft a step-by-step resolution plan. Write the final output strictly to `.kilo/PR_REVISION_PLAN.md`."
    
    The `@pr-planner` agent will inspect the code base (read-only) and emit `.kilo/PR_REVISION_PLAN.md`.
  </Step>

  <Step subtitle="Optional Gate" title="Review & Approve Plan">
    Inspect `.kilo/PR_REVISION_PLAN.md` to verify:
    - Target files under `Allowed Files` match expected scope.
    - Logic changes adhere to repository patterns.
    - Verification commands are correctly specified.
  </Step>

  <Step subtitle="Phase 2: Execution (pr-implementer)" title="Apply Code Changes & Verify">
    Switch to or delegate task to the `@pr-implementer` agent:
    
    > **Prompt to Agent:** "Read `.kilo/PR_REVISION_PLAN.md` and apply the exact modifications to the listed files. Do not modify files outside the plan. Once edits are applied, run the specified verification suite."
    
    The `@pr-implementer` agent will make minimal edits and run test commands via `bash`.
  </Step>

  <Step subtitle="Final Verification" title="Stage Changes & Update PR">
    Check `git status` and `git diff` to confirm only expected changes were made and tests pass, then commit and push to the feature branch.
  </Step>
</Sequence>
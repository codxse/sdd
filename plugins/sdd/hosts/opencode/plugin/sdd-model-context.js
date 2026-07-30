// Give an opencode session the model identity the host never states.
//
// opencode's built-in system context is the working directory, project root, git
// flag, platform, and today's date — and nothing else. No model ID reaches the
// model, so without this every gated sdd skill (/specify, /refine, /orchestrate)
// classifies `unsure` and stops, on a frontier model as readily as a budget one.
// Same gap Kimi Code has, and the same reason it went unnoticed there: `unsure`
// refuses in the same words as `budget`, so a refusal-only test cannot see it.
//
// It injects at **two** seams, and both are load-bearing:
//
//   1. `experimental.chat.system.transform` — the only hook onto the system prompt. Its
//      input carries the resolved model, so the ID comes from the host rather than being
//      reconstructed. Fires for the main session (session/llm/request.ts) and for
//      subagents (agent/agent.ts), which is what the /validate reviewer pin needs. The
//      `experimental.` prefix is opencode's, not ours.
//   2. `tool.execute.after` on the `skill` tool — appends the same ID to the loaded skill
//      body. This one is not redundancy, it is the fix. opencode delivers a skill as a
//      *tool result* mid-conversation, so the tier rubric lands far from the system
//      prompt; asked to classify, a budget model does not look back. Observed on
//      claude-haiku-4-5 with seam 1 alone and the correct ID in the system prompt: it
//      emitted `model-guard: id=claude-opus-4-1 tier=frontier` — an ID it invented,
//      inflating itself to frontier and authoring a story. Putting the ID *in* the skill
//      text, next to the rubric that reads it, is what stops that. Don't drop this seam
//      as duplication.
//
// opencode's default prompt also frames the session as Claude Code, which is where that
// confabulation pulls from — hence the "this line wins" wording below.
//
// Do not "simplify" to a config read. `model` / `small_model` in opencode.json is the
// session's model only when the user did not override it with `-m`, `/models`, or a
// per-agent pin. Asserting it anyway is worse than silence: it tells a budget session
// it is frontier, turning "stop" into "author".
//
// Fail closed: emit nothing when no ID can be established. Silence leaves the session
// `unsure`, which the gated skills already handle by stopping. A confident wrong
// answer does not fail safe.

const qualify = (model) => {
  if (!model) return ""
  // Model.Info carries `id`; older SDK shapes call it `modelID`. Prefer the
  // provider-qualified form, since the tier map matches on ID substrings and a
  // provider prefix never introduces a false match.
  const id = model.id ?? model.modelID ?? ""
  if (!id) return ""
  return model.providerID ? `${model.providerID}/${id}` : id
}

const line = (id) =>
  `Host-reported exact model ID: \`${id}\`. Treat this session fact as authoritative for model-tier classification.`

export const SddModelContext = async () => {
  // The skill tool runs in the same session as the request that triggered it, but its
  // hook input carries no model. Remember what the system-prompt seam last resolved.
  let current = ""

  return {
    "experimental.chat.system.transform": async ({ model }, output) => {
      const id = qualify(model)
      if (!id) return
      current = id
      output.system.push(line(id))
    },
    "tool.execute.after": async (input, output) => {
      if (input.tool !== "skill" || !current) return
      output.output += [
        "",
        line(current),
        "Classify this session's tier from that exact ID. Do not infer an ID from the host's name,",
        "from this skill's examples, or from expectation — where this line and an assumption disagree,",
        "this line wins. If it is absent, you are `unsure`; stop rather than guess.",
      ].join("\n")
    },
  }
}

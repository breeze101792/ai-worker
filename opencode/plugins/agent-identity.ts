import { Plugin } from "@opencode/plugin"

const reminder = (agent: string) =>
  [
    "<system-reminder>",
    `The active agent for this session is \`${agent}\`. Only the instructions in this system prompt apply.`,
    "Earlier turns in this conversation may have been produced by another agent after the user switched.",
    "Their role statements are stale: do not answer as another agent or repeat a refusal made under a different role.",
    "</system-reminder>",
  ].join("\n")

export default Plugin.define({
  id: "agent-identity",
  async setup(ctx) {
    await ctx.session.hook("context", (event) => {
      if (typeof event.agent !== "string" || event.agent.length === 0) return
      event.system.push({ type: "text", text: reminder(event.agent) })
    })
  },
})
